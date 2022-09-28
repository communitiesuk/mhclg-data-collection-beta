class LettingsLogValidator < ActiveModel::Validator
  # Validations methods need to be called 'validate_' to run on model save
  # or form page submission
  include Validations::SetupValidations
  include Validations::HouseholdValidations
  include Validations::PropertyValidations
  include Validations::FinancialValidations
  include Validations::TenancyValidations
  include Validations::DateValidations
  include Validations::LocalAuthorityValidations

  def validate(record)
    validation_methods = public_methods.select { |method| method.starts_with?("validate_") }
    validation_methods.each { |meth| public_send(meth, record) }
  end
end

class LettingsLog < Log
  include Validations::SoftValidations
  include DerivedVariables::LettingsLogVariables

  has_paper_trail

  validates_with LettingsLogValidator
  before_validation :recalculate_start_year!, if: :startdate_changed?
  before_validation :reset_scheme_location!, if: :scheme_changed?, unless: :location_changed?
  
  # Warning: Postcode checks require external service request - can be slow
  before_validation :process_postcode_changes!, if: :postcode_full_changed?  
  before_validation :process_previous_postcode_changes!, if: :ppostcode_full_changed?
  
  before_validation :reset_invalidated_dependent_fields!  
  before_validation :reset_location_fields!, unless: :postcode_known?
  before_validation :reset_previous_location_fields!, unless: :previous_postcode_known?
  before_validation :set_derived_fields!

  belongs_to :scheme, optional: true
  belongs_to :location, optional: true

  scope :filter_by_year, ->(year) { where(startdate: Time.zone.local(year.to_i, 4, 1)...Time.zone.local(year.to_i + 1, 4, 1)) }
  scope :filter_by_tenant_code, ->(tenant_code) { where("tenancycode ILIKE ?", "%#{tenant_code}%") }
  scope :filter_by_propcode, ->(propcode) { where("propcode ILIKE ?", "%#{propcode}%") }
  scope :filter_by_postcode, ->(postcode_full) { where("REPLACE(postcode_full, ' ', '') ILIKE ?", "%#{postcode_full.delete(' ')}%") }
  scope :filter_by_location_postcode, ->(postcode_full) { left_joins(:location).where("REPLACE(locations.postcode, ' ', '') ILIKE ?", "%#{postcode_full.delete(' ')}%") }
  scope :search_by, lambda { |param|
                      filter_by_location_postcode(param)
                          .or(filter_by_tenant_code(param))
                          .or(filter_by_propcode(param))
                          .or(filter_by_postcode(param))
                          .or(filter_by_id(param))
                    }

  AUTOGENERATED_FIELDS = %w[id status created_at updated_at discarded_at].freeze
  OPTIONAL_FIELDS = %w[first_time_property_let_as_social_housing tenancycode propcode].freeze
  RENT_TYPE_MAPPING_LABELS = { 1 => "Social Rent", 2 => "Affordable Rent", 3 => "Intermediate Rent" }.freeze
  HAS_BENEFITS_OPTIONS = [1, 6, 8, 7].freeze
  NUM_OF_WEEKS_FROM_PERIOD = { 2 => 26, 3 => 13, 4 => 12, 5 => 50, 6 => 49, 7 => 48, 8 => 47, 9 => 46, 1 => 52 }.freeze
  SUFFIX_FROM_PERIOD = { 2 => "every 2 weeks", 3 => "every 4 weeks", 4 => "every month" }.freeze
  RETIREMENT_AGES = { "M" => 67, "F" => 60, "X" => 67 }.freeze

  def form
    FormHandler.instance.get_form(form_name) || FormHandler.instance.current_lettings_form
  end

  def recalculate_start_year!
    @start_year = nil
    collection_start_year
  end

  def form_name
    return unless startdate

    FormHandler.instance.form_name_from_start_year(collection_start_year, "lettings")
  end

  def self.editable_fields
    attribute_names - AUTOGENERATED_FIELDS
  end

  def la
    if location
      location.location_code
    else
      super
    end
  end

  def postcode_full
    if location
      location.postcode
    else
      super
    end
  end

  def postcode_full=(postcode)
    if postcode
      super UKPostcode.parse(postcode).to_s
    else
      super nil
    end
  end

  def ppostcode_full=(postcode)
    if postcode
      super UKPostcode.parse(postcode).to_s
    else
      super nil
    end
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
      (earnings / 52.0).round(0)
    end
  end

  def weekly_value(field_value)
    num_of_weeks = NUM_OF_WEEKS_FROM_PERIOD[period]
    return unless field_value && num_of_weeks

    (field_value / 52 * num_of_weeks).round(2)
  end

  def weekly_to_value_per_period(field_value)
    num_of_weeks = NUM_OF_WEEKS_FROM_PERIOD[period]

    ((field_value * 52) / num_of_weeks).round(2)
  end

  def applicable_income_range
    return unless ecstat1

    ALLOWED_INCOME_RANGES[ecstat1]
  end

  def first_time_property_let_as_social_housing?
    first_time_property_let_as_social_housing == 1
  end

  def net_income_refused?
    # 2: Tenant prefers not to say
    net_income_known == 2
  end

  def net_income_is_weekly?
    # 1: Weekly
    !!(incfreq && incfreq == 1)
  end

  def net_income_is_monthly?
    # 2: Monthly
    incfreq == 2
  end

  def net_income_is_yearly?
    # 3: Yearly
    incfreq == 3
  end

  def net_income_soft_validation_triggered?
    net_income_in_soft_min_range? || net_income_in_soft_max_range?
  end

  def given_reasonable_preference?
    # 1: Yes
    reasonpref == 1
  end

  def is_renewal?
    # 1: Yes
    renewal == 1
  end

  def is_general_needs?
    # 1: General Needs
    needstype == 1
  end

  def is_supported_housing?
    # 2: Supported Housing
    needstype == 2
  end

  def has_hbrentshortfall?
    # 1: Yes
    hbrentshortfall == 1
  end

  def postcode_known?
    # 1: Yes
    postcode_known == 1
  end

  def previous_postcode_known?
    # 1: Yes
    ppcodenk == 1
  end

  def previous_la_known?
    # 1: Yes
    previous_la_known == 1
  end

  def tshortfall_unknown?
    tshortfall_known == 1
  end

  def is_fixed_term_tenancy?
    [4, 6].include?(tenancy)
  end

  def is_secure_tenancy?
    return unless collection_start_year

    # 1: Secure (including flexible)
    if collection_start_year < 2022
      tenancy == 1
    else
      # 6: Secure - fixed term, 7: Secure - lifetime
      [6, 7].include?(tenancy)
    end
  end

  def is_assured_shorthold_tenancy?
    # 4: Assured Shorthold
    tenancy == 4
  end

  def is_internal_transfer?
    # 1: Internal Transfer
    referral == 1
  end

  def is_relet_to_temp_tenant?
    # 9: Re-let to tenant who occupied same property as temporary accommodation
    rsnvac == 9
  end

  def is_bedsit?
    # 2: Bedsit
    unittype_gn == 2
  end

  def is_shared_housing?
    # 4: Shared flat or maisonette
    # 9: Shared house
    # 10: Shared bungalow
    [4, 9, 10].include?(unittype_gn)
  end

  def has_first_let_vacancy_reason?
    # 15: First let of new-build property
    # 16: First let of conversion, rehabilitation or acquired property
    # 17: First let of leased property
    [15, 16, 17].include?(rsnvac)
  end

  def previous_tenancy_was_temporary?
    # 4: Tied housing or renting with job
    # 6: Supported housing
    # 8: Sheltered accomodation (<= 21/22)
    # 24: Housed by National Asylum Support Service (prev Home Office)
    # 25: Other
    # 34: Specialist retirement housing
    # 35: Extra care housing
    ![4, 6, 8, 24, 25, 34, 35].include?(prevten)
  end

  def armed_forces_regular?
    # 1: Yes – the person is a current or former regular
    !!(armedforces && armedforces == 1)
  end

  def armed_forces_no?
    # 2: No
    armedforces == 2
  end

  def armed_forces_refused?
    # 3: Person prefers not to say / Refused
    armedforces == 3
  end

  def has_pregnancy?
    # 1: Yes
    !!(preg_occ && preg_occ == 1)
  end

  def pregnancy_refused?
    # 3: Tenant prefers not to say / Refused
    preg_occ == 3
  end

  def is_assessed_homeless?
    # 11: Assessed as homeless (or threatened with homelessness within 56 days) by a local authority and owed a homelessness duty
    homeless == 11
  end

  def is_not_homeless?
    # 1: No
    homeless == 1
  end

  def is_london_rent?
    # 2: London Affordable Rent
    # 4: London Living Rent
    rent_type == 2 || rent_type == 4
  end

  def previous_tenancy_was_foster_care?
    # 13: Children's home or foster care
    prevten == 13
  end

  def previous_tenancy_was_refuge?
    # 21: Refuge
    prevten == 21
  end

  def is_reason_permanently_decanted?
    # 1: Permanently decanted from another property owned by this landlord
    reason == 1
  end

  def receives_housing_benefit_only?
    # 1: Housing benefit
    hb == 1
  end

  def benefits_unknown?
    hb == 3
  end

  # Option 8 has been removed starting from 22/23
  def receives_housing_benefit_and_universal_credit?
    # 8: Housing benefit and Universal Credit (without housing element)
    hb == 8
  end

  def receives_uc_with_housing_element_excl_housing_benefit?
    # 6: Universal Credit with housing element (excluding housing benefit)
    hb == 6
  end

  def receives_no_benefits?
    # 9: None
    hb == 9
  end

  def tenant_refuses_to_say_benefits?
    hb == 10
  end

  # Option 7 has been removed starting from 22/23
  def receives_universal_credit_but_no_housing_benefit?
    # 7: Universal Credit (without housing element)
    hb == 7
  end

  def ethnic_refused?
    ethnic_group == 17
  end

  def receives_housing_related_benefits?
    if collection_start_year <= 2021
      receives_housing_benefit_only? || receives_uc_with_housing_element_excl_housing_benefit? ||
        receives_housing_benefit_and_universal_credit?
    else
      receives_housing_benefit_only? || receives_uc_with_housing_element_excl_housing_benefit?
    end
  end

  def local_housing_referral?
    # 3: PRP lettings only - Nominated by local housing authority
    referral == 3
  end

  def is_prevten_la_general_needs?
    # 30: Fixed term Local Authority General Needs tenancy
    # 31: Lifetime Local Authority General Needs tenancy
    [30, 31].any?(prevten)
  end

  def owning_organisation_name
    owning_organisation&.name
  end

  def managing_organisation_name
    managing_organisation&.name
  end

  def created_by_name
    created_by&.name
  end

  def is_dpo
    created_by&.is_dpo
  end

  delegate :service_name, :sensitive, :registered_under_care_act, :primary_client_group, :has_other_client_group, :secondary_client_group, :owning_organisation, :managing_organisation, :support_type, :intended_stay, :created_at, prefix: "scheme", to: :scheme, allow_nil: true
  delegate :scheme_type, to: :scheme, allow_nil: true

  def scheme_code
    scheme&.id ? "S#{scheme.id}" : nil
  end

  def scheme_owning_organisation_name
    scheme_owning_organisation&.name
  end

  def scheme_managing_organisation_name
    scheme_managing_organisation&.name
  end

  delegate :postcode, :name, :units, :type_of_unit, :mobility_type, :startdate, prefix: "location", to: :location, allow_nil: true
  delegate :location_admin_district, to: :location, allow_nil: true

  # This is not the location_code in the db, location.id is just called code in the UI
  def location_code
    location&.id
  end

  def self.to_csv(user = nil)
    Csv::LettingsLogCsvService.new(user).to_csv
  end

  def soft_min_for_period
    soft_min = LaRentRange.find_by(start_year: collection_start_year, la:, beds:, lettype:).soft_min
    "#{soft_value_for_period(soft_min)} #{SUFFIX_FROM_PERIOD[period].presence || 'every week'}"
  end

  def soft_max_for_period
    soft_max = LaRentRange.find_by(start_year: collection_start_year, la:, beds:, lettype:).soft_max
    "#{soft_value_for_period(soft_max)} #{SUFFIX_FROM_PERIOD[period].presence || 'every week'}"
  end

  def optional_fields
    OPTIONAL_FIELDS + dynamically_not_required
  end

  (1..8).each do |person_num|
    define_method("retirement_age_for_person_#{person_num}") do
      retirement_age_for_person(person_num)
    end

    define_method("plural_gender_for_person_#{person_num}") do
      plural_gender_for_person(person_num)
    end
  end

  def retirement_age_for_person(person_num)
    gender = public_send("sex#{person_num}".to_sym)
    return unless gender

    RETIREMENT_AGES[gender]
  end

  def plural_gender_for_person(person_num)
    gender = public_send("sex#{person_num}".to_sym)
    return unless gender

    if %w[M X].include?(gender)
      "male and non-binary people"
    elsif gender == "F"
      "females"
    end
  end

  def age_known?(person_num)
    return false unless person_num.is_a?(Integer)

    !!public_send("age#{person_num}_known")&.zero?
  end

  def age_unknown?(person_num)
    return false unless person_num.is_a?(Integer)

    public_send("age#{person_num}_known") == 1
  end

  def unittype_sh
    location.type_of_unit_before_type_cast if location
  end

  def lettings?
    true
  end

  def rent_type_detail
    form.get_question("rent_type", self)&.label_from_value(rent_type)
  end

