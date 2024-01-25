require "rails_helper"

RSpec.describe BulkUpload::Sales::Year2024::CsvParser do
  subject(:service) { described_class.new(path:) }

  let(:file) { Tempfile.new }
  let(:path) { file.path }
  let(:log) { build(:sales_log, :completed, :with_uprn) }

  context "when parsing csv with headers" do
    before do
      file.write("Question\n")
      file.write("Additional info\n")
      file.write("Values\n")
      file.write("Can be empty?\n")
      file.write("Type of letting the question applies to\n")
      file.write("Duplicate check field?\n")
      file.write(BulkUpload::SalesLogToCsv.new(log:).default_2024_field_numbers_row)
      file.write(BulkUpload::SalesLogToCsv.new(log:).to_2024_csv_row)
      file.rewind
    end

    it "returns correct offsets" do
      expect(service.row_offset).to eq(7)
      expect(service.col_offset).to eq(1)
    end

    it "parses csv correctly" do
      expect(service.row_parsers[0].field_22).to eql(log.uprn)
    end
  end

  context "when parsing csv with headers in arbitrary order" do
    let(:seed) { rand }

    before do
      file.write("Question\n")
      file.write("Additional info\n")
      file.write("Values\n")
      file.write("Can be empty?\n")
      file.write("Type of letting the question applies to\n")
      file.write("Duplicate check field?\n")
      file.write(BulkUpload::SalesLogToCsv.new(log:).default_2024_field_numbers_row(seed:))
      file.write(BulkUpload::SalesLogToCsv.new(log:).to_2024_csv_row(seed:))
      file.rewind
    end

    it "returns correct offsets" do
      expect(service.row_offset).to eq(7)
      expect(service.col_offset).to eq(1)
    end

    it "parses csv correctly" do
      expect(service.row_parsers[0].field_22).to eql(log.uprn)
    end
  end

  context "when parsing csv without headers" do
    let(:file) { Tempfile.new }
    let(:path) { file.path }
    let(:log) { build(:sales_log, :completed, :with_uprn) }

    before do
      file.write(BulkUpload::SalesLogToCsv.new(log:, col_offset: 0).to_2024_csv_row)
      file.rewind
    end

    it "returns correct offsets" do
      expect(service.row_offset).to eq(0)
      expect(service.col_offset).to eq(0)
    end

    it "parses csv correctly" do
      expect(service.row_parsers[0].field_22).to eql(log.uprn)
    end
  end

  context "when parsing with BOM aka byte order mark" do
    let(:file) { Tempfile.new }
    let(:path) { file.path }
    let(:log) { build(:sales_log, :completed, :with_uprn) }
    let(:bom) { "\uFEFF" }

    before do
      file.write(bom)
      file.write(BulkUpload::SalesLogToCsv.new(log:, col_offset: 0).to_2024_csv_row)
      file.close
    end

    it "parses csv correctly" do
      expect(service.row_parsers[0].field_22).to eql(log.uprn)
    end
  end

  context "when an invalid byte sequence" do
    let(:file) { Tempfile.new }
    let(:path) { file.path }
    let(:log) { build(:sales_log, :completed, :with_uprn) }
    let(:invalid_sequence) { "\x81" }

    before do
      file.write(invalid_sequence)
      file.write(BulkUpload::SalesLogToCsv.new(log:, col_offset: 0).to_2024_csv_row)
      file.close
    end

    it "parses csv correctly" do
      expect(service.row_parsers[0].field_22).to eql(log.uprn)
    end
  end

  describe "#column_for_field", aggregate_failures: true do
    context "when headers present" do
      before do
        file.write("Question\n")
        file.write("Additional info\n")
        file.write("Values\n")
        file.write("Can be empty?\n")
        file.write("Type of letting the question applies to\n")
        file.write("Duplicate check field?\n")
        file.write(BulkUpload::SalesLogToCsv.new(log:).default_2024_field_numbers_row)
        file.write(BulkUpload::SalesLogToCsv.new(log:).to_2024_csv_row)
        file.rewind
      end

      it "returns correct column" do
        expect(service.column_for_field("field_1")).to eql("B")
        expect(service.column_for_field("field_99")).to eql("CV")
      end
    end
  end

  context "when parsing csv with carriage returns" do
    before do
      file.write("Question\r\n")
      file.write("Additional info\r")
      file.write("Values\r\n")
      file.write("Can be empty?\r")
      file.write("Type of letting the question applies to\r\n")
      file.write("Duplicate check field?\r")
      file.write(BulkUpload::SalesLogToCsv.new(log:).default_2024_field_numbers_row)
      file.write(BulkUpload::SalesLogToCsv.new(log:).to_2024_csv_row)
      file.rewind
    end

    it "parses csv correctly" do
      expect(service.row_parsers[0].field_22).to eql(log.uprn)
    end
  end
end
