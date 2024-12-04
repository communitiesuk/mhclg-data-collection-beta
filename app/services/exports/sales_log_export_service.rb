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
      sales_log.attributes_before_type_cast
      # attribute_hash["formid"] = attribute_hash["old_form_id"] || (attribute_hash["id"] + LOG_ID_OFFSET)
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
