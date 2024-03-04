class Form::Lettings::Questions::EthnicArab < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "ethnic"
    @check_answer_label = "Lead tenant’s ethnic background"
    @header = "Which of the following best describes the lead tenant’s Arab background?"
    @type = "radio"
    @check_answers_card_number = 1
    @hint_text = "The lead tenant is the person in the household who does the most paid work. If several people do the same paid work, the lead tenant is whoever is the oldest."
    @answer_options = ANSWER_OPTIONS
    @question_number = QUESTION_NUMBER_FROM_YEAR.fetch(form.start_date.year, QUESTION_NUMBER_FROM_YEAR.max_by { |k, _v| k }.last)
  end

  ANSWER_OPTIONS = {
    "19" => {
      "value" => "Arab",
    },
    "16" => {
      "value" => "Other ethnic group",
    },
  }.freeze

  QUESTION_NUMBER_FROM_YEAR = { 2023 => 35, 2024 => 34 }.freeze
end
