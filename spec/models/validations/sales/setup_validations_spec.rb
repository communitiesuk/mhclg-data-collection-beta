require "rails_helper"

RSpec.describe Validations::Sales::SetupValidations do
  subject(:setup_validator) { validator_class.new }

  let(:validator_class) { Class.new { include Validations::Sales::SetupValidations } }

  describe "#validate_saledate" do
    context "with saledate_next_collection_year_validation_enabled == true" do
      before do
        allow(FeatureToggle).to receive(:saledate_next_collection_year_validation_enabled?).and_return(true)
      end

      context "when saledate is blank" do
        let(:record) { build(:sales_log, saledate: nil) }

        it "does not add an error" do
          setup_validator.validate_saledate(record)

          expect(record.errors).to be_empty
        end
      end

      context "when saledate is in the 22/23 financial year" do
        let(:record) { build(:sales_log, saledate: Time.zone.local(2023, 1, 1)) }

        it "does not add an error" do
          setup_validator.validate_saledate(record)

          expect(record.errors).to be_empty
        end
      end

      context "when saledate is before the 22/23 financial year" do
        let(:record) { build(:sales_log, saledate: Time.zone.local(2020, 1, 1)) }

        it "adds error" do
          setup_validator.validate_saledate(record)

          expect(record.errors[:saledate]).to include("Enter a date within the 22/23 or 23/24 financial years, which is between 1st April 2022 and 31st March 2024")
        end
      end

      context "when saledate is after the 22/23 financial year" do
        let(:record) { build(:sales_log, saledate: Time.zone.local(2025, 4, 1)) }

        it "adds error" do
          setup_validator.validate_saledate(record)

          expect(record.errors[:saledate]).to include("Enter a date within the 22/23 or 23/24 financial years, which is between 1st April 2022 and 31st March 2024")
        end
      end
    end

    context "with saledate_next_collection_year_validation_enabled == false" do
      before do
        allow(FeatureToggle).to receive(:saledate_next_collection_year_validation_enabled?).and_return(false)
      end

      context "when saledate is blank" do
        let(:record) { build(:sales_log, saledate: nil) }

        it "does not add an error" do
          setup_validator.validate_saledate(record)

          expect(record.errors).to be_empty
        end
      end

      context "when saledate is in the 22/23 financial year" do
        let(:record) { build(:sales_log, saledate: Time.zone.local(2023, 1, 1)) }

        it "does not add an error" do
          setup_validator.validate_saledate(record)

          expect(record.errors).to be_empty
        end
      end

      context "when saledate is before the 22/23 financial year" do
        let(:record) { build(:sales_log, saledate: Time.zone.local(2020, 1, 1)) }

        it "adds error" do
          setup_validator.validate_saledate(record)

          expect(record.errors[:saledate]).to include("Enter a date within the 22/23 financial year, which is between 1st April 2022 and 31st March 2023")
        end
      end

      context "when saledate is after the 22/23 financial year" do
        let(:record) { build(:sales_log, saledate: Time.zone.local(2025, 4, 1)) }

        it "adds error" do
          setup_validator.validate_saledate(record)

          expect(record.errors[:saledate]).to include("Enter a date within the 22/23 financial year, which is between 1st April 2022 and 31st March 2023")
        end
      end
    end
  end
end
