namespace :core do
  desc "Export data XMLs for import into Central Data System (CDS)"
  task :data_export, %i[format full_update] => :environment do |_task, args|
    format = args[:format]
    full_update = args[:full_update].present? && args[:full_update] == "true"

    storage_service = Storage::S3Service.new(Configuration::PaasConfigurationService.new, ENV["EXPORT_PAAS_INSTANCE"])
    export_service = Exports::LettingsLogExportService.new(storage_service)

    if format.present? && format == "CSV"
      export_service.export_csv_lettings_logs
    else
      export_service.export_xml_lettings_logs(full_update:)
    end
  end
end

namespace :illness_type_0 do
  desc "Export log data where illness_type_0 == 1"
  task export: :environment do |_task|
    logs = LettingsLog.where(illness_type_0: 1, status: "completed").includes(created_by: :organisation)
    puts "log_id,created_by_id,organisation_id,organisation_name,startdate"

    logs.each do |log|
      puts [
        log.id,
        log.created_by_id,
        log.created_by.organisation.id,
        log.created_by.organisation.name,
        log.startdate&.strftime("%d/%m/%Y"),
      ].join(",")
    end
  end
end
