class Form::Sales::Questions::Buyer2IncomeKnown < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "income2nk"
    @check_answer_label = "Buyer 2’s gross annual income known?"
    @header = "Do you know buyer 2’s annual income?"
    @type = "radio"
    @answer_options = ANSWER_OPTIONS
    @conditional_for = {
      "income2" => [0],
    }
    @check_answers_card_number = 2
    @question_number = QUESTION_NUMBER_FROM_YEAR.fetch(form.start_date.year, QUESTION_NUMBER_FROM_YEAR.max_by { |k, _v| k }.last)
    @hidden_in_check_answers = {
      "depends_on" => [
        {
          "income2nk" => 0,
        },
      ],
    }
  end

  ANSWER_OPTIONS = {
    "0" => { "value" => "Yes" },
    "1" => { "value" => "No" },
  }.freeze

  QUESTION_NUMBER_FROM_YEAR = { 2023 => 69, 2024 => 71 }.freeze
end
