class Scheme < ApplicationRecord
  belongs_to :owning_organisation, class_name: "Organisation"
  has_many :locations, dependent: :delete_all
  has_many :lettings_logs, class_name: "LettingsLog", dependent: :delete_all
  has_many :scheme_deactivation_periods, class_name: "SchemeDeactivationPeriod"

  has_paper_trail

  scope :filter_by_id, ->(id) { where(id: (id.start_with?("S", "s") ? id[1..] : id)) }
  scope :search_by_service_name, ->(name) { where("service_name ILIKE ?", "%#{name}%") }
  scope :search_by_postcode, ->(postcode) { where("schemes.id IN (SELECT DISTINCT scheme_id FROM locations WHERE REPLACE(locations.postcode, ' ', '') ILIKE ?)", "%#{postcode.delete(' ')}%") }
  scope :search_by_location_name, ->(name) { where("schemes.id IN (SELECT DISTINCT scheme_id FROM locations WHERE locations.name ILIKE ?)", "%#{name}%") }
  scope :search_by, lambda { |param|
                      search_by_postcode(param)
                        .or(search_by_service_name(param))
                        .or(search_by_location_name(param))
                        .or(filter_by_id(param))
                    }

  scope :order_by_service_name, lambda {
    order("lower(service_name) ASC")
  }
  scope :filter_by_owning_organisation, ->(owning_organisation, _user = nil) { where(owning_organisation:) }
  scope :filter_by_status, lambda { |statuses, _user = nil|
    filtered_records = all
    scopes = []

    statuses.each do |status|
      status = status == "active" ? "active_status" : status
      if respond_to?(status, true)
        scopes << send(status)
      end
    end

    if scopes.any?
      filtered_records = filtered_records
      .left_outer_joins(:scheme_deactivation_periods)
      .joins(:owning_organisation)
      .merge(scopes.reduce(&:or))
    end

    filtered_records
  }

  scope :incomplete, lambda {
    where.not(confirmed: true)
         .or(where(confirmed: nil))
    .or(where.not(id: Location.select(:scheme_id).where(confirmed: true).distinct))
    .where.not(id: joins(:owning_organisation).deactivated_by_organisation.pluck(:id))
    .where.not(id: joins(:scheme_deactivation_periods).deactivated_directly.pluck(:id))
    .where.not(id: joins(:scheme_deactivation_periods).reactivating_soon.pluck(:id))
    .where.not(id: joins(:scheme_deactivation_periods).deactivating_soon.pluck(:id))
  }

  scope :deactivated, lambda {
    deactivated_by_organisation
      .or(deactivated_directly)
  }

  scope :deactivated_by_organisation, lambda { |date = Time.zone.now|
    merge(Organisation.filter_by_inactive.or(Organisation.where("merge_date <= ?", date)))
  }

  scope :deactivated_directly, lambda { |date = Time.zone.now|
    merge(SchemeDeactivationPeriod.deactivations_without_reactivation)
      .where("scheme_deactivation_periods.deactivation_date <= ?", date)
  }

  scope :deactivating_soon, lambda { |date = Time.zone.now|
    merge(SchemeDeactivationPeriod.deactivations_without_reactivation)
    .where("scheme_deactivation_periods.deactivation_date > ? AND scheme_deactivation_periods.deactivation_date < ? ", date, 6.months.from_now)
    .where.not(id: joins(:owning_organisation).deactivated_by_organisation.pluck(:id))
  }

  scope :reactivating_soon, lambda { |date = Time.zone.now|
    merge(SchemeDeactivationPeriod.deactivations_with_reactivation)
      .where.not("scheme_deactivation_periods.reactivation_date IS NULL")
      .where("scheme_deactivation_periods.reactivation_date > ?", date)
      .where("scheme_deactivation_periods.deactivation_date <= ?", date)
      .where.not(id: joins(:owning_organisation).deactivated_by_organisation.pluck(:id))
  }

  scope :activating_soon, lambda { |date = Time.zone.now|
    where("schemes.startdate > ?", date)
  }

  scope :active_status, lambda {
    where.not(id: joins(:scheme_deactivation_periods).reactivating_soon.pluck(:id))
    .where.not(id: incomplete.pluck(:id))
    .where.not(id: joins(:scheme_deactivation_periods).deactivating_soon.pluck(:id))
    .where.not(id: joins(:owning_organisation).deactivated_by_organisation.pluck(:id))
    .where.not(id: joins(:owning_organisation).joins(:scheme_deactivation_periods).deactivated_directly.pluck(:id))
    .where.not(id: activating_soon.pluck(:id))
  }

  scope :active, lambda { |date = Time.zone.now|
    where.not(id: joins(:scheme_deactivation_periods).reactivating_soon(date).pluck(:id))
    .where.not(id: incomplete.pluck(:id))
      .where.not(id: joins(:owning_organisation).deactivated_by_organisation(date).pluck(:id))
      .where.not(id: joins(:owning_organisation).joins(:scheme_deactivation_periods).deactivated_directly(date).pluck(:id))
      .where.not(id: activating_soon(date).pluck(:id))
  }

  scope :visible, -> { where(discarded_at: nil) }

  scope :duplicate_sets, lambda {
    scope = visible
    .group(*DUPLICATE_SCHEME_ATTRIBUTES)
    .where.not(scheme_type: nil)
    .where.not(registered_under_care_act: nil)
    .where.not(primary_client_group: nil)
    .where.not(has_other_client_group: nil)
    .where.not(secondary_client_group: nil).or(where(has_other_client_group: 0))
    .where.not(support_type: nil)
    .where.not(intended_stay: nil)
    .having(
      "COUNT(*) > 1",
    )
    scope.pluck("ARRAY_AGG(id)")
  }

  scope :duplicate_active_sets, lambda {
    scope = active
    .group(*DUPLICATE_SCHEME_ATTRIBUTES)
    .where.not(scheme_type: nil)
    .where.not(registered_under_care_act: nil)
    .where.not(primary_client_group: nil)
    .where.not(has_other_client_group: nil)
    .where.not(secondary_client_group: nil).or(where(has_other_client_group: 0))
    .where.not(support_type: nil)
    .where.not(intended_stay: nil)
    .having(
      "COUNT(*) > 1",
    )
    scope.pluck("ARRAY_AGG(id)")
  }

  validate :validate_confirmed
  validate :validate_owning_organisation

  auto_strip_attributes :service_name, squish: true

  SENSITIVE = {
    No: 0,
    Yes: 1,
  }.freeze

  enum :sensitive, SENSITIVE, suffix: true

  REGISTERED_UNDER_CARE_ACT = {
    "Yes – registered care home providing nursing care": 4,
    "Yes – registered care home providing personal care": 3,
    "Yes – part registered as a care home": 2,
    "No": 1,
  }.freeze

  enum :registered_under_care_act, REGISTERED_UNDER_CARE_ACT

  SCHEME_TYPE = {
    "Direct Access Hostel": 5,
    "Foyer": 4,
    "Housing for older people": 7,
    "Other Supported Housing": 6,
    "Missing": 0,
  }.freeze

  enum :scheme_type, SCHEME_TYPE, suffix: true

  SUPPORT_TYPE = {
    "Missing": 0,
    "Low level": 2,
    "Medium level": 3,
    "High level": 4,
    "Nursing care in a care home": 5,
    "Floating support": 6,
  }.freeze

  enum :support_type, SUPPORT_TYPE, suffix: true

  PRIMARY_CLIENT_GROUP = {
    "Homeless families with support needs": "O",
    "Offenders and people at risk of offending": "H",
    "Older people with support needs": "M",
    "People at risk of domestic violence": "L",
    "People with a physical or sensory disability": "A",
    "People with alcohol problems": "G",
    "People with drug problems": "F",
    "People with HIV or AIDS": "B",
    "People with learning disabilities": "D",
    "People with mental health problems": "E",
    "Refugees (permanent)": "I",
    "Rough sleepers": "S",
    "Single homeless people with support needs": "N",
    "Teenage parents": "R",
    "Young people at risk": "Q",
    "Young people leaving care": "P",
    "Missing": "X",
  }.freeze

  enum :primary_client_group, PRIMARY_CLIENT_GROUP, suffix: true
  enum :secondary_client_group, PRIMARY_CLIENT_GROUP, suffix: true

  INTENDED_STAY = {
    "Very short stay": "V",
    "Short stay": "S",
    "Medium stay": "M",
    "Permanent": "P",
    "Missing": "X",
  }.freeze

  HAS_OTHER_CLIENT_GROUP = {
    No: 0,
    Yes: 1,
  }.freeze

  enum :intended_stay, INTENDED_STAY, suffix: true
  enum :has_other_client_group, HAS_OTHER_CLIENT_GROUP, suffix: true

  ARRANGEMENT_TYPE = {
    "The same organisation that owns the housing stock": "D",
    "Another registered stock owner": "R",
    "A registered charity or voluntary organisation": "V",
    "Another organisation": "O",
    "Missing": "X",
  }.freeze

  DUPLICATE_SCHEME_ATTRIBUTES = %w[scheme_type registered_under_care_act primary_client_group secondary_client_group has_other_client_group support_type intended_stay].freeze

  enum :arrangement_type, ARRANGEMENT_TYPE, suffix: true

  def self.find_by_id_on_multiple_fields(scheme_id, location_id)
    return if scheme_id.nil?

    if scheme_id.start_with?("S")
      where(id: scheme_id[1..]).first
    elsif location_id.present?
      joins(:locations).where("ltrim(schemes.old_visible_id, '0') = ? AND ltrim(locations.old_visible_id, '0') = ?", scheme_id.to_i.to_s, location_id.to_i.to_s).first || where("ltrim(schemes.old_visible_id, '0') = ?", scheme_id.to_i.to_s).first
    else
      where("ltrim(old_visible_id, '0') = ?", scheme_id.to_i.to_s).first
    end
  end

  def id_to_display
    "S#{id}"
  end

  def check_details_attributes
    [
      { name: "Scheme code", value: id_to_display, id: "id" },
      { name: "Name", value: service_name, id: "service_name", edit: true },
      { name: "Status", value: status, id: "status" },
      { name: "Confidential information", value: sensitive, id: "sensitive", edit: true },
      { name: "Type of scheme", value: scheme_type, id: "scheme_type", edit: true },
      { name: "Registered under Care Standards Act 2000", value: registered_under_care_act, id: "registered_under_care_act", edit: true },
      { name: "Housing stock owned by", value: owning_organisation.name, id: "owning_organisation_id", edit: true },
      { name: "Support services provided by", value: arrangement_type, id: "arrangement_type", edit: true },
      { name: "Primary client group", value: primary_client_group, id: "primary_client_group", edit: true },
      { name: "Has another client group", value: has_other_client_group, id: "has_other_client_group", edit: true },
      { name: "Secondary client group", value: secondary_client_group, id: "secondary_client_group", edit: true },
      { name: "Level of support given", value: support_type, id: "support_type", edit: true },
      { name: "Intended length of stay", value: intended_stay, id: "intended_stay", edit: true },
    ]
  end

  def care_acts_options_with_hints
    hints = { "Yes – part registered as a care home": "A proportion of units are registered as being a care home." }

    Scheme.registered_under_care_acts.keys.map { |key, _| OpenStruct.new(id: key, name: key.to_s.humanize, description: hints[key.to_sym]) }
  end

  def support_level_options_with_hints
    hints = {
      "Low level": "Staff visiting once a week, fortnightly or less.",
      "Medium level": "Staff on site daily or making frequent visits with some out-of-hours cover.",
      "High level": "Intensive level of staffing provided on a 24-hour basis.",
    }
    Scheme.support_types.keys.excluding("Missing").excluding("Floating support").map { |key, _| OpenStruct.new(id: key, name: key.to_s.humanize, description: hints[key.to_sym]) }
  end

  def intended_length_of_stay_options_with_hints
    hints = {
      "Very short stay": "Up to one month.",
      "Short stay": "Up to one year.",
      "Medium stay": "More than one year but with an expectation to move on.",
      "Permanent": "Provides a home for life with no requirement for the tenant to move.",

    }
    Scheme.intended_stays.keys.excluding("Missing").map { |key, _| OpenStruct.new(id: key, name: key.to_s.humanize, description: hints[key.to_sym]) }
  end

  def validate_confirmed
    required_attributes = attribute_names - %w[id created_at updated_at old_id old_visible_id confirmed end_date sensitive secondary_client_group total_units deactivation_date deactivation_date_type startdate discarded_at]

    if confirmed == true
      required_attributes.any? do |attribute|
        if self[attribute].blank?
          errors.add attribute.to_sym
          self.confirmed = false
        end
      end
    end
  end

  def validate_owning_organisation
    unless owning_organisation&.holds_own_stock?
      errors.add(:owning_organisation_id, :does_not_own_stock, message: I18n.t("validations.scheme.owning_organisation.does_not_own_stock"))
    end
  end

  def available_from
    startdate || FormHandler.instance.earliest_open_collection_start_date(now: created_at)
  end

  def open_deactivation
    scheme_deactivation_periods.deactivations_without_reactivation.first
  end

  def last_deactivation_before(date)
    scheme_deactivation_periods.where("deactivation_date <= ?", date).order("created_at").last
  end

  def last_deactivation_date
    scheme_deactivation_periods.order(deactivation_date: :desc).first&.deactivation_date
  end

  def status
    @status ||= status_at(Time.zone.now)
  end

  def status_at(date)
    return :deleted if discarded_at.present?
    return :deactivated if owning_organisation.status_at(date) == :deactivated || owning_organisation.status_at(date) == :merged ||
      (open_deactivation&.deactivation_date.present? && date.beginning_of_day >= open_deactivation.deactivation_date.beginning_of_day)
    return :incomplete unless confirmed && locations.confirmed.any?
    return :deactivating_soon if open_deactivation&.deactivation_date.present? && date.beginning_of_day < open_deactivation.deactivation_date.beginning_of_day
    return :reactivating_soon if last_deactivation_before(date)&.reactivation_date.present? && date.beginning_of_day < last_deactivation_before(date).reactivation_date.beginning_of_day
    return :activating_soon if startdate.present? && date.beginning_of_day < startdate.beginning_of_day

    :active
  end

  def active?
    status == :active
  end

  def has_active_locations?
    locations.active.exists?
  end

  def has_active_locations_on_date?(date)
    return false unless date

    locations.active(date).exists?
  end

  def reactivating_soon?
    status == :reactivating_soon
  end

  def deactivated?
    status == :deactivated
  end

  def deactivating_soon?
    status == :deactivating_soon
  end

  def deactivates_in_a_long_time?
    status_at(6.months.from_now) == :deactivating_soon
  end

  def discard!
    update!(discarded_at: Time.zone.now)
    locations.each(&:discard!)
  end
end
