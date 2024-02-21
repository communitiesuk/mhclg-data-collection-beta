class Form::Sales::Questions::Buyer1AgeKnown < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "age1_known"
    @check_answer_label = "Buyer 1’s age"
    @header = "Do you know buyer 1’s age?"
    @type = "radio"
    @answer_options = ANSWER_OPTIONS
    @hint_text = "Buyer 1 is the person in the household who does the most paid work. If it’s a joint purchase and the buyers do the same amount of paid work, buyer 1 is whoever is the oldest."
    @conditional_for = {
      "age1" => [0],
    }
    @hidden_in_check_answers = {
      "depends_on" => [
        {
          "age1_known" => 0,
        },
        {
          "age1_known" => 1,
        },
        {
          "age1_known" => 2,
        },
      ],
    }
    @check_answers_card_number = 1
    @question_number = QUESION_NUMBER_FROM_YEAR.fetch(form.start_date.year, QUESION_NUMBER_FROM_YEAR.max_by { |k, _v| k }.last)
  end

  ANSWER_OPTIONS = {
    "0" => { "value" => "Yes" },
    "1" => { "value" => "No" },
    "2" => { "value" => "Buyer prefers not to say" },
  }.freeze

  QUESION_NUMBER_FROM_YEAR = { 2023 => 20, 2024 => 22 }.freeze
end
