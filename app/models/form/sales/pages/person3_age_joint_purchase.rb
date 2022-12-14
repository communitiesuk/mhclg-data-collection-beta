class Form::Sales::Pages::Person3AgeJointPurchase < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "person_3_age_joint_purchase"
    @header = ""
    @description = ""
    @subsection = subsection
    @depends_on = [
      { "details_known_3" => 1, "jointpur" => 1 },
    ]
  end

  def questions
    @questions ||= [
      Form::Sales::Questions::Person3AgeKnown.new("age5_known", { check_answers_card_number: 5,
                                                                  conditional_for: {
                                                                    "age5" => [0],
                                                                  },
                                                                  hidden_in_check_answers: {
                                                                    "depends_on" => [
                                                                      {
                                                                        "age5_known" => 0,
                                                                      },
                                                                      {
                                                                        "age5_known" => 1,
                                                                      },
                                                                    ],
                                                                  } }, self),
      Form::Sales::Questions::Person3Age.new("age5", { check_answers_card_number: 5,
                                                       hidden_in_check_answers: { "depends_on" => [{ "jointpur" => 2 }] },
                                                       inferred_check_answers_value: { "condition" => { "age5_known" => 1 }, "value" => "Not known" } }, self),
    ]
  end
end
