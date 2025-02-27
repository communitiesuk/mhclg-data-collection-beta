class Form::Lettings::Questions::ReferralHsc < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "referral"
    @copy_key = "lettings.household_situation.referral.hsc"
    @type = "radio"
    @check_answers_card_number = 0
    @question_number = QUESTION_NUMBER_FROM_YEAR[form.start_date.year] || QUESTION_NUMBER_FROM_YEAR[QUESTION_NUMBER_FROM_YEAR.keys.max]
  end

  def answer_options
    {
      "15" => {
        "value" => "Health service",
      },
      "9" => {
        "value" => "Community learning disability team",
      },
      "14" => {
        "value" => "Community mental health team",
      },
      "24" => {
        "value" => "Adult social services",
      },
      "17" => {
        "value" => "Children's social care",
      },
    }.freeze
  end

  QUESTION_NUMBER_FROM_YEAR = { 2025 => 84 }.freeze
end
