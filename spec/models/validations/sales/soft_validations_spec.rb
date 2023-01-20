require "rails_helper"

RSpec.describe Validations::Sales::SoftValidations do
  let(:record) { FactoryBot.create(:sales_log) }

  describe "income1 min validations" do
    context "when validating soft min" do
      it "returns false if no income1 is given" do
        record.income1 = nil
        expect(record)
          .not_to be_income1_under_soft_min
      end

      it "returns false if no ecstat1 is given" do
        record.ecstat1 = nil
        expect(record)
          .not_to be_income1_under_soft_min
      end

      [
        {
          income1: 4500,
          ecstat1: 1,
        },
        {
          income1: 1400,
          ecstat1: 2,
        },
        {
          income1: 999,
          ecstat1: 3,
        },
        {
          income1: 1899,
          ecstat1: 5,
        },
        {
          income1: 1888,
          ecstat1: 0,
        },
      ].each do |test_case|
        it "returns true if income1 is below soft min for ecstat1 #{test_case[:ecstat1]}" do
          record.income1 = test_case[:income1]
          record.ecstat1 = test_case[:ecstat1]
          expect(record)
            .to be_income1_under_soft_min
        end
      end

      [
        {
          income1: 5001,
          ecstat1: 1,
        },
        {
          income1: 1600,
          ecstat1: 2,
        },
        {
          income1: 1004,
          ecstat1: 3,
        },
        {
          income1: 2899,
          ecstat1: 4,
        },
        {
          income1: 2899,
          ecstat1: 5,
        },
        {
          income1: 5,
          ecstat1: 6,
        },
        {
          income1: 10_888,
          ecstat1: 0,
        },
      ].each do |test_case|
        it "returns false if income1 is over soft min for ecstat1 #{test_case[:ecstat1]}" do
          record.income1 = test_case[:income1]
          record.ecstat1 = test_case[:ecstat1]
          expect(record)
            .not_to be_income1_under_soft_min
        end
      end
    end
  end

  describe "mortgage amount validations" do
    context "when validating soft max" do
      it "returns false if no mortgage is given" do
        record.mortgage = nil
        expect(record)
          .not_to be_mortgage_over_soft_max
      end

      it "returns false if no inc1mort is given" do
        record.inc1mort = nil
        record.mortgage = 20_000
        expect(record)
          .not_to be_mortgage_over_soft_max
      end

      it "returns false if no inc2mort is given" do
        record.inc1mort = 2
        record.inc2mort = nil
        record.mortgage = 20_000
        expect(record)
          .not_to be_mortgage_over_soft_max
      end

      it "returns false if no income1 is given and inc1mort is yes" do
        record.inc1mort = 1
        record.inc2mort = 2
        record.income1 = nil
        record.mortgage = 20_000
        expect(record)
          .not_to be_mortgage_over_soft_max
      end

      it "returns false if no income2 is given and inc2mort is yes" do
        record.inc1mort = 2
        record.inc2mort = 1
        record.income2 = nil
        record.mortgage = 20_000
        expect(record)
          .not_to be_mortgage_over_soft_max
      end

      it "returns true if only income1 is used for mortgage and it is less than 1/5 of the mortgage" do
        record.inc1mort = 1
        record.income1 = 10_000
        record.mortgage = 51_000
        record.inc2mort = 2
        expect(record)
          .to be_mortgage_over_soft_max
      end

      it "returns false if only income1 is used for mortgage and it is more than 1/5 of the mortgage" do
        record.inc1mort = 1
        record.income1 = 10_000
        record.mortgage = 44_000
        record.inc2mort = 2
        expect(record)
          .not_to be_mortgage_over_soft_max
      end

      it "returns true if only income2 is used for mortgage and it is less than 1/5 of the mortgage" do
        record.inc1mort = 2
        record.inc2mort = 1
        record.income2 = 10_000
        record.mortgage = 51_000
        expect(record)
          .to be_mortgage_over_soft_max
      end

      it "returns false if only income2 is used for mortgage and it is more than 1/5 of the mortgage" do
        record.inc1mort = 2
        record.inc2mort = 1
        record.income2 = 10_000
        record.mortgage = 44_000
        expect(record)
          .not_to be_mortgage_over_soft_max
      end

      it "returns true if income1 and income2 are used for mortgage and their sum is less than 1/5 of the mortgage" do
        record.inc1mort = 1
        record.inc2mort = 1
        record.income1 = 10_000
        record.income2 = 10_000
        record.mortgage = 101_000
        expect(record)
          .to be_mortgage_over_soft_max
      end

      it "returns false if income1 and income2 are used for mortgage and their sum is more than 1/5 of the mortgage" do
        record.inc1mort = 1
        record.inc2mort = 1
        record.income1 = 8_000
        record.income2 = 17_000
        record.mortgage = 124_000
        expect(record)
          .not_to be_mortgage_over_soft_max
      end

      it "returns true if neither of the incomes are used for mortgage and the mortgage is more than 0" do
        record.inc1mort = 2
        record.inc2mort = 2
        record.mortgage = 124_000
        expect(record)
          .to be_mortgage_over_soft_max
      end

      it "returns false if neither of the incomes are used for mortgage and the mortgage is 0" do
        record.inc1mort = 2
        record.inc2mort = 2
        record.mortgage = 0
        expect(record)
          .not_to be_mortgage_over_soft_max
      end
    end

    context "when validating extra borrowing" do
      it "returns false if extrabor not present" do
        record.mortgage = 50_000
        record.deposit = 40_000
        record.value = 100_000
        record.discount = 11
        expect(record)
          .not_to be_extra_borrowing_expected_but_not_reported
      end

      it "returns false if deposit not present" do
        record.extrabor = 2
        record.deposit = 40_000
        record.value = 100_000
        record.discount = 11
        expect(record)
          .not_to be_extra_borrowing_expected_but_not_reported
      end

      it "returns false if deposit not present" do
        record.extrabor = 2
        record.mortgage = 50_000
        record.value = 100_000
        record.discount = 11
        expect(record)
          .not_to be_extra_borrowing_expected_but_not_reported
      end

      it "returns false if value not present" do
        record.extrabor = 2
        record.mortgage = 50_000
        record.deposit = 40_000
        record.discount = 11
        expect(record)
          .not_to be_extra_borrowing_expected_but_not_reported
      end

      it "returns false if discount not present" do
        record.extrabor = 2
        record.mortgage = 50_000
        record.deposit = 40_000
        record.value = 100_000
        expect(record)
          .not_to be_extra_borrowing_expected_but_not_reported
      end

      it "returns false if extra borrowing expected and reported" do
        record.extrabor = 1
        record.mortgage = 50_000
        record.deposit = 40_000
        record.value = 100_000
        record.discount = 11
        expect(record)
          .not_to be_extra_borrowing_expected_but_not_reported
      end

      it "returns true if extra borrowing expected but not reported" do
        record.extrabor = 2
        record.mortgage = 50_000
        record.deposit = 40_000
        record.value = 100_000
        record.discount = 11
        expect(record)
          .to be_extra_borrowing_expected_but_not_reported
      end
    end
  end

  describe "savings amount validations" do
    context "when validating soft max" do
      it "returns false if no savings is given" do
        record.savings = nil
        expect(record)
          .not_to be_savings_over_soft_max
      end

      it "savings is over 100_000" do
        record.savings = 100_001
        expect(record)
          .to be_savings_over_soft_max
      end

      it "savings is under 100_000" do
        record.savings = 99_999
        expect(record)
          .not_to be_mortgage_over_soft_max
      end
    end
  end

  describe "deposit amount validations" do
    context "when validating soft max" do
      it "returns false if no savings is given" do
        record.savings = nil
        record.deposit = 8_001
        expect(record)
          .not_to be_deposit_over_soft_max
      end

      it "returns false if no deposit is given" do
        record.deposit = nil
        record.savings = 6_000
        expect(record)
          .not_to be_deposit_over_soft_max
      end

      it "returns true if deposit is more than 4/3 of savings" do
        record.deposit = 8_001
        record.savings = 6_000
        expect(record)
          .to be_deposit_over_soft_max
      end

      it "returns fals if deposit is less than 4/3 of savings" do
        record.deposit = 7_999
        record.savings = 6_000
        expect(record)
          .not_to be_deposit_over_soft_max
      end
    end
  end
end
