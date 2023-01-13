module Validations::SharedValidations
  def validate_other_field(record, value_other = nil, main_field = nil, other_field = nil, main_label = nil, other_label = nil)
    return unless main_field || other_field

    main_field_label = main_label || main_field.to_s.humanize(capitalize: false)
    other_field_label = other_label || other_field.to_s.humanize(capitalize: false)
    if record[main_field] == value_other && record[other_field].blank?
      record.errors.add other_field.to_sym, I18n.t("validations.other_field_missing", main_field_label:, other_field_label:)
    end

    if record[main_field] != value_other && record[other_field].present?
      record.errors.add other_field.to_sym, I18n.t("validations.other_field_not_required", main_field_label:, other_field_label:)
    end
  end

  def validate_numeric_min_max(record)
    record.form.numeric_questions.each do |question|
      next unless question.min || question.max
      next unless record[question.id]

      field = question.check_answer_label || question.id

      begin
        answer = Float(record.public_send("#{question.id}_before_type_cast"))
      rescue ArgumentError
        record.errors.add question.id.to_sym, I18n.t("validations.numeric.valid", field:, min: question.min, max: question.max)
      end

      next unless answer

      if (question.min && question.min > answer) || (question.max && question.max < answer)
        record.errors.add question.id.to_sym, I18n.t("validations.numeric.valid", field:, min: question.min, max: question.max)
      end
    end
  end

  def location_during_startdate_validation(record, field)
    location_inactive_status = inactive_status(record.startdate, record.location)

    if location_inactive_status.present?
      date, scope, deactivation_date = location_inactive_status.values_at(:date, :scope, :deactivation_date)
      record.errors.add field, I18n.t("validations.setup.startdate.location.#{scope}", postcode: record.location.postcode, date:, deactivation_date:)
    end
  end

  def scheme_during_startdate_validation(record, field)
    scheme_inactive_status = inactive_status(record.startdate, record.scheme)
    if scheme_inactive_status.present?
      date, scope, deactivation_date = scheme_inactive_status.values_at(:date, :scope, :deactivation_date)
      record.errors.add field, I18n.t("validations.setup.startdate.scheme.#{scope}", name: record.scheme.service_name, date:, deactivation_date:)
    end
  end

  def inactive_status(date, resource)
    return if date.blank? || resource.blank?

    status = resource.status_at(date)
    return unless %i[reactivating_soon activating_soon deactivated].include?(status)

    closest_reactivation = resource.recent_deactivation
    open_deactivation = resource.open_deactivation

    date = case status
           when :reactivating_soon then closest_reactivation.reactivation_date
           when :activating_soon then resource&.available_from
           when :deactivated then open_deactivation.deactivation_date
           end

    { scope: status, date: date&.to_formatted_s(:govuk_date), deactivation_date: closest_reactivation&.deactivation_date&.to_formatted_s(:govuk_date) }
  end

  def validate_valid_radio_option(record)
    return unless FeatureToggle.validate_valid_radio_options?

    record.attributes.each do |question_id, _v|
      question = record.form.get_question(question_id, record)

      next unless question&.type == "radio"
      next unless record[question_id].present? && !question.answer_options.key?(record[question_id].to_s) && question.page.routed_to?(record, nil)

      record.errors.add(question_id, I18n.t("validations.invalid_option", question: question.check_answer_label&.downcase))
    end
  end

  def shared_validate_person_age_and_relationship_matches_economic_status(record, person_num)
    age = record.public_send("age#{person_num}")
    economic_status = record.public_send("ecstat#{person_num}")
    relationship = record.public_send("relat#{person_num}")
    return unless age && economic_status && relationship

    if age >= 16 && age <= 19 && person_is_child?(relationship) && (!person_is_fulltime_student?(economic_status) && !person_economic_status_refused?(economic_status))
      record.errors.add "ecstat#{person_num}", I18n.t("validations.household.ecstat.student_16_19", person_num:)
      record.errors.add "age#{person_num}", I18n.t("validations.household.age.student_16_19", person_num:)
      record.errors.add "relat#{person_num}", I18n.t("validations.household.relat.student_16_19", person_num:)
    end
  end

  def shared_validate_partner_count(record, max_people)
    partner_count = (2..max_people).count { |n| person_is_partner?(record["relat#{n}"]) }
    if partner_count > 1
      record.errors.add :base, I18n.t("validations.household.relat.one_partner")
    end
  end


private

  def person_is_partner?(relationship)
    relationship == "P"
  end

  def person_is_child?(relationship)
    relationship == "C"
  end

  def person_is_fulltime_student?(economic_status)
    economic_status == 7
  end

  def person_economic_status_refused?(economic_status)
    economic_status == 10
  end
end
