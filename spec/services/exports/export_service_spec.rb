require "rails_helper"

RSpec.describe Exports::ExportService do
  subject(:export_service) { described_class.new(storage_service) }

  let(:storage_service) { instance_double(Storage::S3Service) }
  let(:expected_master_manifest_filename) { "Manifest_2022_05_01_0001.csv" }
  let(:start_time) { Time.zone.local(2022, 5, 1) }
  let(:user) { FactoryBot.create(:user, email: "test1@example.com") }
  let(:organisations_export_service) { instance_double("Exports::OrganisationExportService", export_xml_organisations: {}) }
  let(:users_export_service) { instance_double("Exports::UserExportService", export_xml_users: {}) }
  let(:sales_logs_export_service) { instance_double("Exports::SalesLogExportService", export_xml_sales_logs: {}) }

  before do
    Timecop.freeze(start_time)
    Singleton.__init__(FormHandler)
    allow(storage_service).to receive(:write_file)
    allow(Exports::LettingsLogExportService).to receive(:new).and_return(lettings_logs_export_service)
    allow(Exports::SalesLogExportService).to receive(:new).and_return(sales_logs_export_service)
    allow(Exports::UserExportService).to receive(:new).and_return(users_export_service)
    allow(Exports::OrganisationExportService).to receive(:new).and_return(organisations_export_service)
  end

  after do
    Timecop.return
  end

  context "when exporting daily XMLs before 2025" do
    context "and no lettings archives get created in lettings logs export" do
      let(:lettings_logs_export_service) { instance_double("Exports::LettingsLogExportService", export_xml_lettings_logs: {}) }

      context "and no user or organisation archives get created in user export" do
        it "generates a master manifest with the correct name" do
          expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
          export_service.export_xml
        end

        it "generates a master manifest with CSV headers but no data" do
          actual_content = nil
          expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\n"
          allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

          export_service.export_xml
          expect(actual_content).to eq(expected_content)
        end
      end

      context "and one user archive gets created in user export" do
        let(:users_export_service) { instance_double("Exports::UserExportService", export_xml_users: { "some_user_file_base_name" => start_time }) }

        it "generates a master manifest with the correct name" do
          expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
          export_service.export_xml
        end

        it "generates a master manifest with CSV headers and correct data" do
          actual_content = nil
          expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\nsome_user_file_base_name,2022-05-01 00:00:00 +0100,some_user_file_base_name.zip\n"
          allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

          export_service.export_xml
          expect(actual_content).to eq(expected_content)
        end
      end

      context "and one organisation archive gets created in organisation export" do
        let(:organisations_export_service) { instance_double("Exports::OrganisationExportService", export_xml_organisations: { "some_organisation_file_base_name" => start_time }) }

        it "generates a master manifest with the correct name" do
          expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
          export_service.export_xml
        end

        it "generates a master manifest with CSV headers and correct data" do
          actual_content = nil
          expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\nsome_organisation_file_base_name,2022-05-01 00:00:00 +0100,some_organisation_file_base_name.zip\n"
          allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

          export_service.export_xml
          expect(actual_content).to eq(expected_content)
        end
      end

      context "and user and organisation archive gets created in organisation export" do
        let(:organisations_export_service) { instance_double("Exports::OrganisationExportService", export_xml_organisations: { "some_organisation_file_base_name" => start_time }) }
        let(:users_export_service) { instance_double("Exports::UserExportService", export_xml_users: { "some_user_file_base_name" => start_time }) }

        it "generates a master manifest with the correct name" do
          expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
          export_service.export_xml
        end

        it "generates a master manifest with CSV headers and correct data" do
          actual_content = nil
          expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\nsome_user_file_base_name,2022-05-01 00:00:00 +0100,some_user_file_base_name.zip\nsome_organisation_file_base_name,2022-05-01 00:00:00 +0100,some_organisation_file_base_name.zip\n"
          allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

          export_service.export_xml
          expect(actual_content).to eq(expected_content)
        end
      end
    end

    context "and one lettings archive gets created in lettings logs export" do
      let(:lettings_logs_export_service) { instance_double("Exports::LettingsLogExportService", export_xml_lettings_logs: { "some_file_base_name" => start_time }) }

      context "and no user archives get created in user export" do
        it "generates a master manifest with the correct name" do
          expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
          export_service.export_xml
        end

        it "generates a master manifest with CSV headers and correct data" do
          actual_content = nil
          expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\nsome_file_base_name,2022-05-01 00:00:00 +0100,some_file_base_name.zip\n"
          allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

          export_service.export_xml
          expect(actual_content).to eq(expected_content)
        end
      end

      context "and one user archive gets created in user export" do
        let(:users_export_service) { instance_double("Exports::UserExportService", export_xml_users: { "some_user_file_base_name" => start_time }) }

        it "generates a master manifest with the correct name" do
          expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
          export_service.export_xml
        end

        it "generates a master manifest with CSV headers and correct data" do
          actual_content = nil
          expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\nsome_file_base_name,2022-05-01 00:00:00 +0100,some_file_base_name.zip\nsome_user_file_base_name,2022-05-01 00:00:00 +0100,some_user_file_base_name.zip\n"
          allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

          export_service.export_xml
          expect(actual_content).to eq(expected_content)
        end
      end
    end

    context "and multiple lettings archives get created in lettings logs export" do
      let(:lettings_logs_export_service) { instance_double("Exports::LettingsLogExportService", export_xml_lettings_logs: { "some_file_base_name" => start_time, "second_file_base_name" => start_time }) }

      context "and no user archives get created in user export" do
        it "generates a master manifest with the correct name" do
          expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
          export_service.export_xml
        end

        it "generates a master manifest with CSV headers and correct data" do
          actual_content = nil
          expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\nsome_file_base_name,2022-05-01 00:00:00 +0100,some_file_base_name.zip\nsecond_file_base_name,2022-05-01 00:00:00 +0100,second_file_base_name.zip\n"
          allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

          export_service.export_xml
          expect(actual_content).to eq(expected_content)
        end
      end

      context "and multiple user archive gets created in user export" do
        let(:users_export_service) { instance_double("Exports::UserExportService", export_xml_users: { "some_user_file_base_name" => start_time, "second_user_file_base_name" => start_time }) }

        it "generates a master manifest with the correct name" do
          expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
          export_service.export_xml
        end

        it "generates a master manifest with CSV headers and correct data" do
          actual_content = nil
          expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\nsome_file_base_name,2022-05-01 00:00:00 +0100,some_file_base_name.zip\nsecond_file_base_name,2022-05-01 00:00:00 +0100,second_file_base_name.zip\nsome_user_file_base_name,2022-05-01 00:00:00 +0100,some_user_file_base_name.zip\nsecond_user_file_base_name,2022-05-01 00:00:00 +0100,second_user_file_base_name.zip\n"
          allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

          export_service.export_xml
          expect(actual_content).to eq(expected_content)
        end
      end

      context "and multiple user and organisation archives gets created in user export" do
        let(:users_export_service) { instance_double("Exports::UserExportService", export_xml_users: { "some_user_file_base_name" => start_time, "second_user_file_base_name" => start_time }) }
        let(:organisations_export_service) { instance_double("Exports::OrganisationExportService", export_xml_organisations: { "some_organisation_file_base_name" => start_time, "second_organisation_file_base_name" => start_time }) }

        it "generates a master manifest with the correct name" do
          expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
          export_service.export_xml
        end

        it "generates a master manifest with CSV headers and correct data" do
          actual_content = nil
          expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\nsome_file_base_name,2022-05-01 00:00:00 +0100,some_file_base_name.zip\nsecond_file_base_name,2022-05-01 00:00:00 +0100,second_file_base_name.zip\nsome_user_file_base_name,2022-05-01 00:00:00 +0100,some_user_file_base_name.zip\nsecond_user_file_base_name,2022-05-01 00:00:00 +0100,second_user_file_base_name.zip\nsome_organisation_file_base_name,2022-05-01 00:00:00 +0100,some_organisation_file_base_name.zip\nsecond_organisation_file_base_name,2022-05-01 00:00:00 +0100,second_organisation_file_base_name.zip\n"
          allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

          export_service.export_xml
          expect(actual_content).to eq(expected_content)
        end
      end
    end

    context "and multiple sales archives get created in sales logs export" do
      let(:lettings_logs_export_service) { instance_double("Exports::LettingsLogExportService", export_xml_lettings_logs: { "some_file_base_name" => start_time, "second_file_base_name" => start_time }) }
      let(:sales_logs_export_service) { instance_double("Exports::SalesLogExportService", export_xml_sales_logs: { "some_sales_file_base_name" => start_time, "second_sales_file_base_name" => start_time }) }

      context "and no user archives get created in user export" do
        it "generates a master manifest with the correct name" do
          expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
          export_service.export_xml
        end

        it "generates a master manifest with CSV headers and correct data" do
          actual_content = nil
          expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\nsome_file_base_name,2022-05-01 00:00:00 +0100,some_file_base_name.zip\nsecond_file_base_name,2022-05-01 00:00:00 +0100,second_file_base_name.zip\n"
          allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

          export_service.export_xml
          expect(actual_content).to eq(expected_content)
        end
      end

      context "and multiple user archive gets created in user export" do
        let(:users_export_service) { instance_double("Exports::UserExportService", export_xml_users: { "some_user_file_base_name" => start_time, "second_user_file_base_name" => start_time }) }

        it "generates a master manifest with the correct name" do
          expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
          export_service.export_xml
        end

        it "generates a master manifest with CSV headers and correct data" do
          actual_content = nil
          expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\nsome_file_base_name,2022-05-01 00:00:00 +0100,some_file_base_name.zip\nsecond_file_base_name,2022-05-01 00:00:00 +0100,second_file_base_name.zip\nsome_user_file_base_name,2022-05-01 00:00:00 +0100,some_user_file_base_name.zip\nsecond_user_file_base_name,2022-05-01 00:00:00 +0100,second_user_file_base_name.zip\n"
          allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

          export_service.export_xml
          expect(actual_content).to eq(expected_content)
        end
      end

      context "and multiple user and organisation archives gets created in user export" do
        let(:users_export_service) { instance_double("Exports::UserExportService", export_xml_users: { "some_user_file_base_name" => start_time, "second_user_file_base_name" => start_time }) }
        let(:organisations_export_service) { instance_double("Exports::OrganisationExportService", export_xml_organisations: { "some_organisation_file_base_name" => start_time, "second_organisation_file_base_name" => start_time }) }

        it "generates a master manifest with the correct name" do
          expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
          export_service.export_xml
        end

        it "generates a master manifest with CSV headers and correct data" do
          actual_content = nil
          expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\nsome_file_base_name,2022-05-01 00:00:00 +0100,some_file_base_name.zip\nsecond_file_base_name,2022-05-01 00:00:00 +0100,second_file_base_name.zip\nsome_user_file_base_name,2022-05-01 00:00:00 +0100,some_user_file_base_name.zip\nsecond_user_file_base_name,2022-05-01 00:00:00 +0100,second_user_file_base_name.zip\nsome_organisation_file_base_name,2022-05-01 00:00:00 +0100,some_organisation_file_base_name.zip\nsecond_organisation_file_base_name,2022-05-01 00:00:00 +0100,second_organisation_file_base_name.zip\n"
          allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

          export_service.export_xml
          expect(actual_content).to eq(expected_content)
        end
      end
    end
  end

  context "when exporting specific lettings log collection" do
    context "and no lettings archives get created in lettings logs export" do
      let(:lettings_logs_export_service) { instance_double("Exports::LettingsLogExportService", export_xml_lettings_logs: {}) }

      context "and user archive gets created in user export" do
        let(:users_export_service) { instance_double("Exports::UserExportService", export_xml_users: { "some_user_file_base_name" => start_time }) }

        it "generates a master manifest with the correct name" do
          expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
          export_service.export_xml(full_update: true, collection: "lettings", year: "2022")
        end

        it "does not write user data" do
          actual_content = nil
          expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\n"
          allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

          export_service.export_xml(full_update: true, collection: "lettings", year: "2022")
          expect(actual_content).to eq(expected_content)
        end
      end
    end

    context "and lettings archive gets created in lettings logs export" do
      let(:lettings_logs_export_service) { instance_double("Exports::LettingsLogExportService", export_xml_lettings_logs: { "some_file_base_name" => start_time }) }

      context "and user archive gets created in user export" do
        let(:users_export_service) { instance_double("Exports::UserExportService", export_xml_users: { "some_user_file_base_name" => start_time }) }

        it "generates a master manifest with the correct name" do
          expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
          export_service.export_xml(full_update: true, collection: "lettings", year: "2023")
        end

        it "does not write user data" do
          actual_content = nil
          expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\nsome_file_base_name,2022-05-01 00:00:00 +0100,some_file_base_name.zip\n"
          allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

          export_service.export_xml(full_update: true, collection: "lettings", year: "2023")
          expect(actual_content).to eq(expected_content)
        end
      end
    end
  end

  context "when exporting user collection" do
    context "and no user archives get created in users export" do
      context "and lettings log archive gets created in lettings logs export" do
        let(:lettings_logs_export_service) { instance_double("Exports::LettingsLogExportService", export_xml_lettings_logs: { "some_file_base_name" => start_time }) }

        it "generates a master manifest with the correct name" do
          expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
          export_service.export_xml(full_update: true, collection: "users")
        end

        it "does not write lettings log data" do
          actual_content = nil
          expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\n"
          allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

          export_service.export_xml(full_update: true, collection: "users")
          expect(actual_content).to eq(expected_content)
        end
      end
    end

    context "and users archive gets created in users export" do
      let(:lettings_logs_export_service) { instance_double("Exports::LettingsLogExportService", export_xml_lettings_logs: { "some_file_base_name" => start_time }) }

      context "and lettings log archive gets created in lettings log export" do
        let(:users_export_service) { instance_double("Exports::UserExportService", export_xml_users: { "some_user_file_base_name" => start_time }) }

        it "generates a master manifest with the correct name" do
          expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
          export_service.export_xml(full_update: true, collection: "users")
        end

        it "does not write lettings log data" do
          actual_content = nil
          expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\nsome_user_file_base_name,2022-05-01 00:00:00 +0100,some_user_file_base_name.zip\n"
          allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

          export_service.export_xml(full_update: true, collection: "users")
          expect(actual_content).to eq(expected_content)
        end
      end
    end
  end

  context "when exporting organisation collection" do
    context "and no organisation archives get created in organisations export" do
      let(:organisations_export_service) { instance_double("Exports::OrganisationExportService", export_xml_organisations: {}) }

      context "and lettings log archive gets created in lettings logs export" do
        let(:lettings_logs_export_service) { instance_double("Exports::LettingsLogExportService", export_xml_lettings_logs: { "some_file_base_name" => start_time }) }

        it "generates a master manifest with the correct name" do
          expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
          export_service.export_xml(full_update: true, collection: "organisations")
        end

        it "does not write lettings log data" do
          actual_content = nil
          expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\n"
          allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

          export_service.export_xml(full_update: true, collection: "organisations")
          expect(actual_content).to eq(expected_content)
        end
      end
    end

    context "and organisations archive gets created in organisations export" do
      let(:lettings_logs_export_service) { instance_double("Exports::LettingsLogExportService", export_xml_lettings_logs: { "some_file_base_name" => start_time }) }

      context "and lettings log archive gets created in lettings log export" do
        let(:organisations_export_service) { instance_double("Exports::OrganisationExportService", export_xml_organisations: { "some_organisation_file_base_name" => start_time }) }

        it "generates a master manifest with the correct name" do
          expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
          export_service.export_xml(full_update: true, collection: "organisations")
        end

        it "does not write lettings log data" do
          actual_content = nil
          expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\nsome_organisation_file_base_name,2022-05-01 00:00:00 +0100,some_organisation_file_base_name.zip\n"
          allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

          export_service.export_xml(full_update: true, collection: "organisations")
          expect(actual_content).to eq(expected_content)
        end
      end
    end
  end

  context "with date after 2025-04-01" do
    let(:start_time) { Time.zone.local(2025, 5, 1) }
    let(:expected_master_manifest_filename) { "Manifest_2025_05_01_0001.csv" }
    let(:lettings_logs_export_service) { instance_double("Exports::LettingsLogExportService", export_xml_lettings_logs: {}) }

    context "when exporting daily XMLs" do
      context "and no sales archives get created in sales logs export" do
        let(:sales_logs_export_service) { instance_double("Exports::SalesLogExportService", export_xml_sales_logs: {}) }
        let(:lettings_logs_export_service) { instance_double("Exports::LettingsLogExportService", export_xml_lettings_logs: {}) }

        context "and no user or organisation archives get created in user export" do
          it "generates a master manifest with the correct name" do
            expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
            export_service.export_xml
          end

          it "generates a master manifest with CSV headers but no data" do
            actual_content = nil
            expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\n"
            allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

            export_service.export_xml
            expect(actual_content).to eq(expected_content)
          end
        end
      end

      context "and one sales archive gets created in sales logs export" do
        let(:sales_logs_export_service) { instance_double("Exports::SalesLogExportService", export_xml_sales_logs: { "some_sales_file_base_name" => start_time }) }
        let(:lettings_logs_export_service) { instance_double("Exports::LettingsLogExportService", export_xml_lettings_logs: { "some_file_base_name" => start_time }) }

        context "and no user archives get created in user export" do
          it "generates a master manifest with the correct name" do
            expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
            export_service.export_xml
          end

          it "generates a master manifest with CSV headers and correct data" do
            actual_content = nil
            expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\nsome_file_base_name,2025-05-01 00:00:00 +0100,some_file_base_name.zip\nsome_sales_file_base_name,2025-05-01 00:00:00 +0100,some_sales_file_base_name.zip\n"
            allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

            export_service.export_xml
            expect(actual_content).to eq(expected_content)
          end
        end

        context "and one user archive gets created in user export" do
          let(:users_export_service) { instance_double("Exports::UserExportService", export_xml_users: { "some_user_file_base_name" => start_time }) }

          it "generates a master manifest with the correct name" do
            expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
            export_service.export_xml
          end

          it "generates a master manifest with CSV headers and correct data" do
            actual_content = nil
            expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\nsome_file_base_name,2025-05-01 00:00:00 +0100,some_file_base_name.zip\nsome_sales_file_base_name,2025-05-01 00:00:00 +0100,some_sales_file_base_name.zip\nsome_user_file_base_name,2025-05-01 00:00:00 +0100,some_user_file_base_name.zip\n"
            allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

            export_service.export_xml
            expect(actual_content).to eq(expected_content)
          end
        end
      end

      context "and multiple sales archives get created in sales logs export" do
        let(:sales_logs_export_service) { instance_double("Exports::SalesLogExportService", export_xml_sales_logs: { "some_sales_file_base_name" => start_time, "second_sales_file_base_name" => start_time }) }
        let(:lettings_logs_export_service) { instance_double("Exports::LettingsLogExportService", export_xml_lettings_logs: { "some_file_base_name" => start_time, "second_file_base_name" => start_time }) }

        context "and no user archives get created in user export" do
          it "generates a master manifest with the correct name" do
            expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
            export_service.export_xml
          end

          it "generates a master manifest with CSV headers and correct data" do
            actual_content = nil
            expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\nsome_file_base_name,2025-05-01 00:00:00 +0100,some_file_base_name.zip\nsecond_file_base_name,2025-05-01 00:00:00 +0100,second_file_base_name.zip\nsome_sales_file_base_name,2025-05-01 00:00:00 +0100,some_sales_file_base_name.zip\nsecond_sales_file_base_name,2025-05-01 00:00:00 +0100,second_sales_file_base_name.zip\n"
            allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

            export_service.export_xml
            expect(actual_content).to eq(expected_content)
          end
        end

        context "and multiple user archive gets created in user export" do
          let(:users_export_service) { instance_double("Exports::UserExportService", export_xml_users: { "some_user_file_base_name" => start_time, "second_user_file_base_name" => start_time }) }

          it "generates a master manifest with the correct name" do
            expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
            export_service.export_xml
          end

          it "generates a master manifest with CSV headers and correct data" do
            actual_content = nil
            expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\nsome_file_base_name,2025-05-01 00:00:00 +0100,some_file_base_name.zip\nsecond_file_base_name,2025-05-01 00:00:00 +0100,second_file_base_name.zip\nsome_sales_file_base_name,2025-05-01 00:00:00 +0100,some_sales_file_base_name.zip\nsecond_sales_file_base_name,2025-05-01 00:00:00 +0100,second_sales_file_base_name.zip\nsome_user_file_base_name,2025-05-01 00:00:00 +0100,some_user_file_base_name.zip\nsecond_user_file_base_name,2025-05-01 00:00:00 +0100,second_user_file_base_name.zip\n"
            allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

            export_service.export_xml
            expect(actual_content).to eq(expected_content)
          end
        end

        context "and multiple user and organisation archives gets created in user export" do
          let(:users_export_service) { instance_double("Exports::UserExportService", export_xml_users: { "some_user_file_base_name" => start_time, "second_user_file_base_name" => start_time }) }
          let(:organisations_export_service) { instance_double("Exports::OrganisationExportService", export_xml_organisations: { "some_organisation_file_base_name" => start_time, "second_organisation_file_base_name" => start_time }) }

          it "generates a master manifest with the correct name" do
            expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
            export_service.export_xml
          end

          it "generates a master manifest with CSV headers and correct data" do
            actual_content = nil
            expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\nsome_file_base_name,2025-05-01 00:00:00 +0100,some_file_base_name.zip\nsecond_file_base_name,2025-05-01 00:00:00 +0100,second_file_base_name.zip\nsome_sales_file_base_name,2025-05-01 00:00:00 +0100,some_sales_file_base_name.zip\nsecond_sales_file_base_name,2025-05-01 00:00:00 +0100,second_sales_file_base_name.zip\nsome_user_file_base_name,2025-05-01 00:00:00 +0100,some_user_file_base_name.zip\nsecond_user_file_base_name,2025-05-01 00:00:00 +0100,second_user_file_base_name.zip\nsome_organisation_file_base_name,2025-05-01 00:00:00 +0100,some_organisation_file_base_name.zip\nsecond_organisation_file_base_name,2025-05-01 00:00:00 +0100,second_organisation_file_base_name.zip\n"
            allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

            export_service.export_xml
            expect(actual_content).to eq(expected_content)
          end
        end
      end
    end
  end

  context "when exporting specific sales log collection" do
    let(:start_time) { Time.zone.local(2025, 5, 1) }
    let(:expected_master_manifest_filename) { "Manifest_2025_05_01_0001.csv" }
    let(:lettings_logs_export_service) { instance_double("Exports::LettingsLogExportService", export_xml_lettings_logs: {}) }

    context "and no sales archives get created in sales logs export" do
      let(:sales_logs_export_service) { instance_double("Exports::SalesLogExportService", export_xml_sales_logs: {}) }

      context "and user archive gets created in user export" do
        let(:users_export_service) { instance_double("Exports::UserExportService", export_xml_users: { "some_user_file_base_name" => start_time }) }

        it "generates a master manifest with the correct name" do
          expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
          export_service.export_xml(full_update: true, collection: "sales", year: "2022")
        end

        it "does not write user data" do
          actual_content = nil
          expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\n"
          allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

          export_service.export_xml(full_update: true, collection: "sales", year: "2022")
          expect(actual_content).to eq(expected_content)
        end
      end
    end

    context "and sales archive gets created in sales logs export" do
      let(:sales_logs_export_service) { instance_double("Exports::SalesLogExportService", export_xml_sales_logs: { "some_sales_file_base_name" => start_time }) }

      context "and user archive gets created in user export" do
        let(:users_export_service) { instance_double("Exports::UserExportService", export_xml_users: { "some_user_file_base_name" => start_time }) }

        it "generates a master manifest with the correct name" do
          expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
          export_service.export_xml(full_update: true, collection: "sales", year: "2023")
        end

        it "does not write user data" do
          actual_content = nil
          expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\nsome_sales_file_base_name,2025-05-01 00:00:00 +0100,some_sales_file_base_name.zip\n"
          allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

          export_service.export_xml(full_update: true, collection: "sales", year: "2023")
          expect(actual_content).to eq(expected_content)
        end
      end
    end
  end
end
