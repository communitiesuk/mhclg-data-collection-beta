class Form::Sales::Questions::PersonAge < ::Form::Question
  def initialize(id, hsh, page, person_index:)
    super(id, hsh, page)
    @check_answer_label = "Person #{person_index}’s age"
    @header = "Age"
    @type = "numeric"
    @width = 3
    @inferred_check_answers_value = [{
      "condition" => { "age#{person_index}_known" => 1 },
      "value" => "Not known",
    }]
    @check_answers_card_number = person_index
    @min = 0
    @max = 110
    @step = 1
    @person_index = person_index
  end

  def question_number
    case form.start_date.year
    when 2023
      29 + (4 * @person_index)
    else
      31 + (4 * @person_index)
    end
  end
end
