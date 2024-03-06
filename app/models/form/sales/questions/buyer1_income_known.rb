class Form::Sales::Questions::Buyer1IncomeKnown < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "income1nk"
    @check_answer_label = "Buyer 1’s gross annual income known?"
    @header = "Do you know buyer 1’s annual income?"
    @type = "radio"
    @answer_options = ANSWER_OPTIONS
    @conditional_for = {
      "income1" => [0],
    }
    @check_answers_card_number = 1
    @question_number = QUESION_NUMBER_FROM_YEAR[form.start_date.year]
    @hidden_in_check_answers = {
      "depends_on" => [
        {
          "income1nk" => 0,
        },
      ],
    }
  end

  ANSWER_OPTIONS = {
    "0" => { "value" => "Yes" },
    "1" => { "value" => "No" },
  }.freeze

  QUESION_NUMBER_FROM_YEAR = { 2023 => 67, 2024 => 69 }.freeze
end
