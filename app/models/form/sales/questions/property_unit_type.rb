class Form::Sales::Questions::PropertyUnitType < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "proptype"
    @check_answer_label = "Type of unit"
    @header = "What type of unit is the property?"
    @type = "radio"
    @answer_options = ANSWER_OPTIONS
    @question_number = QUESION_NUMBER_FROM_YEAR[form.start_date.year]
  end

  ANSWER_OPTIONS = {
    "1" => { "value" => "Flat or maisonette" },
    "2" => { "value" => "Bedsit" },
    "3" => { "value" => "House" },
    "4" => { "value" => "Bungalow" },
    "9" => { "value" => "Other" },
  }.freeze

  QUESION_NUMBER_FROM_YEAR = { 2023 => 12, 2024 => 16 }.freeze
end
