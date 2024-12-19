module Exports
  class ExportService
    include CollectionTimeHelper

    def initialize(storage_service, logger = Rails.logger)
      @storage_service = storage_service
      @logger = logger
    end

    def export_xml(full_update: false, collection: nil, year: nil)
      start_time = Time.zone.now
      daily_run_number = get_daily_run_number
      lettings_archives_for_manifest = {}
      sales_archives_for_manifest = {}
      users_archives_for_manifest = {}
      organisations_archives_for_manifest = {}

      if collection.present?
        case collection
        when "users"
          users_archives_for_manifest = get_user_archives(start_time, full_update)
        when "organisations"
          organisations_archives_for_manifest = get_organisation_archives(start_time, full_update)
        when "lettings"
          lettings_archives_for_manifest = get_lettings_archives(start_time, full_update, year)
        when "sales"
          sales_archives_for_manifest = get_sales_archives(start_time, full_update, year)
        end
      else
        users_archives_for_manifest = get_user_archives(start_time, full_update)
        organisations_archives_for_manifest = get_organisation_archives(start_time, full_update)
        lettings_archives_for_manifest = get_lettings_archives(start_time, full_update, year)
        sales_archives_for_manifest = get_sales_archives(start_time, full_update, year) if Time.zone.now >= Time.zone.local(2025, 4, 1)
      end

      write_master_manifest(daily_run_number, lettings_archives_for_manifest.merge(sales_archives_for_manifest).merge(users_archives_for_manifest).merge(organisations_archives_for_manifest))
    end

  private

    def get_daily_run_number
      today = Time.zone.today
      Export.where(created_at: today.beginning_of_day..today.end_of_day).select(:started_at).distinct.count + 1
    end

    def write_master_manifest(daily_run, archive_datetimes)
      today = Time.zone.today
      increment_number = daily_run.to_s.rjust(4, "0")
      month = today.month.to_s.rjust(2, "0")
      day = today.day.to_s.rjust(2, "0")
      file_path = "Manifest_#{today.year}_#{month}_#{day}_#{increment_number}.csv"
      string_io = build_manifest_csv_io(archive_datetimes)
      @storage_service.write_file(file_path, string_io)
    end

    def build_manifest_csv_io(archive_datetimes)
      headers = ["zip-name", "date-time zipped folder generated", "zip-file-uri"]
      csv_string = CSV.generate do |csv|
        csv << headers
        archive_datetimes.each do |(archive, datetime)|
          csv << [archive, datetime, "#{archive}.zip"]
        end
      end
      StringIO.new(csv_string)
    end

    def get_user_archives(start_time, full_update)
      users_export_service = Exports::UserExportService.new(@storage_service, start_time)
      users_export_service.export_xml_users(full_update:)
    end

    def get_organisation_archives(start_time, full_update)
      organisations_export_service = Exports::OrganisationExportService.new(@storage_service, start_time)
      organisations_export_service.export_xml_organisations(full_update:)
    end

    def get_lettings_archives(start_time, full_update, collection_year)
      lettings_export_service = Exports::LettingsLogExportService.new(@storage_service, start_time)
      lettings_export_service.export_xml_lettings_logs(full_update:, collection_year:)
    end

    def get_sales_archives(start_time, full_update, collection_year)
      sales_export_service = Exports::SalesLogExportService.new(@storage_service, start_time)
      sales_export_service.export_xml_sales_logs(full_update:, collection_year:)
    end
  end
end
