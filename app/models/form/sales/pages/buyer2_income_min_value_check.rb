class Form::Sales::Pages::Buyer2IncomeMinValueCheck < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @depends_on = [
      {
        "income2_under_soft_min?" => true,
      },
    ]
    @title_text = {
      "translation" => "soft_validations.income.under_soft_min_for_economic_status.title_text",
      "arguments" => [
        {
          "key" => "field_formatted_as_currency",
          "arguments_for_key" => "income2",
          "i18n_template" => "income",
        },
        {
          "key" => "income_soft_min_for_ecstat",
          "arguments_for_key" => "ecstat2",
          "i18n_template" => "minimum",
        },
      ],
    }
    @informative_text = {
      "translation" => "soft_validations.income.under_soft_min_for_economic_status.hint_text",
      "arguments" => [],
    }
  end

  def questions
    @questions ||= [
      Form::Sales::Questions::Buyer2IncomeValueCheck.new(nil, nil, self, check_answers_card_number: 2),
    ]
  end

  def interruption_screen_question_ids
    %w[ecstat2 income2]
  end
end
