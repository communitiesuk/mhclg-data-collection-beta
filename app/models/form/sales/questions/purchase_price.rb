class Form::Sales::Questions::PurchasePrice < ::Form::Question
  def initialize(id, hsh, page, ownershipsch:)
    super(id, hsh, page)
    @id = "value"
    @check_answer_label = "Purchase price"
    @header = "What is the full purchase price?"
    @type = "numeric"
    @min = 0
    @step = 0.01
    @width = 5
    @prefix = "£"
    @hint_text = hint_text
    @ownership_sch = ownershipsch
    @question_number = QUESION_NUMBER_FROM_YEAR_AND_OWNERSHIP[form.start_date.year][ownershipsch] if QUESION_NUMBER_FROM_YEAR_AND_OWNERSHIP[form.start_date.year].present?
  end

  QUESION_NUMBER_FROM_YEAR_AND_OWNERSHIP = {
    2023 => { 2 => 100, 3 => 110 },
    2024 => { 2 => 102, 3 => 112 },
  }.freeze

  def hint_text
    return if @ownership_sch == 3 # outright sale

    "For all schemes, including Right to Acquire (RTA), Right to Buy (RTB), Voluntary Right to Buy (VRTB) or Preserved Right to Buy (PRTB) sales, enter the full price of the property without any discount"
  end
end
