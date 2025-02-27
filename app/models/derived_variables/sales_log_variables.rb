module DerivedVariables::SalesLogVariables
  include DerivedVariables::SharedLogic

  def set_derived_fields!
    reset_invalidated_derived_values!(DEPENDENCIES)

    self.pregblank = 1 if no_buyer_organisation?
    self.ethnic = 17 if ethnic_refused?
    self.mscharge = nil if no_monthly_leasehold_charges?
    if exdate.present?
      self.exday = exdate.day
      self.exmonth = exdate.month
      self.exyear = exdate.year
    end
    if hodate.present?
      self.hoday = hodate.day
      self.homonth = hodate.month
      self.hoyear = hodate.year
    end

    if outright_sale?
      if mortgage_not_used?
        self.deposit = value
      elsif mortgage_use_unknown?
        self.deposit = nil
      elsif mortgageused_changed?(from: 2, to: 1)
        # Clear when switching mortgage used from no to yes
        self.deposit = nil
      end
    end

    if saledate && form.start_year_2024_or_later? && discounted_ownership_sale?
      self.ppostcode_full = postcode_full
      self.ppcodenk = pcodenk
      self.prevloc = la
      self.is_previous_la_inferred = is_la_inferred
      self.previous_la_known = la_known
    end

    self.pcode1, self.pcode2 = postcode_full.split if postcode_full.present?
    self.ppostc1, self.ppostc2 = ppostcode_full.split if ppostcode_full.present?
    self.totchild = total_child
    self.totadult = total_adult + total_elder
    self.hhmemb = number_of_household_members
    self.hhtype = household_type

    if saledate && form.start_year_2024_or_later?
      self.soctenant = soctenant_from_prevten_values
      clear_child_ecstat_for_age_changes!
      child_under_16_constraints!
    end

    self.uprn_known = 0 if address_answered_without_uprn?

    if uprn_known&.zero?
      self.uprn = nil
      if uprn_known_was == 1
        reset_address_fields!
      end
    end

    if uprn_known == 1 && uprn_confirmed&.zero?
      reset_address_fields!
      self.uprn_known = 0
      self.uprn_confirmed = nil
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

    if form.start_year_2025_or_later? && is_bedsit?
      self.beds = 1
    end

    self.nationality_all = nationality_all_group if nationality_uk_or_prefers_not_to_say?
    self.nationality_all_buyer2 = nationality_all_buyer2_group if nationality2_uk_or_prefers_not_to_say?

    if saledate_changed? && !LocalAuthority.active(saledate).where(code: la).exists?
      self.la = nil
      self.is_la_inferred = false
    end

    self.numstair = is_firststair? ? 1 : nil if numstair == 1 && firststair_changed?
    self.mrent = 0 if stairowned_100?

    set_encoded_derived_values!(DEPENDENCIES)
  end

private

  DEPENDENCIES = [
    {
      conditions: {
        buylivein: 2,
      },
      derived_values: {
        buy1livein: 2,
      },
    },
    {
      conditions: {
        buylivein: 2,
        jointpur: 1,
      },
      derived_values: {
        buy1livein: 2,
        buy2livein: 2,
      },
    },
    {
      conditions: {
        buylivein: 1,
        jointpur: 2,
      },
      derived_values: {
        buy1livein: 1,
      },
    },
    {
      conditions: {
        mortgageused: 2,
      },
      derived_values: {
        mortgage: 0,
      },
    },
    {
      conditions: {
        mortgageused: 3,
      },
      derived_values: {
        mortgage: nil,
      },
    },
  ].freeze

  def number_of_household_members
    return unless hholdcount.present? && jointpur.present?

    number_of_buyers = joint_purchase? ? 2 : 1
    hholdcount + number_of_buyers
  end

  def total_elder
    ages = [age1, age2, age3, age4, age5, age6]
    ages.count { |age| age.present? && age >= 60 }
  end

  def total_child
    (2..6).count do |i|
      age = public_send("age#{i}")
      relat = public_send("relat#{i}")
      age.present? && (age < 20 && %w[C].include?(relat) || age < 18)
    end
  end

  def total_adult
    total = age1.present? && age1.between?(16, 59) ? 1 : 0
    total + (2..6).count do |i|
      age = public_send("age#{i}")
      relat = public_send("relat#{i}")
      age.present? && (age.between?(20, 59) || age.between?(18, 19) && relat != "C")
    end
  end

  def child_under_16_constraints!
    start_index = joint_purchase? ? 3 : 2
    (start_index..6).each do |idx|
      if age_under_16?(idx)
        self["ecstat#{idx}"] = 9
      end
    end
  end

  def clear_child_ecstat_for_age_changes!
    start_index = joint_purchase? ? 3 : 2
    (start_index..6).each do |idx|
      if public_send("age#{idx}_changed?") && self["ecstat#{idx}"] == 9
        self["ecstat#{idx}"] = nil
      end
    end
  end

  def household_type
    return unless total_elder && total_adult && totchild

    if only_one_elder?
      1
    elsif only_two_elders?
      2
    elsif only_one_adult?
      3
    elsif only_two_adults?
      4
    elsif one_adult_with_at_least_one_child?
      5
    elsif at_least_two_adults_with_at_least_one_child?
      6
    else
      9
    end
  end

  def at_least_two_adults_with_at_least_one_child?
    total_elder.zero? && total_adult >= 2 && totchild >= 1
  end

  def one_adult_with_at_least_one_child?
    total_elder.zero? && total_adult == 1 && totchild >= 1
  end

  def only_two_adults?
    total_elder.zero? && total_adult == 2 && totchild.zero?
  end

  def only_one_adult?
    total_elder.zero? && total_adult == 1 && totchild.zero?
  end

  def only_two_elders?
    total_elder == 2 && total_adult.zero? && totchild.zero?
  end

  def only_one_elder?
    total_elder == 1 && total_adult.zero? && totchild.zero?
  end

  def address_answered_without_uprn?
    [address_line1, town_or_city].all?(&:present?) && uprn.nil?
  end

  def soctenant_from_prevten_values
    return unless prevten && shared_ownership_scheme?

    prevten_was_social_housing? ? 1 : 2
  end

  def prevten_was_social_housing?
    [1, 2].include?(prevten) || [1, 2].include?(prevtenbuy2)
  end

  def reset_address_fields!
    self.uprn = nil
    self.uprn_known = nil
    self.address_line1 = nil
    self.address_line2 = nil
    self.town_or_city = nil
    self.county = nil
    self.pcode1 = nil
    self.pcode2 = nil
    self.pcodenk = nil
    self.address_line1_input = nil
    self.postcode_full_input = nil
    self.postcode_full = nil
    self.is_la_inferred = nil
    self.la = nil
  end
end
