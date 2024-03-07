class Form::Sales::Questions::PersonRelationshipToBuyer1 < ::Form::Question
  def initialize(id, hsh, page, person_index:)
    super(id, hsh, page)
    @check_answer_label = "Person #{person_index}’s relationship to Buyer 1"
    @header = "What is Person #{person_index}’s relationship to Buyer 1?"
    @type = "radio"
    @answer_options = ANSWER_OPTIONS
    @check_answers_card_number = person_index
    @inferred_check_answers_value = [{
      "condition" => {
        id => "R",
      },
      "value" => "Prefers not to say",
    }]
    @person_index = person_index
    @question_number = question_number
  end

  ANSWER_OPTIONS = {
    "P" => { "value" => "Partner" },
    "C" => { "value" => "Child", "hint" => "Must be eligible for child benefit, aged under 16 or under 20 if still in full-time education." },
    "X" => { "value" => "Other" },
    "R" => { "value" => "Person prefers not to say" },
  }.freeze

  def question_number
    base_question_number = case form.start_date.year
                           when 2023
                             28
                           else
                             30
                           end

    base_question_number + (4 * @person_index)
  end
end
