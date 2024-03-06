class Form::Sales::Questions::PersonWorkingSituation < ::Form::Question
  def initialize(id, hsh, page, person_index:)
    super(id, hsh, page)
    @check_answer_label = "Person #{person_index}’s working situation"
    @header = "Which of these best describes Person #{person_index}’s working situation?"
    @type = "radio"
    @answer_options = ANSWER_OPTIONS
    @check_answers_card_number = person_index
    @inferred_check_answers_value = [{
      "condition" => {
        id => 10,
      },
      "value" => "Prefers not to say",
    }]
    @person_index = person_index
  end

  ANSWER_OPTIONS = {
    "1" => { "value" => "Full-time - 30 hours or more" },
    "2" => { "value" => "Part-time - Less than 30 hours" },
    "3" => { "value" => "In government training into work, such as New Deal" },
    "4" => { "value" => "Jobseeker" },
    "6" => { "value" => "Not seeking work" },
    "8" => { "value" => "Unable to work due to long term sick or disability" },
    "5" => { "value" => "Retired" },
    "0" => { "value" => "Other" },
    "10" => { "value" => "Person prefers not to say" },
    "7" => { "value" => "Full-time student" },
    "9" => { "value" => "Child under 16" },
  }.freeze

  def question_number
    base_question_number = case form.start_date.year
                           when 2023
                             31
                           else
                             33
                           end

    base_question_number + (4 * @person_index)
  end
end
