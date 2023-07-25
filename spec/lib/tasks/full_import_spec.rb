require "rails_helper"
require "rake"
require "zip"

describe "rake import:full", type: :task do
  subject(:task) { Rake::Task["import:full"] }

  let(:s3_service) { instance_double(Storage::S3Service) }
  let(:archive_service) { instance_double(Storage::ArchiveService) }
  let(:paas_config_service) { instance_double(Configuration::PaasConfigurationService) }

  before do
    Rake.application.rake_require("tasks/full_import")
    Rake::Task.define_task(:environment)
    task.reenable

    allow(Configuration::PaasConfigurationService).to receive(:new).and_return(paas_config_service)
    allow(Storage::S3Service).to receive(:new).and_return(s3_service)
    allow(s3_service).to receive(:get_file_io).and_return("")
    allow(s3_service).to receive(:write_file)
    allow(Storage::ArchiveService).to receive(:new).and_return(archive_service)
  end

  context "when starting a full import" do
    let(:lettings_logs_service) { instance_double(Imports::LettingsLogsImportService) }
    let(:sales_logs_service) { instance_double(Imports::SalesLogsImportService) }
    let(:rent_period_service) { instance_double(Imports::OrganisationRentPeriodImportService) }
    let(:data_protection_service) { instance_double(Imports::DataProtectionConfirmationImportService) }
    let(:user_service) { instance_double(Imports::UserImportService) }
    let(:location_service) { instance_double(Imports::SchemeLocationImportService) }
    let(:scheme_service) { instance_double(Imports::SchemeImportService) }
    let(:organisation_service) { instance_double(Imports::OrganisationImportService) }

    before do
      allow(Imports::OrganisationImportService).to receive(:new).and_return(organisation_service)
      allow(Imports::SchemeImportService).to receive(:new).and_return(scheme_service)
      allow(Imports::SchemeLocationImportService).to receive(:new).and_return(location_service)
      allow(Imports::UserImportService).to receive(:new).and_return(user_service)
      allow(Imports::DataProtectionConfirmationImportService).to receive(:new).and_return(data_protection_service)
      allow(Imports::OrganisationRentPeriodImportService).to receive(:new).and_return(rent_period_service)
      allow(Imports::LettingsLogsImportService).to receive(:new).and_return(lettings_logs_service)
      allow(Imports::SalesLogsImportService).to receive(:new).and_return(sales_logs_service)
    end

    it "raises an exception if no parameters are provided" do
      expect { task.invoke }.to raise_error(/Usage/)
    end

    context "with all folders being present" do
      before { allow(archive_service).to receive(:folder_present?).and_return(true) }

      it "calls every import method with the correct folder" do
        expect(organisation_service).to receive(:create_organisations).with("institution")
        expect(scheme_service).to receive(:create_schemes).with("mgmtgroups")
        expect(location_service).to receive(:create_scheme_locations).with("schemes")
        expect(user_service).to receive(:create_users).with("user")
        expect(data_protection_service).to receive(:create_data_protection_confirmations).with("dataprotect")
        expect(rent_period_service).to receive(:create_organisation_rent_periods).with("rent-period")
        expect(lettings_logs_service).to receive(:create_logs).with("logs")
        expect(sales_logs_service).to receive(:create_logs).with("logs")

        task.invoke(fixture_path)
      end
    end

    context "when a specific folders are missing" do
      before do
        allow(archive_service).to receive(:folder_present?).and_return(true)
        allow(archive_service).to receive(:folder_present?).with("mgmtgroups").and_return(false)
        allow(archive_service).to receive(:folder_present?).with("schemes").and_return(false)
        allow(Rails.logger).to receive(:info)
      end

      it "only calls import methods for existing folders" do
        expect(organisation_service).to receive(:create_organisations)
        expect(user_service).to receive(:create_users)
        expect(data_protection_service).to receive(:create_data_protection_confirmations)
        expect(rent_period_service).to receive(:create_organisation_rent_periods)
        expect(lettings_logs_service).to receive(:create_logs)
        expect(sales_logs_service).to receive(:create_logs)

        expect(scheme_service).not_to receive(:create_schemes)
        expect(location_service).not_to receive(:create_scheme_locations)

        task.invoke(fixture_path)
      end
    end
  end
end
