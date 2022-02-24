module Validations::TenancyValidations
  # Validations methods need to be called 'validate_<page_name>' to run on model save
  # or 'validate_' to run on submit as well
  include Validations::SharedValidations

  def validate_fixed_term_tenancy(record)
    is_present = record.tenancylength.present?
    is_in_range = record.tenancylength.to_i.between?(2, 99)
    conditions = [
      {
        condition: !(record.is_secure_tenancy? || record.is_assured_shorthold_tenancy?) && is_present,
        error: I18n.t("validations.tenancy.length.fixed_term_not_required"),
      },
      {
        condition: (record.is_assured_shorthold_tenancy? && !is_in_range) && is_present,
        error: I18n.t("validations.tenancy.length.shorthold"),
      },
      {
        condition: record.is_secure_tenancy? && (!is_in_range && is_present),
        error: I18n.t("validations.tenancy.length.secure"),
      },
    ]

    conditions.each do |condition|
      next unless condition[:condition]

      record.errors.add :tenancylength, condition[:error]
      record.errors.add :tenancy, condition[:error]
    end
  end

  def validate_other_tenancy_type(record)
    validate_other_field(record, 4, :tenancy, :tenancyother)
  end

  def validate_tenancy_type(record)
    if record.tenancy.present? && !record.is_secure_tenancy? && record.is_internal_transfer?
      record.errors.add :tenancy, I18n.t("validations.tenancy.internal_transfer")
      record.errors.add :referral, I18n.t("validations.household.referral.cannot_be_secure_tenancy")
    end
  end
end
