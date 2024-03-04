class Form::Lettings::Questions::SchargeMonthly < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "scharge"
    @check_answer_label = "Service charge"
    @header = "What is the service charge?"
    @type = "numeric"
    @width = 5
    @check_answers_card_number = 0
    @min = 0
    @hint_text = "For example, for cleaning. Households may receive housing benefit or Universal Credit towards the service charge."
    @step = 0.01
    @fields_to_add = %w[brent scharge pscharge supcharg]
    @result_field = "tcharge"
    @prefix = "£"
    @suffix = " every month"
    @question_number = QUESTION_NUMBER_FROM_YEAR.fetch(form.start_date.year, QUESTION_NUMBER_FROM_YEAR.max_by { |k, _v| k }.last)
  end

  QUESTION_NUMBER_FROM_YEAR = { 2023 => 96, 2024 => 95 }.freeze
end
