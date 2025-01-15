module UserHelper
  def aliased_user_edit(user, current_user)
    current_user == user ? edit_account_path : edit_user_path(user)
  end

  def perspective(user, current_user)
    current_user == user ? "Are you" : "Is this person"
  end

  def can_edit_org?(current_user)
    current_user.data_coordinator? || current_user.support?
  end

  def delete_user_link(user)
    govuk_button_link_to "Delete this user", delete_confirmation_user_path(user), warning: true
  end

  def organisation_change_warning(user, new_organisation)
    logs_count = user.assigned_to_lettings_logs.count + user.assigned_to_sales_logs.count
    logs_count_text = logs_count == 1 ? "is #{logs_count} log" : "are #{logs_count} logs"

    "You’re moving #{user.name} from #{user.organisation.name} to #{new_organisation.name}. There #{logs_count_text} assigned to them."
  end

  def organisation_change_confirmation_warning(user, new_organisation, log_reassignment)
    log_reassignment_text = "There are no logs assigned to them."

    logs_count = user.assigned_to_lettings_logs.count + user.assigned_to_sales_logs.count
    if logs_count.positive?
      case log_reassignment
      when "reassign_all"
        log_reassignment_text = "The stock owner and managing agent on their logs will change to #{new_organisation.name}."
      when "reassign_stock_owner"
        log_reassignment_text = "The stock owner on their logs will change to #{new_organisation.name}."
      when "reassign_managing_agent"
        log_reassignment_text = "The managing agent on their logs will change to #{new_organisation.name}."
      when "unassign"
        log_reassignment_text = "Their logs will be unassigned."
      end
    end

    "You’re moving #{user.name} from #{user.organisation.name} to #{new_organisation.name}. #{log_reassignment_text}"
  end

  def remove_attributes_from_error_messages(user)
    modified_errors = []

    user.errors.each do |error|
      cleaned_message = error.type.gsub(error.attribute.to_s.humanize, "").strip
      modified_errors << [error.attribute, cleaned_message]
    end

    user.errors.clear

    modified_errors.each do |attribute, message|
      user.errors.add(attribute, message)
    end
  end

  def display_pending_email_change_banner?(user)
    user.unconfirmed_email.present? && user.email != user.unconfirmed_email
  end

  def pending_email_change_title_text(current_user, user)
    if current_user == user
      "You have requested to change your email address to #{user.unconfirmed_email}."
    else
      "There has been a request to change this user’s email address to #{user.unconfirmed_email}."
    end
  end

  def pending_email_change_banner_text(current_user)
    text = "A confirmation link has been sent to the new email address. The current email will continue to work until the change is confirmed."
    text += " Deactivating this user will cancel the email change request." if current_user.support? || current_user.data_coordinator?

    text
  end

  def user_details_html(user, current_user, attribute)
    value = user.send(attribute)
    return value.humanize if value.present?

    case attribute
    when "role"
      current_user.data_coordinator? || current_user.support? ? govuk_link_to("Select role", aliased_user_edit(user, current_user), class: "govuk-link govuk-link--no-visited-state") : "No role assigned"
    when "phone"
      govuk_link_to("Enter telephone number", aliased_user_edit(user, current_user), class: "govuk-link govuk-link--no-visited-state")
    else
      "No answer provided"
    end
  end

  def user_action_text(user, attribute)
    return "Change" if %w[role phone].include?(attribute) && user.send(attribute).present?

    ""
  end
end
