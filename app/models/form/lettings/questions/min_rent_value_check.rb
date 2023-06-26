class Form::Lettings::Questions::MinRentValueCheck < ::Form::Question
  def initialize(id, hsh, page, check_answers_card_number:)
    super(id, hsh, page)
    @id = "rent_value_check"
    @check_answer_label = "Total rent confirmation"
    @header = "Are you sure this is correct?"
    @type = "interruption_screen"
    @hint_text = I18n.t("soft_validations.rent.soft_min_hint_text")
    # @hint_text = "This is lower than we would expect. Check:<ul class=\"govuk-body-l app-panel--interruption\"><li>the decimal point</li><li>the frequency, for example every week or every calendar month</li><li>the rent type is correct, for example affordable or social rent</li></ul>"
    @check_answers_card_number = check_answers_card_number
    @answer_options = ANSWER_OPTIONS
    @hidden_in_check_answers = { "depends_on" => [{ "rent_value_check" => 0 }, { "rent_value_check" => 1 }] }
  end



  ANSWER_OPTIONS = { "0" => { "value" => "Yes" }, "1" => { "value" => "No" } }.freeze
end
