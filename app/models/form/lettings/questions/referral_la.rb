class Form::Lettings::Questions::ReferralLa < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "referral"
    @copy_key = "lettings.household_situation.referral.la"
    @type = "radio"
    @check_answers_card_number = 0
    @question_number = QUESTION_NUMBER_FROM_YEAR[form.start_date.year] || QUESTION_NUMBER_FROM_YEAR[QUESTION_NUMBER_FROM_YEAR.keys.max]
  end

  def answer_options
    {
      "21" => {
        "value" => "Local authority lettings",
      },
      "3" => {
        "value" => "PRP lettings nominated by a local authority",
      },
      "4" => {
        "value" => "PRP support lettings referred by a local authority",
      },
      "22" => {
        "value" => "Other",
      },
    }.freeze
  end

  QUESTION_NUMBER_FROM_YEAR = { 2025 => 84 }.freeze
end
