class Form::Sales::Questions::SavingsNk < ::Form::Question
  def initialize(id, hsh, page, joint_purchase:)
    super(id, hsh, page)
    @id = "savingsnk"
    @check_answer_label = "#{joint_purchase ? 'Buyers’' : 'Buyer’s'} total savings known?"
    @header = "Do you know how much the #{joint_purchase ? 'buyers' : 'buyer'} had in savings before they paid any deposit for the property?"
    @type = "radio"
    @answer_options = ANSWER_OPTIONS
    @conditional_for = {
      "savings" => [0],
    }
    @hidden_in_check_answers = {
      "depends_on" => [
        {
          "savingsnk" => 0,
        },
      ],
    }
    @question_number = 72
  end

  ANSWER_OPTIONS = {
    "0" => { "value" => "Yes" },
    "1" => { "value" => "No" },
  }.freeze
end
