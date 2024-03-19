class Form::Sales::Pages::PartnerUnder16ValueCheck < Form::Sales::Pages::Person
  def initialize(id, hsh, subsection, person_index:)
    super
    @depends_on = [
      {
        "person_#{person_index}_partner_under_16?" => true,
      },
    ]
    @person_index = person_index
    @title_text = {
      "translation" => "soft_validations.partner_under_16_sales.title",
      "arguments" => [
        {
          "key" => "age#{person_index}",
          "label" => true,
          "i18n_template" => "age",
        },
      ],
    }
    @informative_text = {}
  end

  def questions
    @questions ||= [
      Form::Sales::Questions::PartnerUnder16ValueCheck.new(nil, nil, self, person_index: @person_index),
    ]
  end

  def interruption_screen_question_ids
    ["age#{@person_index}", "relat#{@person_index}"]
  end
end
