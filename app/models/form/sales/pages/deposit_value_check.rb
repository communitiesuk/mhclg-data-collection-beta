class Form::Sales::Pages::DepositValueCheck < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @depends_on = [
      {
        "deposit_over_soft_max?" => true,
      },
    ]
    @informative_text = {}
    @title_text = {
      "translation" => "soft_validations.deposit.title_text",
    }
  end

  def questions
    @questions ||= [
      Form::Sales::Questions::DepositValueCheck.new(nil, nil, self),
    ]
  end

  def affected_question_ids
    %w[savings deposit]
  end
end
