class BulkUpload::Lettings::Validator
  include ActiveModel::Validations

  attr_reader :bulk_upload, :path

  validate :validate_file_not_empty
  validate :validate_field_numbers_count
  validate :validate_max_columns_count_if_no_headers
  validate :validate_correct_template
  validate :validate_missing_required_headers

  def initialize(bulk_upload:, path:)
    @bulk_upload = bulk_upload
    @path = path
  end

  def call
    row_parsers.each(&:valid?)

    validate_duplicate_rows if FeatureToggle.bulk_upload_duplicate_log_check_enabled?

    row_parsers.each_with_index do |row_parser, index|
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
    return false if any_logs_already_exist? && FeatureToggle.bulk_upload_duplicate_log_check_enabled?

    row_parsers.each do |row_parser|
      row_parser.log.blank_invalid_non_setup_fields!
    end

    return false if any_logs_invalid?

    true
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

  def soft_validation_errors_only?
    errors = bulk_upload.bulk_upload_errors
    errors.count == errors.where(category: "soft_validation").count && errors.count.positive?
  end

  def any_logs_already_exist?
    row_parsers.any?(&:log_already_exists?)
  end

  def total_logs_count
    csv_parser.body_rows.count
  end

private

  # n^2 algo
  def validate_duplicate_rows
    row_parsers.each do |rp|
      dupe = row_parsers.reject { |r| r.object_id.equal?(rp.object_id) }.any? do |rp_counter|
        rp.spreadsheet_duplicate_hash == rp_counter.spreadsheet_duplicate_hash
      end

      if dupe
        rp.add_duplicate_found_in_spreadsheet_errors
      end
    end
  end

  def any_logs_invalid?
    row_parsers.any? { |row_parser| row_parser.log.invalid? }
  end

  def csv_parser
    @csv_parser ||= case bulk_upload.year
                    when 2023
                      BulkUpload::Lettings::Year2023::CsvParser.new(path:)
                    when 2024
                      BulkUpload::Lettings::Year2024::CsvParser.new(path:)
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
    if File.size(path).zero? || csv_parser.body_rows.flatten.compact.empty?
      errors.add(:base, :blank_file)

      halt_validations!
    end
  end

  def validate_field_numbers_count
    return if halt_validations?

    unless csv_parser.correct_field_count?
      errors.add(:base, :wrong_field_numbers_count)
      halt_validations!
    end
  end

  def validate_max_columns_count_if_no_headers
    return if halt_validations?

    if csv_parser.too_many_columns?
      errors.add(:base, :over_max_column_count)
      halt_validations!
    end
  end

  def validate_correct_template
    return if halt_validations?

    errors.add(:base, :wrong_template) if csv_parser.wrong_template_for_year?
  end

  def validate_missing_required_headers
    return if halt_validations?

    errors.add :base, I18n.t("bulk_upload.lettings.validator.attributes.base.no_headers", guidance_link: Forms::BulkUploadLettings::Guidance.new(year: bulk_upload.year).view_path) if csv_parser.missing_required_headers?
  end

  def halt_validations!
    @halt_validations = true
  end

  def halt_validations?
    @halt_validations ||= false
  end
end
