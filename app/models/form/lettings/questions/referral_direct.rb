class Form::Lettings::Questions::ReferralDirect < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "referral"
    @copy_key = "lettings.household_situation.referral.direct"
    @type = "radio"
    @check_answers_card_number = 0
    @question_number = QUESTION_NUMBER_FROM_YEAR[form.start_date.year] || QUESTION_NUMBER_FROM_YEAR[QUESTION_NUMBER_FROM_YEAR.keys.max]
  end

  def answer_options
    {
      "20" => {
        "value" => "Homeless households owed a duty and not on a housing register or waiting list",
      },
      "2" => {
        "value" => "Tenant applied directly for an available property",
      },
      "8" => {
        "value" => "Relocated through official housing mobility scheme",
      },
    }.freeze
  end

  QUESTION_NUMBER_FROM_YEAR = { 2025 => 84 }.freeze
end
