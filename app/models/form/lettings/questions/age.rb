class Form::Lettings::Questions::Age < ::Form::Question
  def initialize(id, hsh, page, person_index:, person_type:)
    super(id, hsh, page)
    @id = "age#{person_index}"
    @check_answer_label = "Person #{person_index}’s age"
    @header = "Age"
    @type = "numeric"
    @width = 2
    @inferred_check_answers_value = [{ "condition" => { "age#{person_index}_known" => 1 }, "value" => "Not known" }]
    @check_answers_card_number = person_index
    @max = 120
    @min = 1
    @step = 1
    @hint_text = "For a child under 1, enter 1" if person_type == "child"
    @person_index = person_index
  end

  def question_number
    base_question_number = case form.start_date.year
                           when 2023
                             31
                           else
                             30
                           end

    base_question_number + (4 * @person_index)
  end
end
