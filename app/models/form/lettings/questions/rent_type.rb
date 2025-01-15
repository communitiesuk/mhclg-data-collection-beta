class Form::Lettings::Questions::RentType < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "rent_type"
    @copy_key = "lettings.setup.rent_type.rent_type"
    @type = "radio"
    @top_guidance_partial = "rent_type_definitions"
    @answer_options = answer_options
    @conditional_for = { "irproduct_other" => [5] }
    @question_number = QUESTION_NUMBER_FROM_YEAR[form.start_date.year] || QUESTION_NUMBER_FROM_YEAR[QUESTION_NUMBER_FROM_YEAR.keys.max] if form.start_date.present?
  end

  ANSWER_OPTIONS = {
    "0" => { "value" => "Social Rent" },
    "1" => { "value" => "Affordable Rent" },
    "2" => { "value" => "London Affordable Rent" },
    "3" => { "value" => "Rent to Buy" },
    "4" => { "value" => "London Living Rent" },
    "5" => { "value" => "Other intermediate rent product" },
  }.freeze

  ANSWER_OPTIONS_2025 = {
    "0" => { "value" => "Social Rent" },
    "1" => { "value" => "Affordable Rent" },
    "2" => { "value" => "London Affordable Rent" },
    "3" => { "value" => "Rent to Buy" },
    "4" => { "value" => "London Living Rent" },
    "5" => { "value" => "Other intermediate rent product" },
    "6" => { "value" => "Specified accommodation - exempt accommodation, managed properties, refuges and local authority hostels" },
  }.freeze

  QUESTION_NUMBER_FROM_YEAR = { 2023 => 6, 2024 => 8 }.freeze

  def answer_options
    form.start_year_2025_or_later? ? ANSWER_OPTIONS_2025 : ANSWER_OPTIONS
  end
end
