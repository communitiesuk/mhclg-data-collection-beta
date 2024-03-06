class Form::Sales::Questions::PropertyLocalAuthorityKnown < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "la_known"
    @check_answer_label = "Local authority known"
    @header = "Do you know the property’s local authority?"
    @type = "radio"
    @answer_options = ANSWER_OPTIONS
    @conditional_for = { "la" => [1] }
    @hidden_in_check_answers = {
      "depends_on" => [
        {
          "la_known" => 1,
        },
      ],
    }
    @question_number = QUESION_NUMBER_FROM_YEAR[form.start_date.year]
  end

  ANSWER_OPTIONS = {
    "1" => { "value" => "Yes" },
    "0" => { "value" => "No" },
  }.freeze

  QUESION_NUMBER_FROM_YEAR = { 2023 => 16, 2024 => 20 }.freeze
end
