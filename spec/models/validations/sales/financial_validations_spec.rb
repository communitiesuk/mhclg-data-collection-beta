require "rails_helper"

RSpec.describe Validations::Sales::FinancialValidations do
  subject(:financial_validator) { validator_class.new }

  let(:validator_class) { Class.new { include Validations::Sales::FinancialValidations } }

  describe "income validations" do
    let(:record) { FactoryBot.create(:sales_log, ownershipsch: 1, la: "E08000035") }

    context "with shared ownership" do
      context "and non london borough" do
        (0..8).each do |ecstat|
          it "adds an error when buyer 1 income is over hard max for ecstat #{ecstat}" do
            record.income1 = 85_000
            record.ecstat1 = ecstat
            financial_validator.validate_income1(record)
            expect(record.errors["income1"])
                .to include(match I18n.t("validations.financial.income1.over_hard_max", hard_max: 80_000))
            expect(record.errors["ecstat1"])
                .to include(match I18n.t("validations.financial.income1.over_hard_max", hard_max: 80_000))
            expect(record.errors["ownershipsch"])
                .to include(match I18n.t("validations.financial.income1.over_hard_max", hard_max: 80_000))
            expect(record.errors["la"])
                .to include(match I18n.t("validations.financial.income1.over_hard_max", hard_max: 80_000))
            expect(record.errors["postcode_full"])
                .to include(match I18n.t("validations.financial.income1.over_hard_max", hard_max: 80_000))
          end
        end

        it "validates that the income is within the expected range for the tenant’s employment status" do
          record.income1 = 75_000
          record.ecstat1 = 1
          financial_validator.validate_income1(record)
          expect(record.errors["income1"]).to be_empty
          expect(record.errors["ecstat1"]).to be_empty
          expect(record.errors["ownershipsch"]).to be_empty
          expect(record.errors["la"]).to be_empty
          expect(record.errors["postcode_full"]).to be_empty
        end
      end

      context "and a london borough" do
        before do
          record.update!(la: "E09000030")
          record.reload
        end

        (0..8).each do |ecstat|
          it "adds an error when buyer 1 income is over hard max for ecstat #{ecstat}" do
            record.income1 = 95_000
            record.ecstat1 = ecstat
            financial_validator.validate_income1(record)
            expect(record.errors["income1"])
                .to include(match I18n.t("validations.financial.income1.over_hard_max", hard_max: 90_000))
            expect(record.errors["ecstat1"])
                .to include(match I18n.t("validations.financial.income1.over_hard_max", hard_max: 90_000))
            expect(record.errors["ownershipsch"])
                .to include(match I18n.t("validations.financial.income1.over_hard_max", hard_max: 90_000))
            expect(record.errors["la"])
                .to include(match I18n.t("validations.financial.income1.over_hard_max", hard_max: 90_000))
            expect(record.errors["postcode_full"])
                .to include(match I18n.t("validations.financial.income1.over_hard_max", hard_max: 90_000))
          end
        end

        it "validates that the income is within the expected range for the tenant’s employment status" do
          record.income1 = 85_000
          record.ecstat1 = 1
          financial_validator.validate_income1(record)
          expect(record.errors["income1"]).to be_empty
          expect(record.errors["ecstat1"]).to be_empty
          expect(record.errors["ownershipsch"]).to be_empty
          expect(record.errors["la"]).to be_empty
          expect(record.errors["postcode_full"]).to be_empty
        end
      end
    end
  end

  describe "#validate_cash_discount" do
    let(:record) { FactoryBot.create(:sales_log) }

    it "adds an error if the cash discount is below zero" do
      record.cashdis = -1
      financial_validator.validate_cash_discount(record)
      expect(record.errors["cashdis"]).to include(match I18n.t("validations.financial.cash_discount_invalid"))
    end

    it "adds an error if the cash discount is one million or more" do
      record.cashdis = 1_000_000
      financial_validator.validate_cash_discount(record)
      expect(record.errors["cashdis"]).to include(match I18n.t("validations.financial.cash_discount_invalid"))
    end

    it "does not add an error if the cash discount is in the expected range" do
      record.cashdis = 10_000
      financial_validator.validate_cash_discount(record)
      expect(record.errors["cashdis"]).to be_empty
    end
  end
end
