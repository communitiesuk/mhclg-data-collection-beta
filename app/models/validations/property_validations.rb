module Validations::PropertyValidations
  # Validations methods need to be called 'validate_<page_name>' to run on model save
  # or 'validate_' to run on submit as well

  REFERRAL_INVALID_TMP = [8, 10, 12, 13, 14, 15].freeze
  def validate_rsnvac(record)
    if record.is_relet_to_temp_tenant? && !record.previous_tenancy_was_temporary?
      record.errors.add :rsnvac, I18n.t("validations.lettings.property.rsnvac.non_temp_accommodation")
    end

    if record.is_relet_to_temp_tenant? && REFERRAL_INVALID_TMP.include?(record.referral)
      record.errors.add :rsnvac, I18n.t("validations.lettings.property.rsnvac.referral_invalid")
      record.errors.add :referral, :referral_invalid, message: I18n.t("validations.lettings.property.referral.rsnvac_non_temp")
      record.errors.add :referral_type, :referral_invalid, message: I18n.t("validations.lettings.property.referral.rsnvac_non_temp")
    end

    if record.renewal.present? && record.renewal.zero? && record.rsnvac == 14
      record.errors.add :rsnvac, I18n.t("validations.lettings.property.rsnvac.not_a_renewal")
    end
  end

  def validate_shared_housing_rooms(record)
    return unless record.unittype_gn

    if record.hhmemb == 1 && record.is_shared_housing? &&
        !record.beds.to_i.between?(1, 3) && record.beds.present?
      record.errors.add :unittype_gn, I18n.t("validations.lettings.property.unittype_gn.one_three_bedroom_single_tenant_shared")
      record.errors.add :beds, :one_three_bedroom_single_tenant_shared, message: I18n.t("validations.lettings.property.beds.one_three_bedroom_single_tenant_shared")
    elsif record.is_shared_housing? && record.beds.present? && !record.beds.to_i.between?(1, 7)
      record.errors.add :unittype_gn, I18n.t("validations.lettings.property.unittype_gn.one_seven_bedroom_shared")
      record.errors.add :beds, I18n.t("validations.lettings.property.beds.one_seven_bedroom_shared")
    end
  end

  def validate_uprn(record)
    return unless record.uprn

    return if record.uprn.match?(/^[0-9]{1,12}$/)

    record.errors.add :uprn, I18n.t("validations.lettings.property.uprn.invalid")
  end

  def validate_property_postcode(record)
    postcode = record.postcode_full
    return unless postcode

    if record.postcode_known? && (postcode.blank? || !postcode.match(POSTCODE_REGEXP))
      error_message = I18n.t("validations.lettings.property.postcode_full.invalid")
      record.errors.add :postcode_full, :wrong_format, message: error_message
    end
  end

  def validate_la_in_england(record)
    return unless record.form.start_year_2025_or_later?

    if record.is_general_needs?
      return unless record.la
      return if record.la.in?(LocalAuthority.england.pluck(:code))

      record.errors.add :la, I18n.t("validations.lettings.property.la.not_in_england")
      record.errors.add :postcode_full, I18n.t("validations.lettings.property.postcode_full.not_in_england")
      record.errors.add :uprn, I18n.t("validations.lettings.property.uprn.not_in_england")
      record.errors.add :uprn_confirmation, I18n.t("validations.lettings.property.uprn_confirmation.not_in_england")
      record.errors.add :uprn_selection, I18n.t("validations.lettings.property.uprn_selection.not_in_england")
      if record.uprn.present?
        record.errors.add :startdate, I18n.t("validations.lettings.property.startdate.address_not_in_england")
      else
        record.errors.add :startdate, I18n.t("validations.lettings.property.startdate.postcode_not_in_england")
      end
    elsif record.is_supported_housing?
      return unless record.location
      return if record.location.location_code.in?(LocalAuthority.england.pluck(:code))

      record.errors.add :location_id, I18n.t("validations.lettings.property.location_id.not_in_england")
      record.errors.add :scheme_id, I18n.t("validations.lettings.property.scheme_id.not_in_england")
      record.errors.add :startdate, I18n.t("validations.lettings.property.startdate.location_not_in_england")
    end
  end
end
