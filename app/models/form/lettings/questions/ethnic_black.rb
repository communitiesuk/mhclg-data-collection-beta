class Form::Lettings::Questions::EthnicBlack < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "ethnic"
    @copy_key = "lettings.household_characteristics.ethnic.ethnic_background_black"
    @type = "radio"
    @check_answers_card_number = 1
    @answer_options = ANSWER_OPTIONS
    @question_number = QUESTION_NUMBER_FROM_YEAR[form.start_date.year] || QUESTION_NUMBER_FROM_YEAR[QUESTION_NUMBER_FROM_YEAR.keys.max]
  end

  ANSWER_OPTIONS = {
    "13" => {
      "value" => "African",
    },
    "12" => {
      "value" => "Caribbean",
    },
    "14" => {
      "value" => "Any other Black, African, Caribbean or Black British background",
    },
  }.freeze

  QUESTION_NUMBER_FROM_YEAR = { 2023 => 35, 2024 => 34 }.freeze
end
