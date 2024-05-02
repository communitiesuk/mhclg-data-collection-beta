class Form::Sales::Questions::MortgageAmount < ::Form::Question
  def initialize(id, hsh, subsection, ownershipsch:)
    super(id, hsh, subsection)
    @id = "mortgage"
    @check_answer_label = "Mortgage amount"
    @header = "What is the mortgage amount?"
    @type = "numeric"
    @min = 1
    @step = 1
    @width = 5
    @prefix = "£"
    @hint_text = "Enter the amount of mortgage agreed with the mortgage lender. Exclude any deposits or cash payments. Numeric in pounds. Rounded to the nearest pound."
    @ownershipsch = ownershipsch
    @question_number = QUESTION_NUMBER_FROM_YEAR_AND_OWNERSHIP.fetch(form.start_date.year, QUESTION_NUMBER_FROM_YEAR_AND_OWNERSHIP.max_by { |k, _v| k }.last)[ownershipsch]
  end

  QUESTION_NUMBER_FROM_YEAR_AND_OWNERSHIP = {
    2023 => { 1 => 91, 2 => 104, 3 => 112 },
    2024 => { 1 => 92, 2 => 105, 3 => 113 },
  }.freeze

  def derived?(log)
    log&.mortgage_not_used?
  end
end
