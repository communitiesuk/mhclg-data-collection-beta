require "rails_helper"

RSpec.describe BulkUpload::Sales::Validator do
  subject(:validator) { described_class.new(bulk_upload:, path:) }

  let(:user) { create(:user, organisation:) }
  let(:organisation) { create(:organisation, old_visible_id: "3") }
  let(:bulk_upload) { create(:bulk_upload, user:) }
  let(:path) { file.path }
  let(:file) { Tempfile.new }

  describe "validations" do
    context "when file is empty" do
      it "is not valid" do
        expect(validator).not_to be_valid
        expect(validator.errors["base"]).to eql(["Template is blank - The template must be filled in for us to create the logs and check if data is correct."])
      end
    end

    context "and has a new line in it (empty)" do
      before do
        file.write("\n")
        file.rewind
      end

      it "is not valid" do
        expect(validator).not_to be_valid
        expect(validator.errors["base"]).to eql(["Template is blank - The template must be filled in for us to create the logs and check if data is correct."])
      end
    end

    context "when file has too many columns" do
      before do
        file.write((%w[a] * 127).join(","))
        file.rewind
      end

      it "is not valid" do
        expect(validator).not_to be_valid
      end
    end

    context "when trying to upload 2022 data for 2023 bulk upload" do
      let(:bulk_upload) { create(:bulk_upload, user:, year: 2023) }

      context "with a valid csv" do
        let(:path) { file_fixture("2022_23_sales_bulk_upload.csv") }

        it "is not valid" do
          expect(validator).not_to be_valid
        end
      end

      context "with unix line endings" do
        let(:fixture_path) { file_fixture("2022_23_sales_bulk_upload.csv") }
        let(:file) { Tempfile.new }
        let(:path) { file.path }

        before do
          string = File.read(fixture_path)
          string.gsub!("\r\n", "\n")
          file.write(string)
          file.rewind
        end

        it "is not valid" do
          expect(validator).not_to be_valid
        end
      end

      context "without headers" do
        let(:log) { build(:sales_log, :completed) }
        let(:file) { Tempfile.new }
        let(:path) { file.path }

        before do
          Timecop.freeze(Time.utc(2022, 6, 3))
          file.write(BulkUpload::SalesLogToCsv.new(log:, line_ending: "\r\n", col_offset: 0).to_2022_csv_row)
          file.close
        end

        after do
          Timecop.unfreeze
        end

        it "is not valid" do
          expect(validator).not_to be_valid
        end
      end
    end
  end

  describe "#call" do
    context "when a valid csv" do
      let(:path) { file_fixture("2022_23_sales_bulk_upload.csv") }

      it "creates validation errors" do
        expect { validator.call }.to change(BulkUploadError, :count)
      end

      it "create validation error with correct values" do
        validator.call

        error = BulkUploadError.find_by(row: "6", field: "field_92", category: "setup")

        expect(error.field).to eql("field_92")
        expect(error.error).to eql("You must answer owning organisation")
        expect(error.purchaser_code).to eql("22 test BU")
        expect(error.row).to eql("6")
        expect(error.cell).to eql("CO6")
        expect(error.col).to eql("CO")
      end
    end

    context "with unix line endings" do
      let(:fixture_path) { file_fixture("2022_23_sales_bulk_upload.csv") }
      let(:file) { Tempfile.new }
      let(:path) { file.path }

      before do
        string = File.read(fixture_path)
        string.gsub!("\r\n", "\n")
        file.write(string)
        file.rewind
      end

      it "creates validation errors" do
        expect { validator.call }.to change(BulkUploadError, :count)
      end
    end

    context "without headers" do
      let(:log) { build(:sales_log, :completed) }
      let(:file) { Tempfile.new }
      let(:path) { file.path }

      before do
        file.write(BulkUpload::SalesLogToCsv.new(log:, line_ending: "\r\n", col_offset: 0).to_2022_csv_row)
        file.close
      end

      it "creates validation errors" do
        expect { validator.call }.to change(BulkUploadError, :count)
      end
    end

    context "when duplicate rows present" do
      let(:file) { Tempfile.new }
      let(:path) { file.path }
      let(:log) { build(:sales_log, :completed) }

      before do
        file.write(BulkUpload::SalesLogToCsv.new(log:, col_offset: 0).to_2022_csv_row)
        file.write(BulkUpload::SalesLogToCsv.new(log:, col_offset: 0).to_2022_csv_row)
        file.close
      end

      it "creates errors" do
        expect { validator.call }.to change(BulkUploadError.where(category: :setup, error: "This is a duplicate of a log in your file"), :count).by(20)
      end
    end
  end

  describe "#create_logs?" do
    around do |example|
      Timecop.freeze(Time.zone.local(2023, 2, 22)) do
        Singleton.__init__(FormHandler)
        example.run
      end
      Timecop.return
      Singleton.__init__(FormHandler)
    end

    context "when all logs are valid" do
      let(:target_path) { file_fixture("completed_2022_23_sales_bulk_upload.csv") }

      before do
        target_array = File.open(target_path).readlines
        target_array[0..118].each do |line|
          file.write line
        end
        file.rewind
      end

      it "returns truthy" do
        validator.call
        expect(validator).to be_create_logs
      end
    end

    context "when there is an invalid log" do
      let(:path) { file_fixture("2022_23_sales_bulk_upload.csv") }

      it "returns falsey" do
        validator.call
        expect(validator).not_to be_create_logs
      end
    end

    context "when a log is not valid?" do
      let(:log_1) { build(:sales_log, :completed, created_by: user) }
      let(:log_2) { build(:sales_log, :completed, created_by: user) }

      before do
        file.write(BulkUpload::SalesLogToCsv.new(log: log_1, line_ending: "\r\n", col_offset: 0).to_2022_csv_row)
        file.write(BulkUpload::SalesLogToCsv.new(log: log_2, line_ending: "\r\n", col_offset: 0, overrides: { organisation_id: "random" }).to_2022_csv_row)
        file.close
      end

      it "returns false" do
        validator.call
        expect(validator).not_to be_create_logs
      end
    end

    context "when all logs valid?" do
      let(:log_1) { build(:sales_log, :completed, created_by: user) }
      let(:log_2) { build(:sales_log, :completed, created_by: user) }

      before do
        file.write(BulkUpload::SalesLogToCsv.new(log: log_1, line_ending: "\r\n", col_offset: 0).to_2022_csv_row)
        file.write(BulkUpload::SalesLogToCsv.new(log: log_2, line_ending: "\r\n", col_offset: 0).to_2022_csv_row)
        file.close
      end

      it "returns true" do
        validator.call
        expect(validator).to be_create_logs
      end
    end

    context "when a single log wants to block log creation" do
      let(:unaffiliated_org) { create(:organisation) }

      let(:log_1) { build(:sales_log, :completed, created_by: user, owning_organisation: unaffiliated_org) }

      before do
        file.write(BulkUpload::SalesLogToCsv.new(log: log_1, line_ending: "\r\n", col_offset: 0).to_2022_csv_row)
        file.close
      end

      it "will not create logs" do
        validator.call
        expect(validator).not_to be_create_logs
      end
    end

    context "when a log has incomplete setup secion" do
      let(:log) { build(:sales_log, created_by: user, saledate: Time.zone.local(2022, 5, 1)) }

      before do
        file.write(BulkUpload::SalesLogToCsv.new(log:, line_ending: "\r\n", col_offset: 0).to_2022_csv_row)
        file.close
      end

      it "returns false" do
        validator.call
        expect(validator).not_to be_create_logs
      end
    end
  end

  describe "#total_logs_count?" do
    around do |example|
      Timecop.freeze(Time.zone.local(2023, 2, 22)) do
        Singleton.__init__(FormHandler)
        example.run
      end
      Timecop.return
      Singleton.__init__(FormHandler)
    end

    context "when all logs are valid" do
      let(:target_path) { file_fixture("completed_2022_23_sales_bulk_upload.csv") }

      before do
        target_array = File.open(target_path).readlines
        target_array[0..118].each do |line|
          file.write line
        end
        file.rewind
      end

      it "returns correct total logs count" do
        expect(validator.total_logs_count).to be(1)
      end
    end
  end
end
