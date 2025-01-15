module DuplicateLogsHelper
  include GovukLinkHelper
  include GovukVisuallyHiddenHelper

  def duplicate_logs_continue_button(all_duplicates, duplicate_log, original_log)
    if all_duplicates.count > 1
      return govuk_button_link_to "Keep this log and delete duplicates", url_for(
        controller: "duplicate_logs",
        action: "delete_duplicates",
        "#{duplicate_log.log_type}_id": duplicate_log.id,
        original_log_id: original_log.id,
        referrer: params[:referrer],
        organisation_id: params[:organisation_id],
      )
    end
    if params[:referrer] == "duplicate_logs_banner"
      current_user.support? ? govuk_button_link_to("Review other duplicates", organisation_duplicates_path(organisation_id: params[:organisation_id], referrer: params[:referrer])) : govuk_button_link_to("Review other duplicates", duplicate_logs_path(referrer: params[:referrer]))
    elsif !original_log.deleted?
      govuk_button_link_to "Back to Log #{original_log.id}", send("#{original_log.log_type}_path", original_log)
    else
      type = duplicate_log.lettings? ? "lettings" : "sales"
      govuk_button_link_to "Back to #{type} logs", url_for(duplicate_log.class)
    end
  end

  def duplicate_logs_action_href(log, page_id, original_log_id)
    send("#{log.log_type}_#{page_id}_path", log, referrer: "interruption_screen", original_log_id:)
  end

  def change_duplicate_logs_action_href(log, page_id, all_duplicates, original_log_id)
    first_remaining_duplicate_id = all_duplicates.map(&:id).reject { |id| id == log.id }.first
    send("#{log.log_type}_#{page_id}_path", log, referrer: params[:referrer] == "duplicate_logs_banner" ? "duplicate_logs_banner" : "duplicate_logs", first_remaining_duplicate_id:, original_log_id:, organisation_id: params[:organisation_id])
  end

  def duplicates_for_user(user)
    {
      lettings: user.editable_duplicate_lettings_logs_sets,
      sales: user.editable_duplicate_sales_logs_sets,
    }
  end

  def duplicates_for_organisation(organisation)
    {
      lettings: organisation.editable_duplicate_lettings_logs_sets,
      sales: organisation.editable_duplicate_sales_logs_sets,
    }
  end

  def duplicate_sets_count(user, organisation)
    duplicates = user.data_provider? ? duplicates_for_user(user) : duplicates_for_organisation(organisation)
    duplicates[:lettings].count + duplicates[:sales].count
  end

  def duplicate_list_header(duplicate_sets_count)
    duplicate_sets_count > 1 ? "Review these #{duplicate_sets_count} sets of logs" : "Review this #{duplicate_sets_count} set of logs"
  end

  def duplicate_log_question_label(question)
    if question.id == "uprn"
      "Postcode (from UPRN)"
    else
      get_question_label(question)
    end
  end

  def duplicate_log_answer_label(question, log)
    if question.id == "uprn"
      postcode_question = log.form.get_question("postcode_full", log)
      get_answer_label(postcode_question, log)
    else
      get_answer_label(question, log)
    end
  end

  def duplicate_log_extra_value(question, log)
    if question.id == "uprn"
      postcode_question = log.form.get_question("postcode_full", log)
      postcode_question.get_extra_check_answer_value(log)
    else
      question.get_extra_check_answer_value(log)
    end
  end

  def duplicate_log_answer_label_present(question, log, current_user)
    if question.id == "uprn"
      postcode_question = log.form.get_question("postcode_full", log)
      postcode_question.answer_label(log, current_user).present?
    else
      question.answer_label(log, current_user).present?
    end
  end

  def duplicate_log_inferred_answers(question, log)
    if question.id == "uprn"
      postcode_question = log.form.get_question("postcode_full", log)
      postcode_question.get_inferred_answers(log)
    else
      question.get_inferred_answers(log)
    end
  end
end
