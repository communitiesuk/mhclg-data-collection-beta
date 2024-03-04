class Form::Lettings::Questions::Earnings < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "earnings"
    @check_answer_label = "Total household income"
    @header = "How much income does the household have in total?"
    @type = "numeric"
    @width = 5
    @check_answers_card_number = 0
    @min = 0
    @top_guidance_partial = "what_counts_as_income"
    @hint_text = ""
    @step = 0.01
    @prefix = "£"
    @suffix = [
      { "label" => " every week", "depends_on" => { "incfreq" => 1 } },
      { "label" => " every month", "depends_on" => { "incfreq" => 2 } },
      { "label" => " every year", "depends_on" => { "incfreq" => 3 } },
    ]
    @question_number = QUESTION_NUMBER_FROM_YEAR[form.start_date.year] || QUESTION_NUMBER_FROM_YEAR[QUESTION_NUMBER_FROM_YEAR.keys.max]
  end

  QUESTION_NUMBER_FROM_YEAR = { 2023 => 88, 2024 => 86 }.freeze
end
