require "rails_helper"

RSpec.describe Validations::SharedValidations do
  subject(:shared_validator) { validator_class.new }

  let(:validator_class) { Class.new { include Validations::SharedValidations } }
  let(:record) { FactoryBot.create(:lettings_log) }
  let(:fake_2021_2022_form) { Form.new("spec/fixtures/forms/2021_2022.json") }

  describe "numeric min max validations" do
    before do
      allow(FormHandler.instance).to receive(:current_lettings_form).and_return(fake_2021_2022_form)
    end

    context "when validating age" do
      it "validates that person 1's age is a number" do
        record.age1 = "random"
        shared_validator.validate_numeric_min_max(record)
        expect(record.errors["age1"])
          .to include(match I18n.t("validations.numeric.valid", field: "Lead tenant’s age", min: 16, max: 120))
      end

      it "validates that other household member ages are a number" do
        record.age2 = "random"
        shared_validator.validate_numeric_min_max(record)
        expect(record.errors["age2"])
          .to include(match I18n.t("validations.numeric.valid", field: "Person 2’s age", min: 1, max: 120))
      end

      it "validates that person 1's age is greater than 16" do
        record.age1 = 15
        shared_validator.validate_numeric_min_max(record)
        expect(record.errors["age1"])
          .to include(match I18n.t("validations.numeric.valid", field: "Lead tenant’s age", min: 16, max: 120))
      end

      it "validates that other household member ages are greater than 1" do
        record.age2 = 0
        shared_validator.validate_numeric_min_max(record)
        expect(record.errors["age2"])
          .to include(match I18n.t("validations.numeric.valid", field: "Person 2’s age", min: 1, max: 120))
      end

      it "validates that person 1's age is less than 121" do
        record.age1 = 121
        shared_validator.validate_numeric_min_max(record)
        expect(record.errors["age1"])
          .to include(match I18n.t("validations.numeric.valid", field: "Lead tenant’s age", min: 16, max: 120))
      end

      it "validates that other household member ages are greater than 121" do
        record.age2 = 123
        shared_validator.validate_numeric_min_max(record)
        expect(record.errors["age2"])
          .to include(match I18n.t("validations.numeric.valid", field: "Person 2’s age", min: 1, max: 120))
      end

      it "validates that person 1's age is between 16 and 120" do
        record.age1 = 63
        shared_validator.validate_numeric_min_max(record)
        expect(record.errors["age1"]).to be_empty
      end

      it "validates that other household member ages are between 1 and 120" do
        record.age6 = 45
        shared_validator.validate_numeric_min_max(record)
        expect(record.errors["age6"]).to be_empty
      end
    end
  end

  describe "radio options validations" do
    it "allows only possible values" do
      record.needstype = 1
      shared_validator.validate_valid_radio_option(record)

      expect(record.errors["needstype"]).to be_empty
    end

    it "denies impossible values" do
      record.needstype = 3
      shared_validator.validate_valid_radio_option(record)

      expect(record.errors["needstype"]).to be_present
      expect(record.errors["needstype"]).to eql(["Enter a valid value for needs type"])
    end
  end
end
