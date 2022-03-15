class CaseLogValidator < ActiveModel::Validator
  # Validations methods need to be called 'validate_' to run on model save
  # or form page submission
  include Validations::HouseholdValidations
  include Validations::PropertyValidations
  include Validations::FinancialValidations
  include Validations::TenancyValidations
  include Validations::DateValidations
  include Validations::LocalAuthorityValidations
  include Validations::SubmissionValidations

  def validate(record)
    validation_methods = public_methods.select { |method| method.starts_with?("validate_") }
    validation_methods.each { |meth| public_send(meth, record) }
  end
end

class CaseLog < ApplicationRecord
  include Validations::SoftValidations

  has_paper_trail

  validates_with CaseLogValidator
  before_validation :process_postcode_changes!, if: :property_postcode_changed?
  before_validation :process_previous_postcode_changes!, if: :previous_postcode_changed?
  before_validation :reset_invalidated_dependent_fields!
  before_validation :reset_location_fields!, unless: :postcode_known?
  before_validation :reset_previous_location_fields!, unless: :previous_postcode_known?
  before_validation :set_derived_fields!
  before_save :update_status!

  belongs_to :owning_organisation, class_name: "Organisation"
  belongs_to :managing_organisation, class_name: "Organisation"

  scope :for_organisation, ->(org) { where(owning_organisation: org).or(where(managing_organisation: org)) }

  AUTOGENERATED_FIELDS = %w[id status created_at updated_at discarded_at].freeze
  OPTIONAL_FIELDS = %w[postcode_known la_known first_time_property_let_as_social_housing tenant_code propcode].freeze
  RENT_TYPE_MAPPING = { 0 => 1, 1 => 2, 2 => 2, 3 => 3, 4 => 3, 5 => 3 }.freeze
  RENT_TYPE_MAPPING_LABELS = { 1 => "Social Rent", 2 => "Affordable Rent", 3 => "Intermediate Rent" }.freeze
  HAS_BENEFITS_OPTIONS = [1, 6, 8, 7].freeze
  STATUS = { "not_started" => 0, "in_progress" => 1, "completed" => 2 }.freeze
  NUM_OF_WEEKS_FROM_PERIOD = { 2 => 26, 3 => 13, 4 => 12, 5 => 50, 6 => 49, 7 => 48, 8 => 47, 9 => 46, 1 => 52 }.freeze
  enum status: STATUS

  def form
    FormHandler.instance.get_form(form_name) || FormHandler.instance.forms.first.second
  end

  def form_name
    return unless startdate

    window_end_date = Time.zone.local(startdate.year, 4, 1)
    if startdate < window_end_date
      "#{startdate.year - 1}_#{startdate.year}"
    else
      "#{startdate.year}_#{startdate.year + 1}"
    end
  end

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

    if net_income_is_weekly?
      earnings
    elsif net_income_is_monthly?
      ((earnings * 12) / 52.0).round(0)
    elsif net_income_is_yearly?
      (earnings / 12.0).round(0)
    end
  end

  def weekly_value(field_value)
    num_of_weeks = NUM_OF_WEEKS_FROM_PERIOD[period]
    return unless field_value && num_of_weeks

    (field_value / 52 * num_of_weeks).round(2)
  end

  def applicable_income_range
    return unless ecstat1

    ALLOWED_INCOME_RANGES[ecstat1]
  end

  def first_time_property_let_as_social_housing?
    first_time_property_let_as_social_housing == 1
  end

  def net_income_refused?
    net_income_known == 2
  end

  def net_income_is_weekly?
    !!(incfreq && incfreq.zero?)
  end

  def net_income_is_monthly?
    incfreq == 1
  end

  def net_income_is_yearly?
    incfreq == 2
  end

  def net_income_soft_validation_triggered?
    net_income_in_soft_min_range? || net_income_in_soft_max_range?
  end

  def given_reasonable_preference?
    reasonpref == 1
  end

  def is_renewal?
    renewal == 1
  end

  def is_general_needs?
    needstype == 1
  end

  def is_supported_housing?
    !!(needstype && needstype.zero?)
  end

  def has_hbrentshortfall?
    !!(hbrentshortfall && hbrentshortfall.zero?)
  end

  def postcode_known?
    postcode_known == 1
  end

  def previous_postcode_known?
    previous_postcode_known == 1
  end

  def la_known?
    la_known == 1
  end

  def previous_la_known?
    previous_la_known == 1
  end

  def is_secure_tenancy?
    tenancy == 3
  end

  def is_assured_shorthold_tenancy?
    tenancy == 1
  end

  def is_internal_transfer?
    referral == 1
  end

  def is_relet_to_temp_tenant?
    rsnvac == 2
  end

  def is_bedsit?
    unittype_gn == 1
  end

  def is_shared_housing?
    [4, 5, 6].include?(unittype_gn)
  end

  def has_first_let_vacancy_reason?
    [11, 12, 13].include?(rsnvac)
  end

  def previous_tenancy_was_temporary?
    ![4, 5, 16, 21, 22].include?(prevten)
  end

  def armed_forces_regular?
    !!(armedforces && armedforces.zero?)
  end

  def armed_forces_no?
    armedforces == 3
  end

  def armed_forces_refused?
    armedforces == 4
  end

  def has_pregnancy?
    !!(preg_occ && preg_occ.zero?)
  end

  def pregnancy_refused?
    preg_occ == 2
  end

  def is_assessed_homeless?
    homeless == 11
  end

  def is_other_homeless?
    homeless == 7
  end

  def is_not_homeless?
    homeless == 1
  end

  def is_london_rent?
    rent_type == 2 || rent_type == 4
  end

  def previous_tenancy_was_foster_care?
    prevten == 13
  end

  def previous_tenancy_was_refuge?
    prevten == 21
  end

  def is_reason_permanently_decanted?
    reason == 1
  end

  def receives_housing_benefit_only?
    hb == 1
  end

  def receives_housing_benefit_and_universal_credit?
    hb == 8
  end

  def receives_uc_with_housing_element_excl_housing_benefit?
    hb == 6
  end

  def receives_no_benefits?
    hb == 9
  end

  def receives_universal_credit_but_no_housing_benefit?
    hb == 7
  end

  def receives_housing_related_benefits?
    receives_housing_benefit_only? || receives_uc_with_housing_element_excl_housing_benefit? ||
      receives_housing_benefit_and_universal_credit?
  end

  def benefits_unknown?
    hb == 3
  end

  def this_landlord?
    landlord == 1
  end

