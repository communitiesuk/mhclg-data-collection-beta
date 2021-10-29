module TenancyValidations
  # Validations methods need to be called 'validate_' to run on model save
  def validate_fixed_term_tenancy(record)
    is_present = record.fixed_term_tenancy.present?
    is_in_range = record.fixed_term_tenancy.to_i.between?(2, 99)
    is_secure = record.tenancy_type == "Fixed term – Secure"
    is_ast = record.tenancy_type == "Fixed term – Assured Shorthold Tenancy (AST)"
    conditions = [
      { condition: !(is_secure || is_ast) && is_present, error: "You must only answer the fixed term tenancy length question if the tenancy type is fixed term" },
      { condition: is_ast && !is_in_range,  error: "Fixed term – Assured Shorthold Tenancy (AST) should be between 2 and 99 years" },
      { condition: is_secure && (!is_in_range && is_present), error: "Fixed term – Secure should be between 2 and 99 years or not specified" },
    ]

    conditions.each { |condition| condition[:condition] ? (record.errors.add :fixed_term_tenancy, condition[:error]) : nil }
  end

  def validate_other_tenancy_type(record)
    validate_other_field(record, "tenancy_type", "other_tenancy_type")
  end
end
