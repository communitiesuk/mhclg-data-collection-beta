module DerivedVariables::SalesLogVariables
  def set_derived_fields!
    reset_invalidated_derived_values!

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
    self.deposit = value if outright_sale? && mortgage_not_used?
    self.pcode1, self.pcode2 = postcode_full.split(" ") if postcode_full.present?
    self.totchild = total_child
    self.totadult = total_adult + total_elder
    self.hhmemb = number_of_household_members
    self.hhtype = household_type

    if uprn_known&.zero?
      self.uprn = nil
    end

    if uprn_confirmed&.zero?
      self.uprn = nil
      self.uprn_known = 0
    end

    set_encoded_derived_values!
  end

private

  DEPENDENCIES = [
    {
      conditions: {
        buylivein: 2,
      },
      derived_values: {
        buy1livein: 2,
      }
    },
    {
      conditions: {
        buylivein: 2,
        jointpur: 1,
      },
      derived_values: {
        buy1livein: 2,
        buy2livein: 2,
      }
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
  ].freeze

  def reset_invalidated_derived_values!
    DEPENDENCIES.each do |dependency|
      any_conditions_changed = dependency[:conditions].any? { |attribute, _value| send("#{attribute}_changed?") }
      next unless any_conditions_changed

      previously_in_derived_state = dependency[:conditions].all? { |attribute, value| send("#{attribute}_was") == value }
      next unless previously_in_derived_state

      dependency[:derived_values].each do |derived_attribute, _derived_value|
        Rails.logger.debug("Cleared derived #{derived_attribute} value")
        send("#{derived_attribute}=", nil)
      end
    end
  end

  def set_encoded_derived_values!
    DEPENDENCIES.each do |dependency|
      derivation_applies = dependency[:conditions].all? { |attribute, value| send(attribute) == value }
      if derivation_applies
        dependency[:derived_values].each { |attribute, value| send("#{attribute}=", value) }
      end
    end
  end

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
end
