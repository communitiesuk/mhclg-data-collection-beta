class Form::Lettings::Questions::PersonWorkingSituation < ::Form::Question
  def initialize(id, hsh, page, person_index:)
    super(id, hsh, page)
    @id = "ecstat#{person_index}"
    @check_answer_label = "Person #{person_index}’s working situation"
    @header = "Which of these best describes person #{person_index}’s working situation?"
    @type = "radio"
    @check_answers_card_number = person_index
    @hint_text = ""
    @person_index = person_index
    @question_number = question_number
    @answer_options = answer_options
  end

  def answer_options
    { "1" => { "value" => "Full-time – 30 hours or more" },
      "2" => { "value" => "Part-time – Less than 30 hours" },
      "7" => { "value" => "Full-time student" },
      "3" => { "value" => "In government training into work, such as New Deal" },
      "4" => { "value" => "Jobseeker" },
      "6" => { "value" => "Not seeking work" },
      "8" => { "value" => "Unable to work because of long term sick or disability" },
      "5" => { "value" => "Retired" },
      "9" => {
        "value" => "Child under 16",
        "depends_on" => [
          { "age#{@person_index}_known" => 1 },
          { "age#{@person_index}" => { "operator" => "<", "operand" => 16 } },
        ],
      },
      "0" => { "value" => "Other" },
      "divider" => { "value" => true },
      "10" => { "value" => "Person prefers not to say" } }
  end

  def question_number
    base_question_number = case form.start_date.year
                           when 2023
                             33
                           else
                             32
                           end

    base_question_number + (4 * @person_index)
  end
end
