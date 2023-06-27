class Form::Lettings::Questions::MaxRentValueCheck < ::Form::Question
  def initialize(id, hsh, page, check_answers_card_number:)
    super(id, hsh, page)
    @id = "rent_value_check"
    @check_answer_label = "Total rent confirmation"
    @header = "Are you sure this is correct?"
    @type = "interruption_screen"
    @hint_text = I18n.t("soft_validations.rent.hint_text", higher_or_lower: "higher")
    @check_answers_card_number = check_answers_card_number
    @answer_options = ANSWER_OPTIONS
    @hidden_in_check_answers = { "depends_on" => [{ "rent_value_check" => 0 }, { "rent_value_check" => 1 }] }
  end

  ANSWER_OPTIONS = { "0" => { "value" => "Yes" }, "1" => { "value" => "No" } }.freeze
end
