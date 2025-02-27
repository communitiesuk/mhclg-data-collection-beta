class Form::Lettings::Questions::ReferralGeneralNeeds < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "referral"
    @copy_key = "lettings.household_situation.referral.general_needs.prp"
    @type = "radio"
    @check_answers_card_number = 0
    @question_number = QUESTION_NUMBER_FROM_YEAR[form.start_date.year] || QUESTION_NUMBER_FROM_YEAR[QUESTION_NUMBER_FROM_YEAR.keys.max]
  end

  def answer_options
    if form.start_year_2024_or_later?
      {
        "1" => {
          "value" => "Internal transfer",
          "hint" => "Where the tenant has moved to another social property owned by the same landlord.",
        },
        "2" => {
          "value" => "Tenant applied directly (no referral or nomination)",
        },
        "3" => {
          "value" => "Nominated by a local housing authority",
        },
        "8" => {
          "value" => "Re-located through official housing mobility scheme",
        },
        "10" => {
          "value" => "Other social landlord",
        },
        "9" => {
          "value" => "Community learning disability team",
        },
        "14" => {
          "value" => "Community mental health team",
        },
        "15" => {
          "value" => "Health service",
        },
        "18" => {
          "value" => "Police, probation, prison or youth offending team – tenant had custodial sentence",
        },
        "19" => {
          "value" => "Police, probation, prison or youth offending team – no custodial sentence",
        },
        "7" => {
          "value" => "Voluntary agency",
        },
        "17" => {
          "value" => "Children’s Social Care",
        },
        "16" => {
          "value" => "Other",
        },
      }.freeze
    else
      {
        "1" => {
          "value" => "Internal transfer",
          "hint" => "Where the tenant has moved to another social property owned by the same landlord.",
        },
        "2" => {
          "value" => "Tenant applied directly (no referral or nomination)",
        },
        "3" => {
          "value" => "Nominated by a local housing authority",
        },
        "4" => {
          "value" => "Referred by local authority housing department",
        },
        "8" => {
          "value" => "Re-located through official housing mobility scheme",
        },
        "10" => {
          "value" => "Other social landlord",
        },
        "9" => {
          "value" => "Community learning disability team",
        },
        "14" => {
          "value" => "Community mental health team",
        },
        "15" => {
          "value" => "Health service",
        },
        "12" => {
          "value" => "Police, probation or prison",
        },
        "7" => {
          "value" => "Voluntary agency",
        },
        "13" => {
          "value" => "Youth offending team",
        },
        "17" => {
          "value" => "Children’s Social Care",
        },
        "16" => {
          "value" => "Other",
        },
      }.freeze
    end
  end

  QUESTION_NUMBER_FROM_YEAR = { 2023 => 85, 2024 => 84 }.freeze
end
