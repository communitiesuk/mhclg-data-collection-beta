require "rails_helper"

RSpec.describe Validations::Sales::PropertyValidations do
  subject(:property_validator) { property_validator_class.new }

  let(:property_validator_class) { Class.new { include Validations::Sales::PropertyValidations } }

  describe "#validate_postcodes_match_if_discounted_ownership" do
    context "when ownership scheme is not discounted ownership" do
      let(:record) { build(:sales_log, ownershipsch: 1) }

      it "when postcodes match no error is added" do
        record.postcode_full = "SW1A 1AA"
        record.ppostcode_full = "SW1A 1AA"

        property_validator.validate_postcodes_match_if_discounted_ownership(record)
        expect(record.errors["postcode_full"]).to be_empty
      end
    end

    context "when ownership scheme is discounted ownership" do
      let(:record) { build(:sales_log, ownershipsch: 2) }

      it "when ppostcode_full is not present no error is added" do
        record.postcode_full = "SW1A 1AA"
        property_validator.validate_postcodes_match_if_discounted_ownership(record)
        expect(record.errors["postcode_full"]).to be_empty
        expect(record.errors["ppostcode_full"]).to be_empty
        expect(record.errors["ownershipsch"]).to be_empty
      end

      it "when postcode_full is not present no error is added" do
        record.ppostcode_full = "SW1A 1AA"
        property_validator.validate_postcodes_match_if_discounted_ownership(record)
        expect(record.errors["postcode_full"]).to be_empty
        expect(record.errors["ppostcode_full"]).to be_empty
        expect(record.errors["ownershipsch"]).to be_empty
      end

      it "when postcodes match no error is added" do
        record.postcode_full = "SW1A 1AA"
        record.ppostcode_full = "SW1A 1AA"
        property_validator.validate_postcodes_match_if_discounted_ownership(record)
        expect(record.errors["postcode_full"]).to be_empty
        expect(record.errors["ppostcode_full"]).to be_empty
        expect(record.errors["ownershipsch"]).to be_empty
      end

      it "when postcodes do not match an error is added" do
        record.postcode_full = "SW1A 1AA"
        record.ppostcode_full = "SW1A 0AA"
        property_validator.validate_postcodes_match_if_discounted_ownership(record)
        expect(record.errors["postcode_full"]).to include(match I18n.t("validations.property.postcode.must_match_previous"))
        expect(record.errors["ppostcode_full"]).to include(match I18n.t("validations.property.postcode.must_match_previous"))
        expect(record.errors["ownershipsch"]).to include(match I18n.t("validations.property.postcode.must_match_previous"))
      end
    end
  end

  describe "#validate_property_unit_type" do
    context "when number of bedrooms is 1" do
      let(:record) { build(:sales_log, beds: 1, proptype: 2) }

      it "does not add an error if it's a bedsit" do
        property_validator.validate_bedsit_number_of_beds(record)
        expect(record.errors).not_to be_present
      end
    end

    context "when number of bedrooms is > 1" do
      let(:record) { build(:sales_log, beds: 2, proptype: 2) }

      it "does add an error if it's a bedsit" do
        property_validator.validate_bedsit_number_of_beds(record)
        expect(record.errors.added?(:proptype, "Answer cannot be 'Bedsit' if the property has 2 or more bedrooms")).to be true
        expect(record.errors.added?(:beds, "Number of bedrooms must be 1 if the property is a bedsit")).to be true
      end

      it "does not add an error if proptype is undefined" do
        record.update!(proptype: nil)
        property_validator.validate_bedsit_number_of_beds(record)
        expect(record.errors).not_to be_present
      end
    end

    context "when number of bedrooms is undefined" do
      let(:record) { build(:sales_log, beds: nil, proptype: 2) }

      it "does not add an error if it's a bedsit" do
        property_validator.validate_bedsit_number_of_beds(record)
        expect(record.errors).not_to be_present
      end
    end
  end

  describe "#validate_uprn" do
    context "when within length limit but alphanumeric" do
      let(:record) { build(:sales_log, uprn: "123abc") }

      it "adds an error" do
        property_validator.validate_uprn(record)
        expect(record.errors.added?(:uprn, "UPRN must be 12 digits or less")).to be true
      end
    end

    context "when over the length limit" do
      let(:record) { build(:sales_log, uprn: "1234567890123") }

      it "adds an error" do
        property_validator.validate_uprn(record)
        expect(record.errors.added?(:uprn, "UPRN must be 12 digits or less")).to be true
      end
    end

    context "when within the limit and only numeric" do
      let(:record) { build(:sales_log, uprn: "123456789012") }

      it "does not add an error" do
        property_validator.validate_uprn(record)
        expect(record.errors).not_to be_present
      end
    end
  end
end
