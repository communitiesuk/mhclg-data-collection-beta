module Validations::HouseholdValidations
  # Validations methods need to be called 'validate_<page_name>' to run on model save
  # or 'validate_' to run on submit as well
  def validate_reasonable_preference(record)
    if record.homeless == "No" && record.reasonpref == "Yes"
      record.errors.add :reasonpref, I18n.t("validations.household.reasonpref.not_homeless")
    elsif record.reasonpref == "Yes"
      if [record.rp_homeless, record.rp_insan_unsat, record.rp_medwel, record.rp_hardship, record.rp_dontknow].none? { |a| a == "Yes" }
        record.errors.add :reasonable_preference_reason, I18n.t("validations.household.reasonable_preference_reason.reason_required")
      end
    elsif record.reasonpref == "No"
      if [record.rp_homeless, record.rp_insan_unsat, record.rp_medwel, record.rp_hardship, record.rp_dontknow].any? { |a| a == "Yes" }
        record.errors.add :reasonable_preference_reason, I18n.t("validations.household.reasonable_preference_reason.reason_not_required")
      end
    end
  end

  def validate_other_reason_for_leaving_last_settled_home(record)
    validate_other_field(record, "reason", "other_reason_for_leaving_last_settled_home")
  end

  def validate_reason_for_leaving_last_settled_home(record)
    if record.reason == "Don’t know" && record.underoccupation_benefitcap != "Don’t know"
      record.errors.add :underoccupation_benefitcap, I18n.t("validations.household.underoccupation_benefitcap.dont_know_required")
    end
  end

  def validate_armed_forces_injured(record)
    if (record.armedforces == "A current or former regular in the UK Armed Forces (excluding National Service)" || record.armedforces == "A current or former reserve in the UK Armed Forces (excluding National Service)") && record.reservist.blank?
      record.errors.add :reservist, I18n.t("validations.household.reservist.injury_required")
    end

    if (record.armedforces == "No" || record.armedforces == "Prefer not to say") && record.reservist.present?
      record.errors.add :reservist, I18n.t("validations.household.reservist.injury_not_required")
    end
  end

  def validate_armed_forces_active_response(record)
    if record.armedforces == "A current or former regular in the UK Armed Forces (excluding National Service)" && record.leftreg.blank?
      record.errors.add :leftreg, I18n.t("validations.household.leftreg.question_required")
    end

    if record.armedforces != "A current or former regular in the UK Armed Forces (excluding National Service)" && record.leftreg.present?
      record.errors.add :leftreg, I18n.t("validations.household.leftreg.question_not_required")
    end
  end

  def validate_pregnancy(record)
    if (record.preg_occ == "Yes" || record.preg_occ == "Prefer not to say") && !women_of_child_bearing_age_in_household(record)
      record.errors.add :preg_occ, I18n.t("validations.household.preg_occ.no_female")
    end
  end

  def validate_household_number_of_other_members(record)
    (2..8).each do |n|
      validate_person_age(record, n)
      validate_person_age_matches_economic_status(record, n)
      validate_person_age_matches_relationship(record, n)
      validate_person_age_and_gender_match_economic_status(record, n)
      validate_person_age_and_relationship_matches_economic_status(record, n)
    end
    validate_partner_count(record)
  end

  def validate_person_1_age(record)
    validate_person_age(record, 1, 16)
  end

  def validate_person_1_economic(record)
    validate_person_age_matches_economic_status(record, 1)
  end

  def validate_accessibility_requirements(record)
    all_options = [record.housingneeds_a, record.housingneeds_b, record.housingneeds_c, record.housingneeds_f, record.housingneeds_g, record.housingneeds_h, record.accessibility_requirements_prefer_not_to_say]
    if all_options.count("Yes") > 1
      mobility_accessibility_options = [record.housingneeds_a, record.housingneeds_b, record.housingneeds_c]
      unless all_options.count("Yes") == 2 && record.housingneeds_f == "Yes" && mobility_accessibility_options.any? { |x| x == "Yes" }
        record.errors.add :housingneeds_a, I18n.t("validations.household.housingneeds_a.one_or_two_choices")
      end
    end
  end

  def validate_shared_housing_rooms(record)
    unless record.unittype_gn.nil?
      if record.unittype_gn == "Bedsit" && record.beds != 1 && record.beds.present?
        record.errors.add :unittype_gn, I18n.t("validations.household.unittype_gn.one_bedroom_bedsit")
      end

      if !record.other_hhmemb.nil? && record.other_hhmemb.positive? && (record.unittype_gn.include?("Shared") && !record.beds.to_i.between?(1, 7))
        record.errors.add :unittype_gn, I18n.t("validations.household.unittype_gn.one_seven_bedroom_shared")
      end

      if record.unittype_gn.include?("Shared") && !record.beds.to_i.between?(1, 3) && record.beds.present?
        record.errors.add :unittype_gn, I18n.t("validations.household.unittype_gn.one_three_bedroom_single_tenant_shared")
      end
    end
  end

