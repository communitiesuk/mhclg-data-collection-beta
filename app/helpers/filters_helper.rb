module FiltersHelper
  def filter_selected?(filter, value, filter_type)
    return false unless session[session_name_for(filter_type)]

    selected_filters = JSON.parse(session[session_name_for(filter_type)])
    return true if selected_filters.blank? && filter == "user" && value == :all
    return true if !selected_filters.key?("organisation") && filter == "organisation_select" && value == :all
    return true if selected_filters["organisation"].present? && filter == "organisation_select" && value == :specific_org
    return false if selected_filters[filter].blank?

    selected_filters[filter].include?(value.to_s)
  end

  def any_filter_selected?(filter_type)
    filters_json = session[session_name_for(filter_type)]
    return false unless filters_json

    filters = JSON.parse(filters_json)
    filters["user"] == "yours" ||
      filters["organisation"].present? ||
      filters["status"]&.compact_blank&.any? ||
      filters["years"]&.compact_blank&.any? ||
      filters["bulk_upload_id"].present?
  end

  def status_filters
    {
      "not_started" => "Not started",
      "in_progress" => "In progress",
      "completed" => "Completed",
    }.freeze
  end

  def selected_option(filter, filter_type)
    return false unless session[session_name_for(filter_type)]

    JSON.parse(session[session_name_for(filter_type)])[filter] || ""
  end

  def organisations_filter_options(user)
    organisation_options = user.support? ? Organisation.all : [user.organisation] + user.organisation.managing_agents
    [OpenStruct.new(id: "", name: "Select an option")] + organisation_options.map { |org| OpenStruct.new(id: org.id, name: org.name) }
  end

  def collection_year_options
    { "2023": "2023/24", "2022": "2022/23", "2021": "2021/22" }
  end

  def filters_applied_text(filter_type)
    applied_filters = JSON.parse(session[session_name_for(filter_type)])
    applied_filters_count = filters_count(applied_filters)
    applied_filters_count.zero? ? "No filters applied" : "#{pluralize(applied_filters_count, 'filter')} applied"
  end

  def reset_filters_link(filter_type)
    applied_filters = JSON.parse(session[session_name_for(filter_type)])
    applied_filters_count = filters_count(applied_filters)
    if applied_filters_count.positive?
      govuk_link_to "Clear", clear_filters_path(filter_type:)
    end
  end

private

  def session_name_for(filter_type)
    "#{filter_type}_filters"
  end

  def filters_count(filters)
    filters.values.sum do |category|
      if category.is_a?(String)
        category != "all" ? 1 : 0
      else
        category.count(&:present?)
      end
    end
  end
end
