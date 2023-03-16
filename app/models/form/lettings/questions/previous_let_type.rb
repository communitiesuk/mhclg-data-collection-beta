class Form::Lettings::Questions::PreviousLetType < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "unitletas"
    @check_answer_label = "Most recent let type"
    @header = "What type was the property most recently let as?"
    @type = "radio"
    @check_answers_card_number = 0
    @hint_text = ""
    @answer_options = ANSWER_OPTIONS
    @question_number = 16
  end

  ANSWER_OPTIONS = {
    "1" => { "value" => "Social rent basis" },
    "2" => { "value" => "Affordable rent basis" },
    "5" => { "value" => "A London Affordable Rent basis" },
    "6" => { "value" => "A Rent to Buy basis" },
    "7" => { "value" => "A London Living Rent basis" },
    "8" => { "value" => "Another Intermediate Rent basis" },
    "divider" => { "value" => true },
    "3" => { "value" => "Don’t know" },
  }.freeze
end
