class SalesLogValidator < ActiveModel::Validator
  include Validations::Sales::SetupValidations
  include Validations::Sales::HouseholdValidations
  include Validations::Sales::PropertyValidations
  include Validations::Sales::FinancialValidations
  include Validations::Sales::SaleInformationValidations
  include Validations::SharedValidations
  include Validations::LocalAuthorityValidations

  def validate(record)
    validation_methods = public_methods.select { |method| method.starts_with?("validate_") }
    validation_methods.each { |meth| public_send(meth, record) }
  end
end

class SalesLog < Log
  include DerivedVariables::SalesLogVariables
  include Validations::Sales::SoftValidations
  include Validations::SoftValidations
  include MoneyFormattingHelper

  self.inheritance_column = :_type_disabled

  has_paper_trail

  validates_with SalesLogValidator
  before_validation :recalculate_start_year!, if: :saledate_changed?
  before_validation :process_postcode_changes!, if: :postcode_full_changed?
  before_validation :process_previous_postcode_changes!, if: :ppostcode_full_changed?
  before_validation :reset_invalidated_dependent_fields!
  before_validation :reset_location_fields!, unless: :postcode_known?
  before_validation :reset_previous_location_fields!, unless: :previous_postcode_known?
  before_validation :set_derived_fields!
  before_validation :process_uprn_change!, if: :should_process_uprn_change?
  before_validation :process_address_change!, if: :should_process_address_change?

  belongs_to :managing_organisation, class_name: "Organisation", optional: true

  scope :filter_by_year, ->(year) { where(saledate: Time.zone.local(year.to_i, 4, 1)...Time.zone.local(year.to_i + 1, 4, 1)) }
  scope :filter_by_years_or_nil, lambda { |years, _user = nil|
    first_year = years.shift
    query = filter_by_year(first_year)
    years.each { |year| query = query.or(filter_by_year(year)) }
    query = query.or(where(saledate: nil))
    query.all
  }
  scope :filter_by_purchaser_code, ->(purchid) { where("purchid ILIKE ?", "%#{purchid}%") }
  scope :search_by, lambda { |param|
    sanitized_param = ActiveRecord::Base.sanitize_sql(param)
    param_without_spaces = sanitized_param.delete(" ")

    by_id = Arel.sql("CASE WHEN id = ? THEN 0 ELSE 1 END")
    by_purchaser_code = Arel.sql("CASE WHEN purchid = ? THEN 0 WHEN purchid ILIKE ? THEN 1 ELSE 2 END")
    by_postcode = Arel.sql("CASE WHEN REPLACE(postcode_full, ' ', '') = ? THEN 0 WHEN REPLACE(postcode_full, ' ', '') ILIKE ? THEN 1 ELSE 2 END")

    filter_by_purchaser_code(param)
      .or(filter_by_postcode(param))
      .or(filter_by_id(param.gsub(/log/i, "")))
      .order([by_id, sanitized_param.to_i],
             [by_purchaser_code, sanitized_param, sanitized_param],
             [by_postcode, param_without_spaces, param_without_spaces])
  }
  scope :age1_answered, -> { where.not(age1: nil).or(where(age1_known: [1, 2])) }
  scope :ecstat1_answered, -> { where.not(ecstat1: nil).or(where("saledate >= ?", Time.zone.local(2025, 4, 1))) }
  scope :duplicate_logs, lambda { |log|
    visible.where(log.slice(*DUPLICATE_LOG_ATTRIBUTES))
    .where.not(id: log.id)
    .where.not(saledate: nil)
    .where.not(sex1: nil)
    .where.not(postcode_full: nil)
    .ecstat1_answered
    .age1_answered
  }
  scope :after_date, ->(date) { where("saledate >= ?", date) }

  scope :duplicate_sets, lambda { |assigned_to_id = nil|
    scope = visible
    .group(*DUPLICATE_LOG_ATTRIBUTES)
    .where.not(saledate: nil)
    .where.not(sex1: nil)
    .where.not(postcode_full: nil)
    .age1_answered
    .ecstat1_answered
    .having("COUNT(*) > 1")

    if assigned_to_id
      scope = scope.having("MAX(CASE WHEN assigned_to_id = ? THEN 1 ELSE 0 END) >= 1", assigned_to_id)
    end

    scope.pluck("ARRAY_AGG(id)")
  }

  OPTIONAL_FIELDS = %w[purchid othtype buyers_organisations].freeze
  DUPLICATE_LOG_ATTRIBUTES = %w[owning_organisation_id purchid saledate age1_known age1 sex1 ecstat1 postcode_full].freeze

  def lettings?
    false
  end

  def sales?
    true
  end

  def startdate
    saledate
  end

  def self.editable_fields
    attribute_names
  end

  def purchaser_code
    purchid
  end

  def form_name
    return unless saledate

    FormHandler.instance.form_name_from_start_year(collection_start_year, "sales")
  end

  def form
    FormHandler.instance.get_form(form_name) || FormHandler.instance.current_sales_form
  end

  def optional_fields
    OPTIONAL_FIELDS + dynamically_not_required
  end

  def dynamically_not_required
    not_required = []
    not_required << "deposit" if form.start_year_2024_or_later? && stairowned_100?
    not_required += %w[address_line2 county]

    not_required
  end

  def unresolved
    false
  end

  LONDON_BOROUGHS = %w[
    E09000001
    E09000033
    E09000020
    E09000013
    E09000032
    E09000022
    E09000028
    E09000030
    E09000012
    E09000019
    E09000007
    E09000005
    E09000009
    E09000018
    E09000027
    E09000021
    E09000024
    E09000029
    E09000008
    E09000006
    E09000023
    E09000011
    E09000004
    E09000016
    E09000002
    E09000026
    E09000025
    E09000031
    E09000014
    E09000010
    E09000003
    E09000015
    E09000017
  ].freeze

  def london_property?
    la && LONDON_BOROUGHS.include?(la)
  end

  def property_not_in_london?
    !london_property?
  end

  def income1_used_for_mortgage?
    inc1mort == 1
  end

  def buyers_will_live_in?
    buylivein == 1
  end

  def buyers_will_not_live_in?
    buylivein == 2
  end

  def buyer_two_will_live_in_property?
    buy2livein == 1
  end

  def buyer_two_will_not_live_in_property?
    buy2livein == 2
  end

  def buyer_one_will_not_live_in_property?
    buy1livein == 2
  end

  def buyer_two_not_already_living_in_property?
    buy2living == 2
  end

  def income2_used_for_mortgage?
    inc2mort == 1
  end

  def right_to_buy?
    [9, 14, 27].include?(type)
  end

  def rent_to_buy_full_ownership?
    type == 29
  end

  def outright_sale_or_discounted_with_full_ownership?
    ownershipsch == 3 || (ownershipsch == 2 && rent_to_buy_full_ownership?)
  end

  def social_homebuy?
    type == 18
  end

  def ppostcode_full=(postcode)
    if postcode
      super UKPostcode.parse(postcode).to_s
    else
      super nil
    end
  end

  def previous_postcode_known?
    ppcodenk&.zero?
  end

  def postcode_known?
    pcodenk&.zero?
  end

  def postcode_full=(postcode)
    if postcode
      super UKPostcode.parse(postcode).to_s
    else
      super nil
    end
  end

  def expected_shared_ownership_deposit_value
    return unless value && equity

    value * equity / 100
  end

  def stairbought_part_of_value
    return unless value && stairbought

    value * stairbought / 100
  end

  def mortgage_deposit_and_discount_total
    mortgage_amount = mortgage || 0
    deposit_amount = deposit || 0
    cashdis_amount = cashdis || 0

    mortgage_amount + deposit_amount + cashdis_amount
  end

  def deposit_and_discount_total
    deposit_amount = deposit || 0
    cashdis_amount = cashdis || 0

    deposit_amount + cashdis_amount
  end

  def value_times_equity
    return unless value && equity

    value * equity / 100
  end

  def mortgage_deposit_and_discount_error_fields
    [
      "mortgage",
      "deposit",
      cashdis.present? ? "cash discount" : nil,
    ].compact.to_sentence
  end

  def mortgage_and_deposit_total
    return unless mortgage && deposit

    mortgage + deposit
  end

  def outright_sale?
    ownershipsch == 3
  end

  def discounted_ownership_sale?
    ownershipsch == 2
  end

  def mortgage_used?
    mortgageused == 1
  end

  def mortgage_not_used?
    mortgageused == 2
  end

  def mortgage_use_unknown?
    mortgageused == 3
  end

  def process_postcode_changes!
    self.postcode_full = upcase_and_remove_whitespace(postcode_full)
    return if postcode_full.blank?

    self.pcodenk = 0
    inferred_la = get_inferred_la(postcode_full)
    self.is_la_inferred = inferred_la.present?
    self.la = inferred_la if inferred_la.present?
  end

  def process_previous_postcode_changes!
    self.ppostcode_full = upcase_and_remove_whitespace(ppostcode_full)
    return if ppostcode_full.blank?

    self.ppcodenk = 0
    inferred_la = get_inferred_la(ppostcode_full)
    self.is_previous_la_inferred = inferred_la.present?
    self.prevloc = inferred_la if inferred_la.present?
  end

  def reset_assigned_to!
    return unless updated_by&.support?
    return if owning_organisation.blank? || managing_organisation.blank? || assigned_to.blank?
    return if assigned_to&.organisation == owning_organisation || assigned_to&.organisation == managing_organisation
    return if assigned_to&.organisation == owning_organisation.absorbing_organisation || assigned_to&.organisation == managing_organisation.absorbing_organisation

    update!(assigned_to: nil)
  end

  def joint_purchase?
    jointpur == 1
  end

  def not_joint_purchase?
    jointpur == 2
  end

  def buyer_has_seen_privacy_notice?
    privacynotice == 1
  end

  def buyer_not_interviewed?
    noint == 1
  end

  def old_persons_shared_ownership?
    type == 24
  end

  def is_bedsit?
    proptype == 2
  end

  def is_beds_inferred?
    form.start_year_2025_or_later? && is_bedsit?
  end

  def shared_ownership_scheme?
    ownershipsch == 1
  end

  def company_buyer?
    companybuy == 1
  end

  def no_monthly_leasehold_charges?
    has_mscharge&.zero?
  end

  def no_buyer_organisation?
    pregyrha&.zero? &&
      pregla&.zero? &&
      pregghb&.zero? &&
      pregother&.zero?
  end

  def buyers_age_for_old_persons_shared_ownership_invalid?
    return unless old_persons_shared_ownership?

    (joint_purchase? && ages_unknown_or_under_64?([1, 2])) || (not_joint_purchase? && ages_unknown_or_under_64?([1]))
  end

  def ages_unknown_or_under_64?(person_indexes)
    person_indexes.all? { |person_num| self["age#{person_num}"].present? && self["age#{person_num}"] < 64 || self["age#{person_num}_known"] == 1 }
  end

  def purchase_price_soft_min
    LaSaleRange.find_by(start_year: collection_start_year, la:, bedrooms: beds).soft_min
  end

  def purchase_price_soft_max
    LaSaleRange.find_by(start_year: collection_start_year, la:, bedrooms: beds).soft_max
  end

  def income_soft_min_for_ecstat(ecstat_field)
    economic_status_code = public_send(ecstat_field)

    return unless ALLOWED_INCOME_RANGES_SALES && ALLOWED_INCOME_RANGES_SALES[economic_status_code]

    soft_min = ALLOWED_INCOME_RANGES_SALES[economic_status_code].soft_min
    format_as_currency(soft_min)
  end

  def should_process_uprn_change?
    return unless uprn
    return unless saledate

    uprn_changed? || saledate_changed?
  end

  def should_process_address_change?
    return unless uprn_selection || select_best_address_match
    return unless saledate
    return unless form.start_year_2024_or_later?

    if select_best_address_match
      address_line1_input.present? && postcode_full_input.present?
    else
      uprn_selection_changed? || saledate_changed?
    end
  end

  def value_with_discount
    return if value.blank?

    discount_amount = discount ? value * discount / 100 : 0
    value - discount_amount
  end

  def mortgage_deposit_and_grant_total
    return if deposit.blank?

    grant_amount = grant || 0
    mortgage_amount = mortgage || 0
    mortgage_amount + deposit + grant_amount
  end

  def beds_for_la_sale_range
    beds.nil? ? nil : [beds, LaSaleRange::MAX_BEDS].min
  end

  def ownership_scheme(uppercase: false)
    ownership_scheme = case ownershipsch
                       when 1 then "shared ownership"
                       when 2 then "discounted ownership"
                       when 3 then "outright or other sale"
                       end
    uppercase ? ownership_scheme.capitalize : ownership_scheme
  end

  def combined_income
    buyer_1_income = income1 || 0
    buyer_2_income = income2 || 0

    buyer_1_income + buyer_2_income
  end

  def blank_compound_invalid_non_setup_fields!
    super

    self.pcodenk = nil if errors.attribute_names.include? :postcode_full
  end

  def duplicate_check_question_ids
    ["owning_organisation_id",
     "saledate",
     "purchid",
     "age1",
     "sex1",
     "ecstat1",
     uprn.blank? ? "postcode_full" : "uprn"].compact
  end

  def soctenant_is_inferred?
    form.start_year_2024_or_later?
  end

  def duplicates
    return SalesLog.none if duplicate_set_id.nil?

    SalesLog.where(duplicate_set_id:).where.not(id:)
  end

  def nationality2_uk_or_prefers_not_to_say?
    nationality_all_buyer2_group&.zero? || nationality_all_buyer2_group == 826
  end

  def is_staircase?
    staircase == 1
  end

  def discount_value
    return unless discount && value

    value * discount / 100
  end

  def is_not_staircasing?
    staircase == 2 || staircase == 3
  end

  def stairowned_100?
    stairowned == 100
  end

  def address_search_given?
    address_line1_input.present? && postcode_full_input.present?
  end

  def is_resale?
    resale == 1
  end

  def is_firststair?
    firststair == 1
  end

  def log_type
    "sales_log"
  end
end
