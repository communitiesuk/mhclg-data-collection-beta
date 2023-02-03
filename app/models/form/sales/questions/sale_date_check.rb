class Form::Sales::Questions::SaleDateCheck < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "hodate_check"
    @check_answer_label = "Completion date check"
    @header = "Are you sure?"
    @type = "interruption_screen"
    @answer_options = {
      "0" => { "value" => "Yes" },
      "1" => { "value" => "No" },
    }
    @hidden_in_check_answers = {
      "depends_on" => [
        {
          "hodate_check" => 0,
        },
        {
          "hodate_check" => 1,
        },
      ],
    }
  end
end
