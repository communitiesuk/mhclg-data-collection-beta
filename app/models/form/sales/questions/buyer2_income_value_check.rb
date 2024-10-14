class Form::Sales::Questions::Buyer2IncomeValueCheck < ::Form::Question
  def initialize(id, hsh, page, check_answers_card_number:)
    super(id, hsh, page)
    @id = "income2_value_check"
    @check_answer_label = "Buyer 2 income confirmation"
    @header = "Are you sure this is correct?"
    @type = "interruption_screen"
    @answer_options = {
      "0" => { "value" => "Yes" },
      "1" => { "value" => "No" },
    }
    @hidden_in_check_answers = {
      "depends_on" => [
        {
          "income2_value_check" => 0,
        },
        {
          "income2_value_check" => 1,
        },
      ],
    }
    @check_answers_card_number = check_answers_card_number
    @page = page
  end
end
