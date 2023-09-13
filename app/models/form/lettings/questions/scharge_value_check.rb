class Form::Lettings::Questions::SchargeValueCheck < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "scharge_value_check"
    @check_answer_label = "Service charge confirmation"
    @header = "Are you sure?"
    @type = "interruption_screen"
    @check_answers_card_number = 0
    @answer_options = ANSWER_OPTIONS
    @hidden_in_check_answers = { "depends_on" => [{ "scharge_value_check" => 0 }, { "scharge_value_check" => 1 }] }
    @hint_text = I18n.t("soft_validations.charges.hint_text")
  end

  ANSWER_OPTIONS = { "0" => { "value" => "Yes" }, "1" => { "value" => "No" } }.freeze
end
