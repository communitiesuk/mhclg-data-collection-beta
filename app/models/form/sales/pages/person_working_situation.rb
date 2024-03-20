class Form::Sales::Pages::PersonWorkingSituation < Form::Sales::Pages::Person
  def initialize(id, hsh, subsection, person_index:)
    super
    @depends_on = [
      {
        "details_known_#{person_index}" => 1,
        "age#{person_index}" => {
          "operator" => ">",
          "operand" => 15,
        },
      },
      { "details_known_#{person_index}" => 1, "age#{person_index}" => nil },
    ]
  end

  def questions
    @questions ||= [
      Form::Sales::Questions::PersonWorkingSituation.new("ecstat#{@person_index}", nil, self, person_index: @person_index),
    ]
  end
end
