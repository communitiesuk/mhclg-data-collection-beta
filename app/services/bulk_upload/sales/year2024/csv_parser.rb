require "csv"

class BulkUpload::Sales::Year2024::CsvParser
  include CollectionTimeHelper

  MAX_COLUMNS = 142
  FORM_YEAR = 2024

  attr_reader :path

  def initialize(path:)
    @path = path
  end

  def row_offset
    if with_headers?
      rows.find_index { |row| row[0].match(/field number/i) } + 1
    else
      0
    end
  end

  def col_offset
    with_headers? ? 1 : 0
  end

  def cols
    @cols ||= ("A".."EK").to_a
  end

  def row_parsers
    @row_parsers ||= body_rows.map do |row|
      stripped_row = row[col_offset..]
      hash = Hash[field_numbers.zip(stripped_row)]

      BulkUpload::Sales::Year2024::RowParser.new(hash)
    end
  end

  def body_rows
    rows[row_offset..]
  end

  def rows
    @rows ||= CSV.parse(normalised_string, row_sep:)
  end

  def column_for_field(field)
    cols[field_numbers.find_index(field) + col_offset]
  end

  def wrong_template_for_year?
    collection_start_year_for_date(first_record_start_date) != FORM_YEAR
  rescue Date::Error
    false
  end

private

  def default_field_numbers
    (1..131).map do |number|
      if number.to_s.match?(/^[0-9]+$/)
        "field_#{number}"
      else
        "field_blank"
      end
    end
  end

  def field_numbers
    @field_numbers ||= if with_headers?
                         rows[row_offset - 1][col_offset..].map { |number| number.to_s.match?(/^[0-9]+$/) ? "field_#{number}" : "field_blank" }
                       else
                         default_field_numbers
                       end
  end

  def headers
    @headers ||= ("field_1".."field_135").to_a
  end

  def with_headers?
    # we will eventually want to validate that headers exist for this year
    rows.map { |r| r[0] }.any? { |cell| cell&.match?(/field number/i) }
  end

  def row_sep
    "\n"
  end

  def normalised_string
    return @normalised_string if @normalised_string

    @normalised_string = File.read(path, encoding: "bom|utf-8")
    @normalised_string.gsub!("\r\n", "\n")
    @normalised_string.scrub!("")
    @normalised_string.tr!("\r", "\n")

    @normalised_string
  end

  def first_record_start_date
    if with_headers?
      Date.new(row_parsers.first.field_6.to_i + 2000, row_parsers.first.field_5.to_i, row_parsers.first.field_4.to_i)
    else
      Date.new(rows.first[5].to_i + 2000, rows.first[4].to_i, rows.first[3].to_i)
    end
  end
end
