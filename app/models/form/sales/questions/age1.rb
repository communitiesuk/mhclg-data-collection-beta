class Form::Sales::Questions::Age1 < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "age1"
    @check_answer_label = "Buyer 1’s age"
    @header = "Age"
    @type = "numeric"
    @width = 2
    @inferred_check_answers_value = [
      {
        "condition" => { "age1_known" => 1 },
        "value" => "Not known",
      },
      {
        "condition" => { "age1_known" => 2 },
        "value" => "Prefers not to say",
      },
    ]
    @check_answers_card_number = 1
    @min = 16
    @max = 110
    @step = 1
    @question_number = QUESION_NUMBER_FROM_YEAR[form.start_date.year]
  end

  QUESION_NUMBER_FROM_YEAR = { 2023 => 20, 2024 => 22 }.freeze
end
