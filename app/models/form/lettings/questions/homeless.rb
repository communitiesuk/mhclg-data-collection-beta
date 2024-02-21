class Form::Lettings::Questions::Homeless < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "homeless"
    @check_answer_label = "Household homeless immediately before letting"
    @header = "Did the household experience homelessness immediately before this letting?"
    @type = "radio"
    @check_answers_card_number = 0
    @hint_text = ""
    @answer_options = ANSWER_OPTIONS
    @question_number = QUESION_NUMBER_FROM_YEAR.fetch(form.start_date.year, QUESION_NUMBER_FROM_YEAR.max_by { |k, _v| k }.last)
  end

  ANSWER_OPTIONS = {
    "11" => { "value" => "Yes - assessed by a local authority as homeless" },
    "1" => { "value" => "No" },
  }.freeze

  QUESION_NUMBER_FROM_YEAR = { 2023 => 79, 2024 => 78 }.freeze
end
