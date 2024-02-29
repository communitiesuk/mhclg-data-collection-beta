module Validations::DateValidations
  include Validations::SharedValidations

  def validate_property_major_repairs(record)
    date_valid?("mrcdate", record)
    if record["startdate"].present? && record["mrcdate"].present? && record["startdate"] < record["mrcdate"]
      record.errors.add :mrcdate, I18n.t("validations.property.mrcdate.before_tenancy_start")
    end

    if is_rsnvac_first_let?(record) && record["mrcdate"].present?
      record.errors.add :mrcdate, I18n.t("validations.property.mrcdate.not_first_let")
    end

    if record["mrcdate"].present? && record["startdate"].present? && record["startdate"].to_date - record["mrcdate"].to_date > 3650
      record.errors.add :mrcdate, I18n.t("validations.property.mrcdate.ten_years_before_tenancy_start")
    end
  end

  def validate_property_void_date(record)
    if record["voiddate"].present? && record["startdate"].present? && record["startdate"].to_date - record["voiddate"].to_date > 3650
      record.errors.add :voiddate, I18n.t("validations.property.void_date.ten_years_before_tenancy_start")
    end

    if record["voiddate"].present? && record["startdate"].present? && record["startdate"].to_date < record["voiddate"].to_date
      record.errors.add :voiddate, I18n.t("validations.property.void_date.before_tenancy_start")
    end

    if record["voiddate"].present? && record["mrcdate"].present? && record["mrcdate"].to_date < record["voiddate"].to_date
      record.errors.add :voiddate, :after_mrcdate, message: I18n.t("validations.property.void_date.after_mrcdate")
      record.errors.add :mrcdate, I18n.t("validations.property.mrcdate.before_void_date")
    end
  end

  def validate_startdate(record)
    return unless record.startdate && date_valid?("startdate", record)

    if !FeatureToggle.allow_future_form_use? && record.startdate > Time.zone.today + 14.days
      record.errors.add :startdate, I18n.t("validations.setup.startdate.later_than_14_days_after")
    end

    if record["voiddate"].present? && record.startdate < record["voiddate"]
      record.errors.add :startdate, I18n.t("validations.setup.startdate.after_void_date")
    end

    if record["mrcdate"].present? && record.startdate < record["mrcdate"]
      record.errors.add :startdate, I18n.t("validations.setup.startdate.after_major_repair_date")
    end

    if record["voiddate"].present? && record["startdate"].to_date - record["voiddate"].to_date > 3650
      record.errors.add :startdate, I18n.t("validations.setup.startdate.ten_years_after_void_date")
    end

    if record["mrcdate"].present? && record["startdate"].to_date - record["mrcdate"].to_date > 3650
      record.errors.add :startdate, I18n.t("validations.setup.startdate.ten_years_after_mrc_date")
    end
  end

private

  def is_rsnvac_first_let?(record)
    [15, 16, 17].include?(record["rsnvac"])
  end
end
