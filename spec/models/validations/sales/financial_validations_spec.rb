require "rails_helper"

RSpec.describe Validations::Sales::FinancialValidations do
  subject(:financial_validator) { validator_class.new }

  let(:validator_class) { Class.new { include Validations::Sales::FinancialValidations } }

  describe "income validations for shared ownership" do
    let(:record) { FactoryBot.create(:sales_log, ownershipsch: 1) }

    context "when buying in a non london borough" do
      before do
        record.update!(la: "E08000035")
        record.reload
      end

      it "adds errors if buyer 1 has income over 80,000" do
        record.income1 = 85_000
        financial_validator.validate_income1(record)
        expect(record.errors["income1"]).to include(match I18n.t("validations.financial.income.over_hard_max_for_outside_london"))
        expect(record.errors["ownershipsch"]).to include(match I18n.t("validations.financial.income.over_hard_max_for_outside_london"))
        expect(record.errors["la"]).to include(match I18n.t("validations.financial.income.over_hard_max_for_outside_london"))
        expect(record.errors["postcode_full"]).to include(match I18n.t("validations.financial.income.over_hard_max_for_outside_london"))
      end

      it "adds errors if buyer 2 has income over 80,000" do
        record.income2 = 85_000
        financial_validator.validate_income2(record)
        expect(record.errors["income2"]).to include(match I18n.t("validations.financial.income.over_hard_max_for_outside_london"))
        expect(record.errors["ownershipsch"]).to include(match I18n.t("validations.financial.income.over_hard_max_for_outside_london"))
        expect(record.errors["la"]).to include(match I18n.t("validations.financial.income.over_hard_max_for_outside_london"))
        expect(record.errors["postcode_full"]).to include(match I18n.t("validations.financial.income.over_hard_max_for_outside_london"))
      end

      it "does not add errors if buyer 1 has income below 80_000" do
        record.income1 = 75_000
        financial_validator.validate_income1(record)
        expect(record.errors).to be_empty
      end

      it "does not add errors if buyer 2 has income below 80_000" do
        record.income2 = 75_000
        financial_validator.validate_income2(record)
        expect(record.errors).to be_empty
      end

      it "adds errors when combined income is over 80_000" do
        record.income1 = 45_000
        record.income2 = 40_000
        financial_validator.validate_combined_income(record)
        expect(record.errors["income1"]).to include(match I18n.t("validations.financial.income.combined_over_hard_max_for_outside_london"))
        expect(record.errors["income2"]).to include(match I18n.t("validations.financial.income.combined_over_hard_max_for_outside_london"))
      end

      it "does not add errors when combined income is under 80_000" do
        record.income1 = 35_000
        record.income2 = 40_000
        financial_validator.validate_combined_income(record)
        expect(record.errors).to be_empty
      end
    end

    context "when buying in a london borough" do
      before do
        record.update!(la: "E09000030")
        record.reload
      end

      it "adds errors if buyer 1 has income over 90,000" do
        record.income1 = 95_000
        financial_validator.validate_income1(record)
        expect(record.errors["income1"]).to include(match I18n.t("validations.financial.income.over_hard_max_for_london"))
        expect(record.errors["ownershipsch"]).to include(match I18n.t("validations.financial.income.over_hard_max_for_london"))
        expect(record.errors["la"]).to include(match I18n.t("validations.financial.income.over_hard_max_for_london"))
        expect(record.errors["postcode_full"]).to include(match I18n.t("validations.financial.income.over_hard_max_for_london"))
      end

      it "adds errors if buyer 2 has income over 90,000" do
        record.income2 = 95_000
        financial_validator.validate_income2(record)
        expect(record.errors["income2"]).to include(match I18n.t("validations.financial.income.over_hard_max_for_london"))
        expect(record.errors["ownershipsch"]).to include(match I18n.t("validations.financial.income.over_hard_max_for_london"))
        expect(record.errors["la"]).to include(match I18n.t("validations.financial.income.over_hard_max_for_london"))
        expect(record.errors["postcode_full"]).to include(match I18n.t("validations.financial.income.over_hard_max_for_london"))
      end

      it "does not add errors if buyer 1 has income below 90_000" do
        record.income1 = 75_000
        financial_validator.validate_income1(record)
        expect(record.errors).to be_empty
      end

      it "does not add errors if buyer 2 has income below 90_000" do
        record.income2 = 75_000
        financial_validator.validate_income2(record)
        expect(record.errors).to be_empty
      end

      it "adds errors when combined income is over 90_000" do
        record.income1 = 55_000
        record.income2 = 40_000
        financial_validator.validate_combined_income(record)
        expect(record.errors["income1"]).to include(match I18n.t("validations.financial.income.combined_over_hard_max_for_london"))
        expect(record.errors["income2"]).to include(match I18n.t("validations.financial.income.combined_over_hard_max_for_london"))
      end

      it "does not add errors when combined income is under 90_000" do
        record.income1 = 35_000
        record.income2 = 40_000
        financial_validator.validate_combined_income(record)
        expect(record.errors).to be_empty
      end
    end
  end

  describe "#validate_mortgage" do
    let(:record) { FactoryBot.create(:sales_log) }

    it "adds an error is the mortgage is zero" do
      record.mortgageused = 1
      record.mortgage = 0
      financial_validator.validate_mortgage(record)
      expect(record.errors[:mortgage]).to include I18n.t("validations.financial.mortgage")
    end

    it "does not add an error is the mortgage is positive" do
      record.mortgageused = 1
      record.mortgage = 234
      financial_validator.validate_mortgage(record)
      expect(record.errors).to be_empty
    end
  end

  describe "#validate_percentage_bought_not_greater_than_percentage_owned" do
    let(:record) { FactoryBot.create(:sales_log) }

    it "does not add an error if the percentage bought is less than the percentage owned" do
      record.stairbought = 20
      record.stairowned = 40
      financial_validator.validate_percentage_bought_not_greater_than_percentage_owned(record)
      expect(record.errors).to be_empty
    end

    it "does not add an error if the percentage bought is equal to the percentage owned" do
      record.stairbought = 30
      record.stairowned = 30
      financial_validator.validate_percentage_bought_not_greater_than_percentage_owned(record)
      expect(record.errors).to be_empty
    end

    it "adds an error to stairowned and not stairbought if the percentage bought is more than the percentage owned" do
      record.stairbought = 50
      record.stairowned = 40
      financial_validator.validate_percentage_bought_not_greater_than_percentage_owned(record)
      expect(record.errors["stairowned"]).to include(match I18n.t("validations.financial.staircasing.percentage_bought_must_be_greater_than_percentage_owned"))
    end
  end

  describe "#validate_percentage_bought_not_equal_percentage_owned" do
    let(:record) { FactoryBot.create(:sales_log) }

    context "with 24/25 logs" do
      before do
        record.saledate = Time.zone.local(2024, 4, 3)
        record.save!(validate: false)
      end

      it "does not add an error if the percentage bought is less than the percentage owned" do
        record.stairbought = 20
        record.stairowned = 40
        financial_validator.validate_percentage_bought_not_equal_percentage_owned(record)
        expect(record.errors).to be_empty
      end

      it "adds an error if the percentage bought is equal to the percentage owned" do
        record.stairbought = 30
        record.stairowned = 30
        financial_validator.validate_percentage_bought_not_equal_percentage_owned(record)
        expect(record.errors["stairowned"]).to include("The percentage bought is 30% and the percentage owned in total is 30%. These figures cannot be the same.")
        expect(record.errors["stairbought"]).to include("The percentage bought is 30% and the percentage owned in total is 30%. These figures cannot be the same.")
      end

      it "does not add an error to stairowned and not stairbought if the percentage bought is more than the percentage owned" do
        record.stairbought = 50
        record.stairowned = 40
        financial_validator.validate_percentage_bought_not_equal_percentage_owned(record)
        expect(record.errors).to be_empty
      end
    end

    context "with 23/24 logs" do
      before do
        record.saledate = Time.zone.local(2023, 4, 3)
        record.save!(validate: false)
      end

      it "does not add an error if the percentage bought is equal to the percentage owned" do
        record.stairbought = 30
        record.stairowned = 30
        financial_validator.validate_percentage_bought_not_equal_percentage_owned(record)
        expect(record.errors).to be_empty
      end
    end
  end

  describe "#validate_monthly_leasehold_charges" do
    let(:record) { FactoryBot.create(:sales_log) }

    it "does not add an error if monthly leasehold charges are positive" do
      record.mscharge = 2345
      financial_validator.validate_monthly_leasehold_charges(record)
      expect(record.errors).to be_empty
    end

    it "adds an error if monthly leasehold charges are zero" do
      record.mscharge = 0
      financial_validator.validate_monthly_leasehold_charges(record)
      expect(record.errors[:mscharge]).to include I18n.t("validations.financial.monthly_leasehold_charges.not_zero")
    end
  end

  describe "#validate_percentage_bought_at_least_threshold" do
    let(:record) { FactoryBot.create(:sales_log) }

    it "adds an error to stairbought and type if the percentage bought is less than the threshold (which is 1% by default, but higher for some shared ownership types)" do
      record.stairbought = 9
      [2, 16, 18, 24].each do |type|
        record.type = type
        financial_validator.validate_percentage_bought_at_least_threshold(record)
        expect(record.errors["stairbought"]).to eq(["The minimum increase in equity while staircasing is 10%"])
        expect(record.errors["type"]).to eq(["The minimum increase in equity while staircasing is 10% for this shared ownership type"])
        record.errors.clear
      end

      record.stairbought = 0
      [28, 30, 31, 32].each do |type|
        record.type = type
        financial_validator.validate_percentage_bought_at_least_threshold(record)
        expect(record.errors["stairbought"]).to eq(["The minimum increase in equity while staircasing is 1%"])
        expect(record.errors["type"]).to eq(["The minimum increase in equity while staircasing is 1% for this shared ownership type"])
        record.errors.clear
      end
    end

    it "doesn't add an error to stairbought and type if the percentage bought is less than the threshold (which is 1% by default, but higher for some shared ownership types)" do
      record.stairbought = 10
      [2, 16, 18, 24].each do |type|
        record.type = type
        financial_validator.validate_percentage_bought_at_least_threshold(record)
        expect(record.errors).to be_empty
        record.errors.clear
      end

      record.stairbought = 1
      [28, 30, 31, 32].each do |type|
        record.type = type
        financial_validator.validate_percentage_bought_at_least_threshold(record)
        expect(record.errors).to be_empty
        record.errors.clear
      end
    end
  end

  describe "#validate_child_income" do
    let(:record) { FactoryBot.create(:sales_log) }

    context "when buyer 2 is not a child" do
      before do
        record.update!(ecstat2: rand(0..8))
        record.reload
      end

      it "does not add an error if buyer 2 has an income" do
        record.ecstat2 = rand(0..8)
        record.income2 = 40_000
        financial_validator.validate_child_income(record)
        expect(record.errors).to be_empty
      end
    end

    context "when buyer 2 is a child" do
      it "does not add an error if buyer 2 has no income" do
        record.saledate = Time.zone.local(2023, 4, 3)
        record.ecstat2 = 9
        record.income2 = 0
        financial_validator.validate_child_income(record)
        expect(record.errors).to be_empty
      end

      it "adds errors if buyer 2 has an income" do
        record.saledate = Time.zone.local(2023, 4, 3)
        record.ecstat2 = 9
        record.income2 = 40_000
        financial_validator.validate_child_income(record)
        expect(record.errors["ecstat2"]).to include(match I18n.t("validations.financial.income.child_has_income"))
        expect(record.errors["income2"]).to include(match I18n.t("validations.financial.income.child_has_income"))
      end

      it "does not add an error if the saledate is before the 23/24 collection window" do
        record.saledate = Time.zone.local(2022, 4, 3)
        record.ecstat2 = 9
        record.income2 = 40_000
        financial_validator.validate_child_income(record)
        expect(record.errors).to be_empty
      end
    end
  end

  describe "#validate_equity_in_range_for_year_and_type" do
    let(:record) { FactoryBot.create(:sales_log, saledate: now) }

    around do |example|
      Timecop.freeze(now) do
        example.run
      end
      Timecop.return
    end

    context "with a log in the 22/23 collection year" do
      let(:now) { Time.zone.local(2023, 1, 1) }

      it "adds an error for type 2, equity below min with the correct percentage" do
        record.type = 2
        record.equity = 1
        financial_validator.validate_equity_in_range_for_year_and_type(record)
        expect(record.errors["equity"]).to include(match I18n.t("validations.financial.equity.under_min", min_equity: 25))
        expect(record.errors["type"]).to include(match I18n.t("validations.financial.equity.under_min", min_equity: 25))
      end

      it "adds an error for type 30, equity below min with the correct percentage" do
        record.type = 30
        record.equity = 1
        financial_validator.validate_equity_in_range_for_year_and_type(record)
        expect(record.errors["equity"]).to include(match I18n.t("validations.financial.equity.under_min", min_equity: 10))
        expect(record.errors["type"]).to include(match I18n.t("validations.financial.equity.under_min", min_equity: 10))
      end

      it "does not add an error for equity in range with the correct percentage" do
        record.type = 2
        record.equity = 50
        financial_validator.validate_equity_in_range_for_year_and_type(record)
        expect(record.errors).to be_empty
      end

      it "adds an error for equity above max with the correct percentage" do
        record.type = 2
        record.equity = 90
        financial_validator.validate_equity_in_range_for_year_and_type(record)
        expect(record.errors["equity"]).to include(match I18n.t("validations.financial.equity.over_max", max_equity: 75))
        expect(record.errors["type"]).to include(match I18n.t("validations.financial.equity.over_max", max_equity: 75))
      end
    end

    context "with a log in 23/24 collection year" do
      let(:now) { Time.zone.local(2024, 1, 1) }

      it "adds an error for type 2, equity below min with the correct percentage" do
        record.type = 2
        record.equity = 1
        financial_validator.validate_equity_in_range_for_year_and_type(record)
        expect(record.errors["equity"]).to include(match I18n.t("validations.financial.equity.under_min", min_equity: 25))
        expect(record.errors["type"]).to include(match I18n.t("validations.financial.equity.under_min", min_equity: 25))
      end

      it "adds an error for type 30, equity below min with the correct percentage" do
        record.type = 30
        record.equity = 1
        financial_validator.validate_equity_in_range_for_year_and_type(record)
        expect(record.errors["equity"]).to include(match I18n.t("validations.financial.equity.under_min", min_equity: 10))
        expect(record.errors["type"]).to include(match I18n.t("validations.financial.equity.under_min", min_equity: 10))
      end

      it "does not add an error for equity in range with the correct percentage" do
        record.type = 2
        record.equity = 50
        financial_validator.validate_equity_in_range_for_year_and_type(record)
        expect(record.errors).to be_empty
      end

      it "adds an error for equity above max with the correct percentage" do
        record.type = 2
        record.equity = 90
        financial_validator.validate_equity_in_range_for_year_and_type(record)
        expect(record.errors["equity"]).to include(match I18n.t("validations.financial.equity.over_max", max_equity: 75))
        expect(record.errors["type"]).to include(match I18n.t("validations.financial.equity.over_max", max_equity: 75))
      end
    end
  end

  describe "#validate_shared_ownership_deposit" do
    let(:record) { FactoryBot.create(:sales_log, saledate: now) }

    around do |example|
      Timecop.freeze(now) do
        Singleton.__init__(FormHandler)
        example.run
      end
      Timecop.return
    end

    context "with a log in the 24/25 collection year" do
      let(:now) { Time.zone.local(2024, 4, 2) }

      it "does not add an error if MORTGAGE + DEPOSIT + CASHDIS are equal VALUE * EQUITY/100" do
        record.mortgage = 1000
        record.deposit = 1000
        record.cashdis = 1000
        record.value = 3000
        record.equity = 100

        financial_validator.validate_shared_ownership_deposit(record)
        expect(record.errors["mortgage"]).to be_empty
        expect(record.errors["deposit"]).to be_empty
        expect(record.errors["cashdis"]).to be_empty
        expect(record.errors["value"]).to be_empty
        expect(record.errors["equity"]).to be_empty
      end

      it "does not add an error if mortgage is used and no mortgage is given" do
        record.mortgage = nil
        record.deposit = 1000
        record.cashdis = 1000
        record.value = 3000
        record.equity = 100

        financial_validator.validate_shared_ownership_deposit(record)
        expect(record.errors["mortgage"]).to be_empty
        expect(record.errors["deposit"]).to be_empty
        expect(record.errors["cashdis"]).to be_empty
        expect(record.errors["value"]).to be_empty
        expect(record.errors["equity"]).to be_empty
      end

      it "adds an error if mortgage is not used and no mortgage is given" do
        record.mortgage = nil
        record.mortgageused = 2
        record.deposit = 1000
        record.cashdis = 1000
        record.value = 3000
        record.equity = 100

        financial_validator.validate_shared_ownership_deposit(record)
        expect(record.errors["mortgage"]).to include("The mortgage, deposit, and cash discount added together is £2,000.00. The value times the equity percentage is £3,000.00. These figures should be the same")
        expect(record.errors["deposit"]).to include("The mortgage, deposit, and cash discount added together is £2,000.00. The value times the equity percentage is £3,000.00. These figures should be the same")
        expect(record.errors["cashdis"]).to include("The mortgage, deposit, and cash discount added together is £2,000.00. The value times the equity percentage is £3,000.00. These figures should be the same")
        expect(record.errors["value"]).to include("The mortgage, deposit, and cash discount added together is £2,000.00. The value times the equity percentage is £3,000.00. These figures should be the same")
        expect(record.errors["equity"]).to include("The mortgage, deposit, and cash discount added together is £2,000.00. The value times the equity percentage is £3,000.00. These figures should be the same")
      end

      it "does not add an error if no deposit is given" do
        record.mortgage = 1000
        record.deposit = nil
        record.cashdis = 1000
        record.value = 3000
        record.equity = 100

        financial_validator.validate_shared_ownership_deposit(record)
        expect(record.errors["mortgage"]).to be_empty
        expect(record.errors["deposit"]).to be_empty
        expect(record.errors["cashdis"]).to be_empty
        expect(record.errors["value"]).to be_empty
        expect(record.errors["equity"]).to be_empty
      end

      it "does not add an error if no cashdis is given and cashdis is routed to" do
        record.mortgage = 1000
        record.deposit = 1000
        record.type = 18
        record.cashdis = nil
        record.value = 3000
        record.equity = 100

        financial_validator.validate_shared_ownership_deposit(record)
        expect(record.errors["mortgage"]).to be_empty
        expect(record.errors["deposit"]).to be_empty
        expect(record.errors["cashdis"]).to be_empty
        expect(record.errors["value"]).to be_empty
        expect(record.errors["equity"]).to be_empty
      end

      it "does not add an error if no cashdis is given and cashdis is not routed to" do
        record.mortgageused = 1
        record.mortgage = 1000
        record.deposit = 1000
        record.type = 2
        record.cashdis = nil
        record.value = 3000
        record.equity = 100

        financial_validator.validate_shared_ownership_deposit(record)
        expect(record.errors["mortgage"]).to be_empty
        expect(record.errors["deposit"]).to be_empty
        expect(record.errors["cashdis"]).to be_empty
        expect(record.errors["value"]).to be_empty
        expect(record.errors["equity"]).to be_empty
      end

      it "does not add an error if no value is given" do
        record.mortgage = 1000
        record.deposit = 1000
        record.cashdis = 1000
        record.value = nil
        record.equity = 100

        financial_validator.validate_shared_ownership_deposit(record)
        expect(record.errors["mortgage"]).to be_empty
        expect(record.errors["deposit"]).to be_empty
        expect(record.errors["cashdis"]).to be_empty
        expect(record.errors["value"]).to be_empty
        expect(record.errors["equity"]).to be_empty
      end

      it "does not add an error if no equity is given" do
        record.mortgage = 1000
        record.deposit = 1000
        record.cashdis = 1000
        record.value = 3000
        record.equity = nil

        financial_validator.validate_shared_ownership_deposit(record)
        expect(record.errors["mortgage"]).to be_empty
        expect(record.errors["deposit"]).to be_empty
        expect(record.errors["cashdis"]).to be_empty
        expect(record.errors["value"]).to be_empty
        expect(record.errors["equity"]).to be_empty
      end

      it "adds an error if MORTGAGE + DEPOSIT + CASHDIS are not equal VALUE * EQUITY/100" do
        record.mortgageused = 1
        record.mortgage = 1000
        record.deposit = 1000
        record.cashdis = 1000
        record.value = 4323
        record.equity = 100

        financial_validator.validate_shared_ownership_deposit(record)
        expect(record.errors["mortgage"]).to include("The mortgage, deposit, and cash discount added together is £3,000.00. The value times the equity percentage is £4,323.00. These figures should be the same")
        expect(record.errors["deposit"]).to include("The mortgage, deposit, and cash discount added together is £3,000.00. The value times the equity percentage is £4,323.00. These figures should be the same")
        expect(record.errors["cashdis"]).to include("The mortgage, deposit, and cash discount added together is £3,000.00. The value times the equity percentage is £4,323.00. These figures should be the same")
        expect(record.errors["value"]).to include("The mortgage, deposit, and cash discount added together is £3,000.00. The value times the equity percentage is £4,323.00. These figures should be the same")
        expect(record.errors["equity"]).to include("The mortgage, deposit, and cash discount added together is £3,000.00. The value times the equity percentage is £4,323.00. These figures should be the same")
      end
    end

    context "with a log in 23/24 collection year" do
      let(:now) { Time.zone.local(2024, 1, 1) }

      it "does not add an error if MORTGAGE + DEPOSIT + CASHDIS are not equal VALUE * EQUITY/100" do
        record.mortgage = 1000
        record.deposit = 1000
        record.cashdis = 1000
        record.value = 4323
        record.equity = 100

        financial_validator.validate_shared_ownership_deposit(record)
        expect(record.errors["mortgage"]).to be_empty
        expect(record.errors["deposit"]).to be_empty
        expect(record.errors["cashdis"]).to be_empty
        expect(record.errors["value"]).to be_empty
        expect(record.errors["equity"]).to be_empty
      end
    end
  end
end
