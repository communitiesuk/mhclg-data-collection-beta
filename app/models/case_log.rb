class CaseLogValidator < ActiveModel::Validator
  # Validations methods need to be called 'validate_<page_name>' to run on model save
  # or 'validate_' to run on submit as well
  include HouseholdValidations
  include PropertyValidations
  include FinancialValidations
  include TenancyValidations
  include DateValidations

  def validate(record)
    # If we've come from the form UI we only want to validate the specific fields
    # that have just been submitted. If we're submitting a log via API or Bulk Upload
    # we want to validate all data fields.
    page_to_validate = record.page_id
    if page_to_validate
      public_send("validate_#{page_to_validate}", record) if respond_to?("validate_#{page_to_validate}")
    else
      validation_methods = public_methods.select { |method| method.starts_with?("validate_") }
      validation_methods.each { |meth| public_send(meth, record) }
    end
  end

private

  def validate_other_field(record, main_field, other_field)
    main_field_label = main_field.humanize(capitalize: false)
    other_field_label = other_field.humanize(capitalize: false)
    if record[main_field] == "Other" && record[other_field].blank?
      record.errors.add other_field.to_sym, "If #{main_field_label} is other then #{other_field_label} must be provided"
    end

    if record[main_field] != "Other" && record[other_field].present?
      record.errors.add other_field.to_sym, "#{other_field_label} must not be provided if #{main_field_label} was not other"
    end
  end
end

class CaseLog < ApplicationRecord
  include Discard::Model
  include SoftValidations
  include DbEnums
  default_scope -> { kept }

  validates_with CaseLogValidator
  before_save :update_status!

  attr_accessor :page_id

  enum status: { "not_started" => 0, "in_progress" => 1, "completed" => 2 }

  enum ethnic: DbEnums.ethnic
  enum national: DbEnums.national, _suffix: true
  enum ecstat1: DbEnums.ecstat, _suffix: true
  enum ecstat2: DbEnums.ecstat, _suffix: true
  enum ecstat3: DbEnums.ecstat, _suffix: true
  enum ecstat4: DbEnums.ecstat, _suffix: true
  enum ecstat5: DbEnums.ecstat, _suffix: true
  enum ecstat6: DbEnums.ecstat, _suffix: true
  enum ecstat7: DbEnums.ecstat, _suffix: true
  enum ecstat8: DbEnums.ecstat, _suffix: true
  enum prevten: DbEnums.previous_tenancy, _suffix: true
  enum homeless: DbEnums.homeless, _suffix: true
  enum underoccupation_benefitcap: DbEnums.benefitcap, _suffix: true
  enum reservist: DbEnums.reservist, _suffix: true
  enum leftreg: DbEnums.leftreg, _suffix: true
  enum illness: DbEnums.illness, _suffix: true
  enum preg_occ: DbEnums.pregnancy, _suffix: true
  enum override_net_income_validation: DbEnums.override_soft_validation, _suffix: true
  enum housingneeds_a: DbEnums.polar, _suffix: true
  enum housingneeds_b: DbEnums.polar, _suffix: true
  enum housingneeds_c: DbEnums.polar, _suffix: true
  enum housingneeds_f: DbEnums.polar, _suffix: true
  enum housingneeds_g: DbEnums.polar, _suffix: true
  enum housingneeds_h: DbEnums.polar, _suffix: true
  enum illness_type_1: DbEnums.polar, _suffix: true
  enum illness_type_2: DbEnums.polar, _suffix: true
  enum illness_type_3: DbEnums.polar, _suffix: true
  enum illness_type_4: DbEnums.polar, _suffix: true
  enum illness_type_5: DbEnums.polar, _suffix: true
  enum illness_type_6: DbEnums.polar, _suffix: true
  enum illness_type_7: DbEnums.polar, _suffix: true
  enum illness_type_8: DbEnums.polar, _suffix: true
  enum illness_type_9: DbEnums.polar, _suffix: true
  enum illness_type_10: DbEnums.polar, _suffix: true
  enum startertenancy: DbEnums.polar2, _suffix: true
  enum tenancy: DbEnums.tenancy, _suffix: true
  enum landlord: DbEnums.landlord, _suffix: true
  enum rsnvac: DbEnums.rsnvac, _suffix: true
  enum unittype_gn: DbEnums.unittype_gn, _suffix: true
  enum rp_homeless: DbEnums.polar, _suffix: true
  enum rp_insan_unsat: DbEnums.polar, _suffix: true
  enum rp_medwel: DbEnums.polar, _suffix: true
  enum rp_hardship: DbEnums.polar, _suffix: true
  enum rp_dontknow: DbEnums.polar, _suffix: true
  enum cbl: DbEnums.polar2, _suffix: true
  enum chr: DbEnums.polar2, _suffix: true
  enum cap: DbEnums.polar2, _suffix: true
  enum wchair: DbEnums.polar2, _suffix: true
  enum incfreq: DbEnums.incfreq, _suffix: true
  enum benefits: DbEnums.benefits, _suffix: true
  enum period: DbEnums.period, _suffix: true
  enum layear: DbEnums.latime, _suffix: true
  enum lawaitlist: DbEnums.latime, _suffix: true
  enum reasonpref: DbEnums.polar_with_unknown, _suffix: true
  enum reason: DbEnums.reason, _suffix: true
  enum la: DbEnums.la, _suffix: true
  enum prevloc: DbEnums.la, _suffix: true
  enum majorrepairs: DbEnums.polar, _suffix: true
  enum hb: DbEnums.housing_benefit, _suffix: true
  enum hbrentshortfall: DbEnums.polar_with_unknown, _suffix: true
  enum property_relet: DbEnums.polar, _suffix: true
  enum armedforces: DbEnums.armed_forces, _suffix: true
  enum first_time_property_let_as_social_housing: DbEnums.polar, _suffix: true
  enum unitletas: DbEnums.unitletas, _suffix: true
  enum builtype: DbEnums.builtype, _suffix: true

  AUTOGENERATED_FIELDS = %w[id status created_at updated_at discarded_at].freeze
  OPTIONAL_FIELDS = %w[do_you_know_the_postcode
                       do_you_know_the_local_authority
                       first_time_property_let_as_social_housing].freeze

  def self.editable_fields
    attribute_names - AUTOGENERATED_FIELDS
  end

  def completed?
    status == "completed"
  end

  def not_started?
    status == "not_started"
  end

  def in_progress?
    status == "in_progress"
  end

  def weekly_net_income
    return unless earnings && incfreq

    case incfreq
    when "Weekly"
      earnings
    when "Monthly"
      ((earnings * 12) / 52.0).round(0)
    when "Yearly"
      (earnings / 12.0).round(0)
    end
  end

  def postcode
    if property_postcode.present?
      UKPostcode.parse(property_postcode).outcode
    end
  end

  def postcod2
    if property_postcode.present?
      UKPostcode.parse(property_postcode).incode
    end
  end

  def ppostc1
    if previous_postcode.present?
      UKPostcode.parse(previous_postcode).outcode
    end
  end

  def ppostc2
    if previous_postcode.present?
      UKPostcode.parse(previous_postcode).incode
    end
  end

  def hhmemb
    other_hhmemb.presence
  end

  def applicable_income_range
    return unless ecstat1

    IncomeRange::ALLOWED[ecstat1.to_sym]
  end

  def mrcday
    if mrcdate.present?
      mrcdate.day
    end
  end

  def mrcmonth
    if mrcdate.present?
      mrcdate.month
    end
  end

  def mrcyear
    if mrcdate.present?
      mrcdate.year
    end
  end

  def incref
    if net_income_known == "Prefer not to say"
      1
    end
  end

