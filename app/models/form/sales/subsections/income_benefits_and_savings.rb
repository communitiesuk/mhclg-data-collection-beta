class Form::Sales::Subsections::IncomeBenefitsAndSavings < ::Form::Subsection
  def initialize(id, hsh, section)
    super
    @id = "income_benefits_and_savings"
    @label = "Income, benefits and savings"
  end

  def depends_on
    if form.start_year_2025_or_later?
      [{ "setup_completed?" => true, "is_staircase?" => false }]
    else
      [{ "setup_completed?" => true }]
    end
  end

  def pages
    @pages ||= [
      Form::Sales::Pages::Buyer1Income.new(nil, nil, self),
      Form::Sales::Pages::Buyer1IncomeMinValueCheck.new("buyer_1_income_min_value_check", nil, self),
      Form::Sales::Pages::Buyer1IncomeMaxValueCheck.new("buyer_1_income_max_value_check", nil, self, check_answers_card_number: 1),
      Form::Sales::Pages::CombinedIncomeMaxValueCheck.new("buyer_1_combined_income_max_value_check", nil, self, check_answers_card_number: 1),
      Form::Sales::Pages::MortgageValueCheck.new("buyer_1_income_mortgage_value_check", nil, self, 1),
      Form::Sales::Pages::Buyer1Mortgage.new(nil, nil, self),
      Form::Sales::Pages::MortgageValueCheck.new("buyer_1_mortgage_value_check", nil, self, 1),
      Form::Sales::Pages::Buyer2Income.new(nil, nil, self),
      Form::Sales::Pages::MortgageValueCheck.new("buyer_2_income_mortgage_value_check", nil, self, 2),
      Form::Sales::Pages::Buyer2IncomeMinValueCheck.new("buyer_2_income_min_value_check", nil, self),
      Form::Sales::Pages::Buyer2IncomeMaxValueCheck.new("buyer_2_income_max_value_check", nil, self, check_answers_card_number: 2),
      Form::Sales::Pages::CombinedIncomeMaxValueCheck.new("buyer_2_combined_income_max_value_check", nil, self, check_answers_card_number: 2),
      Form::Sales::Pages::Buyer2Mortgage.new(nil, nil, self),
      Form::Sales::Pages::MortgageValueCheck.new("buyer_2_mortgage_value_check", nil, self, 2),
      Form::Sales::Pages::HousingBenefits.new("housing_benefits_joint_purchase", nil, self, joint_purchase: true),
      Form::Sales::Pages::HousingBenefits.new("housing_benefits_not_joint_purchase", nil, self, joint_purchase: false),
      Form::Sales::Pages::Savings.new("savings_joint_purchase", nil, self, joint_purchase: true),
      Form::Sales::Pages::Savings.new("savings", nil, self, joint_purchase: false),
      Form::Sales::Pages::SavingsValueCheck.new("savings_joint_purchase_value_check", nil, self, joint_purchase: true),
      Form::Sales::Pages::SavingsValueCheck.new("savings_value_check", nil, self, joint_purchase: false),
      Form::Sales::Pages::DepositValueCheck.new("savings_deposit_joint_purchase_value_check", nil, self, joint_purchase: true),
      Form::Sales::Pages::DepositValueCheck.new("savings_deposit_value_check", nil, self, joint_purchase: false),
      Form::Sales::Pages::PreviousOwnership.new("previous_ownership_joint_purchase", nil, self, joint_purchase: true),
      Form::Sales::Pages::PreviousOwnership.new("previous_ownership_not_joint_purchase", nil, self, joint_purchase: false),
      previous_shared_page,
    ].compact
  end

  def displayed_in_tasklist?(log)
    return true unless form.start_year_2025_or_later?

    log.staircase != 1
  end

private

  def previous_shared_page
    if form.start_date.year >= 2023
      Form::Sales::Pages::PreviousShared.new(nil, nil, self)
    end
  end
end
