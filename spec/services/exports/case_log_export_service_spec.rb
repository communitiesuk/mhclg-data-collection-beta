require "rails_helper"

RSpec.describe Exports::CaseLogExportService do
  let(:storage_service) { instance_double(StorageService) }

  let(:export_file) { File.open("spec/fixtures/exports/case_logs.xml", "r:UTF-8") }
  let(:local_manifest_file) { File.open("spec/fixtures/exports/manifest.xml", "r:UTF-8") }

  let(:expected_master_manifest_filename) { "Manifest_2022_05_01_0001.csv" }
  let(:expected_master_manifest_rerun) { "Manifest_2022_05_01_0002.csv" }
  let(:expected_zip_filename) { "core_2021_2022_jan_mar_f0001_inc001.zip" }
  let(:expected_manifest_filename) { "manifest.xml" }

  let!(:case_log) { FactoryBot.create(:case_log, :completed) }

  def replace_entity_ids(export_template)
    export_template.sub!(/\{id\}/, (case_log["id"] + Exports::CaseLogExportService::LOG_ID_OFFSET).to_s)
    export_template.sub!(/\{owning_org_id\}/, case_log["owning_organisation_id"].to_s)
    export_template.sub!(/\{managing_org_id\}/, case_log["managing_organisation_id"].to_s)
    export_template.sub!(/\{created_by_id\}/, case_log["created_by_id"].to_s)
  end

  def replace_record_number(export_template, record_number)
    export_template.sub!(/\{recno\}/, record_number.to_s)
  end

  context "when exporting daily case logs" do
    subject(:export_service) { described_class.new(storage_service) }

    let(:start_time) { Time.zone.local(2022, 5, 1) }

    before do
      Timecop.freeze(start_time)
      allow(storage_service).to receive(:write_file)
    end

    context "and no case logs is available for export" do
      it "generates a master manifest with the correct name" do
        expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args)
        export_service.export_case_logs
      end

      it "generates a master manifest with CSV headers but no data" do
        actual_content = nil
        expected_content = "zip-name,date-time zipped folder generated,zip-file-uri\n"
        allow(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) { |_, arg2| actual_content = arg2&.string }

        export_service.export_case_logs
        expect(actual_content).to eq(expected_content)
      end
    end

    context "and one case log is available for export" do
      let(:expected_data_filename) { "core_2021_2022_jan_mar_f0001_inc001.xml" }

      it "generates a ZIP export file with the expected filename" do
        expect(storage_service).to receive(:write_file).with(expected_zip_filename, any_args)
        export_service.export_case_logs
      end

      it "generates an XML manifest file with the expected filename within the ZIP file" do
        expect(storage_service).to receive(:write_file).with(expected_zip_filename, any_args) do |_, content|
          entry = Zip::File.open_buffer(content).find_entry(expected_manifest_filename)
          expect(entry).not_to be_nil
          expect(entry.name).to eq(expected_manifest_filename)
        end
        export_service.export_case_logs
      end

      it "generates an XML export file with the expected filename within the ZIP file" do
        expect(storage_service).to receive(:write_file).with(expected_zip_filename, any_args) do |_, content|
          entry = Zip::File.open_buffer(content).find_entry(expected_data_filename)
          expect(entry).not_to be_nil
          expect(entry.name).to eq(expected_data_filename)
        end
        export_service.export_case_logs
      end

      it "generates an XML manifest file with the expected content within the ZIP file" do
        expected_content = replace_record_number(local_manifest_file.read, 1)
        expect(storage_service).to receive(:write_file).with(expected_zip_filename, any_args) do |_, content|
          entry = Zip::File.open_buffer(content).find_entry(expected_manifest_filename)
          expect(entry).not_to be_nil
          expect(entry.get_input_stream.read).to eq(expected_content)
        end

        export_service.export_case_logs
      end

      it "generates an XML export file with the expected content within the ZIP file" do
        expected_content = replace_entity_ids(export_file.read)
        expect(storage_service).to receive(:write_file).with(expected_zip_filename, any_args) do |_, content|
          entry = Zip::File.open_buffer(content).find_entry(expected_data_filename)
          expect(entry).not_to be_nil
          expect(entry.get_input_stream.read).to eq(expected_content)
        end

        export_service.export_case_logs
      end
    end

    context "and multiple case logs are available for export on different periods" do
      before { FactoryBot.create(:case_log, startdate: Time.zone.local(2022, 4, 1)) }

      context "when case logs are across multiple quarters" do
        it "generates multiple ZIP export files with the expected filenames" do
          expect(storage_service).to receive(:write_file).with("core_2021_2022_jan_mar_f0001_inc001.zip", any_args)
          expect(storage_service).to receive(:write_file).with("core_2022_2023_apr_jun_f0001_inc001.zip", any_args)

          export_service.export_case_logs
        end
      end
    end

    context "and multiple case logs are available for export on same periods" do
      before { FactoryBot.create(:case_log, startdate: Time.zone.local(2022, 3, 20)) }

      it "generates an XML manifest file with the expected content within the ZIP file" do
        expected_content = replace_record_number(local_manifest_file.read, 2)
        allow(storage_service).to receive(:write_file).with(expected_zip_filename, any_args) do |_, content|
          entry = Zip::File.open_buffer(content).find_entry(expected_manifest_filename)
          expect(entry).not_to be_nil
          expect(entry.get_input_stream.read).to eq(expected_content)
        end

        export_service.export_case_logs
      end

      it "creates a logs export record in a database with correct time" do
        expect { export_service.export_case_logs }
          .to change(LogsExport, :count).by(1)
        expect(LogsExport.last.started_at).to eq(start_time)
      end

      context "when this is the first export (full)" do
        it "records a ZIP archive in the master manifest (existing case logs)" do
          expect(storage_service).to receive(:write_file).with(expected_master_manifest_filename, any_args) do |_, csv_content|
            csv = CSV.parse(csv_content, headers: true)
            expect(csv&.count).to eq(1)
          end

          export_service.export_case_logs
        end
      end

      context "when this is an partial export" do
        it "does not add any entry in the master manifest (no case logs)" do
          start_time = Time.zone.local(2022, 4, 1)
          LogsExport.new(started_at: start_time, daily_run_number: 1).save!

          expect(storage_service).to receive(:write_file).with(expected_master_manifest_rerun, any_args) do |_, csv_content|
            csv = CSV.parse(csv_content, headers: true)
            expect(csv&.count).to eq(0)
          end

          export_service.export_case_logs
        end
      end
    end

    context "and a previous export has run the same day" do
      before do
        export_service.export_case_logs
      end

      it "increments the master manifest number by 1" do
        expect(storage_service).to receive(:write_file).with(expected_master_manifest_rerun, any_args)
        export_service.export_case_logs
      end
    end

    context "when export has an error" do
      it "does not save a record in the database" do
        allow(storage_service).to receive(:write_file).and_raise(StandardError.new("This is an exception"))
        export = LogsExport.new
        allow(LogsExport).to receive(:new).and_return(export)
        expect(export).not_to receive(:save!)
        expect { export_service.export_case_logs }.to raise_error(StandardError)
      end
    end
  end
end
