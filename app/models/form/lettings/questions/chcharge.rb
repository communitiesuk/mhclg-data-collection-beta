class Form::Lettings::Questions::Chcharge < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "chcharge"
    @check_answer_label = "Care home charges"
    @header = "How much does the household pay every month?"
    @type = "numeric"
    @width = 5
    @check_answers_card_number = 0
    @hint_text = ""
    @step = 0.01
    @prefix = "£"
    @suffix = " every month"
  end
end
