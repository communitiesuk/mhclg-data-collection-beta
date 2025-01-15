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
  include Validations::DateValidations
  include Validations::FinancialValidations
  include MoneyFormattingHelper

  has_paper_trail

  validates_with LettingsLogValidator
  before_validation :recalculate_start_year!, if: :startdate_changed?
  before_validation :reset_scheme_location!, if: :scheme_changed?, unless: :location_changed?
  before_validation :process_postcode_changes!, if: :postcode_full_changed?
  before_validation :process_previous_postcode_changes!, if: :ppostcode_full_changed?
  before_validation :reset_invalidated_dependent_fields!
  before_validation :reset_location_fields!, unless: :postcode_known?
  before_validation :reset_previous_location_fields!, unless: :previous_postcode_known?
  before_validation :set_derived_fields!
  before_validation :process_uprn_change!, if: :should_process_uprn_change?
  before_validation :process_address_change!, if: :should_process_address_change?

  belongs_to :scheme, optional: true
  belongs_to :location, optional: true
  belongs_to :managing_organisation, class_name: "Organisation", optional: true

  scope :filter_by_year, ->(year) { where(startdate: Time.zone.local(year.to_i, 4, 1)...Time.zone.local(year.to_i + 1, 4, 1)) }
  scope :filter_by_years_or_nil, lambda { |years, _user = nil|
    first_year = years.shift
    query = filter_by_year(first_year)
    years.each { |year| query = query.or(filter_by_year(year)) }
    query = query.or(where(startdate: nil))
    query.all
  }
  scope :filter_by_tenant_code, ->(tenant_code) { where("tenancycode ILIKE ?", "%#{tenant_code}%") }
  scope :filter_by_propcode, ->(propcode) { where("propcode ILIKE ?", "%#{propcode}%") }
  scope :filter_by_location_postcode, ->(postcode_full) { left_joins(:location).where("REPLACE(locations.postcode, ' ', '') ILIKE ?", "%#{postcode_full.delete(' ')}%") }
  scope :filter_by_needstype, ->(needstype) { where(needstype:) }
  scope :filter_by_needstypes, lambda { |needstypes, _user = nil|
    first_needstype = needstypes.shift
    query = filter_by_needstype(first_needstype)
    needstypes.each { |needstype| query = query.or(filter_by_needstype(needstype)) }
    query.all
  }
  scope :search_by, lambda { |param|
    sanitized_param = ActiveRecord::Base.sanitize_sql(param)
    param_without_spaces = sanitized_param.delete(" ")

    by_id = Arel.sql("CASE WHEN lettings_logs.id = ? THEN 0 ELSE 1 END")
    by_tenant_code = Arel.sql("CASE WHEN tenancycode = ? THEN 0 WHEN tenancycode ILIKE ? THEN 1 ELSE 2 END")
    by_propcode = Arel.sql("CASE WHEN propcode = ? THEN 0 WHEN propcode ILIKE ? THEN 1 ELSE 2 END")
    by_postcode = Arel.sql("CASE WHEN REPLACE(postcode_full, ' ', '') = ? THEN 0 WHEN REPLACE(postcode_full, ' ', '') ILIKE ? THEN 1 ELSE 2 END")

    filter_by_location_postcode(param)
      .or(filter_by_tenant_code(param))
      .or(filter_by_propcode(param))
      .or(filter_by_postcode(param))
      .or(filter_by_id(param.gsub(/log/i, "")))
      .order(
        [by_id, sanitized_param.to_i],
        [by_tenant_code, sanitized_param, sanitized_param],
        [by_propcode, sanitized_param, sanitized_param],
        [by_postcode, param_without_spaces, param_without_spaces],
      )
  }
  scope :after_date, ->(date) { where("lettings_logs.startdate >= ?", date) }
  scope :before_date, ->(date) { where("lettings_logs.startdate < ?", date) }
  scope :unresolved, -> { where(unresolved: true) }
  scope :age1_answered, -> { where.not(age1: nil).or(where(age1_known: 1)) }
  scope :tcharge_answered, -> { where.not(tcharge: nil).or(where(household_charge: 1)).or(where(is_carehome: 1)) }
  scope :chcharge_answered, -> { where.not(chcharge: nil).or(where(is_carehome: [nil, 0])) }
  scope :location_for_log_answered, ->(log) { where(location_id: log.location_id).or(where(needstype: 1)) }
  scope :postcode_for_log_answered, ->(log) { where(postcode_full: log.postcode_full).or(where(needstype: 2)) }
  scope :location_answered, -> { where.not(location_id: nil).or(where(needstype: 1)) }
  scope :postcode_answered, -> { where.not(postcode_full: nil).or(where(needstype: 2)) }
  scope :duplicate_logs, lambda { |log|
    visible
      .where.not(id: log.id)
      .where.not(startdate: nil)
      .where.not(sex1: nil)
      .where.not(ecstat1: nil)
      .where.not(needstype: nil)
      .age1_answered
      .tcharge_answered
      .chcharge_answered
      .location_for_log_answered(log)
      .postcode_for_log_answered(log)
      .where(log.slice(*DUPLICATE_LOG_ATTRIBUTES))
  }

  scope :duplicate_sets, lambda { |assigned_to_id = nil|
    scope = visible
    .group(*DUPLICATE_LOG_ATTRIBUTES, :postcode_full, :location_id)
    .where.not(startdate: nil)
    .where.not(sex1: nil)
    .where.not(ecstat1: nil)
    .where.not(needstype: nil)
    .age1_answered
    .tcharge_answered
    .chcharge_answered
    .location_answered
    .postcode_answered
    .having(
      "COUNT(*) > 1",
    )

    if assigned_to_id
      scope = scope.having("MAX(CASE WHEN assigned_to_id = ? THEN 1 ELSE 0 END) >= 1", assigned_to_id)
    end
    scope.pluck("ARRAY_AGG(id)")
  }

  scope :with_illness_without_type, lambda {
    where(illness: 1,
          illness_type_1: false,
          illness_type_2: false,
          illness_type_3: false,
          illness_type_4: false,
          illness_type_5: false,
          illness_type_6: false,
          illness_type_7: false,
          illness_type_8: false,
          illness_type_9: false,
          illness_type_10: false)
  }

  scope :filter_by_user_text_search, ->(param, user) { where(assigned_to: User.visible(user).search_by(param)) }
  scope :filter_by_owning_organisation_text_search, ->(param, _user) { where(owning_organisation: Organisation.search_by(param)) }
  scope :filter_by_managing_organisation_text_search, ->(param, _user) { where(managing_organisation: Organisation.search_by(param)) }

  AUTOGENERATED_FIELDS = %w[id status created_at updated_at discarded_at].freeze
  OPTIONAL_FIELDS = %w[tenancycode propcode chcharge].freeze
  RENT_TYPE_MAPPING_LABELS = { 1 => "Social Rent", 2 => "Affordable Rent", 3 => "Intermediate Rent", 4 => "Specified accommodation" }.freeze
  HAS_BENEFITS_OPTIONS = [1, 6, 8, 7].freeze
  NUM_OF_WEEKS_FROM_PERIOD = { 2 => 26, 3 => 13, 4 => 12, 5 => 50, 6 => 49, 7 => 48, 8 => 47, 9 => 46, 1 => 52, 10 => 53 }.freeze
  SUFFIX_FROM_PERIOD = { 2 => "every 2 weeks", 3 => "every 4 weeks", 4 => "every month" }.freeze
  DUPLICATE_LOG_ATTRIBUTES = %w[owning_organisation_id tenancycode startdate age1_known age1 sex1 ecstat1 tcharge household_charge chcharge].freeze
  RENT_TYPE = {
    social_rent: 0,
    affordable_rent: 1,
    london_affordable_rent: 2,
    rent_to_buy: 3,
    london_living_rent: 4,
    other_intermediate_rent_product: 5,
    specified_accommodation: 6,
  }.freeze

  def form
    FormHandler.instance.get_form(form_name) || FormHandler.instance.current_lettings_form
  end

  def lettings?
    true
  end

  def sales?
    false
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
      location.linked_local_authorities.active(form.start_date).first&.code || location.location_code
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

    format_as_currency((field_value * 52) / num_of_weeks)
  end

  def applicable_income_range
    return unless ecstat1 && hhmemb && ALLOWED_INCOME_RANGES[ecstat1]

    range = ALLOWED_INCOME_RANGES[ecstat1].clone

    if hhmemb > 1
      (2..hhmemb).each do |person_index|
        ecstat = self["ecstat#{person_index}"]

        if ecstat.nil?
          age = self["age#{person_index}"]
          # This should match the conditions under which ecstat is inferred as 9 (child under 16)
          ecstat = age && age < 16 ? 9 : 10
        end

        person_range = ALLOWED_INCOME_RANGES[ecstat]
        range.soft_min += person_range.soft_min
        range.hard_min += person_range.hard_min
        range.soft_max += person_range.soft_max
        range.hard_max += person_range.hard_max
      end
    end

    range
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

  def starter_tenancy?
    startertenancy == 1
  end

  def tenancy_type_fixed_term?
    [4, 6].include? tenancy
  end

  def tenancy_type_periodic?
    tenancy == 8
  end

  def is_general_needs?
    # 1: General Needs
    needstype == 1
  end

  def is_supported_housing?
    # 2: Supported Housing
    needstype == 2
  end

  def has_housing_benefit_rent_shortfall?
    # 1: Yes
    hbrentshortfall == 1
  end

  def postcode_known?
    # 1: Yes
    postcode_known == 1
  end

  def previous_postcode_known?
    # 0: Yes
    ppcodenk&.zero?
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

  def is_periodic_tenancy?
    # 8: Periodic
    tenancy == 8
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

  def is_beds_inferred?
    form.start_year_2024_or_later? && is_bedsit?
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

  def vacancy_reason_not_renewal_or_first_let?
    [5, 6, 8, 9, 10, 11, 12, 13, 18, 19, 20, 21, 22].include? rsnvac
  end

  def previous_tenancy_was_temporary?
    # 4: Tied housing or renting with job
    # 6: Supported housing
    # 8: Sheltered accommodation (<= 21/22)
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

  def beds_for_la_rent_range
    return 0 if is_supported_housing?

    beds.nil? ? nil : [beds, LaRentRange::MAX_BEDS].min
  end

  def soft_min_for_period
    soft_min = LaRentRange.find_by(
      start_year: collection_start_year,
      la:,
      beds: beds_for_la_rent_range,
      lettype:,
    ).soft_min
    "#{soft_value_for_period(soft_min)} #{SUFFIX_FROM_PERIOD[period].presence || 'every week'}"
  end

  def soft_max_for_period
    soft_max = LaRentRange.find_by(
      start_year: collection_start_year,
      la:,
      beds: beds_for_la_rent_range,
      lettype:,
    ).soft_max
    "#{soft_value_for_period(soft_max)} #{SUFFIX_FROM_PERIOD[period].presence || 'every week'}"
  end

  def optional_fields
    OPTIONAL_FIELDS + dynamically_not_required
  end

  def age_unknown?(person_num)
    return false unless person_num.is_a?(Integer)

    public_send("age#{person_num}_known") == 1
  end

  def unittype_sh
    location.type_of_unit_before_type_cast if location
  end

  def renttype_detail
    form.get_question("rent_type", self)&.label_from_value(rent_type)
  end

  def renttype_detail_code
    RENTTYPE_DETAIL_MAPPING[rent_type] if rent_type.present?
  end

  def non_location_setup_questions_completed?
    form.setup_sections.all? do |section|
      section.subsections.all? do |subsection|
        relevant_qs = subsection.questions.reject { |q| optional_fields.include?(q.id) || %w[scheme_id location_id].include?(q.id) }
        relevant_applicable_qs = select_applicable_questions(self, relevant_qs)
        relevant_applicable_qs.all? do |question|
          question.completed?(self)
        end
      end
    end
  end

  # this is the same as the subsection method, but only for given questions
  def select_applicable_questions(log, questions)
    questions.select do |q|
      (q.displayed_to_user?(log) && !q.derived?(log)) || q.is_derived_or_has_inferred_check_answers_value?(log)
    end
  end

  def resolve!
    update(unresolved: false)
  end

  def owning_organisation_provider_type
    owning_organisation&.provider_type
  end

  def reset_assigned_to!
    return unless updated_by&.support?
    return if owning_organisation.blank? || managing_organisation.blank? || assigned_to.blank?
    return if assigned_to&.organisation == managing_organisation || assigned_to&.organisation == owning_organisation
    return if assigned_to&.organisation == owning_organisation.absorbing_organisation || assigned_to&.organisation == managing_organisation.absorbing_organisation

    update!(assigned_to: nil)
  end

  def care_home_charge_expected_not_provided?
    is_carehome? && chcharge.blank?
  end

  def rent_and_charges_paid_weekly?
    [1, 5, 6, 7, 8, 9, 10].include? period
  end

  def rent_and_charges_paid_every_4_weeks?
    period == 3
  end

  def rent_and_charges_paid_every_2_weeks?
    period == 2
  end

  def rent_and_charges_paid_monthly?
    period == 4
  end

  def is_carehome?
    is_carehome == 1
  end

  def blank_compound_invalid_non_setup_fields!
    super

    self.postcode_known = nil if errors.attribute_names.include? :postcode_full

    if errors.of_kind?(:earnings, :under_hard_min)
      self.incfreq = nil
    end
  end

  def la_referral_for_general_needs?
    is_general_needs? && referral == 4
  end

  def has_any_person_details?(person_index)
    ["sex#{person_index}", "relat#{person_index}", "ecstat#{person_index}"].any? { |field| public_send(field).present? } || public_send("age#{person_index}_known") == 1
  end

  def details_not_known_for_person?(person_index)
    public_send("details_known_#{person_index}") == 1
  end

  def duplicate_check_question_ids
    ["owning_organisation_id",
     "startdate",
     "tenancycode",
     uprn.blank? ? "postcode_full" : "uprn",
     "scheme_id",
     "location_id",
     "age1",
     "sex1",
     "ecstat1",
     household_charge == 1 ? "household_charge" : nil,
     "tcharge",
     is_carehome? ? "chcharge" : nil].compact
  end

  def letting_allocation_none
    letting_allocation_unknown
  end

  def affordable_or_social_rent?
    renttype == 1 || renttype == 2
  end

  def no_or_unknown_other_housing_needs?
    housingneeds_other&.zero? || housingneeds_other == 2
  end

  def has_housingneeds?
    housingneeds == 1
  end

  def housingneeds_type_not_listed?
    housingneeds_type == 3
  end

  def duplicates
    return LettingsLog.none if duplicate_set_id.nil?

    LettingsLog.where(duplicate_set_id:).where.not(id:)
  end

  def address_search_given?
    address_line1_input.present? && postcode_full_input.present?
  end

  def process_postcode_changes!
    self.postcode_full = upcase_and_remove_whitespace(postcode_full)
    return if postcode_full.blank?

    self.postcode_known = 1
    inferred_la = get_inferred_la(postcode_full)
    self.is_la_inferred = inferred_la.present?
    self.la = inferred_la if inferred_la.present?
  end

  def scheme_has_multiple_locations?
    return false unless scheme

    scheme_locations_count ||= scheme.locations.active_in_2_weeks.size
    scheme_locations_count > 1
  end

  def scheme_has_large_number_of_locations?
    return false unless scheme

    scheme_locations_count ||= scheme.locations.active_in_2_weeks.size
    scheme_locations_count > 19
  end

