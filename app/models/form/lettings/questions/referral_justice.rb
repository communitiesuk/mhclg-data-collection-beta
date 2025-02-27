class Form::Lettings::Questions::ReferralJustice < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "referral"
    @copy_key = "lettings.household_situation.referral.justice"
    @type = "radio"
    @check_answers_card_number = 0
    @question_number = QUESTION_NUMBER_FROM_YEAR[form.start_date.year] || QUESTION_NUMBER_FROM_YEAR[QUESTION_NUMBER_FROM_YEAR.keys.max]
  end

  def answer_options
    {
      "18" => {
        "value" => "With a custodial sentence",
      },
      "19" => {
        "value" => "No custodial sentence",
      },
    }.freeze
  end

  QUESTION_NUMBER_FROM_YEAR = { 2025 => 84 }.freeze
end
