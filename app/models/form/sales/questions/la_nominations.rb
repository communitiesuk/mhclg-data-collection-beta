class Form::Sales::Questions::LaNominations < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "lanomagr"
    @check_answer_label = "Household rehoused under a local authority nominations agreement?"
    @header = "Was the household rehoused under a 'local authority nominations agreement'?"
    @type = "radio"
    @answer_options = ANSWER_OPTIONS
    @hint_text = "A local authority nominations agreement is a written agreement between a local authority and private registered provider (PRP) that some or all of its sales vacancies are offered to local authorities for rehousing"
    @question_number = QUESION_NUMBER_FROM_YEAR.fetch(form.start_date.year, QUESION_NUMBER_FROM_YEAR.max_by { |k, _v| k }.last)
  end

  ANSWER_OPTIONS = {
    "1" => { "value" => "Yes" },
    "2" => { "value" => "No" },
    "3" => { "value" => "Don’t know" },
  }.freeze

  QUESION_NUMBER_FROM_YEAR = { 2023 => 83, 2024 => 85 }.freeze
end
