class BulkUpload::Sales::LogCreator
  attr_reader :bulk_upload, :path

  def initialize(bulk_upload:, path:)
    @bulk_upload = bulk_upload
    @path = path
  end

  def call
    row_parsers.each do |row_parser|
      row_parser.valid?

      next if row_parser.blank_row?

      row_parser.log.blank_invalid_non_setup_fields!
      row_parser.log.bulk_upload = bulk_upload
      row_parser.log.creation_method = "bulk upload"
      row_parser.log.status = "pending"

      begin
        row_parser.log.save!
      rescue StandardError => e
        Sentry.capture_exception(e)
      end
    end
  end

private

  def csv_parser
    @csv_parser ||= case bulk_upload.year
                    when 2023
                      BulkUpload::Sales::Year2023::CsvParser.new(path:)
                    when 2024
                      BulkUpload::Sales::Year2024::CsvParser.new(path:)
                    when 2025
                      BulkUpload::Sales::Year2025::CsvParser.new(path:)
                    else
                      raise "csv parser not found"
                    end
  end

  def row_offset
    csv_parser.row_offset
  end

  def col_offset
    csv_parser.col_offset
  end

  def row_parsers
    return @row_parsers if @row_parsers

    @row_parsers = csv_parser.row_parsers

    @row_parsers.each do |row_parser|
      row_parser.bulk_upload = bulk_upload
    end

    @row_parsers
  end

  def body_rows
    csv_parser.body_rows
  end

  def rows
    csv_parser.rows
  end
end
