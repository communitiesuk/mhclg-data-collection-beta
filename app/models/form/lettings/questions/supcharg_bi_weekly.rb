class Form::Lettings::Questions::SupchargBiWeekly < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "supcharg"
    @check_answer_label = "Support charge"
    @header = "What is the support charge?"
    @type = "numeric"
    @width = 5
    @check_answers_card_number = 0
    @min = 0
    @hint_text = "Any charges made to fund support services included in tenancy agreement."
    @step = 0.01
    @fields_to_add = %w[brent scharge pscharge supcharg]
    @result_field = "tcharge"
    @prefix = "£"
    @suffix = " every 2 weeks"
    @question_number = QUESION_NUMBER_FROM_YEAR.fetch(form.start_date.year, QUESION_NUMBER_FROM_YEAR.max_by { |k, _v| k }.last)
  end

  QUESION_NUMBER_FROM_YEAR = { 2023 => 98, 2024 => 97 }.freeze
end
