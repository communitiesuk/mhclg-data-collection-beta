module TenancyValidations
  # Validations methods need to be called 'validate_<page_name>' to run on model save
  # or 'validate_' to run on submit as well
  def validate_fixed_term_tenancy(record)
    is_present = record.tenancylength.present?
    is_in_range = record.tenancylength.to_i.between?(2, 99)
    is_secure = record.tenancy == "Fixed term – Secure"
    is_ast = record.tenancy == "Fixed term – Assured Shorthold Tenancy (AST)"
    conditions = [
      { condition: !(is_secure || is_ast) && is_present, error: "You must only answer the fixed term tenancy length question if the tenancy type is fixed term" },
      { condition: is_ast && !is_in_range,  error: "Fixed term – Assured Shorthold Tenancy (AST) should be between 2 and 99 years" },
      { condition: is_secure && (!is_in_range && is_present), error: "Fixed term – Secure should be between 2 and 99 years or not specified" },
    ]

    conditions.each { |condition| condition[:condition] ? (record.errors.add :tenancylength, condition[:error]) : nil }
  end

  def validate_other_tenancy_type(record)
    validate_other_field(record, "tenancy", "tenancyother")
  end
end
