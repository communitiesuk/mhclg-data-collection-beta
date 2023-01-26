module Validations::Sales::SaleInformationValidations
  def validate_practical_completion_date_before_saledate(record)
    return if record.saledate.blank? || record.hodate.blank?

    unless record.saledate > record.hodate
      record.errors.add :hodate, "Practical completion or handover date must be before exchange date"
    end
  end

  def validate_years_living_in_property_before_purchase(record)
    return unless record.proplen && record.proplen.nonzero?

    case record.type
    when 18
      record.errors.add :type, I18n.t("validations.sale_information.proplen.social_homebuy")
      record.errors.add :proplen, I18n.t("validations.sale_information.proplen.social_homebuy")
    when 28, 29
      record.errors.add :type, I18n.t("validations.sale_information.proplen.rent_to_buy")
      record.errors.add :proplen, I18n.t("validations.sale_information.proplen.rent_to_buy")
    end
  end

  def validate_exchange_date(record)
    return unless record.exdate && record.saledate

    record.errors.add(:exdate, I18n.t("validations.sale_information.exdate.must_be_before_saledate")) if record.exdate > record.saledate

    return if (record.saledate.to_date - record.exdate.to_date).to_i / 365 < 1

    record.errors.add(:exdate, I18n.t("validations.sale_information.exdate.must_be_less_than_1_year_from_saledate"))
  end

  def validate_previous_property_unit_type(record)
    return unless record.fromprop && record.frombeds

    if record.frombeds != 1 && record.fromprop == 2
      record.errors.add :frombeds, I18n.t("validations.sale_information.previous_property_beds.property_type_bedsit")
      record.errors.add :fromprop, I18n.t("validations.sale_information.previous_property_type.property_type_bedsit")
    end
  end

  def validate_discounted_ownership_value(record)
    return unless record.value && record.deposit && record.ownershipsch
    return unless record.mortgage || record.mortgageused == 2
    return unless record.discount || record.grant || record.type == 29

    discount_amount = record.discount ? record.value * record.discount / 100 : 0
    grant_amount = record.grant || 0
    mortgage_amount = record.mortgage || 0
    value_with_discount = (record.value - discount_amount)
    if mortgage_amount + record.deposit + grant_amount != value_with_discount && record.discounted_ownership_sale?
      %i[mortgage deposit grant value discount ownershipsch].each do |field|
        record.errors.add field, I18n.t("validations.sale_information.discounted_ownership_value", value_with_discount: sprintf("%.2f", value_with_discount))
      end
    end
  end

  def validate_mortgage_length(record)
    return unless record.mortlen

    return if record.mortlen >= 0 && record.mortlen <= 60

    record.errors.add :mortlen, I18n.t("validations.sale_information.mortlen.range")
  end
end
