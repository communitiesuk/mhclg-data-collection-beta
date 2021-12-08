require "uri"
require "net/http"
require "json"

class CaseLogValidator < ActiveModel::Validator
  # Validations methods need to be called 'validate_' to run on model save
  # or form page submission
  include Validations::HouseholdValidations
  include Validations::PropertyValidations
  include Validations::FinancialValidations
  include Validations::TenancyValidations
  include Validations::DateValidations

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
  include Validations::SoftValidations
  include Constants::CaseLog
  include Constants::IncomeRanges
  default_scope -> { kept }

  validates_with CaseLogValidator
  before_save :update_status!

  belongs_to :owning_organisation, class_name: "Organisation"
  belongs_to :managing_organisation, class_name: "Organisation"

  scope :for_organisation, ->(org) { where(owning_organisation: org).or(where(managing_organisation: org)) }

  enum status: { "not_started" => 0, "in_progress" => 1, "completed" => 2 }

  enum ethnic: ETHNIC
  enum national: NATIONAL, _suffix: true
  enum ecstat1: ECSTAT, _suffix: true
  enum ecstat2: ECSTAT, _suffix: true
  enum ecstat3: ECSTAT, _suffix: true
  enum ecstat4: ECSTAT, _suffix: true
  enum ecstat5: ECSTAT, _suffix: true
  enum ecstat6: ECSTAT, _suffix: true
  enum ecstat7: ECSTAT, _suffix: true
  enum ecstat8: ECSTAT, _suffix: true
  enum prevten: PREVIOUS_TENANCY, _suffix: true
  enum homeless: HOMELESS, _suffix: true
  enum underoccupation_benefitcap: BENEFITCAP, _suffix: true
  enum reservist: RESERVIST, _suffix: true
  enum leftreg: LEFTREG, _suffix: true
  enum illness: ILLNESS, _suffix: true
  enum preg_occ: PREGNANCY, _suffix: true
  enum override_net_income_validation: POLAR, _suffix: true
  enum housingneeds_a: POLAR, _suffix: true
  enum housingneeds_b: POLAR, _suffix: true
  enum housingneeds_c: POLAR, _suffix: true
  enum housingneeds_f: POLAR, _suffix: true
  enum housingneeds_g: POLAR, _suffix: true
  enum housingneeds_h: POLAR, _suffix: true
  enum accessibility_requirements_prefer_not_to_say: POLAR, _suffix: true
  enum illness_type_1: POLAR, _suffix: true
  enum illness_type_2: POLAR, _suffix: true
  enum illness_type_3: POLAR, _suffix: true
  enum illness_type_4: POLAR, _suffix: true
  enum illness_type_5: POLAR, _suffix: true
  enum illness_type_6: POLAR, _suffix: true
  enum illness_type_7: POLAR, _suffix: true
  enum illness_type_8: POLAR, _suffix: true
  enum illness_type_9: POLAR, _suffix: true
  enum illness_type_10: POLAR, _suffix: true
  enum startertenancy: POLAR2, _suffix: true
  enum tenancy: TENANCY, _suffix: true
  enum landlord: LANDLORD, _suffix: true
  enum rsnvac: RSNVAC, _suffix: true
  enum unittype_gn: UNITTYPE_GN, _suffix: true
  enum rp_homeless: POLAR, _suffix: true
  enum rp_insan_unsat: POLAR, _suffix: true
  enum rp_medwel: POLAR, _suffix: true
  enum rp_hardship: POLAR, _suffix: true
  enum rp_dontknow: POLAR, _suffix: true
  enum cbl: POLAR2, _suffix: true
  enum chr: POLAR2, _suffix: true
  enum cap: POLAR2, _suffix: true
  enum wchair: POLAR2, _suffix: true
  enum incfreq: INCFREQ, _suffix: true
  enum benefits: BENEFITS, _suffix: true
  enum period: PERIOD, _suffix: true
  enum layear: LATIME, _suffix: true
  enum lawaitlist: LATIME, _suffix: true
  enum reasonpref: POLAR_WITH_UNKNOWN, _suffix: true
  enum reason: REASON, _suffix: true
  enum la: LA, _suffix: true
  enum prevloc: LA, _suffix: true
  enum majorrepairs: POLAR, _suffix: true
  enum hb: HOUSING_BENEFIT, _suffix: true
  enum hbrentshortfall: POLAR_WITH_UNKNOWN, _suffix: true
  enum property_relet: POLAR, _suffix: true
  enum armedforces: ARMED_FORCES, _suffix: true
  enum first_time_property_let_as_social_housing: POLAR, _suffix: true
  enum unitletas: UNITLETAS, _suffix: true
  enum builtype: BUILTYPE, _suffix: true
  enum incref: POLAR, _suffix: true
  enum renttype: RENT_TYPE, _suffix: true
  enum needstype: NEEDS_TYPE, _suffix: true
  enum lettype: LET_TYPE, _suffix: true
  enum postcode_known: POLAR, _suffix: true
  enum la_known: POLAR, _suffix: true

  AUTOGENERATED_FIELDS = %w[id status created_at updated_at discarded_at renttype lettype].freeze
  OPTIONAL_FIELDS = %w[postcode_known
                       la_known
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

    ALLOWED_INCOME_RANGES[ecstat1.to_sym]
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
    if startdate.present?
      self.day = startdate.day
      self.month = startdate.month
      self.year = startdate.year
    end
    self.incref = 1 if net_income_known == "Prefer not to say"
    self.hhmemb = other_hhmemb + 1 if other_hhmemb.present?
    self.renttype = RENT_TYPE_MAPPING[rent_type]
    self.lettype = "#{renttype} #{needstype} #{owning_organisation['Org type']}" if renttype.present? && needstype.present? && owning_organisation["Org type"].present?
    self.la = get_la(property_postcode) if property_postcode.present?
  end

  def get_la(postcode)
    uri = URI("https://api.os.uk/search/places/v1/postcode?key=#{ENV['OS_PLACES_API_KEY']}&postcode=#{postcode}&dataset=LPI")
    res = Net::HTTP.get_response(uri)
    response_body = JSON.parse(res.body)
    response_body["results"][0]["LPI"]["ADMINISTRATIVE_AREA"].downcase.capitalize if res.is_a?(Net::HTTPSuccess) && (response_body["header"]["totalresults"]).to_i.positive?
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
