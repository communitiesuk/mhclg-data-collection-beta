class Form::Lettings::Questions::Age < ::Form::Question
  def initialize(id, hsh, page, person_index:, is_child:)
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
    @hint_text = "For a child under 1, enter 1" if is_child
  end
end