private

  def women_of_child_bearing_age_in_household(record)
    (1..8).any? do |n|
      next if record["sex#{n}"].nil? || record["age#{n}"].nil?

      record["sex#{n}"] == "Female" && record["age#{n}"] >= 16 && record["age#{n}"] <= 50
    end
  end

  def validate_person_age(record, person_num, lower_bound = 1)
    age = record.public_send("age#{person_num}")
    return unless age

    begin
      Integer(record.public_send("age#{person_num}_before_type_cast"))
    rescue ArgumentError
      record.errors.add "age#{person_num}".to_sym, I18n.t("validations.household.age.must_be_valid", lower_bound: lower_bound)
    end

    if age < lower_bound || age > 120
      record.errors.add "age#{person_num}".to_sym, I18n.t("validations.household.age.must_be_valid", lower_bound: lower_bound)
    end
  end

  def validate_person_age_matches_economic_status(record, person_num)
    age = record.public_send("age#{person_num}")
    economic_status = record.public_send("ecstat#{person_num}")
    return unless age && economic_status

    if age > 70 && economic_status != "Retired"
      record.errors.add "ecstat#{person_num}", I18n.t("validations.household.ecstat.retired_over_70", person_num: person_num)
    end
    if age < 16 && economic_status != "Child under 16"
      record.errors.add "ecstat#{person_num}", I18n.t("validations.household.ecstat.child_under_16", person_num: person_num)
    end
  end

  def validate_person_age_matches_relationship(record, person_num)
    age = record.public_send("age#{person_num}")
    relationship = record.public_send("relat#{person_num}")
    return unless age && relationship

    if age < 16 && relationship != "Child - includes young adult and grown-up"
      record.errors.add "relat#{person_num}", I18n.t("validations.household.relat.child_under_16", person_num: person_num)
    end
  end

  def validate_person_age_and_relationship_matches_economic_status(record, person_num)
    age = record.public_send("age#{person_num}")
    economic_status = record.public_send("ecstat#{person_num}")
    relationship = record.public_send("relat#{person_num}")
    return unless age && economic_status && relationship

    if age >= 16 && age <= 19 && relationship == "Child - includes young adult and grown-up" && (economic_status != "Full-time student" || economic_status != "Prefer not to say")
      record.errors.add "ecstat#{person_num}", I18n.t("validations.household.ecstat.student_16_19", person_num: person_num)
    end
  end

  def validate_person_age_and_gender_match_economic_status(record, person_num)
    age = record.public_send("age#{person_num}")
    gender = record.public_send("sex#{person_num}")
    economic_status = record.public_send("ecstat#{person_num}")
    return unless age && economic_status && gender

    if gender == "Male" && economic_status == "Retired" && age < 65
      record.errors.add "age#{person_num}", I18n.t("validations.household.age.retired_male")
    end
    if gender == "Female" && economic_status == "Retired" && age < 60
      record.errors.add "age#{person_num}", I18n.t("validations.household.age.retired_female")
    end
  end

  def validate_partner_count(record)
    # TODO: probably need to keep track of which specific field is wrong so we can highlight it in the UI
    partner_count = (2..8).count { |n| record.public_send("relat#{n}") == "Partner" }
    if partner_count > 1
      record.errors.add :base, I18n.t("validations.household.relat.one_partner")
    end
  end
end
