class Form::Lettings::Questions::BrentWeekly < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "brent"
    @check_answer_label = "Basic rent"
    @header = "What is the basic rent?"
    @type = "numeric"
    @width = 5
    @check_answers_card_number = 0
    @min = 0
    @hint_text = "This is the amount paid before any charges are added for services (for example, hot water or cleaning). Households may receive housing benefit or Universal Credit towards basic rent."
    @step = 0.01
    @fields_to_add = %w[brent scharge pscharge supcharg]
    @result_field = "tcharge"
    @prefix = "£"
    @suffix = " every week"
    @question_number = QUESION_NUMBER_FROM_YEAR.fetch(form.start_date.year, QUESION_NUMBER_FROM_YEAR.max_by { |k, _v| k }.last)
  end

  QUESION_NUMBER_FROM_YEAR = { 2023 => 95, 2024 => 94 }.freeze
end
