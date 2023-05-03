class Form::Sales::Pages::BuyerLiveInValueCheck < Form::Sales::Pages::Person
  def initialize(id, hsh, subsection, person_index:)
    super
    @depends_on = [
      {
        "buyer#{person_index}_livein_wrong_for_ownership_type?" => true,
      },
    ]
    @title_text = {
      "translation" => "soft_validations.buyer#{person_index}_livein_wrong_for_ownership_type.title_text",
      "arguments" => [{ "key" => "ownership_scheme", "label" => false, "i18n_template" => "ownership_scheme" }],
    }
    @informative_text = {}
  end

  def questions
    @questions ||= [
      Form::Sales::Questions::BuyerLiveInValueCheck.new(nil, nil, self, person_index: @person_index),
    ]
  end

  def affected_question_ids
    ["ownershipsch", "buy#{@person_index}livein"]
  end
end
