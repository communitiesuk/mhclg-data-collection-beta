module LogActionsHelper
  include GovukLinkHelper

  def edit_actions_for_log(log)
    back = back_button_for(log)
    delete = delete_button_for_log(log)

    return if back.nil? && delete.nil?

    content_tag(:div, class: "govuk-button-group") do
      safe_join([back, delete])
    end
  end

private

  def back_button_for(log)
    if log.completed?
      if log.bulk_uploaded?
        if log.lettings?
          govuk_button_link_to "Back to uploaded logs", resume_bulk_upload_lettings_result_path(log.bulk_upload)
        else
          govuk_button_link_to "Back to uploaded logs", resume_bulk_upload_sales_result_path(log.bulk_upload)
        end
      elsif log.lettings?
        govuk_button_link_to "Back to lettings logs", lettings_logs_path
      elsif log.sales?
        govuk_button_link_to "Back to sales logs", sales_logs_path
      end
    end
  end

  def policy_class_for(log)
    log.lettings? ? LettingsLogPolicy : SalesLogPolicy
  end

  def delete_button_for_log(log)
    if policy_class_for(log).new(current_user, log).destroy?
      govuk_button_link_to(
        "Delete log",
        lettings_log_delete_confirmation_path(log),
        warning: true,
      )
    end
  end
end
