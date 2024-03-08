class Form::Lettings::Questions::Builtype < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "builtype"
    @check_answer_label = "Type of building"
    @header = "What type of building is the property?"
    @type = "radio"
    @check_answers_card_number = 0
    @hint_text = ""
    @answer_options = ANSWER_OPTIONS
    @question_number = QUESTION_NUMBER_FROM_YEAR[form.start_date.year] || QUESTION_NUMBER_FROM_YEAR[QUESTION_NUMBER_FROM_YEAR.keys.max]
  end

  ANSWER_OPTIONS = {
    "2" => { "value" => "Converted from previous residential or non-residential property" },
    "1" => { "value" => "Purpose built" },
  }.freeze

  QUESTION_NUMBER_FROM_YEAR = { 2023 => 20 }.freeze
end