private

  PIO = PostcodeService.new

  def reset_derived_questions
    dependent_questions = { waityear: [{ key: :renewal, value: 0 }],
                            referral: [{ key: :renewal, value: 0 }],
                            underoccupation_benefitcap: [{ key: :renewal, value: 0 }],
                            wchair: [{ key: :needstype, value: 1 }],
                            location_id: [{ key: :needstype, value: 1 }] }

    dependent_questions.each do |dependent, conditions|
      condition_key = conditions.first[:key]
      condition_value = conditions.first[:value]
      if public_send("#{condition_key}_changed?") && condition_value == public_send(condition_key) && !public_send("#{dependent}_changed?")
        Rails.logger.debug("Cleared derived #{dependent} value")
        self[dependent] = nil
      end
    end
  end

  def reset_scheme
    return unless scheme && owning_organisation

    self.scheme = nil if scheme.owning_organisation != owning_organisation
  end

  def reset_invalidated_dependent_fields!
    super

    reset_created_by
    reset_scheme
    reset_derived_questions
  end

  def dynamically_not_required
    not_required = []
    not_required << "previous_la_known" if postcode_known?
    not_required << "tshortfall" if tshortfall_unknown?
    not_required << "tenancylength" if tenancylength_optional?

    not_required
  end

  def tenancylength_optional?
    return false unless collection_start_year
    return true if collection_start_year < 2022

    collection_start_year >= 2022 && !is_fixed_term_tenancy?
  end

  def age_under_16?(person_num)
    public_send("age#{person_num}") && public_send("age#{person_num}") < 16
  end

  def process_postcode_changes!
    self.postcode_full = upcase_and_remove_whitespace(postcode_full)
    process_postcode(postcode_full, "postcode_known", "is_la_inferred", "la")
  end

  def process_previous_postcode_changes!
    self.ppostcode_full = upcase_and_remove_whitespace(ppostcode_full)
    process_postcode(ppostcode_full, "ppcodenk", "is_previous_la_inferred", "prevloc")
  end

  def process_postcode(postcode, postcode_known_key, la_inferred_key, la_key)
    return if postcode.blank?

    self[postcode_known_key] = 1
    inferred_la = get_inferred_la(postcode)
    self[la_inferred_key] = inferred_la.present?
    self[la_key] = inferred_la if inferred_la.present?
  end

  def reset_location_fields!
    reset_location(is_la_inferred, "la", "is_la_inferred", "postcode_full", 1)
  end

  def reset_previous_location_fields!
    reset_location(is_previous_la_inferred, "prevloc", "is_previous_la_inferred", "ppostcode_full", previous_la_known)
  end

  def reset_location(is_inferred, la_key, is_inferred_key, postcode_key, is_la_known)
    if is_inferred || is_la_known != 1
      self[la_key] = nil
    end
    self[is_inferred_key] = false
    self[postcode_key] = nil
  end

  def get_inferred_la(postcode)
    result = PIO.lookup(postcode)
    result[:location_code] if result
  end

  def get_has_benefits
    HAS_BENEFITS_OPTIONS.include?(hb) ? 1 : 0
  end

  def get_lettype
    return unless rent_type.present? && needstype.present? && owning_organisation.present? && owning_organisation[:provider_type].present?

    case RENT_TYPE_MAPPING_LABELS[RENT_TYPE_MAPPING[rent_type]]
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

  def age_refused?
    [age1_known, age2_known, age3_known, age4_known, age5_known, age6_known, age7_known, age8_known].any?(1)
  end

  def sex_refused?
    [sex1, sex2, sex3, sex4, sex5, sex6, sex7, sex8].any?("R")
  end

  def relat_refused?
    [relat2, relat3, relat4, relat5, relat6, relat7, relat8].any?("R")
  end

  def ecstat_refused?
    [ecstat1, ecstat2, ecstat3, ecstat4, ecstat5, ecstat6, ecstat7, ecstat8].any?(10)
  end

  def soft_value_for_period(value)
    num_of_weeks = NUM_OF_WEEKS_FROM_PERIOD[period]
    return "" unless value && num_of_weeks

    (value * 52 / num_of_weeks).round(2)
  end

  def upcase_and_remove_whitespace(string)
    string&.upcase.gsub(/\s+/, "")
  end

  def fully_wheelchair_accessible?
    housingneeds_type.present? && housingneeds_type.zero?
  end

  def essential_wheelchair_access?
    housingneeds_type == 1
  end

  def level_access_housing?
    housingneeds_type == 2
  end

  def other_housingneeds?
    housingneeds_other == 1
  end

  def has_housingneeds?
    housingneeds == 1
  end

  def no_housingneeds?
    housingneeds == 2
  end

  def unknown_housingneeds?
    housingneeds == 3
  end
end
