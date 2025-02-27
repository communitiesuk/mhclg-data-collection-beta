module DerivedVariables::LettingsLogVariables
  include DerivedVariables::SharedLogic

  RENT_TYPE_MAPPING = {
    0 => 1, # "Social Rent"  =>  "Social Rent"
    1 => 2, # "Affordable Rent" => "Affordable Rent"
    2 => 2, # "London Affordable Rent"  =>  "Affordable Rent"
    3 => 3, # "Rent to Buy"  => "Intermediate Rent"
    4 => 3, # "London Living Rent"  => "Intermediate Rent"
    5 => 3, # "Other intermediate rent product"  => "Intermediate Rent"
    6 => 4, # "Specified accommodation - exempt accommodation, managed properties, refuges and local authority hostels"  => "Specified accommodation"
  }.freeze

  UNITLETAS_MAPPING = {
    0 => 1, # "Social Rent"  =>  "Social Rent basis"
    1 => 2, # "Affordable Rent" => "Affordable Rent basis"
    2 => 5, # "London Affordable Rent"  =>  "London Affordable Rent basis"
    3 => 6, # "Rent to Buy"  => "Rent to Buy basis"
    4 => 7, # "London Living Rent"  => "London Living Rent basis"
    5 => 8, # "Other intermediate rent product"  => "Another Intermediate Rent basis"
    6 => 9, # "Specified accommodation - exempt accommodation, managed properties, refuges and local authority hostels"  => "Specified accommodation - exempt accommodation, manged properties, refuges and local authority hostels"
  }.freeze

  RENTTYPE_DETAIL_MAPPING = {
    0 => 1,
    1 => 2,
    2 => 3,
    3 => 4,
    4 => 5,
    5 => 6,
    6 => 7,
  }.freeze

  def set_derived_fields!
    clear_inapplicable_derived_values!
    set_encoded_derived_values!(DEPENDENCIES)

    if rsnvac.present?
      self.newprop = has_first_let_vacancy_reason? ? 1 : 2
    end
    self.renttype = RENT_TYPE_MAPPING[rent_type]
    self.lettype = get_lettype
    self.lar = get_lar
    self.irproduct = get_irproduct
    self.totchild = get_totchild
    self.totelder = get_totelder
    self.totadult = get_totadult
    self.refused = get_refused
    self.ethnic = 17 if ethnic_refused?
    if %i[brent scharge pscharge supcharg].any? { |f| public_send(f).present? }
      self.brent ||= 0
      self.scharge ||= 0
      self.pscharge ||= 0
      self.supcharg ||= 0
      self.tcharge = brent.to_f + scharge.to_f + pscharge.to_f + supcharg.to_f
    end
    if period.present?
      self.wrent = weekly_value(brent) if brent.present?
      self.wscharge = weekly_value(scharge) if scharge.present?
      self.wpschrge = weekly_value(pscharge) if pscharge.present?
      self.wsupchrg = weekly_value(supcharg) if supcharg.present?
      self.wtcharge = weekly_value(tcharge) if tcharge.present?
      self.wchchrg = weekly_value(chcharge) if is_supported_housing? && chcharge.present?
    end
    self.wtshortfall = if tshortfall && receives_housing_related_benefits? && period
                         weekly_value(tshortfall)
                       end
    self.has_benefits = get_has_benefits
    self.tshortfall_known = 0 if tshortfall
    self.nocharge = household_charge&.zero? ? 1 : 0
    if form.start_year_2024_or_later? && is_bedsit?
      self.beds = 1
    end

    clear_child_ecstat_for_age_changes!
    child_under_16_constraints!

    self.hhtype = household_type
    self.new_old = new_or_existing_tenant

    if is_supported_housing? && location
      self.wchair = location.mobility_type_before_type_cast == "W" ? 1 : 2
    end

    set_housingneeds_fields if housingneeds?

    self.uprn_known = 0 if address_answered_without_uprn?

    if uprn_known&.zero?
      self.uprn = nil
      if uprn_known_was == 1
        self.address_line1 = nil
        self.address_line2 = nil
        self.town_or_city = nil
        self.county = nil
        self.postcode_known = nil
        self.postcode_full = nil
        self.la = nil
      end
    end

    if uprn_known == 1 && uprn_confirmed&.zero?
      self.uprn = nil
      self.uprn_known = 0
      self.uprn_confirmed = nil
      self.address_line1 = nil
      self.address_line2 = nil
      self.town_or_city = nil
      self.county = nil
      self.postcode_known = nil
      self.postcode_full = nil
      self.la = nil
      self.previous_la_known = nil if is_renewal?
    end

    if form.start_year_2024_or_later?
      if manual_address_entry_selected
        self.uprn_known = 0
        self.uprn_selection = nil
        self.uprn_confirmed = nil
      else
        self.uprn_confirmed = 1 if uprn.present?
        self.uprn_known = 1 if uprn.present?
        reset_address_fields! if uprn.blank?
        if uprn_changed?
          self.uprn_selection = uprn
        end
      end
    end

    if is_renewal?
      self.underoccupation_benefitcap = 2 if collection_start_year == 2021
      self.voiddate = startdate
      self.unitletas = UNITLETAS_MAPPING[rent_type]
      if is_general_needs?
        self.prevten = 32 if owning_organisation&.provider_type == "PRP"
        self.prevten = 30 if owning_organisation&.provider_type == "LA"
      end
      self.ppostcode_full = postcode_full
      self.ppcodenk = case postcode_known
                      when 0
                        1
                      when 1
                        0
                      end
      self.is_previous_la_inferred = is_la_inferred
      self.previous_la_known = la.present? ? 1 : nil
      self.prevloc = la
    end

    self.vacdays = property_vacant_days

    self.nationality_all = nationality_all_group if nationality_uk_or_prefers_not_to_say?

    if startdate_changed? && !LocalAuthority.active(startdate).where(code: la).exists?
      self.la = nil
      self.is_la_inferred = false
    end

    reset_address_fields! if is_supported_housing?

    set_checkbox_values!
  end

