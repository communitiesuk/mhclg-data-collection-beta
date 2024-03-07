class Form::Lettings::Questions::UnittypeGn < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "unittype_gn"
    @check_answer_label = "Type of unit"
    @header = "What type of unit is the property?"
    @type = "radio"
    @check_answers_card_number = 0
    @hint_text = ""
    @answer_options = ANSWER_OPTIONS
    @question_number = QUESTION_NUMBER_FROM_YEAR[form.start_date.year] || QUESTION_NUMBER_FROM_YEAR[QUESTION_NUMBER_FROM_YEAR.keys.max]
  end

  ANSWER_OPTIONS = {
    "2" => { "value" => "Bedsit" },
    "8" => { "value" => "Bungalow" },
    "1" => { "value" => "Flat or maisonette" },
    "7" => { "value" => "House" },
    "10" => { "value" => "Shared bungalow" },
    "4" => { "value" => "Shared flat or maisonette" },
    "9" => { "value" => "Shared house" },
    "6" => { "value" => "Other" },
  }.freeze

  QUESTION_NUMBER_FROM_YEAR = { 2023 => 19 }.freeze
end
