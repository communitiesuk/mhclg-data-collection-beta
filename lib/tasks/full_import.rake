Import = Struct.new("Import", :import_class, :import_method, :folder)

namespace :import do
  desc "Run a full import for the institutions listed in the named file on s3"
  task :full, %i[institutions_csv_name] => :environment do |_task, args|
    institutions_csv_name = args[:institutions_csv_name]
    raise "Usage: rake core:full_import['institutions_csv_name']" if institutions_csv_name.blank?

    s3_service = Storage::S3Service.new(Configuration::PaasConfigurationService.new, ENV["IMPORT_PAAS_INSTANCE"])
    csv = CSV.parse(s3_service.get_file_io(institutions_csv_name), headers: true)
    org_count = csv.length

    initial_import_list = [
      Import.new(Imports::OrganisationImportService, :create_organisations, "institution"),
      Import.new(Imports::SchemeImportService, :create_schemes, "mgmtgroups"),
      Import.new(Imports::SchemeLocationImportService, :create_scheme_locations, "schemes"),
      Import.new(Imports::UserImportService, :create_users, "user"),
      Import.new(Imports::DataProtectionConfirmationImportService, :create_data_protection_confirmations, "dataprotect"),
      Import.new(Imports::OrganisationRentPeriodImportService, :create_organisation_rent_periods, "rent-period"),
    ]

    Rails.logger.info("Beginning initial imports for #{org_count} organisations")

    csv.each do |row|
      archive_path = row[1]
      archive_io = s3_service.get_file_io(archive_path)
      archive_service = Storage::ArchiveService.new(archive_io)

      Rails.logger.info("Performing initial imports for organisation #{row[0]}")

      initial_import_list.each do |step|
        if archive_service.folder_present?(step.folder)
          step.import_class.new(archive_service).send(step.import_method, step.folder)
        end
      end
    end

    logs_import_list = [
      Import.new(Imports::LettingsLogsImportService, :create_logs, "logs"),
      Import.new(Imports::SalesLogsImportService, :create_logs, "logs"),
    ]

    Rails.logger.info("Initial imports complete, beginning log imports for #{org_count} organisations")

    csv.each do |row|
      archive_path = row[1]
      archive_io = s3_service.get_file_io(archive_path)
      archive_service = Storage::ArchiveService.new(archive_io)

      log_count = row[2].to_i + row[3].to_i + row[4].to_i + row[5].to_i
      Rails.logger.info("Importing logs for organisation #{row[0]}, expecting #{log_count} logs")

      logs_import_list.each do |step|
        if archive_service.folder_present?(step.folder)
          step.import_class.new(archive_service).send(step.import_method, step.folder)
        end
      end
    end

    Rails.logger.info("Log import complete, triggering user invite emails")

    csv.each do |row|
      organisation = Organisation.find_by(name: row[0])
      next unless organisation

      users = User.where(organisation:, active: true, initial_confirmation_sent: false)
      users.each { |user| ResendInvitationMailer.resend_invitation_email(user).deliver_later }
    end

    Rails.logger.info("Invite emails triggered, generating report")

    rep = CSV.generate do |report|
      headers = ["Institution name", "Id", "Old Completed lettings logs", "Old In progress lettings logs", "Old Completed sales logs", "Old In progress sales logs", "New Completed lettings logs", "New In Progress lettings logs", "New Completed sales logs", "New In Progress sales logs"]
      report << headers

      csv.each do |row|
        name = row[0]
        organisation = Organisation.find_by(name:)
        next unless organisation

        completed_sales_logs = organisation.owned_sales_logs.where(status: "completed").count
        in_progress_sales_logs = organisation.owned_sales_logs.where(status: "in_progress").count
        completed_lettings_logs = organisation.owned_lettings_logs.where(status: "completed").count
        in_progress_lettings_logs = organisation.owned_lettings_logs.where(status: "in_progress").count
        report << row.push(completed_lettings_logs, in_progress_lettings_logs, completed_sales_logs, in_progress_sales_logs)
      end
    end

    report_name = "MigratedLogsReport_#{institutions_csv_name}"
    s3_service.write_file(report_name, rep)

    Rails.logger.info("Logs report available in s3 import bucket at #{report_name}")
  end
end
