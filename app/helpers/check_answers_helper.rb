module CheckAnswersHelper
  def total_answered_questions(subsection, case_log, form)
    total_questions(subsection, case_log, form).keys.count do |question_key|
      case_log[question_key].present?
    end
  end

  def total_number_of_questions(subsection, case_log, form)
    total_questions(subsection, case_log, form).count
  end

  def total_questions(subsection, case_log, form)
    questions = form.questions_for_subsection(subsection)
    questions_not_applicable = []
    questions.reject do |question_key, question|
      question.fetch("conditional_for", []).map do |conditional_question_key, condition|
        if condition_not_met(case_log, question_key, question, condition)
          questions_not_applicable << conditional_question_key
        end
      end
      questions_not_applicable.include?(question_key)
    end
  end

  def condition_not_met(case_log, question_key, question, condition)
    case question["type"]
    when "numeric"
      # rubocop:disable Security/Eval
      case_log[question_key].blank? || !eval(case_log[question_key].to_s + condition)
    # rubocop:enable Security/Eval
    when "radio"
      case_log[question_key].blank? || !condition.include?(case_log[question_key])
    else
      raise "Not implemented yet"
    end
  end

  def create_update_answer_link(case_log_answer, case_log_id, page)
    link_name = case_log_answer.blank? ? "Answer" : "Change"
    link_to(link_name, "/case_logs/#{case_log_id}/#{page}", class: "govuk-link").html_safe
  end

  def create_next_missing_question_link(case_log_id, subsection, case_log, form)
    pages_to_fill_in = []
    form.pages_for_subsection(subsection).each do |page_title, page_info|
      page_info["questions"].any? { |question| case_log[question].blank? }
      pages_to_fill_in << page_title
    end
    url = "/case_logs/#{case_log_id}/#{pages_to_fill_in.first}"
    link_to("Answer the missing questions", url, class: "govuk-link").html_safe
  end

  def display_answered_questions_summary(subsection, case_log, form)
    if total_answered_questions(subsection, case_log, form) == total_number_of_questions(subsection, case_log, form)
      '<p class="govuk-body govuk-!-margin-bottom-7">You answered all the questions</p>'.html_safe
    else
      "<p class=\"govuk-body govuk-!-margin-bottom-7\">You answered #{total_answered_questions(subsection, case_log, form)} of #{total_number_of_questions(subsection, case_log, form)} questions</p>
      #{create_next_missing_question_link(case_log['id'], subsection, case_log, form)}".html_safe
    end
  end
end
