class Form::Sales::Questions::GenderIdentity2 < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "sex2"
    @check_answer_label = "Buyer 2’s gender identity"
    @header = "Which of these best describes buyer 2’s gender identity?"
    @type = "radio"
    @answer_options = ANSWER_OPTIONS
    @check_answers_card_number = 2
    @inferred_check_answers_value = [{
      "condition" => {
        "sex2" => "R",
      },
      "value" => "Prefers not to say",
    }]
    @question_number = 29
  end

  ANSWER_OPTIONS = {
    "F" => { "value" => "Female" },
    "M" => { "value" => "Male" },
    "X" => { "value" => "Non-binary" },
    "R" => { "value" => "Buyer prefers not to say" },
  }.freeze

  def hint_text
    if form.start_year_after_2024?
      "This should be however they personally choose to identify from the options below. This may or may not be the same as their biological sex or the sex they were assigned at birth."
    end
  end
end
