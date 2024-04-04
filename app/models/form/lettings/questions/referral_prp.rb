class Form::Lettings::Questions::ReferralPrp < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "referral"
    @check_answer_label = "Source of referral for letting"
    @header = "What was the source of referral for this letting?"
    @type = "radio"
    @check_answers_card_number = 0
    @hint_text = "You told us that the needs type is general needs. We have removed some options because of this."
    @question_number = QUESTION_NUMBER_FROM_YEAR[form.start_date.year] || QUESTION_NUMBER_FROM_YEAR[QUESTION_NUMBER_FROM_YEAR.keys.max]
  end

  def answer_options
    if form.start_year_after_2024?
      {
        "1" => {
          "value" => "Internal transfer",
          "hint" => "Where the tenant has moved to another social property owned by the same landlord.",
        },
        "2" => {
          "value" => "Tenant applied directly (no nomination)",
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
          "value" => "Tenant applied directly (no nomination)",
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
