class Form::Lettings::Questions::ReferralType < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "referral_type"
    @copy_key = "lettings.household_situation.referral.type"
    @type = "radio"
    @check_answers_card_number = 0
    @question_number = QUESTION_NUMBER_FROM_YEAR[form.start_date.year] || QUESTION_NUMBER_FROM_YEAR[QUESTION_NUMBER_FROM_YEAR.keys.max]
  end

  def answer_options
    {
      "101" => {
        "value" => "Direct",
      },
      "102" => {
        "value" => "From a local authority housing register or waiting list",
      },
      "103" => {
        "value" => "From a PRP-only housing register or waiting list (no local authority involvement)",
      },
      "104" => {
        "value" => "Health and social care services",
      },
      "105" => {
        "value" => "Police, probation, prison or youth offending team",
      },
      "7" => {
        "value" => "Voluntary agency",
      },
      "16" => {
        "value" => "Other",
      },
    }.freeze
  end

  QUESTION_NUMBER_FROM_YEAR = { 2025 => 84 }.freeze
end