private

  DEPENDENCIES = [
    {
      conditions: {
        renewal: 1,
      },
      derived_values: {
        referral: 1,
        waityear: 2,
        offered: 0,
        rsnvac: 14,
        first_time_property_let_as_social_housing: 0,
      },
    },
    {
      conditions: {
        net_income_known: 2,
      },
      derived_values: {
        incref: 1,
      },
    },
    {
      conditions: {
        net_income_known: 0,
      },
      derived_values: {
        incref: 0,
      },
    },
    {
      conditions: {
        net_income_known: 1,
      },
      derived_values: {
        incref: 2,
      },
    },
  ].freeze

  def clear_inapplicable_derived_values!
    reset_invalidated_derived_values!(DEPENDENCIES)
    if (startdate_changed? || renewal_changed?) && (renewal_was == 1 && startdate_was&.between?(Time.zone.local(2021, 4, 1), Time.zone.local(2022, 3, 31)))
      self.underoccupation_benefitcap = nil
    end
    if renewal_changed? && renewal_was == 1
      self.voiddate = nil
      self.unitletas = nil
    end
    if %w[PRP LA].include?(managing_organisation&.provider_type) &&
        (needstype_changed? || renewal_changed?) &&
        needstype_was == 1 && renewal_was == 1
      self.prevten = nil
    end
    if needstype_changed? && needstype_was == 2
      self.wchair = nil
      self.location_id = nil
    end
    if form.start_year_2024_or_later? && (unittype_gn_changed? && unittype_gn_was == 2)
      self.beds = nil
    end
  end

  def get_totelder
    ages = [age1, age2, age3, age4, age5, age6, age7, age8]
    ages.count { |x| !x.nil? && x >= 60 }
  end

  def get_totchild
    relationships = [relat2, relat3, relat4, relat5, relat6, relat7, relat8]
    relationships.count("C")
  end

  def get_totadult
    total = !age1.nil? && age1 >= 16 && age1 < 60 ? 1 : 0
    total + (2..8).count do |i|
      age = public_send("age#{i}")
      relat = public_send("relat#{i}")
      !age.nil? && ((age >= 16 && age < 18 && %w[P X].include?(relat)) || age >= 18 && age < 60)
    end
  end

  def get_refused
    return 1 if details_unknown? || age_refused? || sex_refused? || relat_refused? || ecstat_refused?

    0
  end

  def child_under_16_constraints!
    (2..8).each do |idx|
      if age_under_16?(idx)
        self["ecstat#{idx}"] = 9
      end
    end
  end

  def clear_child_ecstat_for_age_changes!
    (2..8).each do |idx|
      if public_send("age#{idx}_changed?") && self["ecstat#{idx}"] == 9
        self["ecstat#{idx}"] = nil
      end
    end
  end

  def household_type
    return unless totelder && totadult && totchild

    if only_one_elder?
      1
    elsif two_adults_including_elders?
      2
    elsif only_one_adult?
      3
    elsif only_two_adults?
      4
    elsif one_adult_with_at_least_one_child?
      5
    elsif two_adults_with_at_least_one_child?
      6
    else
      9
    end
  end

  def two_adults_with_at_least_one_child?
    totelder.zero? && totadult >= 2 && totchild >= 1
  end

  def one_adult_with_at_least_one_child?
    totelder.zero? && totadult == 1 && totchild >= 1
  end

  def only_two_adults?
    totelder.zero? && totadult == 2 && totchild.zero?
  end

  def only_one_adult?
    totelder.zero? && totadult == 1 && totchild.zero?
  end

  def two_adults_including_elders?
    (totelder + totadult) == 2 && totelder >= 1
  end

  def only_one_elder?
    totelder == 1 && totadult.zero? && totchild.zero?
  end

  def new_or_existing_tenant
    return unless startdate

    referral_within_sector = [1, 10]
    previous_social_tenancies = if collection_start_year <= 2021
                                  [6, 8, 30, 31, 32, 33]
                                else
                                  [6, 30, 31, 32, 33, 34, 35]
                                end

    if previous_social_tenancies.include?(prevten) || referral_within_sector.include?(referral)
      2 # Tenant existing in social housing sector
    else
      1 # Tenant new to social housing sector
    end
  end

  def property_vacant_days
    return unless startdate

    if mrcdate.present?
      startdate.to_date - mrcdate.to_date
    elsif voiddate.present?
      startdate.to_date - voiddate.to_date
    end
  end

  def reset_scheme_location!
    self.location = nil
    if scheme && scheme.locations.active_in_2_weeks.size == 1
      self.location = scheme.locations.active_in_2_weeks.first
    end
  end

  def set_housingneeds_fields
    self.housingneeds_a = fully_wheelchair_accessible? ? 1 : 0
    self.housingneeds_b = essential_wheelchair_access? ? 1 : 0
    self.housingneeds_c = level_access_housing? ? 1 : 0
    self.housingneeds_f = other_housingneeds? ? 1 : 0
    set_housingneeds_values_to_zero unless has_housingneeds?
    self.housingneeds_g = no_housingneeds? ? 1 : 0
    self.housingneeds_h = unknown_housingneeds? ? 1 : 0
  end

  def set_housingneeds_values_to_zero
    self.housingneeds_a = 0
    self.housingneeds_b = 0
    self.housingneeds_c = 0
    self.housingneeds_f = 0
    self.housingneeds_g = 0
    self.housingneeds_h = 0
  end

  def reset_address_fields!
    self.uprn = nil
    self.uprn_known = nil
    self.uprn_confirmed = nil
    self.address_line1 = nil
    self.address_line2 = nil
    self.town_or_city = nil
    self.county = nil
  end

  def address_answered_without_uprn?
    [address_line1, town_or_city].all?(&:present?) && uprn.nil?
  end

  def get_lar
    return 1 if rent_type == 2
    return 2 if rent_type == 1
  end

  def get_irproduct
    return 1 if rent_type == 3
    return 2 if rent_type == 4
    return 3 if rent_type == 5
  end

  def set_checkbox_values!
    form.questions.select { |q| q.type == "checkbox" }.each do |question|
      options = question.answer_keys_without_dividers
      next unless options.any? { |option| self[option] == 1 }

      options.each do |option|
        if self[option].nil?
          self[option] = 0
        end
      end
    end
  end
end
