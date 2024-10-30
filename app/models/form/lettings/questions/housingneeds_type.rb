class Form::Lettings::Questions::HousingneedsType < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "housingneeds_type"
    @copy_key = "lettings.household_needs.housingneeds_type.housingneeds_type"
    @type = "radio"
    @check_answers_card_number = 0
    @answer_options = ANSWER_OPTIONS
    @question_number = QUESTION_NUMBER_FROM_YEAR[form.start_date.year] || QUESTION_NUMBER_FROM_YEAR[QUESTION_NUMBER_FROM_YEAR.keys.max]
  end

  ANSWER_OPTIONS = {
    "0" => { "value" => "Fully wheelchair accessible housing" },
    "1" => { "value" => "Wheelchair access to essential rooms" },
    "2" => { "value" => "Level access housing" },
    "divider" => { "value" => true },
    "3" => { "value" => "None of the listed options" },
  }.freeze

  QUESTION_NUMBER_FROM_YEAR = { 2023 => 71, 2024 => 70 }.freeze
end
