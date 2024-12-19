require "rails_helper"

RSpec.describe Exports::SalesLogExportService do
  subject(:export_service) { described_class.new(storage_service, start_time) }

  let(:storage_service) { instance_double(Storage::S3Service) }

  let(:xml_export_file) { File.open("spec/fixtures/exports/sales_log.xml", "r:UTF-8") }
  let(:local_manifest_file) { File.open("spec/fixtures/exports/manifest.xml", "r:UTF-8") }

  let(:expected_zip_filename) { "core_sales_2025_2026_apr_mar_f0001_inc0001.zip" }
  let(:expected_data_filename) { "core_sales_2025_2026_apr_mar_f0001_inc0001_pt001.xml" }
  let(:expected_manifest_filename) { "manifest.xml" }
  let(:start_time) { Time.zone.local(2026, 3, 1) }
  let(:organisation) { create(:organisation, name: "MHCLG", housing_registration_no: 1234) }
  let(:user) { FactoryBot.create(:user, email: "test1@example.com", organisation:) }

  def replace_entity_ids(sales_log, export_template)
    export_template.sub!(/\{owning_org_id\}/, sales_log["owning_organisation_id"].to_s)
    export_template.sub!(/\{managing_org_id\}/, sales_log["managing_organisation_id"].to_s)
    export_template.sub!(/\{assigned_to_id\}/, sales_log["assigned_to_id"].to_s)
    export_template.sub!(/\{created_by_id\}/, sales_log["created_by_id"].to_s)
    export_template.sub!(/\{id\}/, sales_log["id"].to_s)
  end

  def replace_record_number(export_template, record_number)
    export_template.sub!(/\{recno\}/, record_number.to_s)
  end

  before do
    Timecop.freeze(start_time)
    Singleton.__init__(FormHandler)
    allow(storage_service).to receive(:write_file)
  end

  after do
    Timecop.return
  end

  context "when exporting daily sales logs in XML" do
    context "and no sales logs are available for export" do
      it "returns an empty archives list" do
        expect(storage_service).not_to receive(:write_file)
        expect(export_service.export_xml_sales_logs).to eq({})
      end
    end

    context "when one pending sales log exists" do
      before do
        FactoryBot.create(
          :sales_log,
          :export,
          status: "pending",
          skip_update_status: true,
        )
      end

      it "returns empty archives list for archives manifest" do
        expect(storage_service).not_to receive(:write_file)
        expect(export_service.export_xml_sales_logs).to eq({})
      end
    end

    context "and one sales log is available for export" do
      let!(:sales_log) { FactoryBot.create(:sales_log, :export, assigned_to: user) }

      it "generates a ZIP export file with the expected filename" do
        expect(storage_service).to receive(:write_file).with(expected_zip_filename, any_args)
        export_service.export_xml_sales_logs
      end

      it "generates an XML export file with the expected filename within the ZIP file" do
        expect(storage_service).to receive(:write_file).with(expected_zip_filename, any_args) do |_, content|
          entry = Zip::File.open_buffer(content).find_entry(expected_data_filename)
          expect(entry).not_to be_nil
          expect(entry.name).to eq(expected_data_filename)
        end
        export_service.export_xml_sales_logs
      end

      it "generates an XML manifest file with the expected content within the ZIP file" do
        expected_content = replace_record_number(local_manifest_file.read, 1)
        expect(storage_service).to receive(:write_file).with(expected_zip_filename, any_args) do |_, content|
          entry = Zip::File.open_buffer(content).find_entry(expected_manifest_filename)
          expect(entry).not_to be_nil
          expect(entry.get_input_stream.read).to eq(expected_content)
        end

        export_service.export_xml_sales_logs
      end

      it "generates an XML export file with the expected content within the ZIP file" do
        expected_content = replace_entity_ids(sales_log, xml_export_file.read)
        expect(storage_service).to receive(:write_file).with(expected_zip_filename, any_args) do |_, content|
          entry = Zip::File.open_buffer(content).find_entry(expected_data_filename)
          expect(entry).not_to be_nil
          expect(entry.get_input_stream.read).to eq(expected_content)
        end

        export_service.export_xml_sales_logs
      end

      it "returns the list with correct archive" do
        expect(export_service.export_xml_sales_logs).to eq({ expected_zip_filename.gsub(".zip", "") => start_time })
      end
    end

    context "and multiple sales logs are available for export on different periods" do
      let(:previous_zip_filename) { "core_sales_2024_2025_apr_mar_f0001_inc0001.zip" }
      let(:next_zip_filename) { "core_sales_2026_2027_apr_mar_f0001_inc0001.zip" }

      before do
        FactoryBot.create(:sales_log, :ignore_validation_errors, saledate: Time.zone.local(2024, 5, 1))
        FactoryBot.create(:sales_log, saledate: Time.zone.local(2025, 5, 1))
        FactoryBot.create(:sales_log, :ignore_validation_errors, saledate: Time.zone.local(2026, 4, 1))
      end

      context "when sales logs are across multiple years" do
        it "generates multiple ZIP export files with the expected filenames" do
          expect(storage_service).to receive(:write_file).with(expected_zip_filename, any_args)
          expect(storage_service).not_to receive(:write_file).with(previous_zip_filename, any_args)
          expect(storage_service).to receive(:write_file).with(next_zip_filename, any_args)
          expect(Rails.logger).to receive(:info).with("Building export run for sales 2025")
          expect(Rails.logger).to receive(:info).with("Creating core_sales_2025_2026_apr_mar_f0001_inc0001 - 1 resources")
          expect(Rails.logger).to receive(:info).with("Added core_sales_2025_2026_apr_mar_f0001_inc0001_pt001.xml")
          expect(Rails.logger).to receive(:info).with("Writing core_sales_2025_2026_apr_mar_f0001_inc0001.zip")
          expect(Rails.logger).to receive(:info).with("Building export run for sales 2026")
          expect(Rails.logger).to receive(:info).with("Creating core_sales_2026_2027_apr_mar_f0001_inc0001 - 1 resources")
          expect(Rails.logger).to receive(:info).with("Added core_sales_2026_2027_apr_mar_f0001_inc0001_pt001.xml")
          expect(Rails.logger).to receive(:info).with("Writing core_sales_2026_2027_apr_mar_f0001_inc0001.zip")

          export_service.export_xml_sales_logs
        end

        it "generates zip export files only for specified year" do
          expect(storage_service).to receive(:write_file).with(next_zip_filename, any_args)
          expect(Rails.logger).to receive(:info).with("Building export run for sales 2026")
          expect(Rails.logger).to receive(:info).with("Creating core_sales_2026_2027_apr_mar_f0001_inc0001 - 1 resources")
          expect(Rails.logger).to receive(:info).with("Added core_sales_2026_2027_apr_mar_f0001_inc0001_pt001.xml")
          expect(Rails.logger).to receive(:info).with("Writing core_sales_2026_2027_apr_mar_f0001_inc0001.zip")

          export_service.export_xml_sales_logs(collection_year: 2026)
        end

        context "and previous full exports are different for previous years" do
          let(:expected_zip_filename) { "core_sales_2025_2026_apr_mar_f0007_inc0004.zip" }
          let(:next_zip_filename) { "core_sales_2026_2027_apr_mar_f0001_inc0001.zip" }

          before do
            Export.new(started_at: Time.zone.yesterday, base_number: 7, increment_number: 3, collection: "sales", year: 2025).save!
          end

          it "generates multiple ZIP export files with different base numbers in the filenames" do
            expect(storage_service).to receive(:write_file).with(expected_zip_filename, any_args)
            expect(storage_service).to receive(:write_file).with(next_zip_filename, any_args)
            expect(Rails.logger).to receive(:info).with("Building export run for sales 2025")
            expect(Rails.logger).to receive(:info).with("Creating core_sales_2025_2026_apr_mar_f0007_inc0004 - 1 resources")
            expect(Rails.logger).to receive(:info).with("Added core_sales_2025_2026_apr_mar_f0007_inc0004_pt001.xml")
            expect(Rails.logger).to receive(:info).with("Writing core_sales_2025_2026_apr_mar_f0007_inc0004.zip")
            expect(Rails.logger).to receive(:info).with("Building export run for sales 2026")
            expect(Rails.logger).to receive(:info).with("Creating core_sales_2026_2027_apr_mar_f0001_inc0001 - 1 resources")
            expect(Rails.logger).to receive(:info).with("Added core_sales_2026_2027_apr_mar_f0001_inc0001_pt001.xml")
            expect(Rails.logger).to receive(:info).with("Writing core_sales_2026_2027_apr_mar_f0001_inc0001.zip")

            export_service.export_xml_sales_logs
          end
        end
      end
    end

    context "and multiple sales logs are available for export on same quarter" do
      before do
        FactoryBot.create(:sales_log, saledate: Time.zone.local(2025, 4, 1))
        FactoryBot.create(:sales_log, saledate: Time.zone.local(2025, 4, 20))
      end

      it "generates an XML manifest file with the expected content within the ZIP file" do
        expected_content = replace_record_number(local_manifest_file.read, 2)
        expect(storage_service).to receive(:write_file).with(expected_zip_filename, any_args) do |_, content|
          entry = Zip::File.open_buffer(content).find_entry(expected_manifest_filename)
          expect(entry).not_to be_nil
          expect(entry.get_input_stream.read).to eq(expected_content)
        end

        export_service.export_xml_sales_logs
      end

      it "creates a logs export record in a database with correct time" do
        expect { export_service.export_xml_sales_logs }
          .to change(Export, :count).by(2)
        expect(Export.last.started_at).to be_within(2.seconds).of(start_time)
      end

      context "when this is the first export (full)" do
        it "returns a ZIP archive for the master manifest (existing sales logs)" do
          expect(export_service.export_xml_sales_logs).to eq({ expected_zip_filename.gsub(".zip", "").gsub(".zip", "") => start_time })
        end
      end

      context "and underlying data changes between getting the logs and writting the manifest" do
        before do
          FactoryBot.create(:sales_log, saledate: Time.zone.local(2026, 2, 1))
          FactoryBot.create(:sales_log, :ignore_validation_errors, saledate: Time.zone.local(2026, 4, 1))
        end

        def remove_logs(logs)
          logs.each(&:destroy)
          file = Tempfile.new
          doc = Nokogiri::XML("<forms/>")
          doc.write_xml_to(file, encoding: "UTF-8")
          file.rewind
          file
        end

        def create_fake_maifest
          file = Tempfile.new
          doc = Nokogiri::XML("<forms/>")
          doc.write_xml_to(file, encoding: "UTF-8")
          file.rewind
          file
        end

        it "maintains the same record number" do
          # rubocop:disable RSpec/SubjectStub
          allow(export_service).to receive(:build_export_xml) do |logs|
            remove_logs(logs)
          end
          allow(export_service).to receive(:build_manifest_xml) do
            create_fake_maifest
          end

          expect(export_service).to receive(:build_manifest_xml).with(1)
          # rubocop:enable RSpec/SubjectStub
          export_service.export_xml_sales_logs
        end
      end

      context "when this is a second export (partial)" do
        before do
          start_time = Time.zone.local(2026, 6, 1)
          Export.new(started_at: start_time, collection: "sales", year: 2025).save!
        end

        it "does not add any entry for the master manifest (no sales logs)" do
          expect(storage_service).not_to receive(:write_file)
          expect(export_service.export_xml_sales_logs).to eq({})
        end
      end
    end

    context "and a previous export has run the same day having sales logs" do
      before do
        FactoryBot.create(:sales_log, saledate: Time.zone.local(2025, 5, 1))
        export_service.export_xml_sales_logs
      end

      context "and we trigger another full update" do
        it "increments the base number" do
          export_service.export_xml_sales_logs(full_update: true)
          expect(Export.last.base_number).to eq(2)
        end

        it "resets the increment number" do
          export_service.export_xml_sales_logs(full_update: true)
          expect(Export.last.increment_number).to eq(1)
        end

        it "returns a correct archives list for manifest file" do
          expect(export_service.export_xml_sales_logs(full_update: true)).to eq({ "core_sales_2025_2026_apr_mar_f0002_inc0001" => start_time })
        end

        it "generates a ZIP export file with the expected filename" do
          expect(storage_service).to receive(:write_file).with("core_sales_2025_2026_apr_mar_f0002_inc0001.zip", any_args)
          export_service.export_xml_sales_logs(full_update: true)
        end
      end
    end

    context "and a previous export has run having no sales logs" do
      before { export_service.export_xml_sales_logs }

      it "doesn't increment the manifest number by 1" do
        export_service.export_xml_sales_logs

        expect(Export.last.increment_number).to eq(1)
      end
    end

    context "and a log has been manually updated since the previous partial export" do
      let(:expected_zip_filename) { "core_sales_2025_2026_apr_mar_f0001_inc0002.zip" }

      before do
        FactoryBot.create(:sales_log, saledate: Time.zone.local(2026, 2, 1), updated_at: Time.zone.local(2026, 2, 27), values_updated_at: Time.zone.local(2026, 2, 29))
        FactoryBot.create(:sales_log, saledate: Time.zone.local(2026, 2, 1), updated_at: Time.zone.local(2026, 2, 27), values_updated_at: Time.zone.local(2026, 2, 29))
        Export.create!(started_at: Time.zone.local(2026, 2, 28), base_number: 1, increment_number: 1, collection: "sales", year: 2025)
      end

      it "generates an XML manifest file with the expected content within the ZIP file" do
        expected_content = replace_record_number(local_manifest_file.read, 2)
        expect(storage_service).to receive(:write_file).with(expected_zip_filename, any_args) do |_, content|
          entry = Zip::File.open_buffer(content).find_entry(expected_manifest_filename)
          expect(entry).not_to be_nil
          expect(entry.get_input_stream.read).to eq(expected_content)
        end

        expect(export_service.export_xml_sales_logs).to eq({ expected_zip_filename.gsub(".zip", "") => start_time })
      end
    end

    context "and one sales log with duplicate reference is available for export" do
      let!(:sales_log) { FactoryBot.create(:sales_log, :export, duplicate_set_id: 123) }

      def replace_duplicate_set_id(export_file)
        export_file.sub!("<duplicate_set_id/>", "<duplicate_set_id>123</duplicate_set_id>")
      end

      it "generates an XML export file with the expected content within the ZIP file" do
        expected_content = replace_entity_ids(sales_log, xml_export_file.read)
        expected_content = replace_duplicate_set_id(expected_content)
        expect(storage_service).to receive(:write_file).with(expected_zip_filename, any_args) do |_, content|
          entry = Zip::File.open_buffer(content).find_entry(expected_data_filename)
          expect(entry).not_to be_nil
          expect(entry.get_input_stream.read).to eq(expected_content)
        end

        export_service.export_xml_sales_logs
      end
    end

    context "when exporting only 24/25 collection period" do
      let(:start_time) { Time.zone.local(2024, 4, 3) }

      before do
        Timecop.freeze(start_time)
        Singleton.__init__(FormHandler)
      end

      after do
        Timecop.unfreeze
        Singleton.__init__(FormHandler)
      end

      context "and one sales log is available for export" do
        let!(:sales_log) { FactoryBot.create(:sales_log, :export) }
        let(:expected_zip_filename) { "core_sales_2024_2025_apr_mar_f0001_inc0001.zip" }
        let(:expected_data_filename) { "core_sales_2024_2025_apr_mar_f0001_inc0001_pt001.xml" }
        let(:xml_export_file) { File.open("spec/fixtures/exports/sales_log_2024.xml", "r:UTF-8") }

        it "generates an XML export file with the expected content within the ZIP file" do
          expected_content = replace_entity_ids(sales_log, xml_export_file.read)
          expect(storage_service).to receive(:write_file).with(expected_zip_filename, any_args) do |_, content|
            entry = Zip::File.open_buffer(content).find_entry(expected_data_filename)
            expect(entry).not_to be_nil
            expect(entry.get_input_stream.read).to eq(expected_content)
          end

          export_service.export_xml_sales_logs(full_update: true, collection_year: 2024)
        end
      end
    end
  end
end
