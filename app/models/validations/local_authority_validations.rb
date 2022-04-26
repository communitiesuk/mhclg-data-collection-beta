module Validations::LocalAuthorityValidations
  POSTCODE_REGEXP = Validations::PropertyValidations::POSTCODE_REGEXP

  def validate_previous_accommodation_postcode(record)
    postcode = record.ppostcode_full
    if record.previous_postcode_known? && (postcode.blank? || !postcode.match(POSTCODE_REGEXP))
      error_message = I18n.t("validations.postcode")
      record.errors.add :ppostcode_full, error_message
    end
  end

  def validate_la(record)
    if record.owning_organisation && record.owning_organisation.local_authorities.present? &&
        record.la && !record.owning_organisation.local_authorities.include?(record.la)
      la_name = record.form.get_question("la", record).label_from_value(record.la)
      org_name = record.owning_organisation.name
      postcode = UKPostcode.parse(record.postcode_full) if record.postcode_full
      record.errors.add :la, I18n.t("validations.property.la.la_invalid_for_org", org_name:, la_name:)
      record.errors.add :postcode_known, I18n.t("validations.property.la.postcode_invalid_for_org", org_name:, postcode:)
    end
  end
end
