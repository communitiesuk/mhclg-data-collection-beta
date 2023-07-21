class FilterManager
  attr_reader :current_user, :session, :params, :filter_type

  def initialize(current_user:, session:, params:, filter_type:)
    @current_user = current_user
    @session = session
    @params = params
    @filter_type = filter_type
  end

  def self.filter_by_search(base_collection, search_term = nil)
    if search_term.present?
      base_collection.search_by(search_term)
    else
      base_collection
    end
  end

  def self.filter_logs(logs, search_term, filters, all_orgs, user)
    logs = filter_by_search(logs, search_term)

    filters.each do |category, values|
      next if Array(values).reject(&:empty?).blank?
      next if category == "owning_organisation" && all_orgs
      next if category == "managing_organisation" && all_orgs
      next if category == "assigned_to"

      logs = logs.public_send("filter_by_#{category}", values, user)
    end
    logs = logs.order(created_at: :desc)
    if user.support?
      if logs.first&.lettings?
        logs.all.includes(:owning_organisation, :managing_organisation)
      else
        logs.all.includes(:owning_organisation)
      end
    else
      logs
    end
  end

  def self.filter_users(users, search_term, filters, user)
    users = filter_by_search(users, search_term)

    filters.each do |category, values|
      next if Array(values).reject(&:empty?).blank?

      users = users.public_send("filter_by_#{category}", values, user)
    end
    users
  end

  def serialize_filters_to_session(specific_org: false)
    session[session_name_for(filter_type)] = session_filters(specific_org:).to_json
  end

  def session_filters(specific_org: false)
    @session_filters ||= deserialize_filters_from_session(specific_org)
  end

  def deserialize_filters_from_session(specific_org)
    current_filters = session[session_name_for(filter_type)]
    new_filters = current_filters.present? ? JSON.parse(current_filters) : {}
    if @filter_type.include?("logs")
      current_user.logs_filters(specific_org:).each do |filter|
        new_filters[filter] = params[filter] if params[filter].present?
      end

      new_filters = new_filters.except("owning_organisation") if params["owning_organisation_select"] == "all"
      new_filters = new_filters.except("managing_organisation") if params["managing_organisation_select"] == "all"

      new_filters = new_filters.except("user") if params["assigned_to"] == "all"
      new_filters["user"] = current_user.id.to_s if params["assigned_to"] == "you"
    end

    if @filter_type.include?("users") && params["status"].present?
      new_filters["status"] = params["status"]
    end

    new_filters
  end

  def filtered_logs(logs, search_term, filters)
    all_orgs = params["managing_organisation_select"] == "all" && params["owning_organisation_select"] == "all"

    FilterManager.filter_logs(logs, search_term, filters, all_orgs, current_user)
  end

  def filtered_users(users, search_term, filters)
    FilterManager.filter_users(users, search_term, filters, current_user)
  end

  def bulk_upload
    id = (logs_filters["bulk_upload_id"] || []).reject(&:blank?)[0]
    @bulk_upload ||= current_user.bulk_uploads.find_by(id:)
  end

private

  def logs_filters
    JSON.parse(session[session_name_for(filter_type)] || "{}") || {}
  end

  def session_name_for(filter_type)
    "#{filter_type}_filters"
  end
end
