class CaseLogValidator < ActiveModel::Validator
  # Validations methods need to be called 'validate_' to run on model save
  # or form page submission
  include HouseholdValidations
  include PropertyValidations
  include FinancialValidations
  include TenancyValidations
  include DateValidations

  def validate(record)
    validation_methods = public_methods.select { |method| method.starts_with?("validate_") }
    validation_methods.each { |meth| public_send(meth, record) }
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

  belongs_to :owning_organisation, class_name: "Organisation"
  belongs_to :managing_organisation, class_name: "Organisation"

  scope :for_organisation, ->(org) { where(owning_organisation: org).or(where(managing_organisation: org)) }

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
  enum incref: DbEnums.polar, _suffix: true
  enum renttype: DbEnums.renttype, _suffix: true
  enum needstype: DbEnums.needstype, _suffix: true
  enum lettype: DbEnums.lettype, _suffix: true

  AUTOGENERATED_FIELDS = %w[id status created_at updated_at discarded_at renttype lettype].freeze
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

  def applicable_income_range
    return unless ecstat1

    IncomeRange::ALLOWED[ecstat1.to_sym]
  end

private

  RENT_TYPE_MAPPING = {
    "Social Rent" => "Social Rent",
    "Affordable Rent" => "Affordable Rent",
    "London Affordable Rent" => "Affordable Rent",
    "Rent To Buy" => "Intermediate Rent",
    "London Living Rent" => "Intermediate Rent",
    "Other Intermediate Rent Product" => "Intermediate Rent",
  }.freeze

  def update_status!
    self.status = if all_fields_completed? && errors.empty?
                    "completed"
                  elsif all_fields_nil?
                    "not_started"
                  else
                    "in_progress"
                  end
    set_derived_fields
  end

  def set_derived_fields
    if property_postcode.present?
      self.postcode = UKPostcode.parse(property_postcode).outcode
      self.postcod2 = UKPostcode.parse(property_postcode).incode
    end
    if previous_postcode.present?
      self.ppostc1 = UKPostcode.parse(previous_postcode).outcode
      self.ppostc2 = UKPostcode.parse(previous_postcode).incode
    end
    if mrcdate.present?
      self.mrcday = mrcdate.day
      self.mrcmonth = mrcdate.month
      self.mrcyear = mrcdate.year
    end
    self.incref = 1 if net_income_known == "Prefer not to say"
    self.hhmemb = other_hhmemb + 1 if other_hhmemb.present?
    self.renttype = RENT_TYPE_MAPPING[rent_type]
    self.lettype = "#{renttype} #{needstype} #{owning_organisation['Org type']}" if renttype.present? && needstype.present? && owning_organisation["Org type"].present?
  end

  def all_fields_completed?
    mandatory_fields.none? { |_key, val| val.nil? }
  end

  def all_fields_nil?
    init_fields = %w[owning_organisation_id managing_organisation_id]
    fields = mandatory_fields.except(*init_fields)
    fields.all? { |_key, val| val.nil? }
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
