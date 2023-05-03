class Form::Sales::Pages::PersonStudentNotChildValueCheck < Form::Sales::Pages::Person
  def initialize(id, hsh, subsection, person_index:)
    super
    @depends_on = [
      {
        "person_#{person_index}_student_not_child?" => true,
      },
    ]
    @person_index = person_index
    @title_text = {
      "translation" => "soft_validations.student_not_child.title_text",
    }
    @informative_text = {}
  end

  def questions
    @questions ||= [
      Form::Sales::Questions::PersonStudentNotChildValueCheck.new(nil, nil, self, person_index: @person_index),
    ]
  end

  def interruption_screen_question_ids
    ["relat#{@person_index}", "exstat#{@person_index}", "age#{@person_index}"]
  end
end
