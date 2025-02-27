class Location < ApplicationRecord
  validates :postcode, on: :postcode, presence: { message: I18n.t("validations.location.postcode_blank") }
  validate :validate_postcode, on: :postcode, if: proc { |model| model.postcode.presence }
  validates :location_admin_district, on: :location_admin_district, presence: { message: I18n.t("validations.location_admin_district") }
  validates :units, on: :units, presence: { message: I18n.t("validations.location.units.must_be_number") }
  validates :units, on: :units, numericality: { greater_than_or_equal_to: 1, message: I18n.t("validations.location.units.must_be_one_or_more") }
  validates :type_of_unit, on: :type_of_unit, presence: { message: I18n.t("validations.location.type_of_unit") }
  validates :mobility_type, on: :mobility_type, presence: { message: I18n.t("validations.location.mobility_standards") }
  validates :startdate, on: :startdate, presence: { message: I18n.t("validations.location.startdate_invalid") }
  validate :validate_startdate, on: :startdate, if: proc { |model| model.startdate.presence }
  validate :validate_confirmed
  belongs_to :scheme
  has_many :lettings_logs, class_name: "LettingsLog"
  has_many :location_deactivation_periods, class_name: "LocationDeactivationPeriod"

  has_paper_trail

  before_validation :lookup_postcode!, if: :postcode_changed?

  auto_strip_attributes :name, squish: true

  scope :search_by_postcode, ->(postcode) { where("REPLACE(locations.postcode, ' ', '') ILIKE ?", "%#{postcode.delete(' ')}%") }
  scope :search_by_name, ->(name) { where("locations.name ILIKE ?", "%#{name}%") }
  scope :search_by, ->(param) { search_by_name(param).or(search_by_postcode(param)) }
  scope :started, -> { where("locations.startdate <= ?", Time.zone.today).or(where(startdate: nil)) }
  scope :started_in_2_weeks, -> { where("locations.startdate <= ?", Time.zone.today + 2.weeks).or(where(startdate: nil)) }
  scope :active_in_2_weeks, -> { where(confirmed: true).and(started_in_2_weeks) }
  scope :confirmed, -> { where(confirmed: true) }
  scope :unconfirmed, -> { where.not(confirmed: true) }
  scope :filter_by_status, lambda { |statuses, _user = nil|
    filtered_records = all
    scopes = []

    statuses.each do |status|
      if respond_to?(status, true)
        scopes << (status == "active" ? send("active_status") : send(status))
      end
    end

    if scopes.any?
      filtered_records = filtered_records
      .left_outer_joins(:location_deactivation_periods)
      .joins(scheme: [:owning_organisation])
      .left_outer_joins(scheme: :scheme_deactivation_periods)
      .order("location_deactivation_periods.created_at DESC")
      .merge(scopes.reduce(&:or))
    end

    filtered_records
  }

  scope :incomplete, lambda {
    where.not(confirmed: true)
      .or(where(confirmed: nil))
  }

  scope :deactivated, lambda { |date = Time.zone.now|
    deactivated_by_organisation(date)
      .or(deactivated_directly(date))
      .or(deactivated_by_scheme(date))
  }

  scope :deactivated_by_organisation, lambda { |date = Time.zone.now|
    merge(Organisation.filter_by_inactive.or(Organisation.where("merge_date <= ?", date)))
  }

  scope :deactivated_by_scheme, lambda { |date = Time.zone.now|
    merge(Scheme.deactivated_directly(date))
  }

  scope :deactivated_directly, lambda { |date = Time.zone.now|
    merge(LocationDeactivationPeriod.deactivations_without_reactivation)
      .where("location_deactivation_periods.deactivation_date <= ?", date)
  }

  scope :deactivating_soon_directly, lambda { |date = Time.zone.now|
    merge(LocationDeactivationPeriod.deactivations_without_reactivation)
      .where("location_deactivation_periods.deactivation_date > ?", date)
  }

  scope :deactivating_soon, lambda { |date = Time.zone.now|
    deactivating_soon_directly
      .or(deactivating_soon_by_scheme(date))
  }

  scope :deactivating_soon_by_scheme, lambda { |date = Time.zone.now|
    merge(Scheme.deactivating_soon(date))
  }

  scope :reactivating_soon, lambda { |date = Time.zone.now|
    where.not("location_deactivation_periods.reactivation_date IS NULL")
         .where("location_deactivation_periods.reactivation_date > ?", date)
         .where.not(id: joins(scheme: [:owning_organisation]).deactivated_by_organisation.pluck(:id))
  }

  scope :reactivating_soon_by_scheme, lambda { |date = Time.zone.now|
    merge(Scheme.reactivating_soon(date))
  }

  scope :activating_soon, lambda { |date = Time.zone.now|
    where("locations.startdate > ?", date)
  }

  scope :active_status, lambda {
    where.not(id: joins(:location_deactivation_periods).reactivating_soon.pluck(:id))
         .where.not(id: joins(scheme: [:scheme_deactivation_periods]).reactivating_soon_by_scheme.pluck(:id))
         .where.not(id: joins(:location_deactivation_periods).merge(Location.deactivated_directly).pluck(:id))
         .where.not(id: joins(scheme: [:scheme_deactivation_periods]).merge(Location.deactivated_by_scheme).pluck(:id))
         .where.not(id: joins(scheme: [:owning_organisation]).merge(Location.deactivated_by_organisation).pluck(:id))
         .where.not(id: incomplete.pluck(:id))
         .where.not(id: joins(:location_deactivation_periods).merge(Location.deactivating_soon_directly).pluck(:id))
         .where.not(id: joins(scheme: %i[owning_organisation scheme_deactivation_periods]).merge(Location.deactivating_soon_by_scheme).pluck(:id))
         .where.not(id: activating_soon.pluck(:id))
  }

  scope :active, lambda { |date = Time.zone.now|
    where.not(id: joins(:location_deactivation_periods).merge(Location.deactivated_directly(date)).pluck(:id))
          .where.not(id: incomplete.pluck(:id))
         .where.not(id: activating_soon(date).pluck(:id))
         .where(scheme: Scheme.active(date))
  }

  scope :visible, -> { where(discarded_at: nil) }

  scope :duplicate_sets, lambda {
    scope = visible
    .group(*DUPLICATE_LOCATION_ATTRIBUTES)
    .where.not(scheme_id: nil)
    .where.not(postcode: nil)
    .where.not(mobility_type: nil)
    .having(
      "COUNT(*) > 1",
    )
    scope.pluck("ARRAY_AGG(id)")
  }

  scope :duplicate_sets_within_given_schemes, lambda {
    scope = visible
    .group(*DUPLICATE_LOCATION_ATTRIBUTES - %w[scheme_id])
    .where.not(postcode: nil)
    .where.not(mobility_type: nil)
    .having(
      "COUNT(*) > 1",
    )
    scope.pluck("ARRAY_AGG(id)")
  }

  scope :duplicate_active_sets, lambda {
    scope = active
    .group(*DUPLICATE_LOCATION_ATTRIBUTES)
    .where.not(scheme_id: nil)
    .where.not(postcode: nil)
    .where.not(mobility_type: nil)
    .having(
      "COUNT(*) > 1",
    )
    scope.pluck("ARRAY_AGG(id)")
  }

  scope :duplicate_active_sets_within_given_schemes, lambda {
    scope = active
    .group(*DUPLICATE_LOCATION_ATTRIBUTES - %w[scheme_id])
    .where.not(postcode: nil)
    .where.not(mobility_type: nil)
    .having(
      "COUNT(*) > 1",
    )
    scope.pluck("ARRAY_AGG(id)")
  }

  DUPLICATE_LOCATION_ATTRIBUTES = %w[scheme_id postcode mobility_type].freeze
  LOCAL_AUTHORITIES = LocalAuthority.all.map { |la| [la.name, la.code] }.to_h

  attribute :local_authorities, :string
  enum :local_authorities, LOCAL_AUTHORITIES
  def self.local_authorities_for_current_year
    LocalAuthority.all.active(Time.zone.today).england.map { |la| [la.code, la.name] }.to_h
  end

  MOBILITY_TYPE = {
    "Wheelchair-user standard": "W",
    "Fitted with equipment and adaptations": "A",
    "Property designed to accessible general standard": "M",
    "None": "N",
    "Missing": "X",
  }.freeze

  enum :mobility_type, MOBILITY_TYPE

  TYPE_OF_UNIT = {
    "Bungalow": 6,
    "Self-contained flat or bedsit": 1,
    "Self-contained flat or bedsit with common facilities": 2,
    "Self-contained house": 7,
    "Shared flat": 3,
    "Shared house or hostel": 4,
  }.freeze

  enum :type_of_unit, TYPE_OF_UNIT

  def self.find_by_id_on_multiple_fields(id)
    return if id.nil?

    where(id:).or(where("ltrim(old_visible_id, '0') = ?", id.to_i.to_s)).first
  end

  def postcode=(postcode)
    if postcode
      super UKPostcode.parse(postcode).to_s
    else
      super nil
    end
  end

  def available_from
    startdate || FormHandler.instance.earliest_open_collection_start_date(now: created_at)
  end

  def open_deactivation
    location_deactivation_periods.deactivations_without_reactivation.first
  end

  def last_deactivation_before(date)
    location_deactivation_periods.where("deactivation_date <= ?", date).order("created_at").last
  end

  def status
    @status ||= status_at(Time.zone.now)
  end

  def status_at(date)
    return :deleted if discarded_at.present?
    return :incomplete unless confirmed
    return :deactivated if scheme.owning_organisation.status_at(date) == :deactivated || scheme.owning_organisation.status_at(date) == :merged ||
      open_deactivation&.deactivation_date.present? && date.beginning_of_day >= open_deactivation.deactivation_date.beginning_of_day || scheme.status_at(date) == :deactivated
    return :deactivating_soon if open_deactivation&.deactivation_date.present? && date.beginning_of_day < open_deactivation.deactivation_date.beginning_of_day || scheme.status_at(date) == :deactivating_soon
    return :activating_soon if startdate.present? && date.beginning_of_day < startdate.beginning_of_day
    return :reactivating_soon if last_deactivation_before(date)&.reactivation_date.present? && date.beginning_of_day < last_deactivation_before(date).reactivation_date.beginning_of_day || scheme.status_at(date) == :reactivating_soon

    :active
  end

  def active?
    status == :active
  end

  def deactivated?
    status == :deactivated
  end

  def reactivating_soon?
    status == :reactivating_soon
  end

  def deactivates_in_a_long_time?
    status_at(6.months.from_now) == :deactivating_soon
  end

  def deactivated_by_scheme?
    status == :deactivated && scheme.status == :deactivated
  end

  def deactivating_soon_by_scheme?
    status == :deactivating_soon && scheme.status == :deactivating_soon
  end

  def reactivating_soon_by_scheme?
    status == :reactivating_soon && scheme.status == :reactivating_soon
  end

  def validate_postcode
    if !postcode&.match(POSTCODE_REGEXP)
      error_message = I18n.t("validations.postcode")
      errors.add :postcode, error_message
    else
      self.postcode = PostcodeService.clean(postcode)
    end
  end

  def validate_startdate
    unless startdate.between?(scheme.available_from, Time.zone.local(2200, 1, 1))
      error_message = I18n.t("validations.location.startdate_out_of_range", date: scheme.available_from.to_formatted_s(:govuk_date))
      errors.add :startdate, error_message
    end
  end

  def validate_confirmed
    self.confirmed = [postcode, location_admin_district, location_code, units, type_of_unit, mobility_type].all?(&:present?)
  end

  def linked_local_authorities
    la = LocalAuthority.find_by(code: location_code)
    return LocalAuthority.none unless la

    LocalAuthority.where(id: [la.id] + la.linked_local_authority_ids)
  end

  def discard!
    update!(discarded_at: Time.zone.now)
  end

private

  PIO = PostcodeService.new

  def lookup_postcode!
    result = PIO.lookup(postcode)
    unless location_admin_district_changed?
      self.location_admin_district = nil
      self.location_code = nil
      self.is_la_inferred = false
    end
    if result
      self.location_code = result[:location_code]
      self.location_admin_district = result[:location_admin_district]
      self.is_la_inferred = true
    else
      self.is_la_inferred = false
    end
  end
end