private

  PIO = Postcodes::IO.new

  def update_status!
    self.status = if all_fields_completed? && errors.empty?
                    "completed"
                  elsif all_fields_nil?
                    "not_started"
                  else
                    "in_progress"
                  end
  end

  def reset_not_routed_questions
    form.invalidated_page_questions(self).each do |question|
      enabled = form.enabled_page_questions(self)
      answer_options = enabled.map(&:id).include?(question.id) ? enabled.find { |q| q.id == question.id }.answer_options : []
      contains_selected_answer_option = answer_options.present? ? answer_options.key?(public_send(question.id).to_s) : false
      if !contains_selected_answer_option && respond_to?(question.id.to_s) && (question.type == "radio" || question.type == "checkbox")
        public_send("#{question.id}=", nil)
      end
    end
  end

  def reset_derived_questions
    dependent_questions = { layear: [{ key: :renewal, value: 0 }],
                            homeless: [{ key: :renewal, value: 0 }],
                            referral: [{ key: :renewal, value: 0 }],
                            underoccupation_benefitcap: [{ key: :renewal, value: 0 }] }

    dependent_questions.each do |dependent, conditions|
      condition_key = conditions.first[:key]
      condition_value = conditions.first[:value]
      if public_send("#{condition_key}_changed?") && condition_value == public_send(condition_key) && !public_send("#{dependent}_changed?")
        self[dependent] = nil
      end
    end
  end

  def reset_invalidated_dependent_fields!
    return unless form

    reset_not_routed_questions
    reset_derived_questions
  end

  def dynamically_not_required
    (form.invalidated_questions(self) + form.readonly_questions).map(&:id).uniq
  end

  def set_derived_fields!
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
    self.incref = 1 if net_income_refused?
    self.hhmemb = other_hhmemb + 1 if other_hhmemb.present?
    self.renttype = RENT_TYPE_MAPPING[rent_type]
    self.lettype = get_lettype
    self.totchild = get_totchild
    self.totelder = get_totelder
    self.totadult = get_totadult
    if %i[brent scharge pscharge supcharg].any? { |f| public_send(f).present? }
      self.brent ||= 0
      self.scharge ||= 0
      self.pscharge ||= 0
      self.supcharg ||= 0
      self.tcharge = brent.to_f + scharge.to_f + pscharge.to_f + supcharg.to_f
    end
    if period.present?
      self.wrent = weekly_value(brent) if brent.present?
      self.wscharge = weekly_value(scharge) if scharge.present?
      self.wpschrge = weekly_value(pscharge) if pscharge.present?
      self.wsupchrg = weekly_value(supcharg) if supcharg.present?
      self.wtcharge = weekly_value(tcharge) if tcharge.present?
    end
    self.has_benefits = get_has_benefits
    self.wtshortfall = if tshortfall && receives_housing_related_benefits?
                         weekly_value(tshortfall)
                       end
    self.nocharge = household_charge&.zero? ? 1 : 0
    self.underoccupation_benefitcap = 3 if renewal == 1 && year == 2021
    self.ethnic = ethnic || ethnic_group
    if is_renewal?
      self.underoccupation_benefitcap = 2 if year == 2021
      self.homeless = 2
      self.referral = 0
      self.layear = 1
      if is_general_needs?
        self.prevten = 32 if managing_organisation.provider_type == "PRP"
        self.prevten = 30 if managing_organisation.provider_type == "LA"
      end
    end
  end

  def process_postcode_changes!
    process_postcode(property_postcode, "postcode_known", "is_la_inferred", "la", "postcode", "postcod2")
  end

  def process_previous_postcode_changes!
    process_postcode(previous_postcode, "previous_postcode_known", "is_previous_la_inferred", "prevloc", "ppostc1", "ppostc2")
  end

  def process_postcode(postcode, postcode_known_key, la_inferred_key, la_key, outcode_key, incode_key)
    return if postcode.blank?

    self[postcode_known_key] = 1
    inferred_la = get_inferred_la(postcode)
    self[la_inferred_key] = inferred_la.present?
    self[la_key] = inferred_la if inferred_la.present?
    self[outcode_key] = UKPostcode.parse(postcode).outcode
    self[incode_key] = UKPostcode.parse(postcode).incode
  end

  def reset_location_fields!
    reset_location(is_la_inferred, "la", "is_la_inferred", "property_postcode", "postcode", "postcod2", la_known)
  end

  def reset_previous_location_fields!
    reset_location(is_previous_la_inferred, "prevloc", "is_previous_la_inferred", "previous_postcode", "ppostc1", "ppostc2", previous_la_known)
  end

  def reset_location(is_inferred, la_key, is_inferred_key, postcode_key, incode_key, outcode_key, is_la_known)
    if is_inferred || is_la_known != 1
      self[la_key] = nil
    end
    self[is_inferred_key] = false
    self[postcode_key] = nil
    self[incode_key] = nil
    self[outcode_key] = nil
  end

  def get_totelder
    ages = [age1, age2, age3, age4, age5, age6, age7, age8]
    ages.count { |x| !x.nil? && x >= 60 }
  end

  def get_totchild
    relationships = [relat2, relat3, relat4, relat5, relat6, relat7, relat8]
    relationships.count(1)
  end

  def get_totadult
    total = !age1.nil? && age1 >= 16 && age1 < 60 ? 1 : 0
    total + (2..8).count do |i|
      age = public_send("age#{i}")
      relat = public_send("relat#{i}")
      !age.nil? && ((age >= 16 && age < 18 && [0, 2].include?(relat)) || age >= 18 && age < 60)
    end
  end

  def get_inferred_la(postcode)
    postcode_lookup = nil
    begin
      Timeout.timeout(5) { postcode_lookup = PIO.lookup(postcode) }
    rescue Timeout::Error
      Rails.logger.warn("Postcodes.io lookup timed out")
    end
    if postcode_lookup && postcode_lookup.info.present?
      postcode_lookup.codes["admin_district"]
    end
  end

  def get_has_benefits
    HAS_BENEFITS_OPTIONS.include?(hb) ? 1 : 0
  end

  def get_lettype
    return unless renttype.present? && needstype.present? && owning_organisation[:provider_type].present?

    case RENT_TYPE_MAPPING_LABELS[renttype]
    when "Social Rent"
      if is_supported_housing?
        owning_organisation[:provider_type] == "PRP" ? 2 : 4
      elsif is_general_needs?
        owning_organisation[:provider_type] == "PRP" ? 1 : 3
      end
    when "Affordable Rent"
      if is_supported_housing?
        owning_organisation[:provider_type] == "PRP" ? 6 : 8
      elsif is_general_needs?
        owning_organisation[:provider_type] == "PRP" ? 5 : 7
      end
    when "Intermediate Rent"
      if is_supported_housing?
        owning_organisation[:provider_type] == "PRP" ? 10 : 12
      elsif is_general_needs?
        owning_organisation[:provider_type] == "PRP" ? 9 : 11
      end
    end
  end

  def all_fields_completed?
    mandatory_fields.none? { |field| public_send(field).nil? if respond_to?(field) }
  end

  def all_fields_nil?
    init_fields = %w[owning_organisation_id managing_organisation_id]
    fields = mandatory_fields.difference(init_fields)
    fields.none? { |field| public_send(field).present? if respond_to?(field) }
  end

  def mandatory_fields
    form.questions.map(&:id).difference(OPTIONAL_FIELDS, dynamically_not_required)
  end
end
