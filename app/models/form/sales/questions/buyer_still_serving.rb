class Form::Sales::Questions::BuyerStillServing < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "hhregresstill"
    @check_answer_label = "Are they still serving in the UK armed forces?"
    @header = "Is the buyer still serving in the UK armed forces?"
    @type = "radio"
    @answer_options = ANSWER_OPTIONS
    @question_number = QUESION_NUMBER_FROM_YEAR[form.start_date.year]
  end

  ANSWER_OPTIONS = {
    "4" => { "value" => "Yes" },
    "5" => { "value" => "No" },
    "6" => { "value" => "Buyer prefers not to say" },
    "7" => { "value" => "Don't know" },
  }.freeze

  QUESION_NUMBER_FROM_YEAR = { 2023 => 63, 2024 => 65 }.freeze
end
