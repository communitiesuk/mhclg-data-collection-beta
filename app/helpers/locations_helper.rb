module LocationsHelper
  def mobility_type_selection
    mobility_types_to_display = Location.mobility_types.excluding("Property designed to accessible general standard", "Missing")
    mobility_types_to_display.map { |key, value| OpenStruct.new(id: key, name: key.to_s.humanize, description: I18n.t("questions.descriptions.location.mobility_type.#{value}")) }
  end

  def another_location_selection
    selection_options(%w[Yes No])
  end

  def location_editable_attributes
    %w[postcode name units type_of_unit mobility_standards]
  end

  def type_of_units_selection
    selection_options(Location.type_of_units)
  end

  def local_authorities_selection
    null_option = [OpenStruct.new(id: "", name: "Select an option")]
    null_option + Location.local_authorities_for_current_year.map { |code, name| OpenStruct.new(code:, name:) }
  end

  def selection_options(resource)
    return [] if resource.blank?

    resource.map { |key, _| OpenStruct.new(id: key, name: key.to_s.humanize) }
  end

  def display_location_attributes(location)
    [
      { name: "Postcode", value: location.postcode, attribute: "postcode" },
      { name: "Location name", value: location.name, attribute: "name" },
      { name: "Status", value: location.status, attribute: "status" },
      { name: "Local authority", value: formatted_local_authority_timeline(location), attribute: "local_authority" },
      { name: "Number of units", value: location.units, attribute: "units" },
      { name: "Most common unit", value: location.type_of_unit, attribute: "type_of_unit" },
      { name: "Mobility standards", value: location.mobility_type, attribute: "mobility_standards" },
      { name: "Location code", value: location.id, attribute: "id" },
      { name: "Availability", value: location_availability(location), attribute: "availability" },
    ]
  end

  def display_location_attributes_for_check_answers(location)
    [
      { name: "Postcode", value: location.postcode, attribute: "postcode" },
      { name: "Location name", value: location.name, attribute: "name" },
      { name: "Local authority", value: formatted_local_authority_timeline(location), attribute: "local_authority" },
      { name: "Number of units", value: location.units, attribute: "units" },
      { name: "Most common unit", value: location.type_of_unit, attribute: "type_of_unit" },
      { name: "Mobility standards", value: location.mobility_type, attribute: "mobility_standards" },
      { name: "Availability", value: location&.startdate&.to_formatted_s(:govuk_date), attribute: "availability" },
    ]
  end

  def location_availability(location)
    availability = ""
    location_active_periods(location).each do |period|
      if period.from.present?
        availability << "\nActive from #{period.from.to_formatted_s(:govuk_date)}"
        availability << " to #{(period.to - 1.day).to_formatted_s(:govuk_date)}\nDeactivated on #{period.to.to_formatted_s(:govuk_date)}" if period.to.present?
      end
    end
    availability.strip
  end

  def location_edit_path(location, attribute)
    send("scheme_location_#{attribute}_path", location.scheme, location, referrer: "check_answers", route: params[:route])
  end

  def location_action_text(attr, location)
    return "" if attr[:value].blank? || (attr[:attribute] == "availability" && location.startdate.blank?)

    "Change"
  end

  def location_action_link(attr, scheme, location, current_user)
    return unless LocationPolicy.new(current_user, location).update?
    return unless current_user.support? && attr[:value].present?

    paths = {
      "postcode" => scheme_location_postcode_path(scheme, location, referrer: "details"),
      "name" => scheme_location_name_path(scheme, location, referrer: "details"),
      "units" => scheme_location_units_path(scheme, location, referrer: "details"),
      "type_of_unit" => scheme_location_type_of_unit_path(scheme, location, referrer: "details"),
      "mobility_standards" => scheme_location_mobility_standards_path(scheme, location, referrer: "details"),
    }

    paths[attr[:attribute]]
  end

  def toggle_location_link(location)
    return govuk_button_link_to "Deactivate this location", scheme_location_new_deactivation_path(location.scheme, location), warning: true if location.active? || location.deactivates_in_a_long_time?
    return govuk_button_link_to "Reactivate this location", scheme_location_new_reactivation_path(location.scheme, location) if location.deactivated? && !location.deactivated_by_scheme?
  end

  def delete_location_link(location)
    govuk_button_link_to "Delete this location", scheme_location_delete_confirmation_path(location.scheme, location), warning: true
  end

  def location_creation_success_notice(location)
    if location.confirmed
      "#{location.postcode} #{location.startdate.blank? || location.startdate.before?(Time.zone.now) ? 'has been' : 'will be'} added to this scheme"
    end
  end

  def user_can_edit_scheme?(user, scheme)
    user.support? || user.organisation == scheme.owning_organisation
  end

  def edit_location_text(scheme, user)
    if user.data_provider?
      "If you think this location should be updated, ask a data coordinator to make the changes. Find your data coordinators on the #{link_to('users page', users_path)}.".html_safe
    elsif user.data_coordinator? && user.organisation.parent_organisations.include?(scheme.owning_organisation)
      "This location belongs to your stock owner #{scheme.owning_organisation.name}."
    end
  end

  def location_details_link_message(attribute)
    text = lowercase_first_letter(attribute[:name])
    return "Select #{text}" if %w[local_authority type_of_unit mobility_standards].include?(attribute[:attribute])
    return "Set #{text}" if attribute[:attribute] == "availability"

    "Enter #{text}"
  end

