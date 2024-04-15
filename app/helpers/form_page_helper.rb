module FormPageHelper
  def action_href(log, page_id, referrer = "check_answers")
    send("#{log.model_name.param_key}_#{page_id}_path", log, referrer:)
  end

  def returning_to_question_page?(page, referrer)
    page.interruption_screen? || referrer == "check_answers"
  end

  def accessed_from_duplicate_logs?(referrer)
    %w[duplicate_logs duplicate_logs_banner].include?(referrer)
  end

  def duplicate_log_set_path(log, original_log_id)
    send("#{log.class.name.underscore}_duplicate_logs_path", log, original_log_id:)
  end

  def relevant_check_answers_path(log, subsection)
    send("#{log.class.name.underscore}_#{subsection.id}_check_answers_path", log)
  end

  def submit_button_text(page, referrer)
    return page.submit_text if page.submit_text.present?

    if accessed_from_duplicate_logs?(referrer) || returning_to_question_page?(page, referrer)
      "Save changes"
    else
      "Save and continue"
    end
  end

  def cancel_button_text(page, referrer)
    if accessed_from_duplicate_logs?(referrer) || returning_to_question_page?(page, referrer)
      "Cancel"
    else
      page.skip_text || "Skip for now"
    end
  end

  def cancel_button_link(page, referrer, original_log_id, log, ignore_answered)
    if accessed_from_duplicate_logs?(referrer)
      duplicate_log_set_path(log, original_log_id)
    elsif returning_to_question_page?(page, referrer)
      send(log.form.cancel_path(page, log), log)
    else
      page.skip_href(log) || send(log.form.next_page_redirect_path(page, log, current_user, ignore_answered:), log)
    end
  end
end
