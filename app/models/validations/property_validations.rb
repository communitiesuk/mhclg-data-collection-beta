module Validations::PropertyValidations
  # Validations methods need to be called 'validate_<page_name>' to run on model save
  # or 'validate_' to run on submit as well

  REFERRAL_INVALID_TMP = [8, 10, 12, 13, 14, 15].freeze
  def validate_rsnvac(record)
    if !record.first_time_property_let_as_social_housing? && record.has_first_let_vacancy_reason?
      record.errors.add :rsnvac, I18n.t("validations.property.rsnvac.first_let_not_social")
    end

    if record.first_time_property_let_as_social_housing? && record.rsnvac.present? && !record.has_first_let_vacancy_reason?
      record.errors.add :rsnvac, I18n.t("validations.property.rsnvac.first_let_social")
    end

    if record.is_relet_to_temp_tenant? && !record.previous_tenancy_was_temporary?
      record.errors.add :rsnvac, I18n.t("validations.property.rsnvac.non_temp_accommodation")
    end

    if record.is_relet_to_temp_tenant? && REFERRAL_INVALID_TMP.include?(record.referral)
      record.errors.add :rsnvac, I18n.t("validations.property.rsnvac.referral_invalid")
      record.errors.add :referral, :referral_invalid, message: I18n.t("validations.household.referral.rsnvac_non_temp")
    end

    if record.renewal.present? && record.renewal.zero? && record.rsnvac == 14
      record.errors.add :rsnvac, I18n.t("validations.property.rsnvac.not_a_renewal")
    end
  end

  def validate_unitletas(record)
    if record.first_time_property_let_as_social_housing? && record.unitletas.present?
      record.errors.add :unitletas, I18n.t("validations.property.rsnvac.previous_let_social")
    end
  end

  def validate_shared_housing_rooms(record)
    unless record.unittype_gn.nil?
      if record.is_bedsit? && record.beds != 1 && record.beds.present?
        record.errors.add :unittype_gn, I18n.t("validations.property.unittype_gn.one_bedroom_bedsit")
        record.errors.add :beds, I18n.t("validations.property.unittype_gn.one_bedroom_bedsit")
      end

      if record.hhmemb == 1 && record.is_shared_housing? &&
          !record.beds.to_i.between?(1, 3) && record.beds.present?
        record.errors.add :unittype_gn, I18n.t("validations.property.unittype_gn.one_three_bedroom_single_tenant_shared")
        record.errors.add :beds, :one_three_bedroom_single_tenant_shared, message: I18n.t("validations.property.unittype_gn.one_three_bedroom_single_tenant_shared")
      elsif record.is_shared_housing? && record.beds.present? && !record.beds.to_i.between?(1, 7)
        record.errors.add :unittype_gn, I18n.t("validations.property.unittype_gn.one_seven_bedroom_shared")
        record.errors.add :beds, I18n.t("validations.property.unittype_gn.one_seven_bedroom_shared")
      end
    end
  end

  def validate_uprn(record)
    return unless record.uprn

    return if record.uprn.match?(/^[0-9]{1,12}$/)

    record.errors.add :uprn, I18n.t("validations.property.uprn.invalid")
  end
end
