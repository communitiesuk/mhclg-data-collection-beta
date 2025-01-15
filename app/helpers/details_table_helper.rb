module DetailsTableHelper
  def details_html(attribute, resource = nil)
    if attribute[:format] == :bullet && attribute[:value].length > 1
      list = attribute[:value].map { |value| "<li>#{value}</li>" }.join
      simple_format(list, { class: "govuk-list govuk-list--bullet" }, wrapper_tag: "ul")
    else
      return simple_format(attribute[:value].first.to_s, { class: "govuk-body" }, wrapper_tag: "p") if attribute[:value].is_a?(Array) && attribute[:value].any?

      value = determine_value(attribute, resource)
      simple_format(value.to_s, { class: "govuk-body" }, wrapper_tag: "p")
    end
  end

private

  def determine_value(attribute, resource)
    return attribute[:value] if attribute[:value].present?

    method_name = "#{resource.class.name.downcase}_value"
    return send(method_name, attribute, resource) if respond_to?(method_name, true)

    "<span class=\"app-!-colour-muted\">No answer provided</span>".html_safe
  end

  def location_value(attribute, resource)
    return nil unless LocationPolicy.new(current_user, resource).update?

    govuk_link_to(location_details_link_message(attribute), location_edit_path(resource, attribute[:attribute]), class: "govuk-link govuk-link--no-visited-state")
  end

  def organisation_value(attribute, resource)
    return nil unless can_edit_org?(current_user) && attribute[:editable]

    govuk_link_to(organisation_details_link_message(attribute), edit_organisation_path(resource), class: "govuk-link govuk-link--no-visited-state")
  end

  def scheme_value(attribute, resource)
    return nil unless can_change_scheme_answer?(attribute[:name], resource)

    govuk_link_to(scheme_details_link_message(attribute), scheme_edit_path(resource, attribute[:id]), class: "govuk-link govuk-link--no-visited-state")
  end
end
