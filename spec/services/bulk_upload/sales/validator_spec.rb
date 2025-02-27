require "rails_helper"

RSpec.describe BulkUpload::Sales::Validator do
  subject(:validator) { described_class.new(bulk_upload:, path:) }

  let(:user) { create(:user, organisation:) }
  let(:organisation) { create(:organisation, old_visible_id: "123") }
  let(:log) { build(:sales_log, :completed, assigned_to: user) }
  let(:log_to_csv) { BulkUpload::SalesLogToCsv.new(log:) }
  let(:bulk_upload) { create(:bulk_upload, user:, year: log.collection_start_year) }
  let(:path) { file.path }
  let(:file) { Tempfile.new }

  describe "validations" do
    context "when file is empty" do
      it "is not valid" do
        expect(validator).not_to be_valid
        expect(validator.errors["base"]).to eql([I18n.t("validations.sales.2024.bulk_upload.blank_file")])
      end
    end

    context "and has a new line in it (empty)" do
      before do
        file.write("\n")
        file.rewind
      end

      it "is not valid" do
        expect(validator).not_to be_valid
        expect(validator.errors["base"]).to eql([I18n.t("validations.sales.2024.bulk_upload.blank_file")])
      end
    end

    context "when file has too many columns" do
      before do
        file.write((%w[a] * (BulkUpload::Sales::Year2023::CsvParser::MAX_COLUMNS + 1)).join(","))
        file.rewind
      end

      it "is not valid" do
        expect(validator).not_to be_valid
      end
    end

    context "when trying to upload 2023 logs for 2024 bulk upload" do
      let(:bulk_upload) { create(:bulk_upload, user:, year: 2024) }
      let(:log) { build(:sales_log, :completed, saledate: Time.zone.local(2023, 10, 10), assigned_to: user) }

      before do
        file.write(log_to_csv.default_field_numbers_row_for_year(2024))
        file.write(log_to_csv.to_year_csv_row(2024))
        file.rewind
      end

      it "is not valid" do
        expect(validator).not_to be_valid
        expect(validator.errors["base"]).to eql([I18n.t("validations.sales.2024.bulk_upload.wrong_template.wrong_template")])
      end
    end

    [
      { line_ending: "\n", name: "unix" },
      { line_ending: "\r\n", name: "windows" },
    ].each do |test_case|
      context "with #{test_case[:name]} line endings" do
        let(:log_to_csv) { BulkUpload::SalesLogToCsv.new(log:, line_ending: test_case[:line_ending]) }

        context "with a valid file" do
          before do
            file.write(log_to_csv.default_field_numbers_row)
            file.write(log_to_csv.to_csv_row)
            file.rewind
          end

          it "is valid" do
            expect(validator).to be_valid
          end
        end
      end
    end

    context "with a valid file in an arbitrary order" do
      let(:seed) { rand }

      before do
        file.write(log_to_csv.default_field_numbers_row(seed:))
        file.write(log_to_csv.to_csv_row(seed:))
        file.rewind
      end

      it "is valid" do
        expect(validator).to be_valid
      end
    end

    context "when file is missing required headers" do
      before do
        file.write(log_to_csv.to_csv_row)
        file.close
      end

      it "is not valid" do
        expect(validator).not_to be_valid
        expect(validator.errors["base"]).to include(match("Your file does not contain the required header rows."))
      end
    end
  end

  describe "#call" do
    context "when a valid csv" do
      before do
        file.write(log_to_csv.default_field_numbers_row)
        file.write(log_to_csv.to_csv_row)
        file.rewind
      end

      it "does not create validation errors" do
        expect { validator.call }.not_to change(BulkUploadError, :count)
      end
    end

    context "with an invalid 2024 csv" do
      before do
        log.owning_organisation = nil
        file.write(log_to_csv.default_field_numbers_row)
        file.write(log_to_csv.to_csv_row)
        file.rewind
      end

      it "creates validation errors" do
        expect { validator.call }.to change(BulkUploadError, :count)
      end

      it "create validation error with correct values" do
        validator.call

        error = BulkUploadError.find_by(row: "2", field: "field_1", category: "setup")

        expect(error.field).to eql("field_1")
        expect(error.error).to eql("You must answer owning organisation.")
        expect(error.purchaser_code).to eql(log.purchaser_code)
        expect(error.row).to eql("2")
        expect(error.cell).to eql("B2")
        expect(error.col).to eql("B")
      end
    end

    [
      { line_ending: "\n", name: "unix" },
      { line_ending: "\r\n", name: "windows" },
    ].each do |test_case|
      context "with #{test_case[:name]} line endings" do
        let(:log_to_csv) { BulkUpload::SalesLogToCsv.new(log:, line_ending: test_case[:line_ending]) }

        context "with a valid file" do
          before do
            file.write(log_to_csv.default_field_numbers_row)
            file.write(log_to_csv.to_csv_row)
            file.rewind
          end

          it "does not create validation errors" do
            expect { validator.call }.not_to change(BulkUploadError, :count)
          end
        end

        context "with an invalid file" do
          let(:log) { build(:sales_log, :completed, assigned_to: user, privacynotice: nil) }

          before do
            file.write(log_to_csv.default_field_numbers_row)
            file.write(log_to_csv.to_csv_row)
            file.rewind
          end

          it "creates validation errors" do
            expect { validator.call }.to change(BulkUploadError, :count)
          end
        end
      end
    end

    context "without headers" do
      before do
        file.write(log_to_csv.to_csv_row)
        file.close
      end

      it "creates validation errors" do
        expect { validator.call }.to change(BulkUploadError, :count)
      end
    end

    context "when duplicate rows present" do
      before do
        file.write(log_to_csv.to_csv_row)
        file.write(log_to_csv.to_csv_row)
        file.close
      end

      it "creates errors" do
        expect { validator.call }.to change(BulkUploadError.where(category: :setup, error: "This is a duplicate of a log in your file."), :count).by(20)
      end
    end
  end

  describe "#block_log_creation_reason" do
    context "when all logs are valid" do
      let(:log_1) { build(:sales_log, :completed, assigned_to: user) }
      let(:log_2) { build(:sales_log, :completed, assigned_to: user) }

      before do
        file.write(BulkUpload::SalesLogToCsv.new(log: log_1).to_csv_row)
        file.write(BulkUpload::SalesLogToCsv.new(log: log_2).to_csv_row)
      end

      it "returns nil" do
        validator.call
        expect(validator.block_log_creation_reason).to be_nil
      end
    end

    context "when a log has a clearable non-setup error" do
      let(:log_1) { build(:sales_log, :completed, assigned_to: user) }
      let(:log_2) { build(:sales_log, :completed, assigned_to: user, age1: 5) }

      before do
        file.write(BulkUpload::SalesLogToCsv.new(log: log_1).to_csv_row)
        file.write(BulkUpload::SalesLogToCsv.new(log: log_2).to_csv_row)
      end

      it "returns nil" do
        validator.call
        expect(validator.block_log_creation_reason).to be_nil
      end
    end

    context "when a log has an incomplete setup section" do
      let(:log_1) { build(:sales_log, :completed, assigned_to: user) }
      let(:log_2) { build(:sales_log, :completed, assigned_to: user, privacynotice: nil) }

      before do
        file.write(BulkUpload::SalesLogToCsv.new(log: log_1).to_csv_row)
        file.write(BulkUpload::SalesLogToCsv.new(log: log_2).to_csv_row)
        file.close
      end

      it "returns the reason" do
        validator.call
        expect(validator.block_log_creation_reason).to eq("setup_errors")
      end
    end

    context "when a single log wants to block log creation" do
      let(:unaffiliated_org) { create(:organisation) }
      let(:log) { build(:sales_log, :completed, assigned_to: user, owning_organisation: unaffiliated_org) }

      before do
        file.write(log_to_csv.to_csv_row)
        file.close
      end

      it "will not create logs" do
        validator.call
        expect(validator.block_log_creation_reason).to eq("setup_errors")
      end
    end
  end

  describe "#total_logs_count?" do
    context "when all logs are valid" do
      let(:log_2) { build(:sales_log, :completed, assigned_to: user) }
      let(:log_3) { build(:sales_log, :completed, assigned_to: user) }

      before do
        file.write(log_to_csv.default_field_numbers_row)
        file.write(log_to_csv.to_csv_row)
        file.write(BulkUpload::SalesLogToCsv.new(log: log_2).to_csv_row)
        file.write(BulkUpload::SalesLogToCsv.new(log: log_3).to_csv_row)
        file.rewind
      end

      it "returns correct total logs count" do
        expect(validator.total_logs_count).to be(3)
      end
    end
  end
end