private

  def reset_invalid_unresolved_log_fields!
    return unless unresolved?

    validate_property_void_date(self)
    self.voiddate = nil if errors[:voiddate].present?

    validate_property_major_repairs(self)
    self.mrcdate = nil if errors[:mrcdate].present?

    validate_rent_range(self)
    if errors[:brent].present?
      self.brent = nil
      self.scharge = nil
      self.pscharge = nil
      self.supcharg = nil
      self.tcharge = nil
    end

    errors.clear
  end

  def reset_scheme
    return unless scheme && owning_organisation
    return unless scheme.owning_organisation != owning_organisation

    self.scheme = nil
    self.location = nil
  end

  def reset_invalidated_dependent_fields!
    super

    reset_invalid_unresolved_log_fields!
    reset_scheme
  end

  def dynamically_not_required
    not_required = []
    not_required << "previous_la_known" if postcode_known?
    not_required << "tshortfall" if tshortfall_unknown?
    not_required << "tenancylength" if tenancylength_optional?
    not_required += %w[address_line2 county]

    not_required
  end

  def tenancylength_optional?
    return false unless collection_start_year
    return true if collection_start_year < 2022

    collection_start_year >= 2022 && !is_fixed_term_tenancy?
  end

  def process_previous_postcode_changes!
    self.ppostcode_full = upcase_and_remove_whitespace(ppostcode_full)
    return if ppostcode_full.blank?

    self.ppcodenk = 0
    inferred_la = get_inferred_la(ppostcode_full)
    self.is_previous_la_inferred = inferred_la.present?
    self.prevloc = inferred_la if inferred_la.present?
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
    when "Specified accommodation"
      if is_supported_housing?
        owning_organisation[:provider_type] == "PRP" ? 14 : 16
      elsif is_general_needs?
        owning_organisation[:provider_type] == "PRP" ? 13 : 15
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

  def details_unknown?
    [details_known_2, details_known_3, details_known_4, details_known_5, details_known_6, details_known_7, details_known_8].any?(1)
  end

  def soft_value_for_period(value)
    num_of_weeks = NUM_OF_WEEKS_FROM_PERIOD[period]
    return "" unless value && num_of_weeks

    format_as_currency((value * 52 / num_of_weeks))
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

  def no_housingneeds?
    housingneeds == 2
  end

  def unknown_housingneeds?
    housingneeds == 3
  end

  def should_process_uprn_change?
    return unless uprn
    return unless startdate

    uprn_changed? || startdate_changed?
  end

  def should_process_address_change?
    return unless uprn_selection || select_best_address_match
    return unless startdate
    return unless form.start_year_2024_or_later?

    if select_best_address_match
      address_line1_input.present? && postcode_full_input.present?
    else
      uprn_selection_changed? || startdate_changed?
    end
  end
end
