class Form::Sales::Questions::Buyer2Nationality < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "nationalbuy2"
    @check_answer_label = "Buyer 2’s nationality"
    @header = "What is buyer 2’s nationality?"
    @type = "radio"
    @answer_options = ANSWER_OPTIONS
    @check_answers_card_number = 2
    @question_number = QUESION_NUMBER_FROM_YEAR.fetch(form.start_date.year, QUESION_NUMBER_FROM_YEAR.max_by { |k, _v| k }.last)
    @inferred_check_answers_value = [{
      "condition" => {
        "national" => 13,
      },
      "value" => "Prefers not to say",
    }]
  end

  ANSWER_OPTIONS = {
    "18" => { "value" => "United Kingdom" },
    "17" => { "value" => "Republic of Ireland" },
    "19" => { "value" => "European Economic Area (EEA), excluding ROI" },
    "12" => { "value" => "Other" },
    "13" => { "value" => "Buyer prefers not to say" },
  }.freeze

  QUESION_NUMBER_FROM_YEAR = { 2023 => 32, 2024 => 34 }.freeze
end
