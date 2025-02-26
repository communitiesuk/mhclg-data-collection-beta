module Exports
  class SalesLogExportService < Exports::XmlExportService
    include Exports::SalesLogExportConstants
    include CollectionTimeHelper

    def export_xml_sales_logs(full_update: false, collection_year: nil)
      archives_for_manifest = {}
      collection_years_to_export(collection_year).each do |year|
        recent_export = Export.sales.where(year:).order("started_at").last
        base_number = Export.sales.where(empty_export: false, year:).maximum(:base_number) || 1
        export = build_export_run("sales", base_number, full_update, year)
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
      "core_sales_#{year}_#{year + 1}_apr_mar_#{base_number_str}_#{increment_str}".downcase
    end

    def retrieve_resources(recent_export, full_update, year)
      if !full_update && recent_export
        params = { from: recent_export.started_at, to: @start_time }
        SalesLog.exportable.where("(updated_at >= :from AND updated_at <= :to) OR (values_updated_at IS NOT NULL AND values_updated_at >= :from AND values_updated_at <= :to)", params).filter_by_year(year)
      else
        params = { to: @start_time }
        SalesLog.exportable.where("updated_at <= :to", params).filter_by_year(year)
      end
    end

    def apply_cds_transformation(sales_log, _export_mode)
      attribute_hash = sales_log.attributes_before_type_cast

      attribute_hash["day"] = sales_log.saledate&.day
      attribute_hash["month"] = sales_log.saledate&.month
      attribute_hash["year"] = sales_log.saledate&.year

      attribute_hash["createddate"] = sales_log.created_at&.iso8601
      attribute_hash["createdby"] = sales_log.created_by&.email
      attribute_hash["createdbyid"] = sales_log.created_by_id
      attribute_hash["username"] = sales_log.assigned_to&.email
      attribute_hash["usernameid"] = sales_log.assigned_to_id
      attribute_hash["uploaddate"] = sales_log.updated_at&.iso8601
      attribute_hash["amendedby"] = sales_log.updated_by&.email
      attribute_hash["amendedbyid"] = sales_log.updated_by_id

      attribute_hash["owningorgid"] = sales_log.owning_organisation&.id
      attribute_hash["owningorgname"] = sales_log.owning_organisation&.name
      attribute_hash["maningorgid"] = sales_log.managing_organisation&.id
      attribute_hash["maningorgname"] = sales_log.managing_organisation&.name

      attribute_hash["creationmethod"] = sales_log.creation_method_before_type_cast
      attribute_hash["bulkuploadid"] = sales_log.bulk_upload_id
      attribute_hash["collectionyear"] = sales_log.form.start_date.year
      attribute_hash["ownership"] = sales_log.ownershipsch
      attribute_hash["joint"] = sales_log.jointpur
      attribute_hash["ethnicgroup1"] = sales_log.ethnic_group
      attribute_hash["ethnicgroup2"] = sales_log.ethnic_group2
      attribute_hash["previouslaknown"] = sales_log.previous_la_known
      attribute_hash["hasmscharge"] = sales_log.has_mscharge

      attribute_hash["hoday"] = sales_log.hodate&.day
      attribute_hash["homonth"] = sales_log.hodate&.month
      attribute_hash["hoyear"] = sales_log.hodate&.year

      attribute_hash["inc1nk"] = sales_log.income1nk
      attribute_hash["inc2nk"] = sales_log.income2nk
      attribute_hash["postcode"] = sales_log.postcode_full
      attribute_hash["islainferred"] = sales_log.is_la_inferred
      attribute_hash["mortlen1"] = sales_log.mortlen
      attribute_hash["ethnic2"] = sales_log.ethnicbuy2
      attribute_hash["prevten2"] = sales_log.prevtenbuy2

      attribute_hash["address1"] = sales_log.address_line1
      attribute_hash["address2"] = sales_log.address_line2
      attribute_hash["towncity"] = sales_log.town_or_city
      attribute_hash["laname"] = LocalAuthority.find_by(code: sales_log.la)&.name
      attribute_hash["address1input"] = sales_log.address_line1_input
      attribute_hash["postcodeinput"] = sales_log.postcode_full_input
      attribute_hash["uprnselected"] = sales_log.uprn_selection

      attribute_hash["bulkaddress1"] = sales_log.address_line1_as_entered
      attribute_hash["bulkaddress2"] = sales_log.address_line2_as_entered
      attribute_hash["bulktowncity"] = sales_log.town_or_city_as_entered
      attribute_hash["bulkcounty"] = sales_log.county_as_entered
      attribute_hash["bulkpostcode"] = sales_log.postcode_full_as_entered
      attribute_hash["bulkla"] = sales_log.la_as_entered
      attribute_hash["nationalityall1"] = sales_log.nationality_all
      attribute_hash["nationalityall2"] = sales_log.nationality_all_buyer2
      attribute_hash["prevlocname"] = LocalAuthority.find_by(code: sales_log.prevloc)&.name
      attribute_hash["liveinbuyer1"] = sales_log.buy1livein
      attribute_hash["liveinbuyer2"] = sales_log.buy2livein

      attribute_hash["has_estate_fee"] = sales_log.has_management_fee
      attribute_hash["estate_fee"] = sales_log.management_fee

      attribute_hash["stairlastday"] = sales_log.lasttransaction&.day
      attribute_hash["stairlastmonth"] = sales_log.lasttransaction&.month
      attribute_hash["stairlastyear"] = sales_log.lasttransaction&.year

      attribute_hash["stairinitialday"] = sales_log.initialpurchase&.day
      attribute_hash["stairinitialmonth"] = sales_log.initialpurchase&.month
      attribute_hash["stairinitialyear"] = sales_log.initialpurchase&.year
      attribute_hash["mscharge_value_check"] = sales_log.monthly_charges_value_check
      attribute_hash
    end

    def is_omitted_field?(field_name, _sales_log)
      !EXPORT_FIELDS.include?(field_name)
    end

    def build_export_xml(sales_logs)
      doc = Nokogiri::XML("<forms/>")

      sales_logs.each do |sales_log|
        attribute_hash = apply_cds_transformation(sales_log, EXPORT_MODE[:xml])
        form = doc.create_element("form")
        doc.at("forms") << form
        attribute_hash.each do |key, value|
          if is_omitted_field?(key, sales_log)
            next
          else
            form << doc.create_element(key, value)
          end
        end
      end

      xml_doc_to_temp_file(doc)
    end

    def collection_years_to_export(collection_year)
      return [collection_year] if collection_year.present?

      FormHandler.instance.sales_forms.values.map { |f| f.start_date.year }.uniq.select { |year| year > 2024 }
    end
  end
end