private

  def update_status!
    self.status = if all_fields_completed? && errors.empty?
                    "completed"
                  elsif all_fields_nil?
                    "not_started"
                  else
                    "in_progress"
                  end
  end

  def all_fields_completed?
    mandatory_fields.none? { |_key, val| val.nil? }
  end

  def all_fields_nil?
    mandatory_fields.all? { |_key, val| val.nil? }
  end

  def mandatory_fields
    required = attributes.except(*(AUTOGENERATED_FIELDS + OPTIONAL_FIELDS))

    dynamically_not_required = []

    if reason != "Other"
      dynamically_not_required << "other_reason_for_leaving_last_settled_home"
    end

    if earnings.to_i.zero?
      dynamically_not_required << "incfreq"
    end

    if sale_or_letting == "Letting"
      dynamically_not_required << "sale_completion_date"
    end

    if la.present?
      dynamically_not_required << "why_dont_you_know_la"
    end

    if tenancy == "Secure (including flexible)"
      dynamically_not_required << "tenancylength"
    end

    unless net_income_in_soft_max_range? || net_income_in_soft_min_range?
      dynamically_not_required << "override_net_income_validation"
    end

    unless tenancy == "Other"
      dynamically_not_required << "tenancyother"
    end

    unless net_income_known == "Yes"
      dynamically_not_required << "earnings"
      dynamically_not_required << "incfreq"
    end

    start_range = (other_hhmemb || 0) + 2
    (start_range..8).each do |n|
      dynamically_not_required << "age#{n}"
      dynamically_not_required << "sex#{n}"
      dynamically_not_required << "relat#{n}"
      dynamically_not_required << "ecstat#{n}"
    end

    if net_income_known != "Prefer not to say"
      dynamically_not_required << "incref"
    end

    required.delete_if { |key, _value| dynamically_not_required.include?(key) }
  end
end
