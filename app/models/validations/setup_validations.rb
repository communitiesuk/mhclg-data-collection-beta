module Validations::SetupValidations
  include Validations::SharedValidations
  include CollectionTimeHelper

  def validate_startdate_setup(record)
    return unless record.startdate && date_valid?("startdate", record)

    first_collection_start_date = if record.startdate_was.present?
                                    editable_collection_start_date
                                  else
                                    active_collection_start_date
                                  end

    unless record.startdate.between?(first_collection_start_date, current_collection_end_date)
      record.errors.add :startdate, startdate_validation_error_message
    end
  end

  def validate_irproduct_other(record)
    if intermediate_product_rent_type?(record) && record.irproduct_other.blank?
      record.errors.add :irproduct_other, I18n.t("validations.setup.intermediate_rent_product_name.blank")
    end
  end

  def validate_location(record)
    location_during_startdate_validation(record)
  end

  def validate_scheme_has_confirmed_locations_validation(record)
    return unless record.scheme

    unless record.scheme.locations.confirmed.any?
      record.errors.add :scheme_id, :no_completed_locations, message: I18n.t("validations.scheme.no_completed_locations")
    end
  end

  def validate_scheme(record)
    location_during_startdate_validation(record)
    scheme_during_startdate_validation(record)
  end

  def validate_organisation(record)
    created_by, managing_organisation, owning_organisation = record.values_at("created_by", "managing_organisation", "owning_organisation")
    unless [created_by, managing_organisation, owning_organisation].any?(&:blank?) || created_by.organisation.absorbed_organisations << created_by.organisation & [managing_organisation, owning_organisation]
      record.errors.add :created_by, I18n.t("validations.setup.created_by.invalid")
      record.errors.add :owning_organisation_id, I18n.t("validations.setup.owning_organisation.invalid")
      record.errors.add :managing_organisation_id, I18n.t("validations.setup.managing_organisation.invalid")
    end
  end

  def validate_managing_organisation_data_sharing_agremeent_signed(record)
    if record.managing_organisation_id_changed? && record.managing_organisation.present? && !record.managing_organisation.data_protection_confirmed?
      record.errors.add :managing_organisation_id, I18n.t("validations.setup.managing_organisation.data_sharing_agreement_not_signed")
    end
  end

private

  def active_collection_start_date
    if FormHandler.instance.lettings_in_crossover_period?
      previous_collection_start_date
    else
      current_collection_start_date
    end
  end

  def editable_collection_start_date
    if FormHandler.instance.lettings_in_edit_crossover_period?
      previous_collection_start_date
    else
      current_collection_start_date
    end
  end

  def startdate_validation_error_message
    current_end_year_long = current_collection_end_date.strftime("#{current_collection_end_date.day.ordinalize} %B %Y")

    if FormHandler.instance.lettings_in_crossover_period?
      I18n.t(
        "validations.setup.startdate.previous_and_current_collection_year",
        previous_start_year_short: previous_collection_start_date.strftime("%y"),
        previous_end_year_short: previous_collection_end_date.strftime("%y"),
        previous_start_year_long: previous_collection_start_date.strftime("#{previous_collection_start_date.day.ordinalize} %B %Y"),
        current_end_year_short: current_collection_end_date.strftime("%y"),
        current_end_year_long:,
      )
    else
      I18n.t(
        "validations.setup.startdate.current_collection_year",
        current_start_year_short: current_collection_start_date.strftime("%y"),
        current_end_year_short: current_collection_end_date.strftime("%y"),
        current_start_year_long: current_collection_start_date.strftime("#{current_collection_start_date.day.ordinalize} %B %Y"),
        current_end_year_long:,
      )
    end
  end

  def intermediate_product_rent_type?(record)
    record.rent_type == 5
  end
end
