class Form::Sales::Questions::Person3Known < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "details_known_3"
    @check_answer_label = "Details known for person 3?"
    @header = "Do you know the details for person 3?"
    @type = "radio"
    @answer_options = ANSWER_OPTIONS
    @page = page
    @hint_text = ""
    @hidden_in_check_answers = {
      "depends_on" => [
        {
          "details_known_3" => 1,
        },
      ],
    }
    @check_answers_card_number = hsh[:check_answers_card_number]
  end

  ANSWER_OPTIONS = {
    "1" => { "value" => "Yes" },
    "2" => { "value" => "No" },
  }.freeze
end
