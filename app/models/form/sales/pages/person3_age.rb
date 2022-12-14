class Form::Sales::Pages::Person3Age < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "person_3_age"
    @header = ""
    @description = ""
    @subsection = subsection
    @depends_on = [
      { "details_known_3" => 1, "jointpur" => 2 },
    ]
  end

  def questions
    @questions ||= [
      Form::Sales::Questions::Person3AgeKnown.new("age4_known", { check_answers_card_number: 4,
                                                                  conditional_for: {
                                                                    "age4" => [0],
                                                                  },
                                                                  hidden_in_check_answers: {
                                                                    "depends_on" => [
                                                                      {
                                                                        "age4_known" => 0,
                                                                      },
                                                                      {
                                                                        "age4_known" => 1,
                                                                      },
                                                                    ],
                                                                  } }, self),
      Form::Sales::Questions::Person3Age.new("age4", { check_answers_card_number: 4,
                                                       hidden_in_check_answers: { "depends_on" => [{ "jointpur" => 1 }] },
                                                       inferred_check_answers_value: { "condition" => { "age4_known" => 1 }, "value" => "Not known" } }, self),
    ]
  end
end
