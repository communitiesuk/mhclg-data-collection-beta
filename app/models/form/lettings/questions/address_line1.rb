class Form::Lettings::Questions::AddressLine1 < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "address_line1"
    @header = "Address line 1"
    @error_label = "Address line 1"
    @type = "text"
    @plain_label = true
    @check_answer_label = "Address lines 1 and 2"
    @disable_clearing_if_not_routed_or_dynamic_answer_options = true
    @question_number = QUESTION_NUMBER_FROM_YEAR[form.start_date.year] || QUESTION_NUMBER_FROM_YEAR[QUESTION_NUMBER_FROM_YEAR.keys.max]
    @hide_question_number_on_page = true
  end

  def answer_label(log, _current_user = nil)
    [
      log.address_line1,
      log.address_line2,
    ].select(&:present?).join("\n")
  end

  QUESTION_NUMBER_FROM_YEAR = { 2023 => 12, 2024 => 13 }.freeze
end
