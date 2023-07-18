class Location < ApplicationRecord
  validates :postcode, on: :postcode, presence: { message: I18n.t("validations.location.postcode_blank") }
  validate :validate_postcode, on: :postcode, if: proc { |model| model.postcode.presence }
  validates :location_admin_district, on: :location_admin_district, presence: { message: I18n.t("validations.location_admin_district") }
  validates :units, on: :units, presence: { message: I18n.t("validations.location.units") }
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

  auto_strip_attributes :name

  scope :search_by_postcode, ->(postcode) { where("REPLACE(postcode, ' ', '') ILIKE ?", "%#{postcode.delete(' ')}%") }
  scope :search_by_name, ->(name) { where("name ILIKE ?", "%#{name}%") }
  scope :search_by, ->(param) { search_by_name(param).or(search_by_postcode(param)) }
  scope :started, -> { where("startdate <= ?", Time.zone.today).or(where(startdate: nil)) }
  scope :active, -> { where(confirmed: true).and(started) }
  scope :started_in_2_weeks, -> { where("startdate <= ?", Time.zone.today + 2.weeks).or(where(startdate: nil)) }
  scope :active_in_2_weeks, -> { where(confirmed: true).and(started_in_2_weeks) }
  scope :confirmed, -> { where(confirmed: true) }
  scope :unconfirmed, -> { where.not(confirmed: true) }
  scope :filter_by_status, ->(statuses, _user = nil) {
    filtered_records = all
    scopes = []
  
    statuses.each do |status|
      if respond_to?(status, true)
        status == "active" ? scopes << send("active_status") : scopes << send(status)
      end
    end
  
    filtered_records = filtered_records.left_outer_joins(:location_deactivation_periods).merge(scopes.reduce(&:or)) if scopes.any?
  
    filtered_records
  }
  
  scope :incomplete, -> {
      where(confirmed: false)
  }
  
  scope :deactivated, -> {
      merge(LocationDeactivationPeriod.deactivations_without_reactivation)
      .where("location_deactivation_periods.deactivation_date <= ?", Time.zone.now)
  }
  
  scope :deactivating_soon, -> {
      merge(LocationDeactivationPeriod.deactivations_without_reactivation)
      .where("location_deactivation_periods.deactivation_date > ?", Time.zone.now)
  }
  
  scope :reactivating_soon, -> {
      where.not("location_deactivation_periods.reactivation_date IS NULL")
      .order("location_deactivation_periods.created_at DESC")
      .where("location_deactivation_periods.reactivation_date > ?", Time.zone.now)
  }
  
  scope :activating_soon, -> {
    where("startdate > ?", Time.zone.now)
  }
  
  scope :active_status, -> {
      where.not(id: joins(:location_deactivation_periods).reactivating_soon.pluck(:id))
      .where.not(id: joins(:location_deactivation_periods).deactivated.pluck(:id))
      .where.not(id: incomplete.pluck(:id))
      .where.not(id: joins(:location_deactivation_periods).deactivating_soon.pluck(:id))
      .where.not(id: activating_soon.pluck(:id))
  }

  LOCAL_AUTHORITIES = LocalAuthority.all.map { |la| [la.name, la.code] }.to_h

  enum local_authorities: LOCAL_AUTHORITIES
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

  enum mobility_type: MOBILITY_TYPE

  TYPE_OF_UNIT = {
    "Bungalow": 6,
    "Self-contained flat or bedsit": 1,
    "Self-contained flat or bedsit with common facilities": 2,
    "Self-contained house": 7,
    "Shared flat": 3,
    "Shared house or hostel": 4,
  }.freeze

  enum type_of_unit: TYPE_OF_UNIT

  def self.find_by_id_on_multiple_fields(id)
    return if id.nil?

    where(id:).or(where(old_visible_id: id)).first
  end

  def postcode=(postcode)
    if postcode
      super UKPostcode.parse(postcode).to_s
    else
      super nil
    end
  end

  def available_from
    return startdate if startdate.present?

    FormHandler.instance.earliest_open_collection_start_date(now: created_at)
  end

  def open_deactivation
    location_deactivation_periods.deactivations_without_reactivation.first
  end

  def recent_deactivation
    location_deactivation_periods.order("created_at").last
  end

  def status
    @status ||= status_at(Time.zone.now)
  end

  def status_at(date)
    return :incomplete unless confirmed
    return :deactivated if open_deactivation&.deactivation_date.present? && date >= open_deactivation.deactivation_date
    return :deactivating_soon if open_deactivation&.deactivation_date.present? && date < open_deactivation.deactivation_date
    return :reactivating_soon if recent_deactivation&.reactivation_date.present? && date < recent_deactivation.reactivation_date
    return :activating_soon if startdate.present? && date < startdate

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

  def validate_postcode
    if !postcode&.match(POSTCODE_REGEXP)
      error_message = I18n.t("validations.postcode")
      errors.add :postcode, error_message
    else
      self.postcode = PostcodeService.clean(postcode)
      if postcode_changed?
        self.location_admin_district = nil
        self.location_code = nil
      end
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

private

  PIO = PostcodeService.new

  def lookup_postcode!
    result = PIO.lookup(postcode)
    if result
      self.location_code = result[:location_code]
      self.location_admin_district = result[:location_admin_district]
    end
  end
end
