class Form::Sales::Questions::HandoverDate < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "hodate"
    @check_answer_label = "Practical completion or handover date"
    @header = "What is the practical completion or handover date?"
    @type = "date"
    @hint_text = "This is the date on which the building contractor hands over responsibility for the completed property to the private registered provider (PRP)"
    @question_number = QUESION_NUMBER_FROM_YEAR[form.start_date.year]
  end

  QUESION_NUMBER_FROM_YEAR = { 2023 => 82, 2024 => 84 }.freeze
end
