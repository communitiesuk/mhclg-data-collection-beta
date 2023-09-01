require "rails_helper"

RSpec.describe Exports::LettingsLogExportService do
  subject(:export_service) { described_class.new(storage_service) }

  let(:storage_service) { instance_double(Storage::S3Service) }

  let(:xml_export_file) { File.open("spec/fixtures/exports/general_needs_log.xml", "r:UTF-8") }
  let(:local_manifest_file) { File.open("spec/fixtures/exports/manifest.xml", "r:UTF-8") }

  let(:real_2021_2022_form) { Form.new("config/forms/2021_2022.json") }
  let(:real_2022_2023_form) { Form.new("config/forms/2022_2023.json") }

  let(:expected_master_manifest_filename) { "Manifest_2022_05_01_0001.csv" }
  let(:expected_master_manifest_rerun) { "Manifest_2022_05_01_0002.csv" }
  let(:expected_zip_filename) { "core_2021_2022_apr_mar_f0001_inc0001.zip" }
  let(:expected_data_filename) { "core_2021_2022_apr_mar_f0001_inc0001_pt001.xml" }
  let(:expected_manifest_filename) { "manifest.xml" }
  let(:start_time) { Time.zone.local(2022, 5, 1) }
  let(:user) { FactoryBot.create(:user, email: "test1@example.com") }

  def replace_entity_ids(lettings_log, export_template)
    export_template.sub!(/\{id\}/, (lettings_log["id"] + Exports::LettingsLogExportService::LOG_ID_OFFSET).to_s)
    export_template.sub!(/\{owning_org_id\}/, (lettings_log["owning_organisation_id"] + Exports::LettingsLogExportService::LOG_ID_OFFSET).to_s)
    export_template.sub!(/\{managing_org_id\}/, (lettings_log["managing_organisation_id"] + Exports::LettingsLogExportService::LOG_ID_OFFSET).to_s)
    export_template.sub!(/\{location_id\}/, (lettings_log["location_id"]).to_s) if lettings_log.needstype == 2
    export_template.sub!(/\{scheme_id\}/, (lettings_log["scheme_id"]).to_s) if lettings_log.needstype == 2
    export_template.sub!(/\{log_id\}/, lettings_log["id"].to_s)
  end

  def replace_record_number(export_template, record_number)
    export_template.sub!(/\{recno\}/, record_number.to_s)
  end

  before do
    Timecop.travel(start_time)
    allow(storage_service).to receive(:write_file)

    # Stub the form handler to use the real form
    allow(FormHandler.instance).to receive(:get_form).with("previous_lettings").and_return(real_2021_2022_form)
    allow(FormHandler.instance).to receive(:get_form).with("current_lettings").and_return(real_2022_2023_form)
    allow(FormHandler.instance).to receive(:get_form).with("next_lettings").and_return(real_2022_2023_form)
  end

  after do
    Timecop.return
  end

  context "when exporting daily lettings logs in XML" do
    context "and no lettings logs is available for export" do
      it "generates a master manifest with the correct name" do
        expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
        export_service.export_xml_lettings_logs
      end

      it "generates a master manifest with CSV headers but no data" do
        actual_content = nil
        expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\n"
        allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

        export_service.export_xml_lettings_logs
        expect(actual_content).to eq(expected_content)
      end
    end

    context "when one pending lettings log exists" do
      before do
        FactoryBot.create(
          :lettings_log,
          :completed,
          status: "pending",
          skip_update_status: true,
          propcode: "123",
          ppostcode_full: "SE2 6RT",
          postcode_full: "NW1 5TY",
          tenancycode: "BZ737",
          startdate: Time.zone.local(2022, 2, 2, 10, 36, 49),
          voiddate: Time.zone.local(2019, 11, 3),
          mrcdate: Time.zone.local(2020, 5, 5, 10, 36, 49),
          tenancylength: 5,
          underoccupation_benefitcap: 4,
        )
      end

      it "generates a master manifest with CSV headers but no data" do
        actual_content = nil
        expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\n"
        allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

        export_service.export_xml_lettings_logs
        expect(actual_content).to eq(expected_content)
      end
    end

    context "and one lettings log is available for export" do
      let!(:lettings_log) { FactoryBot.create(:lettings_log, :completed, created_by: user, propcode: "123", ppostcode_full: "SE2 6RT", postcode_full: "NW1 5TY", tenancycode: "BZ737", startdate: Time.zone.local(2022, 2, 2, 10, 36, 49), voiddate: Time.zone.local(2019, 11, 3), mrcdate: Time.zone.local(2020, 5, 5, 10, 36, 49), tenancylength: 5, underoccupation_benefitcap: 4) }

      it "generates a ZIP export file with the expected filename" do
        expect(storage_service).to receive(:write_file).with(expected_zip_filename, any_args)
        export_service.export_xml_lettings_logs
      end

      it "generates an XML manifest file with the expected filename within the ZIP file" do
        expect(storage_service).to receive(:write_file).with(expected_zip_filename, any_args) do |_, content|
          entry = Zip::File.open_buffer(content).find_entry(expected_manifest_filename)
          expect(entry).not_to be_nil
          expect(entry.name).to eq(expected_manifest_filename)
        end
        export_service.export_xml_lettings_logs
      end

      it "generates an XML export file with the expected filename within the ZIP file" do
        expect(storage_service).to receive(:write_file).with(expected_zip_filename, any_args) do |_, content|
          entry = Zip::File.open_buffer(content).find_entry(expected_data_filename)
          expect(entry).not_to be_nil
          expect(entry.name).to eq(expected_data_filename)
        end
        export_service.export_xml_lettings_logs
      end

      it "generates an XML manifest file with the expected content within the ZIP file" do
        expected_content = replace_record_number(local_manifest_file.read, 1)
        expect(storage_service).to receive(:write_file).with(expected_zip_filename, any_args) do |_, content|
          entry = Zip::File.open_buffer(content).find_entry(expected_manifest_filename)
          expect(entry).not_to be_nil
          expect(entry.get_input_stream.read).to eq(expected_content)
        end

        export_service.export_xml_lettings_logs
      end

      it "generates an XML export file with the expected content within the ZIP file" do
        expected_content = replace_entity_ids(lettings_log, xml_export_file.read)
        expect(storage_service).to receive(:write_file).with(expected_zip_filename, any_args) do |_, content|
          entry = Zip::File.open_buffer(content).find_entry(expected_data_filename)
          expect(entry).not_to be_nil
          expect(entry.get_input_stream.read).to eq(expected_content)
        end

        export_service.export_xml_lettings_logs
      end

      it "generates a master manifest with CSV headers" do
        actual_content = nil
        expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\ncore_2021_2022_apr_mar_f0001_inc0001,2022-05-01 00:00:00 +0100,#{expected_zip_filename}\n"
        allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

        export_service.export_xml_lettings_logs
        expect(actual_content).to eq(expected_content)
      end
    end

    context "with 23/24 collection period" do
      before do
        Timecop.freeze(Time.zone.local(2023, 4, 3))
        Singleton.__init__(FormHandler)
        stub_request(:get, "https://api.os.uk/search/places/v1/uprn?key=OS_DATA_KEY&uprn=100023336956")
         .to_return(status: 200, body: '{"status":200,"results":[{"DPA":{
          "PO_BOX_NUMBER": "fake",
      "ORGANISATION_NAME": "org",
      "DEPARTMENT_NAME": "name",
      "SUB_BUILDING_NAME": "building",
      "BUILDING_NAME": "name",
      "BUILDING_NUMBER": "number",
      "DEPENDENT_THOROUGHFARE_NAME": "data",
      "THOROUGHFARE_NAME": "thing",
      "POST_TOWN": "London",
      "POSTCODE": "SE2 6RT"

         }}]}', headers: {})
      end

      after do
        Timecop.unfreeze
        Singleton.__init__(FormHandler)
      end

      context "and one lettings log is available for export" do
        let!(:lettings_log) { FactoryBot.create(:lettings_log, :completed, created_by: user, uprn_known: 1, uprn: "100023336956", propcode: "123", postcode_full: "SE2 6RT", ppostcode_full: "SE2 6RT", tenancycode: "BZ737", startdate: Time.zone.local(2023, 4, 2, 10, 36, 49), voiddate: Time.zone.local(2021, 11, 3), mrcdate: Time.zone.local(2022, 5, 5, 10, 36, 49), tenancylength: 5, underoccupation_benefitcap: 4) }
        let(:expected_zip_filename) { "core_2023_2024_apr_mar_f0001_inc0001.zip" }
        let(:expected_data_filename) { "core_2023_2024_apr_mar_f0001_inc0001_pt001.xml" }
        let(:xml_export_file) { File.open("spec/fixtures/exports/general_needs_log_23_24.xml", "r:UTF-8") }

        it "generates an XML export file with the expected content within the ZIP file" do
          expected_content = replace_entity_ids(lettings_log, xml_export_file.read)
          expect(storage_service).to receive(:write_file).with(expected_zip_filename, any_args) do |_, content|
            entry = Zip::File.open_buffer(content).find_entry(expected_data_filename)
            expect(entry).not_to be_nil
            expect(entry.get_input_stream.read).to eq(expected_content)
          end

          export_service.export_xml_lettings_logs
        end
      end
    end

    context "and multiple lettings logs are available for export on different periods" do
      let(:expected_zip_filename2) { "core_2022_2023_apr_mar_f0001_inc0001.zip" }

      before do
        FactoryBot.create(:lettings_log, startdate: Time.zone.local(2022, 2, 1))
        FactoryBot.create(:lettings_log, startdate: Time.zone.local(2022, 4, 1))
      end

      context "when lettings logs are across multiple quarters" do
        it "generates multiple ZIP export files with the expected filenames" do
          expect(storage_service).to receive(:write_file).with(expected_zip_filename, any_args)
          expect(storage_service).to receive(:write_file).with(expected_zip_filename2, any_args)
          expect(Rails.logger).to receive(:info).with("Building export run for 2021")
          expect(Rails.logger).to receive(:info).with("Creating core_2021_2022_apr_mar_f0001_inc0001 - 1 logs")
          expect(Rails.logger).to receive(:info).with("Added core_2021_2022_apr_mar_f0001_inc0001_pt001.xml")
          expect(Rails.logger).to receive(:info).with("Writing core_2021_2022_apr_mar_f0001_inc0001.zip")
          expect(Rails.logger).to receive(:info).with("Building export run for 2022")
          expect(Rails.logger).to receive(:info).with("Creating core_2022_2023_apr_mar_f0001_inc0001 - 1 logs")
          expect(Rails.logger).to receive(:info).with("Added core_2022_2023_apr_mar_f0001_inc0001_pt001.xml")
          expect(Rails.logger).to receive(:info).with("Writing core_2022_2023_apr_mar_f0001_inc0001.zip")
          expect(Rails.logger).to receive(:info).with("Building export run for 2023")
          expect(Rails.logger).to receive(:info).with("Creating core_2023_2024_apr_mar_f0001_inc0001 - 0 logs")

          export_service.export_xml_lettings_logs
        end

        it "generates zip export files only for specified year" do
          expect(storage_service).to receive(:write_file).with(expected_zip_filename2, any_args)
          expect(Rails.logger).to receive(:info).with("Building export run for 2022")
          expect(Rails.logger).to receive(:info).with("Creating core_2022_2023_apr_mar_f0001_inc0001 - 1 logs")
          expect(Rails.logger).to receive(:info).with("Added core_2022_2023_apr_mar_f0001_inc0001_pt001.xml")
          expect(Rails.logger).to receive(:info).with("Writing core_2022_2023_apr_mar_f0001_inc0001.zip")

          export_service.export_xml_lettings_logs(collection_year: 2022)
        end
      end
    end

    context "and multiple lettings logs are available for export on same quarter" do
      before do
        FactoryBot.create(:lettings_log, startdate: Time.zone.local(2022, 2, 1), needstype: 2)
        FactoryBot.create(:lettings_log, startdate: Time.zone.local(2022, 3, 20), owning_organisation: nil)
      end

      it "generates an XML manifest file with the expected content within the ZIP file" do
        expected_content = replace_record_number(local_manifest_file.read, 2)
        expect(storage_service).to receive(:write_file).with(expected_zip_filename, any_args) do |_, content|
          entry = Zip::File.open_buffer(content).find_entry(expected_manifest_filename)
          expect(entry).not_to be_nil
          expect(entry.get_input_stream.read).to eq(expected_content)
        end

        export_service.export_xml_lettings_logs
      end

      it "creates a logs export record in a database with correct time" do
        expect { export_service.export_xml_lettings_logs }
          .to change(LogsExport, :count).by(3)
        expect(LogsExport.last.started_at).to be_within(2.seconds).of(start_time)
      end

      context "when this is the first export (full)" do
        it "records a ZIP archive in the master manifest (existing lettings logs)" do
          expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) do |_, csv_content|
            csv = CSV.parse(csv_content, headers: true)
            expect(csv&.count).to be > 0
          end

          export_service.export_xml_lettings_logs
        end
      end

      context "when this is a second export (partial)" do
        before do
          start_time = Time.zone.local(2022, 6, 1)
          LogsExport.new(started_at: start_time).save!
        end

        it "does not add any entry in the master manifest (no lettings logs)" do
          expect(storage_service).to receive(:write_file).with(expected_master_manifest_rerun, any_args) do |_, csv_content|
            csv = CSV.parse(csv_content, headers: true)
            expect(csv&.count).to eq(0)
          end
          export_service.export_xml_lettings_logs
        end
      end
    end

    context "and a previous export has run the same day having lettings logs" do
      before do
        FactoryBot.create(:lettings_log, startdate: Time.zone.local(2022, 2, 1))
        export_service.export_xml_lettings_logs
      end

      it "increments the master manifest number by 1" do
        expect(storage_service).to receive(:write_file).with(expected_master_manifest_rerun, any_args)
        export_service.export_xml_lettings_logs
      end

      context "and we trigger another full update" do
        it "increments the base number" do
          export_service.export_xml_lettings_logs(full_update: true)
          expect(LogsExport.last.base_number).to eq(2)
        end

        it "resets the increment number" do
          export_service.export_xml_lettings_logs(full_update: true)
          expect(LogsExport.last.increment_number).to eq(1)
        end

        it "records a ZIP archive in the master manifest (existing lettings logs)" do
          expect(storage_service).to receive(:write_file).with(expected_master_manifest_rerun, any_args) do |_, csv_content|
            csv = CSV.parse(csv_content, headers: true)
            expect(csv&.count).to be > 0
          end
          export_service.export_xml_lettings_logs(full_update: true)
        end

        it "generates a ZIP export file with the expected filename" do
          expect(storage_service).to receive(:write_file).with("core_2021_2022_apr_mar_f0002_inc0001.zip", any_args)
          export_service.export_xml_lettings_logs(full_update: true)
        end
      end
    end

    context "and a previous export has run having no lettings logs" do
      before { export_service.export_xml_lettings_logs }

      it "doesn't increment the manifest number by 1" do
        export_service.export_xml_lettings_logs

        expect(LogsExport.last.increment_number).to eq(1)
      end
    end

    context "and a log has been migrated since the previous partial export" do
      before do
        FactoryBot.create(:lettings_log, startdate: Time.zone.local(2022, 2, 1), updated_at: Time.zone.local(2022, 4, 27), imported_at: Time.zone.local(2022, 4, 29))
        FactoryBot.create(:lettings_log, startdate: Time.zone.local(2022, 2, 1), updated_at: Time.zone.local(2022, 4, 27), imported_at: Time.zone.local(2022, 4, 29))
        LogsExport.create!(started_at: Time.zone.local(2022, 4, 28), base_number: 1, increment_number: 1)
      end

      it "generates an XML manifest file with the expected content within the ZIP file" do
        expected_content = replace_record_number(local_manifest_file.read, 2)
        expect(storage_service).to receive(:write_file).with(expected_master_manifest_rerun, any_args)
        expect(storage_service).to receive(:write_file).with(expected_zip_filename, any_args) do |_, content|
          entry = Zip::File.open_buffer(content).find_entry(expected_manifest_filename)
          expect(entry).not_to be_nil
          expect(entry.get_input_stream.read).to eq(expected_content)
        end

        export_service.export_xml_lettings_logs
      end
    end
  end

  context "when exporting a supported housing lettings logs in XML" do
    let(:export_file) { File.open("spec/fixtures/exports/supported_housing_logs.xml", "r:UTF-8") }
    let(:organisation) { FactoryBot.create(:organisation, provider_type: "LA") }
    let(:user) { FactoryBot.create(:user, organisation:, email: "fake@email.com") }
    let(:other_user) { FactoryBot.create(:user, organisation:, email: "other@email.com") }
    let(:scheme) { FactoryBot.create(:scheme, :export, owning_organisation: organisation) }
    let(:location) { FactoryBot.create(:location, :export, scheme:, startdate: Time.zone.local(2021, 4, 1), old_id: "1a") }

    let(:lettings_log) { FactoryBot.create(:lettings_log, :completed, :export, :sh, scheme:, location:, created_by: user, updated_by: other_user, owning_organisation: organisation, startdate: Time.zone.local(2022, 2, 2, 10, 36, 49), voiddate: Time.zone.local(2019, 11, 3), mrcdate: Time.zone.local(2020, 5, 5, 10, 36, 49), underoccupation_benefitcap: 4, sheltered: 1) }

    before do
      FactoryBot.create(:location, scheme:, startdate: Time.zone.local(2021, 4, 1), units: nil)
    end

    it "generates an XML export file with the expected content" do
      expected_content = replace_entity_ids(lettings_log, export_file.read)
      expect(storage_service).to receive(:write_file).with(expected_zip_filename, any_args) do |_, content|
        entry = Zip::File.open_buffer(content).find_entry(expected_data_filename)
        expect(entry).not_to be_nil
        expect(entry.get_input_stream.read).to eq(expected_content)
      end
      export_service.export_xml_lettings_logs(full_update: true)
    end
  end
end
