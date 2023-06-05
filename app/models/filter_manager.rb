class FilterManager
  attr_reader :current_user, :session, :params, :filter_type

  def initialize(current_user:, session:, params:, filter_type:)
    @current_user = current_user
    @session = session
    @params = params
    @filter_type = filter_type
  end

  def serialize_filters_to_session(specific_org: false)
    session["#{@filter_type}_filters"] = session_filters(specific_org:).to_json
  end

  def session_filters(specific_org: false)
    @session_filters ||= deserialize_filters_from_session(specific_org)
  end

  def deserialize_filters_from_session(specific_org)
    current_filters = session["#{@filter_type}_filters"]
    new_filters = current_filters.present? ? JSON.parse(current_filters) : {}
    if @filter_type.include?("logs")
      current_user.logs_filters(specific_org:).each do |filter|
        new_filters[filter] = params[filter] if params[filter].present?
      end
    end
    params["organisation_select"] == "all" ? new_filters.except("organisation") : new_filters
  end

  def filtered_logs(logs, search_term, filters)
    all_orgs = params["organisation_select"] == "all"
    FilterService.filter_logs(logs, search_term, filters, all_orgs, current_user)
  end
end
