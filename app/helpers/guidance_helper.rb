module GuidanceHelper
  include GovukLinkHelper
  include GovukVisuallyHiddenHelper

  def question_link(question_id, log, user)
    question = log.form.get_question(question_id, log)
    return "" unless question.page.routed_to?(log, user)

    "(#{govuk_link_to "Q#{question.question_number}", send("#{log.log_type}_#{question.page.id}_path", log)})".html_safe
  end
end
