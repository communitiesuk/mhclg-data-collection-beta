class Form::Lettings::Questions::La < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "la"
    @check_answer_label = "Local Authority"
    @header = "What is the property’s local authority?"
    @type = "select"
    @check_answers_card_number = nil
    @hint_text = ""
    @question_number = QUESTION_NUMBER_FROM_YEAR.fetch(form.start_date.year, QUESTION_NUMBER_FROM_YEAR.max_by { |k, _v| k }.last)
    @disable_clearing_if_not_routed_or_dynamic_answer_options = true
  end

  def answer_options
    { "" => "Select an option" }.merge(LocalAuthority.active(form.start_date).england.map { |la| [la.code, la.name] }.to_h)
  end

  QUESTION_NUMBER_FROM_YEAR = { 2023 => 13, 2024 => 14 }.freeze
end
