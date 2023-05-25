class BulkUpload::Sales::Validator
  include ActiveModel::Validations

  attr_reader :bulk_upload, :path

  validate :validate_file_not_empty
  validate :validate_max_columns
  validate :validate_correct_template

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
          purchaser_code: row_parser.purchaser_code,
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
    return false if any_logs_already_exist? && FeatureToggle.bulk_upload_duplicate_log_check_enabled?

    row_parsers.each do |row_parser|
      row_parser.log.blank_invalid_non_setup_fields!
    end

    return false if any_logs_invalid?

    true
  end

  def any_setup_errors?
    bulk_upload
      .bulk_upload_errors
      .where(category: "setup")
      .count
      .positive?
  end

  def any_logs_already_exist?
    row_parsers.any?(&:log_already_exists?)
  end

  def soft_validation_errors_only?
    errors = bulk_upload.bulk_upload_errors
    errors.count == errors.where(category: "soft_validation").count && errors.count.positive?
  end

private

  def any_logs_invalid?
    row_parsers.any? { |row_parser| row_parser.log.invalid? }
  end

  def csv_parser
    @csv_parser ||= case bulk_upload.year
                    when 2022
                      BulkUpload::Sales::Year2022::CsvParser.new(path:)
                    when 2023
                      BulkUpload::Sales::Year2023::CsvParser.new(path:)
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

  def validate_max_columns
    return if halt_validations?

    column_count = rows.map(&:size).max

    errors.add(:base, :over_max_column_count) if column_count > csv_parser.class::MAX_COLUMNS
  end

  def validate_correct_template
    return if halt_validations?

    errors.add(:base, :wrong_template) if csv_parser.wrong_template_for_year?
  end

  def halt_validations!
    @halt_validations = true
  end

  def halt_validations?
    @halt_validations ||= false
  end
end
