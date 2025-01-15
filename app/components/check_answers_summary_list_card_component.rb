class CheckAnswersSummaryListCardComponent < ViewComponent::Base
  attr_reader :questions, :log, :user

  def initialize(questions:, log:, user:, correcting_hard_validation: false)
    @questions = questions
    @log = log
    @user = user
    @correcting_hard_validation = correcting_hard_validation

    super
  end

  def applicable_questions
    questions.reject { |q| q.hidden_in_check_answers?(log, user) }
  end

  def get_answer_label(question)
    question.answer_label(log, user).presence || unanswered_value(question)
  end

  def get_question_label(question)
    [question.question_number_string, question.check_answer_label.to_s.presence || question.header.to_s].compact.join(" - ")
  end

  def check_answers_card_title(question)
    return "Lead tenant" if question.form.type == "lettings" && question.check_answers_card_number == 1
    return "Buyer #{question.check_answers_card_number}" if question.check_answers_card_number <= number_of_buyers

    "Person #{question.check_answers_card_number}"
  end

  def action_href(question, log)
    referrer = question.displayed_as_answered?(log) ? "check_answers" : "check_answers_new_answer"
    send("#{log.model_name.param_key}_#{question.page.id}_path", log, referrer:)
  end

  def correct_validation_action_href(question, log, _related_question_ids, correcting_hard_validation)
    return action_href(question, log) unless correcting_hard_validation

    if question.displayed_as_answered?(log)
      send("#{log.model_name.param_key}_confirm_clear_answer_path", log, question_id: question.id)
    else
      send("#{log.model_name.param_key}_#{question.page.id}_path", log, referrer: "check_errors", related_question_ids: request.query_parameters["related_question_ids"], original_page_id: request.query_parameters["original_page_id"])
    end
  end

private

  def unanswered_value(question)
    link_class = if log.creation_method_bulk_upload? && log.bulk_upload.present? && !log.optional_fields.include?(question.id)
                   "app-red-link app-red-link---no-visited-state"
                 else
                   "govuk-link govuk-link--no-visited-state"
                 end

    govuk_link_to question.check_answer_prompt, correct_validation_action_href(question, log, nil, @correcting_hard_validation), class: link_class
  end

  def number_of_buyers
    log[:jointpur] == 1 ? 2 : 1
  end
end
