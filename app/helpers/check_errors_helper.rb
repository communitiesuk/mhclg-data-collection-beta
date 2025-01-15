module CheckErrorsHelper
  include GovukLinkHelper

  def check_errors_answer_text(question, log)
    question.displayed_as_answered?(log) ? "Change" : "Answer"
  end

  def check_errors_answer_link(log, question, page, applicable_questions)
    send("#{log.log_type}_#{question.page.id}_path", log, referrer: "check_errors", original_page_id: page.id, related_question_ids: applicable_questions.map(&:id))
  end
end
