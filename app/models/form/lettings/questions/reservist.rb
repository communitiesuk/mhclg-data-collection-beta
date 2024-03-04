class Form::Lettings::Questions::Reservist < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "reservist"
    @check_answer_label = "Person seriously injured or ill as result of serving in UK armed forces"
    @header = "Was the person seriously injured or ill as a result of serving in the UK armed forces?"
    @type = "radio"
    @check_answers_card_number = 0
    @hint_text = ""
    @answer_options = ANSWER_OPTIONS
    @question_number = QUESTION_NUMBER_FROM_YEAR.fetch(form.start_date.year, QUESTION_NUMBER_FROM_YEAR.max_by { |k, _v| k }.last)
  end

  ANSWER_OPTIONS = {
    "1" => { "value" => "Yes" },
    "2" => { "value" => "No" },
    "divider" => { "value" => true },
    "3" => { "value" => "Person prefers not to say" },
  }.freeze

  QUESTION_NUMBER_FROM_YEAR = { 2023 => 68, 2024 => 67 }.freeze
end
