module MergeRequestsHelper
  include GovukLinkHelper
  include GovukVisuallyHiddenHelper

  def display_value_or_placeholder(value, placeholder = "No answer provided")
    value.presence || content_tag(:span, placeholder, class: "app-!-colour-muted")
  end

  def value_exists?(merge_request, attribute)
    merge_request.send(attribute).present? || (attribute == "helpdesk_ticket" && merge_request.has_helpdesk_ticket == false)
  end

  def details_prompt_link(page, merge_request)
    govuk_link_to(merge_request_details_prompt(page), send("#{page}_merge_request_path", merge_request, referrer: "check_answers"), class: "govuk-link govuk-link--no-visited-state")
  end

  def merge_request_details_prompt(page)
    messages = {
      "existing_absorbing_organisation" => "Tell us if absorbing organisation is already active",
      "helpdesk_ticket" => "Enter helpdesk ticket number",
      "merging_organisations" => "Add merging organisations",
      "merge_date" => "Set merge date",
    }
    messages[page] || "Enter #{lowercase_first_letter(page.humanize)}"
  end

  def merge_request_action_text(merge_request, attribute)
    value_exists?(merge_request, attribute) ? "Change" : ""
  end

  def request_details(merge_request)
    [
      { label: "Requester", value: display_value_or_placeholder(merge_request.requester&.name) },
      { label: "Helpdesk ticket", value: helpdesk_ticket_value(merge_request), action: merge_request_action(merge_request, "helpdesk_ticket") },
      { label: "Status", value: status_tag(merge_request.status) },
    ]
  end

  def merge_details(merge_request)
    [
      { label: "Absorbing organisation", value: display_value_or_placeholder(merge_request.absorbing_organisation_name, details_prompt_link("absorbing_organisation", merge_request)), action: merge_request_action(merge_request, "absorbing_organisation") },
      { label: "Merging organisations", value: merge_request.merge_request_organisations.any? ? merge_request.merge_request_organisations.map(&:merging_organisation_name).join("<br>").html_safe : display_value_or_placeholder(nil, details_prompt_link("merging_organisations", merge_request)), action: merge_request_action(merge_request, "merging_organisations") },
      { label: "Merge date", value: display_value_or_placeholder(merge_request.merge_date, details_prompt_link("merge_date", merge_request)), action: merge_request_action(merge_request, "merge_date") },
      { label: "Absorbing organisation already active?", value: display_value_or_placeholder(merge_request.existing_absorbing_organisation_label, details_prompt_link("existing_absorbing_organisation", merge_request)), action: merge_request_action(merge_request, "existing_absorbing_organisation") },
    ]
  end

  def merge_outcomes(merge_request)
    [
      { label: "Total users after merge", value: display_value_or_placeholder(merge_request.total_users_label), action: merge_outcome_action(merge_request, "user_outcomes") },
      { label: "Total schemes after merge", value: display_value_or_placeholder(merge_request.total_schemes_label), action: merge_outcome_action(merge_request, "scheme_outcomes") },
      { label: "Total logs after merge", value: display_value_or_placeholder(merge_request.total_logs_label), action: merge_outcome_action(merge_request, "logs_outcomes") },
      { label: "Total stock owners & managing agents after merge", value: display_value_or_placeholder(merge_request.total_stock_owners_managing_agents_label), action: merge_outcome_action(merge_request, "relationship_outcomes") },
    ]
  end

  def ordered_merging_organisations(merge_request, new_merging_org_ids)
    Organisation.where(id: new_merging_org_ids) + merge_request.merge_request_organisations.order(created_at: :desc).map(&:merging_organisation)
  end

  def submit_merge_request_button_text(referrer)
    if accessed_from_check_answers?(referrer)
      "Save changes"
    else
      "Save and continue"
    end
  end

  def secondary_merge_request_link_text(referrer, skip_for_now: false)
    if accessed_from_check_answers?(referrer)
      "Cancel"
    elsif skip_for_now
      "Skip for now"
    else
      ""
    end
  end

  def accessed_from_check_answers?(referrer)
    %w[check_answers].include?(referrer)
  end

  def merge_request_back_link(merge_request, page, referrer)
    return merge_request_path(merge_request) if accessed_from_check_answers?(referrer)

    case page
    when "absorbing_organisation"
      organisations_path(tab: "merge-requests")
    when "merging_organisations"
      absorbing_organisation_merge_request_path(merge_request)
    when "merge_date"
      merging_organisations_merge_request_path(merge_request)
    when "existing_absorbing_organisation"
      merge_date_merge_request_path(merge_request)
    when "helpdesk_ticket"
      existing_absorbing_organisation_merge_request_path(merge_request)
    end
  end

  def merge_request_action(merge_request, page, attribute = nil)
    attribute = page if attribute.nil?
    return nil unless value_exists?(merge_request, attribute)

    unless merge_request.status == "request_merged" || merge_request.status == "processing"
      { text: merge_request_action_text(merge_request, attribute), href: send("#{page}_merge_request_path", merge_request, referrer: "check_answers"), visually_hidden_text: page.humanize }
    end
  end

  def merge_outcome_action(merge_request, page)
    unless merge_request.status == "request_merged" || merge_request.status == "processing"
      { text: "View", href: send("#{page}_merge_request_path", merge_request), visually_hidden_text: page.humanize }
    end
  end

  def submit_merge_request_url(referrer)
    referrer == "check_answers" ? merge_request_path(referrer: "check_answers") : merge_request_path
  end

  def merging_organisations_without_users_text(organisations)
    return "" unless organisations.count.positive?

    if organisations.count == 1
      "#{organisations.first.name} has no users."
    else
      "#{organisations.map(&:name).to_sentence} have no users."
    end
  end

  def link_to_merging_organisation_users(organisation)
    count_text = organisation.users.count == 1 ? "1 #{organisation.name} user" : "all #{organisation.users.count} #{organisation.name} users"
    govuk_link_to "View #{count_text} (opens in a new tab)", users_organisation_path(organisation), target: "_blank"
  end

  def total_users_after_merge_text(merge_request)
    count = merge_request.total_visible_users_after_merge
    "#{"#{count} user".pluralize(count)} after merge"
  end

  def total_stock_owners_after_merge_text(merge_request)
    count = merge_request.total_stock_owners_after_merge
    "#{"#{count} stock owner".pluralize(count)} after merge"
  end

  def total_managing_agents_after_merge_text(merge_request)
    count = merge_request.total_managing_agents_after_merge
    "#{"#{count} managing agent".pluralize(count)} after merge"
  end

  def related_organisations(merge_request, relationship_type)
    organisations =  merge_request.absorbing_organisation.send(relationship_type.pluralize).visible + merge_request.merging_organisations.flat_map { |org| org.send(relationship_type.pluralize).visible }
    organisations += [merge_request.absorbing_organisation] + merge_request.merging_organisations
    organisations.group_by { |relationship| relationship }.select { |_, occurrences| occurrences.size > 1 }.keys
  end

  def related_organisations_text(merge_request, relationship_type)
    if related_organisations(merge_request, relationship_type).any?
      "Some of the organisations merging have common #{relationship_type.humanize(capitalize: false).pluralize}.<br><br>"
    else
      ""
    end
  end

  def organisations_without_relationships(merge_request, relationship_type)
    ([merge_request.absorbing_organisation] + merge_request.merging_organisations).select { |org| org.send(relationship_type.pluralize).visible.empty? }
  end

  def organisations_without_relationships_text(organisations_without_relationships, relationship_type)
    return "" unless organisations_without_relationships.any?

    org_names = organisations_without_relationships.map(&:name).to_sentence
    verb = organisations_without_relationships.count > 1 ? "have" : "has"
    "#{org_names} #{verb} no #{relationship_type.humanize(capitalize: false).pluralize}.<br><br>"
  end

  def generate_organisation_link_text(organisation_count, org, relationship_type)
    "View #{organisation_count == 1 ? 'the' : 'all'} #{organisation_count} #{org.name} #{relationship_type.humanize(capitalize: false).pluralize(organisation_count)} (opens in a new tab)"
  end

  def relationship_text(merge_request, relationship_type, organisation_path_helper)
    text = ""
    organisations_without_relationships = organisations_without_relationships(merge_request, relationship_type)

    text += related_organisations_text(merge_request, relationship_type)
    text += organisations_without_relationships_text(organisations_without_relationships, relationship_type)

    ([merge_request.absorbing_organisation] + merge_request.merging_organisations).each do |org|
      organisation_count = org.send(relationship_type.pluralize).visible.count
      next if organisation_count.zero?

      link_text = generate_organisation_link_text(organisation_count, org, relationship_type)
      text += "#{govuk_link_to(link_text, send(organisation_path_helper, org), target: '_blank')}<br><br>"
    end

    text.html_safe
  end

  def stock_owners_text(merge_request)
    relationship_text(merge_request, "stock_owner", :stock_owners_organisation_path)
  end

  def managing_agent_text(merge_request)
    relationship_text(merge_request, "managing_agent", :managing_agents_organisation_path)
  end

  def merging_organisations_without_schemes_text(organisations)
    return "" unless organisations.count.positive?

    if organisations.count == 1
      "#{organisations.first.name} has no schemes."
    else
      "#{organisations.map(&:name).to_sentence} have no schemes."
    end
  end

  def link_to_merging_organisation_schemes(organisation)
    count_text = organisation.owned_schemes.count == 1 ? "1 #{organisation.name} scheme" : "all #{organisation.owned_schemes.count} #{organisation.name} schemes"
    govuk_link_to "View #{count_text} (opens in a new tab)", schemes_organisation_path(organisation), target: "_blank"
  end

  def total_schemes_after_merge_text(merge_request)
    count = merge_request.total_visible_schemes_after_merge
    "#{"#{count} scheme".pluralize(count)} after merge"
  end

  def total_lettings_logs_after_merge_text(merge_request)
    count = merge_request.total_visible_lettings_logs_after_merge
    "#{"#{count} lettings log".pluralize(count)} after merge"
  end

  def total_sales_logs_after_merge_text(merge_request)
    count = merge_request.total_visible_sales_logs_after_merge
    "#{"#{count} sales log".pluralize(count)} after merge"
  end

  def merging_organisations_lettings_logs_outcomes_text(merge_request)
    merging_organisations_logs_outcomes_text(merge_request, "lettings")
  end

  def merging_organisations_sales_logs_outcomes_text(merge_request)
    merging_organisations_logs_outcomes_text(merge_request, "sales")
  end

  def merging_organisations_logs_outcomes_text(merge_request, type)
    text = ""
    if any_organisations_have_logs?(merge_request.merging_organisations, type)
      managed_or_reported = type == "lettings" ? "managed" : "reported"
      merging_organisations = merge_request.merging_organisations.count == 1 ? "merging organisation" : "merging organisations"
      text += "#{merge_request.absorbing_organisation.name} users will have access to all #{type} logs owned or #{managed_or_reported} by the #{merging_organisations} after the merge.<br><br>"

      if any_organisations_have_logs_after_merge_date?(merge_request.merging_organisations, type, merge_request.merge_date)
        startdate = type == "lettings" ? "tenancy start date" : "sale completion date"
        text += "#{type.capitalize} logs that are owned or #{managed_or_reported} by the #{merging_organisations} and have a #{startdate} after the merge date will have their owning or managing organisation changed to #{merge_request.absorbing_organisation.name}.<br><br>"
      end

      if any_organisations_share_logs?(merge_request.merging_organisations, type)
        text += "Some logs are owned and #{managed_or_reported} by different organisations in this merge. They appear in the list for both the owning and the managing organisation.<br><br>"
      end
    end

    organisations_without_logs, organisations_with_logs = merge_request.merging_organisations.partition { |organisation| organisation.send("#{type}_logs").count.zero? }
    if merge_request.absorbing_organisation.send("#{type}_logs").count.zero?
      organisations_without_logs = [merge_request.absorbing_organisation] + organisations_without_logs
    else
      organisations_with_logs = [merge_request.absorbing_organisation] + organisations_with_logs
    end

    if organisations_without_logs.any?
      text += "#{organisations_without_logs.map(&:name).to_sentence} #{organisations_without_logs.count == 1 ? 'has' : 'have'} no #{type} logs.<br><br>"
    end

    organisations_with_logs.each do |organisation|
      text += "#{link_to_merging_organisation_logs(organisation, type)}<br><br>"
    end

    text.html_safe
  end

  def link_to_merging_organisation_logs(organisation, type)
    count_text = organisation.send("#{type}_logs").count == 1 ? "1 #{organisation.name} #{type} log" : "all #{organisation.send("#{type}_logs").count} #{organisation.name} #{type} logs"
    govuk_link_to "View #{count_text} (opens in a new tab)", send("#{type}_logs_organisation_path", organisation), target: "_blank"
  end

  def lettings_logs_outcomes_header_text(merge_request)
    count = merge_request.total_visible_lettings_logs_after_merge
    "#{count} #{'lettings log'.pluralize(count)} after merge"
  end

  def sales_logs_outcomes_header_text(merge_request)
    count = merge_request.total_visible_sales_logs_after_merge
    "#{count} #{'sales log'.pluralize(count)} after merge"
  end

  def any_organisations_have_logs?(organisations, type)
    organisations.any? { |organisation| organisation.send("#{type}_logs").count.positive? }
  end

  def any_organisations_have_logs_after_merge_date?(organisations, type, merge_date)
    organisations.any? { |organisation| organisation.send("#{type}_logs").after_date(merge_date).exists? }
  end

  def any_organisations_share_logs?(organisations, type)
    organisations.any? { |organisation| organisation.send("#{type}_logs").filter_by_managing_organisation(organisations.where.not(id: organisation.id)).exists? }
  end

  def begin_merge_disabled?(merge_request)
    merge_request.status != "ready_to_merge" || merge_request.merge_date.future?
  end

  def helpdesk_ticket_value(merge_request)
    if merge_request.helpdesk_ticket.present?
      link_to("#{merge_request.helpdesk_ticket} (opens in a new tab)", "https://mhclgdigital.atlassian.net/browse/#{merge_request.helpdesk_ticket}", target: "_blank", rel: "noopener noreferrer")
    elsif merge_request.has_helpdesk_ticket == false
      "Not reported by a helpdesk ticket"
    else
      display_value_or_placeholder(nil, details_prompt_link("helpdesk_ticket", merge_request))
    end
  end
end
