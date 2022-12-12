module Validations::Sales::FinancialValidations
  # Validations methods need to be called 'validate_<page_name>' to run on model save
  # or 'validate_' to run on submit as well

  def validate_income1(record)
    if record.ecstat1 && record.income1 && record.ownershipsch == 1
      if record.buyer_1_child? && record.income1.positive?
        record.errors.add :income1, I18n.t("validations.financial.income1.child_income")
      elsif record.income1 > 80_000
        record.errors.add :income1, I18n.t("validations.financial.income1.over_hard_max", hard_max: 80_000)
      end
    end
  end
end
