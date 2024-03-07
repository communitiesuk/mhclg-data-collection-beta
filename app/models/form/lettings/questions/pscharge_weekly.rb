class Form::Lettings::Questions::PschargeWeekly < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "pscharge"
    @check_answer_label = "Personal service charge"
    @header = "What is the personal service charge?"
    @type = "numeric"
    @width = 5
    @check_answers_card_number = 0
    @min = 0
    @hint_text = "For example, for heating or hot water. This doesn’t include housing benefit or Universal Credit."
    @step = 0.01
    @fields_to_add = %w[brent scharge pscharge supcharg]
    @result_field = "tcharge"
    @prefix = "£"
    @suffix = " every week"
    @question_number = QUESTION_NUMBER_FROM_YEAR[form.start_date.year] || QUESTION_NUMBER_FROM_YEAR[QUESTION_NUMBER_FROM_YEAR.keys.max]
  end

  QUESTION_NUMBER_FROM_YEAR = { 2023 => 97, 2024 => 96 }.freeze
end
