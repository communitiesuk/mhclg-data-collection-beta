module CheckAnswersHelper
  include GovukLinkHelper
  include GovukVisuallyHiddenHelper

  def display_answered_questions_summary(subsection, lettings_log, current_user)
    total = total_count(subsection, lettings_log, current_user)
    answered = answered_questions_count(subsection, lettings_log, current_user)
    if total == answered
      '<p class="govuk-body">You answered all the questions.</p>'.html_safe
    else
      "<p class=\"govuk-body\">You have answered #{answered} of #{total} questions.</p>".html_safe
    end
  end

  def can_change_scheme_answer?(attribute_name, scheme)
    return true if current_user.support?
    return false unless current_user.data_coordinator?

    editable_attributes = ["Name", "Confidential information", "Housing stock owned by"]

    !scheme.confirmed? || editable_attributes.include?(attribute_name)
  end

  def any_questions_have_summary_card_number?(subsection, lettings_log)
    subsection.applicable_questions(lettings_log).map(&:check_answers_card_number).compact.length.positive?
  end

  def next_incomplete_section_path(log, redirect_path)
    "#{log.log_type}_#{redirect_path.underscore.tr('/', '_')}_path"
  end

private

  def answered_questions_count(subsection, lettings_log, current_user)
    answered_questions(subsection, lettings_log, current_user).count
  end

  def answered_questions(subsection, lettings_log, current_user)
    total_applicable_questions(subsection, lettings_log, current_user).select { |q| q.completed?(lettings_log) }
  end

  def total_count(subsection, lettings_log, current_user)
    total_applicable_questions(subsection, lettings_log, current_user).count
  end

  def total_applicable_questions(subsection, lettings_log, current_user)
    subsection.applicable_questions(lettings_log).reject { |q| q.hidden_in_check_answers?(lettings_log, current_user) }
  end

  def get_answer_label(question, lettings_log)
    question.answer_label(lettings_log, current_user).presence || unanswered_value(log: lettings_log, question:)
  end

  def get_question_label(question)
    [question.question_number_string, question.check_answer_label.to_s.presence || question.header.to_s].compact.join(" - ")
  end

  def unanswered_value(log:, question:)
    if log.creation_method_bulk_upload? && log.bulk_upload.present? && !log.optional_fields.include?(question.id)
      "<span class=\"app-!-colour-red\">You still need to answer this question</span>".html_safe
    else
      "<span class=\"app-!-colour-muted\">You didn’t answer this question</span>".html_safe
    end
  end
end
