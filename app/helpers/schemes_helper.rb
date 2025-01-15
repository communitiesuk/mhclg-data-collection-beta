module SchemesHelper
  def scheme_availability(scheme)
    availability = ""
    scheme_active_periods(scheme).each do |period|
      if period.from.present?
        availability << "\nActive from #{period.from.to_formatted_s(:govuk_date)}"
        availability << " to #{(period.to - 1.day).to_formatted_s(:govuk_date)}\nDeactivated on #{period.to.to_formatted_s(:govuk_date)}" if period.to.present?
      end
    end
    availability.strip
  end

  def toggle_scheme_link(scheme)
    return govuk_button_link_to "Deactivate this scheme", scheme_new_deactivation_path(scheme), warning: true if scheme.active? || scheme.deactivates_in_a_long_time?
    return govuk_button_link_to "Reactivate this scheme", scheme_new_reactivation_path(scheme) if scheme.deactivated? || scheme.deactivating_soon?
  end

  def delete_scheme_link(scheme)
    govuk_button_link_to "Delete this scheme", scheme_delete_confirmation_path(scheme), warning: true
  end

  def owning_organisation_options(current_user)
    if current_user.support?
      Organisation.visible.map { |org| OpenStruct.new(id: org.id, name: org.name) }
    else
      user_org = [current_user.organisation]
      stock_owners = current_user.organisation.stock_owners.visible.filter { |org| org.status == :active || (org.status == :merged && org.merge_date >= FormHandler.instance.start_date_of_earliest_open_for_editing_collection_period) }
      merged_organisations = current_user.organisation.absorbed_organisations.visible.merged_during_open_collection_period
      (user_org + stock_owners + merged_organisations).map { |org| OpenStruct.new(id: org.id, name: org.name) }
    end
  end

  def null_option
    [OpenStruct.new(id: "", name: "Select an option")]
  end

  def edit_scheme_text(scheme, user)
    if user.data_provider?
      "If you think this scheme should be updated, ask a data coordinator to make the changes. Find your data coordinators on the #{link_to('users page', users_path)}.".html_safe
    elsif user.data_coordinator? && user.organisation.parent_organisations.include?(scheme.owning_organisation)
      "This scheme belongs to your stock owner #{scheme.owning_organisation.name}."
    end
  end

  def selected_schemes_and_locations_text(download_type, schemes)
    scheme_count = schemes.count
    case download_type
    when "schemes"
      "You've selected #{pluralize(scheme_count, 'scheme')}."
    when "locations"
      location_count = Location.where(scheme: schemes).count
      "You've selected #{pluralize(location_count, 'location')} from #{pluralize(scheme_count, 'scheme')}."
    when "combined"
      location_count = Location.where(scheme: schemes).count
      "You've selected #{pluralize(scheme_count, 'scheme')} with #{pluralize(location_count, 'location')}. The CSV will have one location per row with scheme details listed for each location."
    end
  end

  def primary_schemes_csv_download_url(search, download_type)
    csv_download_schemes_path(search:, download_type:)
  end

  def secondary_schemes_csv_download_url(organisation, search, download_type)
    schemes_csv_download_organisation_path(organisation, search:, download_type:)
  end

  def scheme_edit_path(scheme, question_id, user = nil)
    case question_id
    when "service_name", "sensitive", "scheme_type", "registered_under_care_act", "owning_organisation_id", "arrangement_type"
      user&.support? || !scheme.confirmed? ? scheme_details_path(scheme, referrer: "check-answers") : scheme_edit_name_path(scheme)
    when "primary_client_group"
      scheme_primary_client_group_path(scheme, referrer: "check-answers")
    when "has_other_client_group"
      scheme_confirm_secondary_client_group_path(scheme, referrer: "check-answers")
    when "secondary_client_group"
      scheme_secondary_client_group_path(scheme, referrer: "check-answers")
    when "support_type", "intended_stay"
      scheme_support_path(scheme, referrer: "check-answers")
    end
  end

  def change_link_text(question_id, scheme)
    return "" if scheme.public_send(question_id).nil?

    "Change"
  end

  def scheme_status_hint(scheme)
    case scheme.status
    when :deactivating_soon
      "This scheme deactivates on #{scheme.last_deactivation_date.to_formatted_s(:govuk_date)}. Any locations you add will be deactivated on the same date. Reactivate the scheme to add locations active after this date."
    when :deactivated
      case scheme.owning_organisation.status
      when :active
        "This scheme deactivated on #{scheme.last_deactivation_date.to_formatted_s(:govuk_date)}. Any locations you add will be deactivated on the same date. Reactivate the scheme to add locations active after this date."
      when :merged
        "This scheme has been deactivated due to #{scheme.owning_organisation.name} merging into #{scheme.owning_organisation.absorbing_organisation.name} on #{scheme.owning_organisation.merge_date.to_formatted_s(:govuk_date)}. Any locations you add will be deactivated on the same date. Use the after merge organisation for schemes and locations active after this date."
      end
    end
  end

  def display_duplicate_schemes_banner?(organisation, current_user)
    return unless organisation.absorbed_organisations.merged_during_open_collection_period.any?
    return unless current_user.data_coordinator? || current_user.support?
    return if organisation.schemes_deduplicated_at.present? && organisation.schemes_deduplicated_at > organisation.absorbed_organisations.map(&:merge_date).max

    organisation.owned_schemes.duplicate_sets.any? || organisation.owned_schemes.any? { |scheme| scheme.locations.duplicate_sets.any? }
  end

  def scheme_details_link_message(attribute)
    text = lowercase_first_letter(attribute[:name])
    return "Select #{text}" if %w[primary_client_group secondary_client_group support_type intended_stay].include?(attribute[:id])
    return "Tell us if it #{text}" if attribute[:id] == "has_other_client_group"

    "Enter #{text}"
  end

  def scheme_back_button_path(scheme, current_page)
    return scheme_check_answers_path(scheme) if request.params[:referrer] == "check-answers"
    return scheme_confirm_secondary_client_group_path(scheme, referrer: "check-answers") if request.params[:referrer] == "has-other-client-group"

    case current_page
    when "details"
      schemes_path
    when "primary_client_group"
      scheme_details_path(scheme)
    when "confirm_secondary_client_group"
      scheme_primary_client_group_path(scheme)
    when "secondary_client_group"
      scheme_confirm_secondary_client_group_path(scheme)
    when "support"
      scheme.has_other_client_group == "Yes" ? scheme_secondary_client_group_path(scheme) : scheme_confirm_secondary_client_group_path(scheme)
    end
  end

private

  ActivePeriod = Struct.new(:from, :to)
  def scheme_active_periods(scheme)
    periods = [ActivePeriod.new(scheme.available_from, nil)]

    sorted_deactivation_periods = remove_nested_periods(scheme.scheme_deactivation_periods.sort_by(&:deactivation_date))
    sorted_deactivation_periods.each do |deactivation|
      periods.last.to = deactivation.deactivation_date
      periods << ActivePeriod.new(deactivation.reactivation_date, nil)
    end

    remove_overlapping_and_empty_periods(periods)
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
end