private

  ActivePeriod = Struct.new(:from, :to)
  def location_active_periods(location)
    periods = [ActivePeriod.new(location.available_from, nil)]
    location_deactivation_periods = location_deactivation_periods(location)
    scheme_deactivation_periods = scheme_deactivation_periods(location, location_deactivation_periods)

    combined_deactivation_periods = location_deactivation_periods + scheme_deactivation_periods
    sorted_deactivation_periods = combined_deactivation_periods.sort_by(&:deactivation_date)

    update_periods_with_deactivations(periods, sorted_deactivation_periods)
    remove_overlapping_and_empty_periods(periods)
  end

  def location_deactivation_periods(location)
    periods = remove_nested_periods(location.location_deactivation_periods.sort_by(&:deactivation_date))
    periods.last&.deactivation_date if periods.last&.reactivation_date.nil?
    periods
  end

  def scheme_deactivation_periods(location, location_deactivation_periods)
    return [] unless location.scheme.scheme_deactivation_periods.any?

    location_deactivation_date = location_deactivation_periods.last&.deactivation_date
    periods = remove_nested_periods(location.scheme.scheme_deactivation_periods.sort_by(&:deactivation_date))
    periods.select do |period|
      period.deactivation_date >= location.available_from && (location_deactivation_date.nil? || period.deactivation_date <= location_deactivation_date)
    end
  end

  def update_periods_with_deactivations(periods, sorted_deactivation_periods)
    sorted_deactivation_periods.each do |deactivation|
      periods.last.to = deactivation.deactivation_date
      periods << ActivePeriod.new(deactivation.reactivation_date, nil)
    end
  end

  def remove_overlapping_and_empty_periods(periods)
    periods.select { |period| period.from.present? && (period.to.nil? || period.from < period.to) }
  end

  def remove_nested_periods(periods)
    periods.select { |inner_period| periods.none? { |outer_period| is_nested?(inner_period, outer_period) } }
  end

  def is_nested?(inner, outer)
    return false if inner == outer
    return false if [inner.deactivation_date, inner.reactivation_date, outer.deactivation_date, outer.reactivation_date].any?(&:blank?)

    [inner.deactivation_date, inner.reactivation_date].all? { |date| date.between?(outer.deactivation_date, outer.reactivation_date) }
  end

  def formatted_local_authority_timeline(location)
    sorted_linked_authorities = location.linked_local_authorities.sort_by(&:start_date)
    return sorted_linked_authorities.first["name"] if sorted_linked_authorities.count == 1

    sorted_linked_authorities.map { |linked_local_authority|
      formatted_start_date = linked_local_authority.start_date.year == 2021 ? "until" : "#{linked_local_authority.start_date&.to_formatted_s(:govuk_date)} -"
      formatted_end_date = linked_local_authority.end_date&.to_formatted_s(:govuk_date) || "present"
      "#{linked_local_authority['name']} (#{formatted_start_date} #{formatted_end_date})"
    }.join("\n")
  end
end
