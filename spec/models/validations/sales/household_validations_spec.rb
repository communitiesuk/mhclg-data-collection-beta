require "rails_helper"

RSpec.describe Validations::Sales::HouseholdValidations do
  subject(:household_validator) { validator_class.new }

  let(:validator_class) { Class.new { include Validations::Sales::HouseholdValidations } }
  let(:record) { build(:sales_log, saledate: log_date) }
  let(:log_date) { Time.zone.local(2023, 4, 1) }

  describe "#validate_partner_count" do
    it "validates that only 1 partner exists" do
      record.relat2 = "P"
      record.relat3 = "P"
      household_validator.validate_partner_count(record)
      expect(record.errors["relat2"])
        .to include(match I18n.t("validations.household.relat.one_partner"))
      expect(record.errors["relat3"])
        .to include(match I18n.t("validations.household.relat.one_partner"))
      expect(record.errors["relat4"])
        .not_to include(match I18n.t("validations.household.relat.one_partner"))
    end

    it "expects that a tenant can have a partner" do
      record.relat3 = "P"
      household_validator.validate_partner_count(record)
      expect(record.errors["base"]).to be_empty
    end
  end

  describe "#validate_person_age_matches_relationship" do
    before do
      Timecop.freeze(log_date)
      Singleton.__init__(FormHandler)
    end

    after do
      Timecop.return
      Singleton.__init__(FormHandler)
    end

    context "with 2023 logs" do
      let(:log_date) { Time.zone.local(2023, 4, 1) }

      context "when the household contains a person under 16" do
        it "expects that person is a child of the tenant" do
          record.age2 = 14
          record.relat2 = "C"
          household_validator.validate_person_age_matches_relationship(record)
          expect(record.errors["relat2"]).to be_empty
          expect(record.errors["age2"]).to be_empty
        end

        it "validates that a person under 16 must not be a partner of the buyer" do
          record.age2 = 14
          record.relat2 = "P"
          household_validator.validate_person_age_matches_relationship(record)
          expect(record.errors["relat2"])
            .to include(match I18n.t("validations.household.relat.child_under_16_sales", person_num: 2))
          expect(record.errors["age2"])
            .to include(match I18n.t("validations.household.age.child_under_16_relat_sales", person_num: 2))
        end
      end

      it "validates that a person over 20 must not be a child of the buyer" do
        record.age2 = 21
        record.relat2 = "C"
        household_validator.validate_person_age_matches_relationship(record)
        expect(record.errors["relat2"])
          .to include(match I18n.t("validations.household.relat.child_over_20"))
        expect(record.errors["age2"])
          .to include(match I18n.t("validations.household.age.child_over_20"))
      end
    end

    context "with 2024 logs" do
      let(:log_date) { Time.zone.local(2024, 4, 1) }

      it "validates person under 16 is not partner" do
        record.age2 = 14
        record.relat2 = "P"
        household_validator.validate_person_age_matches_relationship(record)
        expect(record.errors["relat2"])
          .to include("Answer cannot be ‘partner’ as you told us person 2's age is under 16")
        expect(record.errors["age2"])
          .not_to include("Age cannot be under 16 as you told us person 2's relationship to the buyer is partner.")
      end

      it "validates person over 19 is not child" do
        record.age2 = 20
        record.relat2 = "C"
        household_validator.validate_person_age_matches_relationship(record)
        expect(record.errors["age2"])
          .to include("Age must be 19 or under as you told us person 2's relationship to the buyer is child")
        expect(record.errors["relat2"])
          .not_to include("Answer cannot be child, as you told us person 2 is over 19")
      end
    end
  end

  describe "#validate_person_age_matches_economic_status" do
    before do
      Timecop.freeze(log_date)
      Singleton.__init__(FormHandler)
    end

    after do
      Timecop.return
      Singleton.__init__(FormHandler)
    end

    context "with 2023 logs" do
      let(:log_date) { Time.zone.local(2023, 4, 1) }

      it "validates that person's economic status must be Child" do
        record.age2 = 14
        record.ecstat2 = 1
        household_validator.validate_person_age_matches_economic_status(record)
        expect(record.errors["ecstat2"])
          .to include(match I18n.t("validations.household.ecstat.child_under_16", person_num: 2))
        expect(record.errors["age2"])
          .to include(match I18n.t("validations.household.age.child_under_16_ecstat", person_num: 2))
      end

      it "expects that person's economic status is Child" do
        record.age2 = 14
        record.ecstat2 = 9
        household_validator.validate_person_age_matches_economic_status(record)
        expect(record.errors["ecstat2"]).to be_empty
        expect(record.errors["age2"]).to be_empty
      end

      it "validates that a person with economic status 'child' must be under 16" do
        record.age2 = 21
        record.ecstat2 = 9
        household_validator.validate_person_age_matches_economic_status(record)
        expect(record.errors["ecstat2"])
          .to include(match I18n.t("validations.household.ecstat.child_over_16", person_num: 2))
        expect(record.errors["age2"])
          .to include(match I18n.t("validations.household.age.child_over_16", person_num: 2))
      end
    end

    context "with 2024 logs" do
      let(:log_date) { Time.zone.local(2024, 4, 1) }

      it "does not run the validation" do
        record.age2 = 14
        record.ecstat2 = 1
        household_validator.validate_person_age_matches_economic_status(record)
        expect(record.errors["ecstat2"])
          .not_to include(match I18n.t("validations.household.ecstat.child_under_16", person_num: 2))
        expect(record.errors["age2"])
          .not_to include(match I18n.t("validations.household.age.child_under_16_ecstat", person_num: 2))
      end
    end
  end

  describe "#validate_child_12_years_younger" do
    before do
      Timecop.freeze(log_date)
      Singleton.__init__(FormHandler)
    end

    after do
      Timecop.return
      Singleton.__init__(FormHandler)
    end

    context "with 2023 logs" do
      let(:log_date) { Time.zone.local(2023, 4, 1) }

      it "validates the child is at least 12 years younger than buyer 1" do
        record.age1 = 30
        record.age2 = record.age1 - 11
        record.relat2 = "C"
        household_validator.validate_child_12_years_younger(record)
        expect(record.errors["age1"])
          .to include(match I18n.t("validations.household.age.child_12_years_younger", person_num: 2))
        expect(record.errors["age2"])
          .to include(match I18n.t("validations.household.age.child_12_years_younger", person_num: 2))
        expect(record.errors["relat2"])
          .to include(match I18n.t("validations.household.age.child_12_years_younger", person_num: 2))
      end

      it "expects the child is at least 12 years younger than buyer 1" do
        record.age1 = 30
        record.age2 = record.age1 - 12
        record.relat2 = "C"
        household_validator.validate_child_12_years_younger(record)
        expect(record.errors["age1"]).to be_empty
        expect(record.errors["age2"]).to be_empty
        expect(record.errors["relate2"]).to be_empty
      end
    end

    context "with 2024 logs" do
      let(:log_date) { Time.zone.local(2024, 4, 1) }

      it "validates that child is at least 12 year younger than buyer" do
        record.age1 = 20
        record.age2 = 17
        record.relat2 = "C"
        household_validator.validate_child_12_years_younger(record)
        expect(record.errors["age1"])
          .to include("Age must be at least 12 years older than person 2's age as person 2's relationship to buyer is child.")
        expect(record.errors["age2"])
          .to include("Age must be at least 12 years younger than the buyer as person 2's relationship to buyer is child.")
        expect(record.errors["relat2"])
          .to include("Relationship cannot be child, as person 2 is less than 12 years younger than the buyer")
      end

      it "expects that child is at least 12 years younger than buyer" do
        record.age1 = 30
        record.age2 = 17
        record.relat2 = "C"
        household_validator.validate_child_12_years_younger(record)
        expect(record.errors["age2"]).to be_empty
        expect(record.errors["relat2"]).to be_empty
      end
    end
  end

  describe "#validate_person_age_and_relationship_matches_economic_status" do
    before do
      Timecop.freeze(log_date)
      Singleton.__init__(FormHandler)
    end

    after do
      Timecop.return
      Singleton.__init__(FormHandler)
    end

    context "with 2023 logs" do
      let(:log_date) { Time.zone.local(2023, 4, 1) }

      it "does not add an error for a person aged 16-19 who is a student but not a child of the buyer" do
        record.age2 = 18
        record.ecstat2 = "7"
        record.relat2 = "P"
        household_validator.validate_person_age_and_relationship_matches_economic_status(record)
        expect(record.errors["relat2"]).to be_empty
        expect(record.errors["ecstat2"]).to be_empty
        expect(record.errors["age2"]).to be_empty
      end

      it "does not add an error for a person not aged 16-19 who is a student but not a child of the buyer" do
        record.age2 = 20
        record.ecstat2 = "7"
        record.relat2 = "P"
        household_validator.validate_person_age_and_relationship_matches_economic_status(record)
        expect(record.errors["relat2"]).to be_empty
        expect(record.errors["ecstat2"]).to be_empty
        expect(record.errors["age2"]).to be_empty
      end

      it "adds errors for a person aged 16-19 who is a child of the buyer but not a student" do
        record.age2 = 17
        record.ecstat2 = "1"
        record.relat2 = "C"
        household_validator.validate_person_age_and_relationship_matches_economic_status(record)
        expect(record.errors["relat2"])
          .to include(match I18n.t("validations.household.relat.student_16_19.cannot_be_child.16_19_not_student"))
        expect(record.errors["age2"])
          .to include(match I18n.t("validations.household.age.student_16_19.cannot_be_16_19.child_not_student"))
        expect(record.errors["ecstat2"])
          .to include(match I18n.t("validations.household.ecstat.student_16_19.must_be_student"))
      end

      it "adds errors for a person who is a child of the buyer and a student but not aged 16-19" do
        record.age2 = 14
        record.ecstat2 = "7"
        record.relat2 = "C"
        household_validator.validate_person_age_and_relationship_matches_economic_status(record)
        expect(record.errors["relat2"])
          .to include(match I18n.t("validations.household.relat.student_16_19.cannot_be_child.student_not_16_19"))
        expect(record.errors["age2"])
          .to include(match I18n.t("validations.household.age.student_16_19.must_be_16_19"))
        expect(record.errors["ecstat2"])
          .to include(match I18n.t("validations.household.ecstat.student_16_19.cannot_be_student.child_not_16_19"))
      end
    end

    context "with 2024 logs" do
      let(:log_date) { Time.zone.local(2024, 4, 1) }

      context "when the household contains a tenant’s child between the ages of 16 and 19" do
        it "validates that person's economic status must be full time student or refused" do
          record.age2 = 17
          record.relat2 = "C"
          record.ecstat2 = 1
          household_validator.validate_person_age_and_relationship_matches_economic_status(record)
          expect(record.errors["ecstat2"])
            .to include("Person 2's working situation must be student or prefers not to say, as their age is 16-19 and their relationship to the buyer is child")
          expect(record.errors["age2"])
            .to include("Person cannot be aged 16-19 if they have relationship ‘child’ but are not a student")
          expect(record.errors["relat2"])
            .to include("Answer cannot be ‘child’ if the person is aged 16-19 but not a student")
        end

        it "expects that person can be a full time student" do
          record.age2 = 17
          record.relat2 = "C"
          record.ecstat2 = 7
          household_validator.validate_person_age_and_relationship_matches_economic_status(record)
          expect(record.errors["ecstat2"]).to be_empty
          expect(record.errors["age2"]).to be_empty
          expect(record.errors["relat2"]).to be_empty
        end

        it "expects that person can refuse to share their work status" do
          record.age2 = 17
          record.relat2 = "C"
          record.ecstat2 = 10
          household_validator.validate_person_age_and_relationship_matches_economic_status(record)
          expect(record.errors["ecstat2"]).to be_empty
          expect(record.errors["age2"]).to be_empty
          expect(record.errors["relat2"]).to be_empty
        end
      end

      it "does not add an error for a person not aged 16-19 who is a student but not a child of the buyer" do
        record.age2 = 20
        record.ecstat2 = "7"
        record.relat2 = "P"
        household_validator.validate_person_age_and_relationship_matches_economic_status(record)
        expect(record.errors["relat2"]).to be_empty
        expect(record.errors["ecstat2"]).to be_empty
        expect(record.errors["age2"]).to be_empty
      end

      it "adds errors for a person who is a child of the buyer and a student but not aged 16-19" do
        record.age2 = 14
        record.ecstat2 = "7"
        record.relat2 = "C"
        household_validator.validate_person_age_and_relationship_matches_economic_status(record)
        expect(record.errors["relat2"])
          .to include("Answer cannot be ‘child’ if the person is a student but not aged 16-19")
        expect(record.errors["age2"])
          .to include("Person 2's age must be 16-19 as their working situation is student and their relationship to the buyer is child")
        expect(record.errors["ecstat2"])
          .to include("Person cannot be a student if they are not aged 16-19 but have relationship ‘child’")
      end

      it "adds errors for a person who is a student and aged 16-19 but not child" do
        record.age2 = 17
        record.ecstat2 = "7"
        record.relat2 = "X"
        household_validator.validate_person_age_and_relationship_matches_economic_status(record)
        expect(record.errors["relat2"])
          .to include("Person 2's relationship to the buyer must be child as their working situation is student and their age is 16-19")
        expect(record.errors["age2"])
          .to include("Person cannot be aged 16-19 if they are a student but not a child")
        expect(record.errors["ecstat2"])
          .to include("Person cannot be a student if they are aged 16-19 but are not a child")
      end
    end
  end

  describe "#validate_buyer_2_not_child" do
    before do
      Timecop.freeze(log_date)
      Singleton.__init__(FormHandler)
    end

    after do
      Timecop.return
      Singleton.__init__(FormHandler)
    end

    context "with 2023 logs" do
      let(:log_date) { Time.zone.local(2023, 4, 1) }

      it "does not add an error if buyer 2 is a child" do
        record.jointpur = 1
        record.relat2 = "C"
        household_validator.validate_buyer_2_not_child(record)
        expect(record.errors["relat2"]).to be_empty
      end
    end

    context "with 2024 logs" do
      let(:log_date) { Time.zone.local(2024, 4, 1) }

      it "validates buyer 2 isn't a child" do
        record.jointpur = 1
        record.relat2 = "C"
        household_validator.validate_buyer_2_not_child(record)
        expect(record.errors["relat2"])
          .to include("Relationship cannot be child, as this person is a buyer")
      end
    end
  end

  describe "validating fields about buyers living in the property" do
    let(:sales_log) { FactoryBot.create(:sales_log, :outright_sale_setup_complete, noint: 1, companybuy: 2, buylivein:, jointpur:, jointmore:, buy1livein:) }

    context "when buyers will live in the property and the sale is a joint purchase" do
      let(:buylivein) { 1 }
      let(:jointpur) { 1 }
      let(:jointmore) { 2 }

      context "and buyer one will live in the property" do
        let(:buy1livein) { 1 }

        it "does not add validations regardless of whether buyer two will live in the property" do
          sales_log.buy2livein = 1
          household_validator.validate_buyers_living_in_property(sales_log)
          expect(sales_log.errors).to be_empty
          sales_log.buy2livein = 2
          household_validator.validate_buyers_living_in_property(sales_log)
          expect(sales_log.errors).to be_empty
        end
      end

      context "and buyer one will not live in the property" do
        let(:buy1livein) { 2 }

        it "does not add validations if buyer two will live in the property or if we do not yet know" do
          sales_log.buy2livein = 1
          household_validator.validate_buyers_living_in_property(sales_log)
          expect(sales_log.errors).to be_empty
          sales_log.buy2livein = nil
          household_validator.validate_buyers_living_in_property(sales_log)
          expect(sales_log.errors).to be_empty
        end

        it "triggers a validation if buyer two will also not live in the property" do
          sales_log.buy2livein = 2
          household_validator.validate_buyers_living_in_property(sales_log)
          expect(sales_log.errors[:buylivein]).to include I18n.t("validations.household.buylivein.buyers_will_live_in_property_values_inconsistent_setup")
          expect(sales_log.errors[:buy2livein]).to include I18n.t("validations.household.buylivein.buyers_will_live_in_property_values_inconsistent")
          expect(sales_log.errors[:buy1livein]).to include I18n.t("validations.household.buylivein.buyers_will_live_in_property_values_inconsistent")
        end
      end

      context "and we don't know whether buyer one will live in the property" do
        let(:buy1livein) { nil }

        it "does not add validations regardless of whether buyer two will live in the property" do
          sales_log.buy2livein = 1
          household_validator.validate_buyers_living_in_property(sales_log)
          expect(sales_log.errors).to be_empty
          sales_log.buy2livein = 2
          household_validator.validate_buyers_living_in_property(sales_log)
          expect(sales_log.errors).to be_empty
        end
      end
    end
  end

  describe "#validate_buyer1_previous_tenure" do
    let(:record) { build(:sales_log) }

    let(:now) { Time.zone.local(2024, 4, 4) }

    before do
      Timecop.freeze(now)
      Singleton.__init__(FormHandler)
      record.ownershipsch = 2
      record.saledate = now
    end

    after do
      Timecop.return
      Singleton.__init__(FormHandler)
    end

    it "adds an error when previous tenure is not valid" do
      [3, 4, 5, 6, 7, 9, 0].each do |prevten|
        record.prevten = prevten
        household_validator.validate_buyer1_previous_tenure(record)
        expect(record.errors["prevten"]).to include("Buyer 1’s previous tenure should be “local authority tenant” or “private registered provider or housing association tenant” for discounted sales")
        expect(record.errors["ownershipsch"]).to include("Buyer 1’s previous tenure should be “local authority tenant” or “private registered provider or housing association tenant” for discounted sales")
      end
    end

    it "does not add an error when previous tenure is allowed" do
      [1, 2].each do |prevten|
        record.prevten = prevten
        household_validator.validate_buyer1_previous_tenure(record)
        expect(record.errors).to be_empty
      end
    end

    it "does not add an error if previous tenure is not given" do
      record.prevten = nil
      household_validator.validate_buyer1_previous_tenure(record)
      expect(record.errors).to be_empty
    end

    it "does not add an error for shared ownership sale" do
      record.ownershipsch = 1

      [1, 2, 3, 4, 5, 6, 7, 9, 0].each do |prevten|
        record.prevten = prevten
        household_validator.validate_buyer1_previous_tenure(record)
        expect(record.errors).to be_empty
      end
    end

    it "does not add an error for outright sale" do
      record.ownershipsch = 3

      [1, 2, 3, 4, 5, 6, 7, 9, 0].each do |prevten|
        record.prevten = prevten
        household_validator.validate_buyer1_previous_tenure(record)
        expect(record.errors).to be_empty
      end
    end

    context "with 23/24 logs" do
      let(:now) { Time.zone.local(2023, 4, 4) }

      it "does not add an error for outright sale" do
        record.ownershipsch = 2

        [1, 2, 3, 4, 5, 6, 7, 9, 0].each do |prevten|
          record.prevten = prevten
          household_validator.validate_buyer1_previous_tenure(record)
          expect(record.errors).to be_empty
        end
      end
    end
  end
end
