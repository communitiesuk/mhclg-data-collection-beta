module Exports
  class LettingsLogExportService < Exports::XmlExportService
    include Exports::LettingsLogExportConstants
    include CollectionTimeHelper

    def export_xml_lettings_logs(full_update: false, collection_year: nil)
      archives_for_manifest = {}
      collection_years_to_export(collection_year).each do |year|
        recent_export = Export.lettings.where(year:).order("started_at").last
        base_number = Export.lettings.where(empty_export: false, year:).maximum(:base_number) || 1
        export = build_export_run("lettings", base_number, full_update, year)
        archives = write_export_archive(export, year, recent_export, full_update)

        archives_for_manifest.merge!(archives)

        export.empty_export = archives.empty?
        export.save!
      end

      archives_for_manifest
    end

  private

    def get_archive_name(year, base_number, increment)
      return unless year

      base_number_str = "f#{base_number.to_s.rjust(4, '0')}"
      increment_str = "inc#{increment.to_s.rjust(4, '0')}"
      "core_#{year}_#{year + 1}_apr_mar_#{base_number_str}_#{increment_str}".downcase
    end

    def retrieve_resources(recent_export, full_update, year)
      if !full_update && recent_export
        params = { from: recent_export.started_at, to: @start_time }
        LettingsLog.exportable.where("(updated_at >= :from AND updated_at <= :to) OR (values_updated_at IS NOT NULL AND values_updated_at >= :from AND values_updated_at <= :to)", params).filter_by_year(year)
      else
        params = { to: @start_time }
        LettingsLog.exportable.where("updated_at <= :to", params).filter_by_year(year)
      end
    end

    def apply_cds_transformation(lettings_log, export_mode)
      attribute_hash = lettings_log.attributes_before_type_cast
      attribute_hash["formid"] = attribute_hash["old_form_id"] || (attribute_hash["id"] + LOG_ID_OFFSET)

      # We can't have a variable number of columns in CSV
      unless export_mode == EXPORT_MODE[:csv]
        case lettings_log.collection_start_year
        when 2021
          attribute_hash.delete("joint")
        when 2022
          attribute_hash.delete("underoccupation_benefitcap")
        end
      end

      # Organisation fields
      if lettings_log.owning_organisation
        attribute_hash["owningorgid"] = lettings_log.owning_organisation.old_visible_id || (lettings_log.owning_organisation.id + LOG_ID_OFFSET)
        attribute_hash["owningorgname"] = lettings_log.owning_organisation.name
        attribute_hash["hcnum"] = lettings_log.owning_organisation.housing_registration_no
      end
      if lettings_log.managing_organisation
        attribute_hash["maningorgid"] = lettings_log.managing_organisation.old_visible_id || (lettings_log.managing_organisation.id + LOG_ID_OFFSET)
        attribute_hash["maningorgname"] = lettings_log.managing_organisation.name
        attribute_hash["manhcnum"] = lettings_log.managing_organisation.housing_registration_no
      end

      # Covert date times to ISO 8601
      attribute_hash["createddate"] = lettings_log.created_at&.iso8601
      attribute_hash["uploaddate"] = lettings_log.updated_at&.iso8601
      attribute_hash["mrcdate"] = lettings_log.mrcdate&.iso8601
      attribute_hash["startdate"] = lettings_log.startdate&.iso8601
      attribute_hash["voiddate"] = lettings_log.voiddate&.iso8601
      attribute_hash["discarded_at"] = lettings_log.discarded_at&.iso8601

      # Age refused
      (1..8).each do |index|
        attribute_hash["age#{index}"] = -9 if attribute_hash["age#{index}_known"] == 1
      end

      attribute_hash["log_id"] = lettings_log.id
      attribute_hash["assigned_to"] = lettings_log.assigned_to&.email
      attribute_hash["created_by"] = lettings_log.created_by&.email
      attribute_hash["amended_by"] = lettings_log.updated_by&.email

      attribute_hash["la"] = lettings_log.la
      attribute_hash["postcode_full"] = lettings_log.postcode_full

      # Supported housing fields
      if lettings_log.is_supported_housing?
        attribute_hash["unittype_sh"] = lettings_log.unittype_sh
        attribute_hash["sheltered"] = lettings_log.sheltered
        attribute_hash["nocharge"] = lettings_log.household_charge == 1 ? 1 : nil
        attribute_hash["chcharge"] = lettings_log.chcharge
        add_scheme_fields!(lettings_log.scheme, attribute_hash) if lettings_log.scheme
        add_location_fields!(lettings_log.location, attribute_hash) if lettings_log.location
        attribute_hash.delete("unittype_gn")
      end

      # details unknown fields
      (2..8).each do |index|
        next unless lettings_log["details_known_#{index}"] == 1

        attribute_hash["age#{index}"] = -9
        attribute_hash["sex#{index}"] = "R"
        attribute_hash["relat#{index}"] = "R"
        attribute_hash["ecstat#{index}"] = 10
      end

      attribute_hash["renttype_detail"] = LettingsLog::RENTTYPE_DETAIL_MAPPING[lettings_log.rent_type] if lettings_log.rent_type.present?

      attribute_hash
    end

    def add_scheme_fields!(scheme, attribute_hash)
      attribute_hash["confidential"] = scheme.sensitive_before_type_cast == 1 ? 1 : nil
      attribute_hash["cligrp1"] = scheme.primary_client_group_before_type_cast
      attribute_hash["cligrp2"] = scheme.secondary_client_group_before_type_cast
      attribute_hash["intstay"] = scheme.intended_stay_before_type_cast
      attribute_hash["mantype"] = scheme.arrangement_type_before_type_cast
      attribute_hash["reghome"] = scheme.registered_under_care_act_before_type_cast
      attribute_hash["schtype"] = scheme.scheme_type_before_type_cast
      attribute_hash["support"] = scheme.support_type_before_type_cast
      attribute_hash["units_scheme"] = scheme.locations.map(&:units).compact.sum
      attribute_hash["scheme"] = scheme.id
      attribute_hash["scheme_status"] = scheme.status_at(attribute_hash["startdate"])
    end

    def add_location_fields!(location, attribute_hash)
      attribute_hash["mobstand"] = location.mobility_type_before_type_cast
      attribute_hash["scheme_old"] = location.old_visible_id
      attribute_hash["units"] = location.units
      attribute_hash["location_code"] = location.id
      attribute_hash["location_status"] = location.status_at(attribute_hash["startdate"])
    end

    def is_omitted_field?(field_name, lettings_log)
      pattern_age = /age\d_known/
      details_known_prefix = "details_known_"
      field_name.starts_with?(details_known_prefix) ||
        pattern_age.match(field_name) ||
        !EXPORT_FIELDS.include?(field_name) ||
        (lettings_log.form.start_year_2024_or_later? && PRE_2024_EXPORT_FIELDS.include?(field_name)) ||
        (!lettings_log.form.start_year_2024_or_later? && POST_2024_EXPORT_FIELDS.include?(field_name))
    end

    def build_export_xml(lettings_logs)
      doc = Nokogiri::XML("<forms/>")

      lettings_logs.each do |lettings_log|
        attribute_hash = apply_cds_transformation(lettings_log, EXPORT_MODE[:xml])
        form = doc.create_element("form")
        doc.at("forms") << form
        attribute_hash.each do |key, value|
          if is_omitted_field?(key, lettings_log)
            next
          else
            form << doc.create_element(key, value)
          end
        end
        form << doc.create_element("providertype", lettings_log.owning_organisation&.read_attribute_before_type_cast(:provider_type))
      end

      xml_doc_to_temp_file(doc)
    end

    def collection_years_to_export(collection_year)
      return [collection_year] if collection_year.present?

      FormHandler.instance.lettings_forms.values.map { |f| f.start_date.year }.uniq
    end
  end
end
