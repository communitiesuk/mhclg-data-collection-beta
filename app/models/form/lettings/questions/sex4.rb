class Form::Lettings::Questions::Sex4 < ::Form::Question
  def initialize(id, hsh, page)
    super
    @id = "sex4"
    @check_answer_label = "Person 4’s gender identity"
    @header = "Which of these best describes person 4’s gender identity?"
    @type = "radio"
    @check_answers_card_number = 4
    @hint_text = ""
    @answer_options = ANSWER_OPTIONS
  end

  ANSWER_OPTIONS = { "F" => { "value" => "Female" }, "M" => { "value" => "Male" }, "X" => { "value" => "Non-binary" }, "divider" => { "value" => true }, "R" => { "value" => "Person prefers not to say" } }.freeze
end
