module Validations::Sales::SaleInformationValidations
  include CollectionTimeHelper
  include MoneyFormattingHelper

  def validate_practical_completion_date_before_saledate(record)
    return if record.saledate.blank? || record.hodate.blank?

    if record.hodate > record.saledate
      record.errors.add :hodate, I18n.t("validations.sale_information.hodate.must_be_before_saledate")
      record.errors.add :saledate, I18n.t("validations.sale_information.saledate.must_be_after_hodate")
    end
  end

  def validate_exchange_date(record)
    return unless record.exdate && record.saledate

    if record.exdate > record.saledate
      record.errors.add :exdate, I18n.t("validations.sale_information.exdate.must_be_before_saledate")
      record.errors.add :saledate, I18n.t("validations.sale_information.saledate.must_be_after_exdate")
    end

    if record.saledate - record.exdate >= 1.year
      record.errors.add :exdate, :over_a_year_from_saledate, message: I18n.t("validations.sale_information.exdate.must_be_less_than_1_year_from_saledate")
      record.errors.add :saledate, I18n.t("validations.sale_information.saledate.must_be_less_than_1_year_from_exdate")
    end
  end

  def validate_previous_property_unit_type(record)
    return unless record.fromprop && record.frombeds

    if record.frombeds != 1 && record.fromprop == 2
      record.errors.add :frombeds, I18n.t("validations.sale_information.previous_property_type.property_type_bedsit")
      record.errors.add :fromprop, I18n.t("validations.sale_information.previous_property_type.property_type_bedsit")
    end
  end

  def validate_discounted_ownership_value(record)
    return unless record.saledate && record.form.start_year_after_2024?
    return unless record.value && record.deposit && record.ownershipsch
    return unless record.mortgage || record.mortgageused == 2 || record.mortgageused == 3
    return unless record.discount || record.grant || record.type == 29

    if record.mortgage_deposit_and_grant_total != record.value_with_discount && record.discounted_ownership_sale?
      %i[mortgageused mortgage value deposit ownershipsch discount grant].each do |field|
        record.errors.add field, I18n.t("validations.sale_information.discounted_ownership_value", mortgage_deposit_and_grant_total: record.field_formatted_as_currency("mortgage_deposit_and_grant_total"), value_with_discount: record.field_formatted_as_currency("value_with_discount"))
      end
    end
  end

  def validate_basic_monthly_rent(record)
    return unless record.mrent && record.ownershipsch && record.type

    if record.shared_ownership_scheme? && !record.old_persons_shared_ownership? && record.mrent > 9999
      record.errors.add :mrent, I18n.t("validations.sale_information.monthly_rent.higher_than_expected")
      record.errors.add :type, I18n.t("validations.sale_information.monthly_rent.higher_than_expected")
    end
  end

  def validate_grant_amount(record)
    return unless record.saledate && record.form.start_year_after_2024?
    return unless record.grant && (record.type == 8 || record.type == 21)

    unless record.grant.between?(9_000, 16_000)
      record.errors.add :grant, I18n.t("validations.sale_information.grant.out_of_range")
    end
  end

  def validate_stairbought(record)
    return unless record.stairbought && record.type
    return unless record.saledate && record.form.start_year_after_2024?

    max_stairbought = case record.type
                      when 30, 16, 28, 31, 32
                        90
                      when 2, 18
                        75
                      when 24
                        50
                      end

    if max_stairbought && record.stairbought > max_stairbought
      record.errors.add :stairbought, I18n.t("validations.sale_information.stairbought.over_max", max_stairbought:, type: record.form.get_question("type", record).answer_label(record))
      record.errors.add :type, I18n.t("validations.sale_information.stairbought.over_max", max_stairbought:, type: record.form.get_question("type", record).answer_label(record))
    end
  end

  def validate_discount_and_value(record)
    return unless record.saledate && record.form.start_year_after_2024?
    return unless record.discount && record.value && record.la

    if record.london_property? && record.discount_value > 136_400
      %i[discount value la postcode_full uprn].each do |field|
        record.errors.add field, I18n.t("validations.sale_information.value.over_discounted_london_max", discount_value: record.field_formatted_as_currency("discount_value"))
      end
    elsif record.property_not_in_london? && record.discount_value > 102_400
      %i[discount value la postcode_full uprn].each do |field|
        record.errors.add field, I18n.t("validations.sale_information.value.over_discounted_max", discount_value: record.field_formatted_as_currency("discount_value"))
      end
    end
  end

  def validate_non_staircasing_mortgage(record)
    return unless record.mortgage && record.value && record.deposit && record.equity
    return unless record.is_not_staircasing?
    return unless record.saledate && record.form.start_year_after_2024?

    if record.mortgage_and_deposit_total != record.expected_shared_ownership_deposit_value
      %i[mortgage value deposit equity].each do |field|
        record.errors.add field, I18n.t("validations.sale_information.non_staircasing_mortgage", mortgage_and_deposit_total: record.field_formatted_as_currency("mortgage_and_deposit_total"), expected_shared_ownership_deposit_value: record.field_formatted_as_currency("expected_shared_ownership_deposit_value"))
      end
    end
  end

  def validate_mortgage_used_and_stairbought(record)
    return unless record.stairowned && record.mortgageused
    return unless record.saledate && record.form.start_year_after_2024?

    if !record.stairowned_100? && record.mortgageused == 3
      record.errors.add :stairowned, I18n.t("validations.sale_information.stairowned.mortgageused_dont_know")
      record.errors.add :mortgageused, I18n.t("validations.sale_information.stairowned.mortgageused_dont_know")
    end
  end
end
