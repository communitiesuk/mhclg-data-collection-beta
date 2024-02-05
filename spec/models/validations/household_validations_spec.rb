require "rails_helper"

RSpec.describe Validations::HouseholdValidations do
  subject(:household_validator) { validator_class.new }

  let(:validator_class) { Class.new { include Validations::HouseholdValidations } }
  let(:record) { FactoryBot.create(:lettings_log) }
  let(:fake_2021_2022_form) { Form.new("spec/fixtures/forms/2021_2022.json") }

  before do
    allow(FormHandler.instance).to receive(:current_lettings_form).and_return(fake_2021_2022_form)
  end

  describe "reasonable preference validations" do
    context "when reasonable preference is not given" do
      it "validates that no reason is needed" do
        record.reasonpref = 1
        record.rp_homeless = 0
        household_validator.validate_reasonable_preference(record)
        expect(record.errors["reasonpref"]).to be_empty
      end

      it "validates that no reason is given" do
        record.reasonpref = 2
        record.rp_medwel = 1
        household_validator.validate_reasonable_preference(record)
        expect(record.errors["reasonable_preference_reason"])
          .to include(match I18n.t("validations.household.reasonable_preference_reason.reason_not_required"))
      end
    end
  end

  describe "reason for leaving last settled home validations" do
    let(:field) { "validations.other_field_not_required" }
    let(:main_field_label) { "reason" }
    let(:other_field_label) { "reasonother" }
    let(:expected_error) { I18n.t(field, main_field_label:, other_field_label:) }

    context "when reason is other" do
      let(:field) { "validations.other_field_missing" }

      it "validates that a reason is provided" do
        record.reason = 20
        record.reasonother = nil
        household_validator.validate_reason_for_leaving_last_settled_home(record)
        expect(record.errors["reasonother"])
          .to include(match(expected_error))
      end

      it "expects that a reason is provided" do
        record.reason = 20
        record.reasonother = "Some unusual reason"
        household_validator.validate_reason_for_leaving_last_settled_home(record)
        expect(record.errors["reasonother"]).to be_empty
      end
    end

    context "when reason is not other" do
      it "validates that other reason is not provided" do
        record.reason = 18
        record.reasonother = "Some other reason"
        household_validator.validate_reason_for_leaving_last_settled_home(record)
        expect(record.errors["reasonother"])
          .to include(match(expected_error))
      end

      it "expects that other reason is not provided" do
        record.reason = 18
        record.reasonother = nil
        household_validator.validate_reason_for_leaving_last_settled_home(record)
        expect(record.errors["reasonother"]).to be_empty
      end
    end

    context "when reason is don't know" do
      let(:expected_error) { I18n.t("validations.household.underoccupation_benefitcap.dont_know_required") }

      it "validates that under occupation benefit cap is also not known" do
        record.reason = 32
        record.underoccupation_benefitcap = 1
        household_validator.validate_reason_for_leaving_last_settled_home(record)
        expect(record.errors["underoccupation_benefitcap"])
          .to include(match(expected_error))
        expect(record.errors["reason"])
          .to include(match(expected_error))
      end

      it "expects that under occupation benefit cap is also not known" do
        record.reason = 32
        record.underoccupation_benefitcap = 4
        household_validator.validate_reason_for_leaving_last_settled_home(record)
        expect(record.errors["underoccupation_benefitcap"]).to be_empty
        expect(record.errors["reason"]).to be_empty
      end
    end

    context "when referral is not internal transfer" do
      it "cannot be permanently decanted from another property owned by this landlord" do
        record.reason = 1
        record.referral = 2
        household_validator.validate_reason_for_leaving_last_settled_home(record)
        expect(record.errors["reason"])
          .to include(match(I18n.t("validations.household.reason.not_internal_transfer")))
        expect(record.errors["referral"])
          .to include(match(I18n.t("validations.household.referral.reason_permanently_decanted")))
      end
    end

    context "when referral is internal transfer" do
      it "can be permanently decanted from another property owned by this landlord" do
        record.reason = 1
        record.referral = 1
        household_validator.validate_reason_for_leaving_last_settled_home(record)
        expect(record.errors["reason"])
          .to be_empty
        expect(record.errors["referral"])
          .to be_empty
      end

      it "cannot have a PRP as landlord and Housing situation before this letting cannot be LA general needs" do
        record.owning_organisation.provider_type = "PRP"
        record.prevten = 30
        record.referral = 1
        household_validator.validate_referral(record)
        expect(record.errors["referral"])
          .to include(match(I18n.t("validations.household.referral.la_general_needs.internal_transfer")))
        expect(record.errors["prevten"])
          .to include(match(I18n.t("validations.household.prevten.la_general_needs.internal_transfer")))

        record.prevten = 31
        household_validator.validate_referral(record)
        expect(record.errors["referral"])
          .to include(match(I18n.t("validations.household.referral.la_general_needs.internal_transfer")))
        expect(record.errors["prevten"])
          .to include(match(I18n.t("validations.household.prevten.la_general_needs.internal_transfer")))
      end
    end

    context "when referral is nominated by a local housing authority" do
      it "cannot have a local authority" do
        record.owning_organisation.provider_type = "LA"
        record.referral = 3
        household_validator.validate_referral(record)
        expect(record.errors["referral"])
          .to include(match(I18n.t("validations.household.referral.prp.local_housing_referral")))
      end

      it "can have a private registered provider" do
        record.owning_organisation.provider_type = "PRP"
        record.referral = 3
        household_validator.validate_referral(record)
        expect(record.errors["referral"])
          .to be_empty
      end
    end
  end

  describe "armed forces validations" do
    context "when the tenant or partner was and is not a member of the armed forces" do
      it "validates that injured in the armed forces is not yes" do
        record.armedforces = 2
        record.reservist = 1
        household_validator.validate_armed_forces(record)
        expect(record.errors["reservist"])
          .to include(match I18n.t("validations.household.reservist.injury_not_required"))
      end
    end

    context "when the tenant prefers not to say if they were or are in the armed forces" do
      it "validates that injured in the armed forces is not yes" do
        record.armedforces = 3
        record.reservist = 1
        household_validator.validate_armed_forces(record)
        expect(record.errors["reservist"])
          .to include(match I18n.t("validations.household.reservist.injury_not_required"))
      end
    end

    context "when the tenant was or is a regular member of the armed forces" do
      it "expects that injured in the armed forces can be yes" do
        record.armedforces = 0
        record.reservist = 1
        household_validator.validate_armed_forces(record)
        expect(record.errors["reservist"]).to be_empty
      end
    end

    context "when the tenant was or is a reserve member of the armed forces" do
      it "expects that injured in the armed forces can be yes" do
        record.armedforces = 1
        record.reservist = 1
        household_validator.validate_armed_forces(record)
        expect(record.errors["reservist"]).to be_empty
      end
    end

    context "when the tenant’s partner was or is a member of the armed forces" do
      it "expects that injured in the armed forces can be yes" do
        record.armedforces = 5
        record.reservist = 1
        household_validator.validate_armed_forces(record)
        expect(record.errors["reservist"]).to be_empty
      end
    end

    context "when the tenant or partner has left the armed forces" do
      it "validates that they served in the armed forces" do
        record.armedforces = 2
        record.leftreg = 0
        household_validator.validate_armed_forces(record)
        expect(record.errors["leftreg"])
          .to include(match I18n.t("validations.household.leftreg.question_not_required"))
      end

      it "expects that they served in the armed forces" do
        record.armedforces = 1
        record.leftreg = 0
        household_validator.validate_armed_forces(record)
        expect(record.errors["leftreg"]).to be_empty
      end

      it "expects that they served in the armed forces and may have been injured" do
        record.armedforces = 1
        record.leftreg = 0
        record.reservist = 1
        household_validator.validate_armed_forces(record)
        expect(record.errors["leftreg"]).to be_empty
        expect(record.errors["reservist"]).to be_empty
      end
    end
  end

  describe "household member validations" do
    it "validates that only 1 partner exists" do
      record.relat2 = "P"
      record.relat3 = "P"
      household_validator.validate_household_number_of_other_members(record)
      expect(record.errors["relat2"])
        .to include(match I18n.t("validations.household.relat.one_partner"))
      expect(record.errors["relat3"])
        .to include(match I18n.t("validations.household.relat.one_partner"))
      expect(record.errors["relat4"])
        .not_to include(match I18n.t("validations.household.relat.one_partner"))
    end

    it "expects that a tenant can have a partner" do
      record.relat3 = "P"
      household_validator.validate_household_number_of_other_members(record)
      expect(record.errors["base"]).to be_empty
    end

    context "when the household contains a person under 16" do
      it "validates that person must be a child of the tenant" do
        record.age2 = 14
        record.relat2 = "P"
        household_validator.validate_household_number_of_other_members(record)
        expect(record.errors["relat2"])
          .to include(match I18n.t("validations.household.relat.child_under_16_lettings", person_num: 2))
        expect(record.errors["age2"])
          .to include(match I18n.t("validations.household.age.child_under_16_relat_lettings", person_num: 2))
      end

      it "expects that person is a child of the tenant" do
        record.age2 = 14
        record.relat2 = "C"
        household_validator.validate_household_number_of_other_members(record)
        expect(record.errors["relat2"]).to be_empty
        expect(record.errors["age2"]).to be_empty
      end

      it "validates that person's economic status must be Child" do
        record.age2 = 14
        record.ecstat2 = 1
        household_validator.validate_household_number_of_other_members(record)
        expect(record.errors["ecstat2"])
          .to include(match I18n.t("validations.household.ecstat.child_under_16", person_num: 2))
        expect(record.errors["age2"])
          .to include(match I18n.t("validations.household.age.child_under_16_ecstat", person_num: 2))
      end

      it "expects that person's economic status is Child" do
        record.age2 = 14
        record.ecstat2 = 9
        household_validator.validate_household_number_of_other_members(record)
        expect(record.errors["ecstat2"]).to be_empty
        expect(record.errors["age2"]).to be_empty
      end

      it "validates that a person with economic status 'child' must be under 16" do
        record.age2 = 21
        record.relat2 = "C"
        record.ecstat2 = 9
        household_validator.validate_household_number_of_other_members(record)
        expect(record.errors["ecstat2"])
          .to include(match I18n.t("validations.household.ecstat.child_over_16", person_num: 2))
        expect(record.errors["age2"])
          .to include(match I18n.t("validations.household.age.child_over_16", person_num: 2))
      end
    end

    context "when the household contains a tenant’s child between the ages of 16 and 19" do
      it "validates that person's economic status must be full time student or refused" do
        record.age2 = 17
        record.relat2 = "C"
        record.ecstat2 = 1
        household_validator.validate_household_number_of_other_members(record)
        expect(record.errors["ecstat2"])
          .to include(match I18n.t("validations.household.ecstat.student_16_19.must_be_student", person_num: 2))
        expect(record.errors["age2"])
          .to include(match I18n.t("validations.household.age.student_16_19.cannot_be_16_19.child_not_student", person_num: 2))
        expect(record.errors["relat2"])
          .to include(match I18n.t("validations.household.relat.student_16_19.cannot_be_child.16_19_not_student", person_num: 2))
      end

      it "expects that person can be a full time student" do
        record.age2 = 17
        record.relat2 = "C"
        record.ecstat2 = 7
        household_validator.validate_household_number_of_other_members(record)
        expect(record.errors["ecstat2"]).to be_empty
        expect(record.errors["age2"]).to be_empty
        expect(record.errors["relat2"]).to be_empty
      end

      it "expects that person can refuse to share their work status" do
        record.age2 = 17
        record.relat2 = "C"
        record.ecstat2 = 10
        household_validator.validate_household_number_of_other_members(record)
        expect(record.errors["ecstat2"]).to be_empty
        expect(record.errors["age2"]).to be_empty
        expect(record.errors["relat2"]).to be_empty
      end
    end

    it "does not add an error for a person aged 16-19 who is a student but not a child of the lead tenant" do
      record.age2 = 18
      record.ecstat2 = "7"
      record.relat2 = "P"
      household_validator.validate_household_number_of_other_members(record)
      expect(record.errors["relat2"]).to be_empty
      expect(record.errors["ecstat2"]).to be_empty
      expect(record.errors["age2"]).to be_empty
    end

    it "does not add an error for a person not aged 16-19 who is a student but not a child of the lead tenant" do
      record.age2 = 20
      record.ecstat2 = "7"
      record.relat2 = "P"
      household_validator.validate_household_number_of_other_members(record)
      expect(record.errors["relat2"]).to be_empty
      expect(record.errors["ecstat2"]).to be_empty
      expect(record.errors["age2"]).to be_empty
    end

    it "adds errors for a person who is a child of the lead tenant and a student but not aged 16-19" do
      record.age2 = 14
      record.ecstat2 = "7"
      record.relat2 = "C"
      household_validator.validate_household_number_of_other_members(record)
      expect(record.errors["relat2"])
        .to include(match I18n.t("validations.household.relat.student_16_19.cannot_be_child.student_not_16_19"))
      expect(record.errors["age2"])
        .to include(match I18n.t("validations.household.age.student_16_19.must_be_16_19"))
      expect(record.errors["ecstat2"])
        .to include(match I18n.t("validations.household.ecstat.student_16_19.cannot_be_student.child_not_16_19"))
    end

    context "when the household contains a person over 70" do
      it "expects that person under 70 does not need to be retired" do
        record.age2 = 50
        record.ecstat2 = 1
        household_validator.validate_household_number_of_other_members(record)
        expect(record.errors["ecstat2"]).to be_empty
        expect(record.errors["age2"]).to be_empty
      end

      it "expects that person over 70 is retired" do
        record.age2 = 71
        record.ecstat2 = 5
        household_validator.validate_household_number_of_other_members(record)
        expect(record.errors["ecstat2"]).to be_empty
        expect(record.errors["age2"]).to be_empty
      end
    end

    context "when the household contains a retired male" do
      it "expects that person is over 65" do
        record.age2 = 66
        record.sex2 = "M"
        record.ecstat2 = 5
        household_validator.validate_household_number_of_other_members(record)
        expect(record.errors["ecstat2"]).to be_empty
        expect(record.errors["sex2"]).to be_empty
        expect(record.errors["age2"]).to be_empty
      end

      it "validates that the number of household members cannot be less than 0" do
        record.hhmemb = -1
        household_validator.validate_numeric_min_max(record)
        expect(record.errors["hhmemb"])
          .to include(match I18n.t("validations.numeric.within_range", field: "Number of Household Members", min: 0, max: 8))
      end

      it "validates that the number of household members cannot be more than 8" do
        record.hhmemb = 9
        household_validator.validate_numeric_min_max(record)
        expect(record.errors["hhmemb"])
          .to include(match I18n.t("validations.numeric.within_range", field: "Number of Household Members", min: 0, max: 8))
      end

      it "expects that the number of other household members is between the min and max" do
        record.hhmemb = 5
        household_validator.validate_numeric_min_max(record)
        expect(record.errors["hhmemb"]).to be_empty
      end
    end

    context "when the household contains a retired female" do
      it "expects that person is over 60" do
        record.age2 = 61
        record.sex2 = "F"
        record.ecstat2 = 5
        household_validator.validate_household_number_of_other_members(record)
        expect(record.errors["ecstat2"]).to be_empty
        expect(record.errors["sex2"]).to be_empty
        expect(record.errors["age2"]).to be_empty
      end
    end
  end

  describe "condition effects validation" do
    it "validates vision can't be selected if answer to anyone in household with health condition is not yes" do
      record.illness = 2
      record.illness_type_1 = 1
      household_validator.validate_condition_effects(record)
      expect(record.errors["condition_effects"])
        .to include(match I18n.t("validations.household.condition_effects.no_choices"))
    end

    it "validates hearing can't be selected if answer to anyone in household with health condition is not yes" do
      record.illness = 2
      record.illness_type_2 = 1
      household_validator.validate_condition_effects(record)
      expect(record.errors["condition_effects"])
        .to include(match I18n.t("validations.household.condition_effects.no_choices"))
    end

    it "validates mobility can't be selected if answer to anyone in household with health condition is not yes" do
      record.illness = 2
      record.illness_type_3 = 1
      household_validator.validate_condition_effects(record)
      expect(record.errors["condition_effects"])
        .to include(match I18n.t("validations.household.condition_effects.no_choices"))
    end

    it "validates dexterity can't be selected if answer to anyone in household with health condition is not yes" do
      record.illness = 2
      record.illness_type_4 = 1
      household_validator.validate_condition_effects(record)
      expect(record.errors["condition_effects"])
        .to include(match I18n.t("validations.household.condition_effects.no_choices"))
    end

    it "validates learning or understanding or concentrating can't be selected if answer to anyone in household with health condition is not yes" do
      record.illness = 2
      record.illness_type_5 = 1
      household_validator.validate_condition_effects(record)
      expect(record.errors["condition_effects"])
        .to include(match I18n.t("validations.household.condition_effects.no_choices"))
    end

    it "validates memory can't be selected if answer to anyone in household with health condition is not yes" do
      record.illness = 2
      record.illness_type_6 = 1
      household_validator.validate_condition_effects(record)
      expect(record.errors["condition_effects"])
        .to include(match I18n.t("validations.household.condition_effects.no_choices"))
    end

    it "validates mental health can't be selected if answer to anyone in household with health condition is not yes" do
      record.illness = 2
      record.illness_type_7 = 1
      household_validator.validate_condition_effects(record)
      expect(record.errors["condition_effects"])
        .to include(match I18n.t("validations.household.condition_effects.no_choices"))
    end

    it "validates stamina or breathing or fatigue can't be selected if answer to anyone in household with health condition is not yes" do
      record.illness = 2
      record.illness_type_8 = 1
      household_validator.validate_condition_effects(record)
      expect(record.errors["condition_effects"])
        .to include(match I18n.t("validations.household.condition_effects.no_choices"))
    end

    it "validates socially or behaviourally can't be selected if answer to anyone in household with health condition is not yes" do
      record.illness = 2
      record.illness_type_9 = 1
      household_validator.validate_condition_effects(record)
      expect(record.errors["condition_effects"])
        .to include(match I18n.t("validations.household.condition_effects.no_choices"))
    end

    it "validates other can't be selected if answer to anyone in household with health condition is not yes" do
      record.illness = 2
      record.illness_type_10 = 1
      household_validator.validate_condition_effects(record)
      expect(record.errors["condition_effects"])
        .to include(match I18n.t("validations.household.condition_effects.no_choices"))
    end

    it "expects that an illness can be selected if answer to anyone in household with health condition is yes " do
      record.illness = 1
      record.illness_type_1 = 1
      record.illness_type_2 = 1
      record.illness_type_3 = 1
      household_validator.validate_condition_effects(record)
      expect(record.errors["condition_effects"]).to be_empty
    end
  end

  describe "referral validations" do
    context "when homelessness is assessed" do
      it "can be internal transfer" do
        record.homeless = 11
        record.referral = 1
        household_validator.validate_referral(record)
        expect(record.errors["referral"]).to be_empty
        expect(record.errors["homeless"]).to be_empty
      end

      it "can be non internal transfer" do
        record.owning_organisation.provider_type = "PRP"
        record.homeless = 0
        record.referral = 3
        household_validator.validate_referral(record)
        expect(record.errors["referral"]).to be_empty
        expect(record.errors["homeless"]).to be_empty
      end
    end

    context "when homelessness is other" do
      it "cannot be internal transfer" do
        record.referral = 1
        record.homeless = 7
        household_validator.validate_referral(record)
        expect(record.errors["referral"]).to be_empty
        expect(record.errors["homeless"]).to be_empty
      end

      it "can be non internal transfer" do
        record.owning_organisation.provider_type = "PRP"
        record.referral = 3
        record.homeless = 1
        household_validator.validate_referral(record)
        expect(record.errors["referral"]).to be_empty
        expect(record.errors["homeless"]).to be_empty
      end
    end
  end

  describe "la validations" do
    context "when previous la is known" do
      it "prevloc has to be provided" do
        record.previous_la_known = 1
        household_validator.validate_prevloc(record)
        expect(record.errors["prevloc"])
          .to include(match I18n.t("validations.household.previous_la_known"))
      end
    end

    context "when validating layear" do
      it "household cannot have just moved to area if renewal" do
        record.layear = 1
        record.renewal = 1
        household_validator.validate_layear(record)
        expect(record.errors["layear"])
          .to include(match I18n.t("validations.household.renewal_just_moved_to_area.layear"))
        expect(record.errors["renewal"])
          .to include(match I18n.t("validations.household.renewal_just_moved_to_area.renewal"))
      end

      context "when validating layear and prevloc" do
        it "household cannot have just moved to area if prevloc is the same as la" do
          record.layear = 1
          record.prevloc = "E07000084"
          record.la = "E07000084"
          record.startdate = Time.zone.now
          household_validator.validate_layear_and_prevloc(record)
          expect(record.errors["layear"])
            .to include(match I18n.t("validations.household.same_la_just_moved_to_area.layear"))
          expect(record.errors["prevloc"])
            .to include(match I18n.t("validations.household.same_la_just_moved_to_area.previous_la"))
          expect(record.errors["ppostcode_full"])
          .to include(match I18n.t("validations.household.same_la_just_moved_to_area.previous_la"))
          expect(record.errors["la"])
            .to include(match I18n.t("validations.household.same_la_just_moved_to_area.current_la"))
          expect(record.errors["postcode_full"])
            .to include(match I18n.t("validations.household.same_la_just_moved_to_area.current_la"))
          expect(record.errors["uprn"])
            .to include(match I18n.t("validations.household.same_la_just_moved_to_area.current_la"))
        end
      end
    end
  end

  describe "previous housing situation validations" do
    context "when the property is being relet to a previously temporary tenant" do
      it "validates that previous tenancy was temporary" do
        record.rsnvac = 9
        record.prevten = 4
        household_validator.validate_previous_housing_situation(record)
        expect(record.errors["prevten"])
          .to include(match I18n.t("validations.household.prevten.non_temp_accommodation"))
      end
    end

    context "when the lead tenant is over 25" do
      it "cannot be children's home/foster care" do
        record.prevten = 13
        record.age1 = 26
        household_validator.validate_previous_housing_situation(record)
        expect(record.errors["prevten"])
          .to include(match I18n.t("validations.household.prevten.over_25_foster_care"))
        expect(record.errors["age1"])
          .to include(match I18n.t("validations.household.age.lead.over_25"))
      end
    end

    context "when the lead tenant is male" do
      it "cannot be refuge" do
        record.prevten = 21
        record.sex1 = "M"
        household_validator.validate_previous_housing_situation(record)
        expect(record.errors["prevten"])
          .to include(match I18n.t("validations.household.prevten.male_refuge"))
        expect(record.errors["sex1"])
          .to include(match I18n.t("validations.household.gender.male_refuge"))
      end
    end

    context "when the referral is internal transfer" do
      it "prevten can be 9" do
        record.referral = 1
        record.prevten = 9
        household_validator.validate_previous_housing_situation(record)
        expect(record.errors["prevten"])
          .to be_empty
        expect(record.errors["referral"])
          .to be_empty
      end

      it "prevten cannot be 3" do
        record.referral = 1
        record.prevten = 3
        household_validator.validate_previous_housing_situation(record)
        expect(record.errors["prevten"])
          .to include(match I18n.t("validations.household.prevten.internal_transfer", prevten: ""))
        expect(record.errors["referral"])
          .to include(match I18n.t("validations.household.referral.prevten_invalid", prevten: ""))
      end

      it "prevten cannot be 4, 10, 13, 19, 23, 24, 25, 26, 28, 29" do
        record.referral = 1
        record.prevten = 4
        household_validator.validate_previous_housing_situation(record)
        expect(record.errors["prevten"])
          .to include(match I18n.t("validations.household.prevten.internal_transfer", prevten: ""))
        expect(record.errors["referral"])
          .to include(match I18n.t("validations.household.referral.prevten_invalid", prevten: ""))
      end
    end
  end

  describe "housing needs validations" do
    it "is invalid when a combination of housingneeds == 1 (yes) && housingneeds_type == 3 (none of listed) && housingneeds_other == 0 (no)" do
      record.housingneeds = 1
      record.housingneeds_type = 3
      record.housingneeds_other = 0

      household_validator.validate_combination_of_housing_needs_responses(record)

      error_message = ["If somebody in the household has disabled access needs, they must have the access needs listed, or other access needs"]

      expect(record.errors["housingneeds"]).to eq(error_message)
      expect(record.errors["housingneeds_type"]).to eq(error_message)
      expect(record.errors["housingneeds_other"]).to eq(error_message)
    end
  end
end
