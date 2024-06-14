class Form::Sales::Questions::Mortgageused < ::Form::Question
  def initialize(id, hsh, subsection, ownershipsch:)
    super(id, hsh, subsection)
    @id = "mortgageused"
    @check_answer_label = "Mortgage used"
    @header = "Was a mortgage used for the purchase of this property?"
    @type = "radio"
    @answer_options = ANSWER_OPTIONS
    @ownershipsch = ownershipsch
    @question_number = QUESTION_NUMBER_FROM_YEAR_AND_OWNERSHIP.fetch(form.start_date.year, QUESTION_NUMBER_FROM_YEAR_AND_OWNERSHIP.max_by { |k, _v| k }.last)[ownershipsch]
  end

  def displayed_answer_options(log, _user = nil)
    if log.outright_sale? && log.saledate && !form.start_year_after_2024?
      answer_options_without_dont_know
    elsif log.stairowned == 100 || log.outright_sale?
      ANSWER_OPTIONS
    else
      answer_options_without_dont_know
    end
  end

  ANSWER_OPTIONS = {
    "1" => { "value" => "Yes" },
    "2" => { "value" => "No" },
    "3" => { "value" => "Don’t know" },
  }.freeze

  def answer_options_without_dont_know
    ANSWER_OPTIONS.reject { |key, _v| key == "3" }
  end

  QUESTION_NUMBER_FROM_YEAR_AND_OWNERSHIP = {
    2023 => { 1 => 90, 2 => 103, 3 => 111 },
    2024 => { 1 => 91, 2 => 104, 3 => 112 },
  }.freeze
end
