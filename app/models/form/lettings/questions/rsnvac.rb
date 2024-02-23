class Form::Lettings::Questions::Rsnvac < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "rsnvac"
    @check_answer_label = "Vacancy reason"
    @header = "What is the reason for the property being vacant?"
    @type = "radio"
    @check_answers_card_number = 0
    @hint_text = ""
    @question_number = QUESTION_NUMBER_FROM_YEAR.fetch(form.start_date.year, QUESTION_NUMBER_FROM_YEAR.max_by { |k, _v| k }.last)
  end

  def answer_options
    if form.start_year_after_2024?
      {
        "14" => {
          "value" => "Renewal of fixed-term tenancy",
          "hint" => "To the same tenant in the same property, except if was previously used as temporary accommodation.",
        },
        "9" => {
          "value" => "Re-let to tenant who occupied same property as temporary accommodation",
        },
        "13" => {
          "value" => "Internal transfer",
          "hint" => "Where a tenant moved from one social housing property to another property. Their landlord may be the same or may have changed.",
        },
        "12" => {
          "value" => "Tenant moved to other social housing provider",
        },
        "8" => {
          "value" => "Tenant moved to private sector or other accommodation",
        },
        "18" => {
          "value" => "Tenant moved to care home",
        },
        "20" => {
          "value" => "Tenant moved to long-stay hospital or similar institution",
        },
        "5" => {
          "value" => "Tenant died with no succession",
        },
        "19" => {
          "value" => "Tenant involved in a succession downsize",
        },
        "6" => {
          "value" => "Tenant abandoned property",
        },
        "10" => {
          "value" => "Tenant was evicted due to rent arrears",
        },
        "11" => {
          "value" => "Tenant was evicted due to anti-social behaviour",
        },
        "21" => {
          "value" => "Tenant was evicted due to both rent arrears and anti-social behaviour",
        },
        "22" => {
          "value" => "Any other reason",
        },
      }
    else
      {
        "13" => {
          "value" => "Internal transfer",
          "hint" => "Where a tenant moved from one social housing property to another property. Their landlord may be the same or may have changed.",
        },
        "5" => {
          "value" => "Previous tenant died with no succession",
        },
        "9" => {
          "value" => "Re-let to tenant who occupied same property as temporary accommodation",
        },
        "14" => {
          "value" => "Renewal of fixed-term tenancy",
          "hint" => "To the same tenant in the same property, except if was previously used as temporary accommodation.",
        },
        "19" => {
          "value" => "Tenant involved in a succession downsize",
        },
        "8" => {
          "value" => "Tenant moved to private sector or other accommodation",
        },
        "12" => {
          "value" => "Tenant moved to other social housing provider",
        },
        "18" => {
          "value" => "Tenant moved to care home",
        },
        "20" => {
          "value" => "Tenant moved to long-stay hospital or similar institution",
        },
        "6" => {
          "value" => "Tenant abandoned property",
        },
        "10" => {
          "value" => "Tenant was evicted due to rent arrears",
        },
        "11" => {
          "value" => "Tenant was evicted due to anti-social behaviour",
        },
      }
    end
  end

  QUESTION_NUMBER_FROM_YEAR = { 2023 => 17, 2024 => 18 }.freeze
end
