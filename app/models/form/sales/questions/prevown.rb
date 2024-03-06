class Form::Sales::Questions::Prevown < ::Form::Question
  def initialize(id, hsh, page, joint_purchase:)
    super(id, hsh, page)
    @id = "prevown"
    @check_answer_label = I18n.t("check_answer_labels.prevown", count: joint_purchase ? 2 : 1)
    @header = I18n.t("questions.prevown", count: joint_purchase ? 2 : 1)
    @type = "radio"
    @answer_options = ANSWER_OPTIONS
    @question_number = QUESION_NUMBER_FROM_YEAR[form.start_date.year]
  end

  ANSWER_OPTIONS = {
    "1" => { "value" => "Yes" },
    "2" => { "value" => "No" },
    "3" => { "value" => "Don’t know" },
  }.freeze

  QUESION_NUMBER_FROM_YEAR = { 2023 => 73, 2024 => 75 }.freeze
end
