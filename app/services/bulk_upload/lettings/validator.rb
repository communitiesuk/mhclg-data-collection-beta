require "csv"

class BulkUpload::Lettings::Validator
  COLUMN_PERCENTAGE_ERROR_THRESHOLD = 0.6
  COLUMN_ABSOLUTE_ERROR_THRESHOLD = 16

  include ActiveModel::Validations

  attr_reader :bulk_upload, :path

  validate :validate_file_not_empty
  validate :validate_field_numbers_count
  validate :validate_max_columns_count_if_no_headers

  def initialize(bulk_upload:, path:)
    @bulk_upload = bulk_upload
    @path = path
  end

  def call
    row_parsers.each_with_index do |row_parser, index|
      row_parser.valid?

      row = index + row_offset + 1

      row_parser.errors.each do |error|
        col = csv_parser.column_for_field(error.attribute.to_s)

        bulk_upload.bulk_upload_errors.create!(
          field: error.attribute,
          error: error.message,
          tenant_code: row_parser.tenant_code,
          property_ref: row_parser.property_ref,
          row:,
          cell: "#{col}#{row}",
          col:,
          category: error.options[:category],
        )
      end
    end
  end

  def create_logs?
    return false if any_setup_errors?
    return false if row_parsers.any?(&:block_log_creation?)

    row_parsers.all? { |row_parser| row_parser.log.valid? }
  end

  def self.question_for_field(field)
    QUESTIONS[field]
  end

  def any_setup_errors?
    bulk_upload
      .bulk_upload_errors
      .where(category: "setup")
      .count
      .positive?
  end

private

  def over_column_error_threshold?
    fields = ("field_1".."field_134").to_a
    percentage_threshold = (row_parsers.size * COLUMN_PERCENTAGE_ERROR_THRESHOLD).ceil

    fields.any? do |field|
      count = row_parsers.count { |row_parser| row_parser.errors[field].present? }

      next if count < COLUMN_ABSOLUTE_ERROR_THRESHOLD

      count > percentage_threshold
    end
  end

  def csv_parser
    @csv_parser ||= case bulk_upload.year
                    when 2022
                      BulkUpload::Lettings::Year2022::CsvParser.new(path:)
                    when 2023
                      BulkUpload::Lettings::Year2023::CsvParser.new(path:)
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

  def field_number_for_attribute(attribute)
    attribute.to_s.split("_").last.to_i
  end

  def cols
    csv_parser.cols
  end

  def row_parsers
    return @row_parsers if @row_parsers

    @row_parsers = csv_parser.row_parsers

    @row_parsers.each do |row_parser|
      row_parser.bulk_upload = bulk_upload
    end

    @row_parsers
  end

  def rows
    csv_parser.rows
  end

  def body_rows
    csv_parser.body_rows
  end

  def validate_file_not_empty
    if File.size(path).zero?
      errors.add(:file, :blank)

      halt_validations!
    end
  end

  def validate_field_numbers_count
    return if halt_validations?

    errors.add(:base, :wrong_field_numbers_count) if csv_parser.valid_field_numbers_count != csv_parser.class::FIELDS
  end

  def validate_max_columns_count_if_no_headers
    return if halt_validations? || csv_parser.with_headers?

    max_columns_count = body_rows.map(&:size).max - col_offset

    errors.add(:base, :over_max_column_count) if max_columns_count > csv_parser.class::MAX_COLUMNS
  end

  def halt_validations!
    @halt_validations = true
  end

  def halt_validations?
    @halt_validations ||= false
  end
end
