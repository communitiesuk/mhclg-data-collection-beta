module Validations::HouseholdValidations
  include Validations::SharedValidations

  # Validations methods need to be called 'validate_<page_name>' to run on model save
  # or 'validate_' to run on submit as well
  def validate_reasonable_preference(record)
    if !record.given_reasonable_preference? && [record.rp_homeless, record.rp_insan_unsat, record.rp_medwel, record.rp_hardship, record.rp_dontknow].any? { |a| a == 1 }
      record.errors.add :reasonable_preference_reason, I18n.t("validations.lettings.household.reasonable_preference_reason.reason_not_required")
    end
  end

  PHRASES_INDICATING_HOMELESSNESS = [
    "Homeless",
    "Homelessness",
    "Temporary accommodation",
    "Temp accommodation",
    "TA",
    "Sleeping rough",
    "Rough sleeping",
  ].freeze

  PHRASES_INDICATING_HOMELESSNESS_REGEX = Regexp.union(
    PHRASES_INDICATING_HOMELESSNESS.map { |phrase| Regexp.new("\\A[^[:alpha:]]*#{phrase}[^[:alpha:]]*\\Z", Regexp::IGNORECASE) },
  )

  def validate_reason_for_leaving_last_settled_home(record)
    if record.reason == 32 && record.underoccupation_benefitcap != 4
      record.errors.add :underoccupation_benefitcap, I18n.t("validations.lettings.household.underoccupation_benefitcap.leaving_last_settled_home.dont_know_required")
      record.errors.add :reason, I18n.t("validations.lettings.household.reason.leaving_last_settled_home.dont_know_required")
    end
    validate_other_field(record, 20, :reason, :reasonother)

    if record.is_reason_permanently_decanted? && record.referral.present? && !record.is_internal_transfer?
      record.errors.add :referral, I18n.t("validations.lettings.household.referral.leaving_last_settled_home.reason_permanently_decanted")
      record.errors.add :referral_type, I18n.t("validations.lettings.household.referral.leaving_last_settled_home.reason_permanently_decanted")
      record.errors.add :reason, I18n.t("validations.lettings.household.reason.leaving_last_settled_home.not_internal_transfer")
    end

    return unless record.form.start_year_2024_or_later?

    if record.reason == 20 && PHRASES_INDICATING_HOMELESSNESS_REGEX.match?(record.reasonother)
      record.errors.add :reason, I18n.t("validations.lettings.household.reason.leaving_last_settled_home.other_not_settled")
    end
  end

  def validate_armed_forces(record)
    if (record.armed_forces_no? || record.armed_forces_refused?) && record.reservist.present?
      record.errors.add :reservist, I18n.t("validations.lettings.household.reservist.injury_not_required")
    end
    if !record.armed_forces_regular? && record.leftreg.present?
      record.errors.add :leftreg, I18n.t("validations.lettings.household.leftreg.question_not_required")
    end
  end

  def validate_partner_count(record)
    return if record.form.start_year_2024_or_later?

    partner_numbers = (2..8).select { |n| person_is_partner?(record["relat#{n}"]) }
    if partner_numbers.count > 1
      partner_numbers.each do |n|
        record.errors.add "relat#{n}", I18n.t("validations.lettings.household.relat.one_partner")
      end
    end
  end

  def validate_person_1_economic(record)
    return unless record.age1 && record.ecstat1 && !record.form.start_year_2024_or_later?

    if record.age1 < 16 && !economic_status_is_child_other_or_refused?(record.ecstat1)
      record.errors.add "ecstat1", I18n.t("validations.lettings.household.ecstat.child_under_16", person_num: 1)
      record.errors.add "age1", I18n.t("validations.lettings.household.age.child_under_16_ecstat", person_num: 1)
    end
    if tenant_is_economic_child?(record.ecstat1) && record.age1 > 16
      record.errors.add "ecstat1", I18n.t("validations.lettings.household.ecstat.child_over_16", person_num: 1)
      record.errors.add "age1", I18n.t("validations.lettings.household.age.child_over_16", person_num: 1)
    end
  end

  def validate_person_age_matches_economic_status(record)
    (2..8).each do |person_num|
      age = record.public_send("age#{person_num}")
      economic_status = record.public_send("ecstat#{person_num}")
      next unless age && economic_status

      if age < 16 && !economic_status_is_child_other_or_refused?(economic_status) && !record.form.start_year_2024_or_later?
        record.errors.add "ecstat#{person_num}", I18n.t("validations.lettings.household.ecstat.child_under_16", person_num:)
        record.errors.add "age#{person_num}", I18n.t("validations.lettings.household.age.child_under_16_ecstat", person_num:)

      end
      if tenant_is_economic_child?(economic_status) && age > 16
        record.errors.add "ecstat#{person_num}", I18n.t("validations.lettings.household.ecstat.child_over_16", person_num:)
        record.errors.add "age#{person_num}", I18n.t("validations.lettings.household.age.child_over_16", person_num:)
      end
    end
  end

  def validate_person_age_matches_relationship(record)
    return unless record.startdate && !record.form.start_year_2024_or_later?

    (2..8).each do |person_num|
      age = record.public_send("age#{person_num}")
      relationship = record.public_send("relat#{person_num}")
      next unless age && relationship

      if age < 16 && !relationship_is_child_other_or_refused?(relationship)
        record.errors.add "relat#{person_num}", I18n.t("validations.lettings.household.relat.child_under_16", person_num:)
        record.errors.add "age#{person_num}", I18n.t("validations.lettings.household.age.child_under_16_relat", person_num:)
      end
    end
  end

  def validate_person_age_and_relationship_matches_economic_status(record)
    return unless record.startdate && !record.form.start_year_2024_or_later?

    (2..8).each do |person_num|
      age = record.public_send("age#{person_num}")
      economic_status = record.public_send("ecstat#{person_num}")
      relationship = record.public_send("relat#{person_num}")
      next unless age && economic_status && relationship

      age_between_16_19 = age.between?(16, 19)
      student = tenant_is_fulltime_student?(economic_status)
      economic_status_refused = tenant_economic_status_refused?(economic_status)
      child = tenant_is_child?(relationship)

      if age_between_16_19 && !(student || economic_status_refused) && child
        record.errors.add "ecstat#{person_num}", I18n.t("validations.lettings.household.ecstat.student_16_19.must_be_student")
        record.errors.add "age#{person_num}", I18n.t("validations.lettings.household.age.student_16_19.cannot_be_16_19.child_not_student")
        record.errors.add "relat#{person_num}", I18n.t("validations.lettings.household.relat.student_16_19.cannot_be_child.16_19_not_student")
      end

      next unless !age_between_16_19 && student && child

      record.errors.add "age#{person_num}", I18n.t("validations.lettings.household.age.student_16_19.must_be_16_19")
      record.errors.add "ecstat#{person_num}", I18n.t("validations.lettings.household.ecstat.student_16_19.cannot_be_student.child_not_16_19")
      record.errors.add "relat#{person_num}", I18n.t("validations.lettings.household.relat.student_16_19.cannot_be_child.student_not_16_19")
    end
  end

  def validate_condition_effects(record)
    all_options = [record.illness_type_1, record.illness_type_2, record.illness_type_3, record.illness_type_4, record.illness_type_5, record.illness_type_6, record.illness_type_7, record.illness_type_8, record.illness_type_9, record.illness_type_10]
    if all_options.count(1) >= 1 && household_no_illness?(record)
      record.errors.add :condition_effects, I18n.t("validations.lettings.household.condition_effects.no_choices")
    end
  end

  def validate_previous_housing_situation(record)
    if record.is_relet_to_temp_tenant? && !record.previous_tenancy_was_temporary?
      record.errors.add :prevten, :non_temp_accommodation, message: I18n.t("validations.lettings.household.prevten.non_temp_accommodation")
    end

    if record.age1.present? && record.age1 > 25 && record.previous_tenancy_was_foster_care?
      record.errors.add :prevten, :over_25_foster_care, message: I18n.t("validations.lettings.household.prevten.over_25_foster_care")
      record.errors.add :age1, I18n.t("validations.lettings.household.age.lead.over_25")
    end

    # 3  Private Sector Tenancy
    # 4  Tied housing or rented with job
    # 7  Direct access hostel
    # 10 Hospital
    # 13 Children's home / Foster Care
    # 14 Bed and breakfast
    # 19 Rough Sleeping
    # 23 Mobile home / Caravan
    # 24 Home Office Asylum Support
    # 25 Other
    # 26 Owner Occupation
    # 27 Owner occupation (low-cost home ownership)
    # 28 Living with Friends or Family
    # 29 Prison / Approved Probation Hostel
    if record.is_internal_transfer? && [3, 4, 7, 10, 13, 14, 19, 23, 24, 25, 26, 27, 28, 29].include?(record.prevten)
      label = record.form.get_question("prevten", record).present? ? record.form.get_question("prevten", record).label_from_value(record.prevten) : ""
      record.errors.add :prevten, :internal_transfer_non_social_housing, message: I18n.t("validations.lettings.household.prevten.internal_transfer", prevten: label)
      record.errors.add :referral, :internal_transfer_non_social_housing, message: I18n.t("validations.lettings.household.referral.prevten_invalid", prevten: label)
      record.errors.add :referral_type, :internal_transfer_non_social_housing, message: I18n.t("validations.lettings.household.referral.prevten_invalid", prevten: label)
    end
  end

  def validate_referral(record)
    return unless record.owning_organisation

    if record.is_internal_transfer? && record.owning_organisation.provider_type == "PRP" && record.is_prevten_la_general_needs?
      record.errors.add :prevten, :internal_transfer_fixed_or_lifetime, message: I18n.t("validations.lettings.household.prevten.la_general_needs.internal_transfer")
      record.errors.add :referral, :internal_transfer_fixed_or_lifetime, message: I18n.t("validations.lettings.household.referral.la_general_needs.internal_transfer")
      record.errors.add :referral_type, :internal_transfer_fixed_or_lifetime, message: I18n.t("validations.lettings.household.referral.la_general_needs.internal_transfer")
    end
  end

  def validate_prevloc(record)
    if record.previous_la_known? && record.prevloc.blank?
      record.errors.add :prevloc, I18n.t("validations.lettings.household.prevloc.previous_la_known")
    end
  end

  def validate_layear(record)
    return unless record.layear && record.renewal

    if record.is_renewal? && record.layear == 1
      record.errors.add :layear, :renewal_just_moved, message: I18n.t("validations.lettings.household.layear.renewal_just_moved_to_area")
      record.errors.add :renewal, I18n.t("validations.lettings.household.renewal.renewal_just_moved_to_area")
    end
  end

  def validate_layear_and_prevloc(record)
    return unless record.layear && record.la && record.prevloc && record.collection_start_year

    if record.la == record.prevloc && record.layear == 1
      record.errors.add :layear, I18n.t("validations.lettings.household.layear.same_la_just_moved_to_area")
      record.errors.add :la, I18n.t("validations.lettings.household.la.same_la_just_moved_to_area")
      record.errors.add :postcode_full, I18n.t("validations.lettings.household.postcode_full.same_la_just_moved_to_area")
      record.errors.add :uprn, I18n.t("validations.lettings.household.uprn.same_la_just_moved_to_area")
      record.errors.add :uprn_selection, I18n.t("validations.lettings.household.uprn_selection.same_la_just_moved_to_area")
      record.errors.add :ppostcode_full, I18n.t("validations.lettings.household.ppostcode_full.same_la_just_moved_to_area")
      record.errors.add :prevloc, I18n.t("validations.lettings.household.prevloc.same_la_just_moved_to_area")
      record.errors.add :scheme_id, :skip_bu_error, message: I18n.t("validations.lettings.household.scheme.same_la_just_moved_to_area")
      record.errors.add :location_id, :skip_bu_error, message: I18n.t("validations.lettings.household.location.same_la_just_moved_to_area")
    end
  end

  def validate_combination_of_housing_needs_responses(record)
    if record.has_housingneeds? && record.housingneeds_type_not_listed? && record.no_or_unknown_other_housing_needs?
      record.errors.add :housingneeds, I18n.t("validations.lettings.household.housingneeds.invalid")
      record.errors.add :housingneeds_type, I18n.t("validations.lettings.household.housingneeds_type.invalid")
      record.errors.add :housingneeds_other, I18n.t("validations.lettings.household.housingneeds_other.invalid")
    end
  end

private

  def household_no_illness?(record)
    record.illness != 1
  end

  def women_of_child_bearing_age_in_household(record)
    (1..8).any? do |n|
      next if record["sex#{n}"].nil?

      record["sex#{n}"] == "F" && (in_pregnancy_age_range?(record, n) || record.age_unknown?(n))
    end
  end

  def in_pregnancy_age_range?(record, person_num)
    return false if record["age#{person_num}"].nil?

    record["age#{person_num}"] >= 11 && record["age#{person_num}"] <= 65
  end

  def women_in_household(record)
    (1..8).any? do |n|
      record["sex#{n}"] == "F"
    end
  end

  def tenant_is_economic_child?(economic_status)
    economic_status == 9
  end

  def tenant_is_fulltime_student?(economic_status)
    economic_status == 7
  end

  def tenant_economic_status_refused?(economic_status)
    economic_status == 10
  end

  def economic_status_is_child_other_or_refused?(economic_status)
    [9, 0, 10].include?(economic_status)
  end

  def tenant_is_child?(relationship)
    relationship == "C"
  end

  def relationship_is_child_other_or_refused?(relationship)
    %w[C X R].include?(relationship)
  end
end
