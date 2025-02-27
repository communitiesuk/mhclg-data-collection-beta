class Form::Sales::Questions::PostcodeForFullAddress < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "postcode_full"
    @copy_key = "sales.property_information.address.postcode_full"
    @type = "text"
    @width = 5
    @inferred_check_answers_value = [{
      "condition" => {
        "pcodenk" => 1,
      },
      "value" => "Not known",
    }]
    @inferred_answers = {
      "la" => {
        "is_la_inferred" => true,
      },
    }
    @plain_label = true
    @disable_clearing_if_not_routed_or_dynamic_answer_options = true
    @question_number = QUESTION_NUMBER_FROM_YEAR[form.start_date.year] || QUESTION_NUMBER_FROM_YEAR[QUESTION_NUMBER_FROM_YEAR.keys.max]
    @hide_question_number_on_page = true
    @bottom_guidance_partial = "address_fallback"
  end

  QUESTION_NUMBER_FROM_YEAR = { 2023 => 15, 2024 => 16, 2025 => 14 }.freeze
end
