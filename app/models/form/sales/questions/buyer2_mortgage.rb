class Form::Sales::Questions::Buyer2Mortgage < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "inc2mort"
    @check_answer_label = "Buyer 2's income used for mortgage application"
    @header = "Q70 - Was buyer 2's income used for a mortgage application?"
    @type = "radio"
    @answer_options = ANSWER_OPTIONS
    @check_answers_card_number = 2
  end

  ANSWER_OPTIONS = {
    "1" => { "value" => "Yes" },
    "2" => { "value" => "No" },
  }.freeze
end
