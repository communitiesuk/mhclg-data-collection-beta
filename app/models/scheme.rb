class Scheme < ApplicationRecord
  belongs_to :owning_organisation, class_name: "Organisation"
  belongs_to :managing_organisation, optional: true, class_name: "Organisation"
  has_many :locations
  has_many :case_logs

  scope :filter_by_id, ->(id) { where(id: (id.start_with?("S") ? id[1..] : id)) }
  scope :search_by_service_name, ->(name) { where("service_name ILIKE ?", "%#{name}%") }
  scope :search_by_postcode, ->(postcode) { joins(:locations).where("locations.postcode ILIKE ?", "%#{postcode.delete(' ')}%") }
  scope :search_by, ->(param) { search_by_postcode(param).or(search_by_service_name(param)).or(filter_by_id(param)).distinct }

  SENSITIVE = {
    No: 0,
    Yes: 1,
  }.freeze

  enum sensitive: SENSITIVE, _suffix: true

  REGISTERED_UNDER_CARE_ACT = {
    "Yes – registered care home providing nursing care": 4,
    "Yes – registered care home providing personal care": 3,
    "Yes – part registered as a care home": 2,
    "No": 1,
  }.freeze

  enum registered_under_care_act: REGISTERED_UNDER_CARE_ACT

  SCHEME_TYPE = {
    "Direct Access Hostel": 5,
    "Foyer": 4,
    "Housing for older people": 7,
    "Other Supported Housing": 6,
    "Missing": 0,
  }.freeze

  enum scheme_type: SCHEME_TYPE, _suffix: true

  SUPPORT_TYPE = {
    "Missing": 0,
    "Resettlement support": 1,
    "Low levels of support": 2,
    "Medium levels of support": 3,
    "High levels of care and support": 4,
    "Nursing care services to a care home": 5,
    "Floating Support": 6,
  }.freeze

  enum support_type: SUPPORT_TYPE, _suffix: true

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

  enum primary_client_group: PRIMARY_CLIENT_GROUP, _suffix: true
  enum secondary_client_group: PRIMARY_CLIENT_GROUP, _suffix: true

  INTENDED_STAY = {
    "Medium stay": "M",
    "Permanent": "P",
    "Short stay": "S",
    "Very short stay": "V",
    "Missing": "X",
  }.freeze

  HAS_OTHER_CLIENT_GROUP = {
    No: 0,
    Yes: 1,
  }.freeze

  enum intended_stay: INTENDED_STAY, _suffix: true
  enum has_other_client_group: HAS_OTHER_CLIENT_GROUP, _suffix: true

  SUPPORT_SERVICES_PROVIDER = {
    "The same organisation that owns the housing stock": 0,
    "Another registered housing provider": 1,
    "A registered charity or voluntary organisation": 2,
    "Another organisation": 3,
  }.freeze

  enum support_services_provider: SUPPORT_SERVICES_PROVIDER

  def id_to_display
    "S#{id}"
  end

  def check_details_attributes
    [
      { name: "Service code", value: id_to_display },
      { name: "Name", value: service_name },
      { name: "Confidential information", value: sensitive },
      { name: "Housing stock owned by", value: owning_organisation.name },
      { name: "Managed by", value: managing_organisation&.name },
      { name: "Type of scheme", value: scheme_type },
      { name: "Registered under Care Standards Act 2000", value: registered_under_care_act },
    ]
  end

  def check_primary_client_attributes
    [
      { name: "Primary client group", value: primary_client_group },
    ]
  end

  def check_secondary_client_confirmation_attributes
    [
      { name: "Has another client group", value: has_other_client_group },
    ]
  end

  def check_secondary_client_attributes
    [
      { name: "Secondary client group", value: secondary_client_group },
    ]
  end

  def check_support_attributes
    [
      { name: "Level of support given", value: support_type },
      { name: "Intended length of stay", value: intended_stay },
    ]
  end

  def display_attributes
    [
      { name: "Scheme code", value: id_to_display },
      { name: "Name", value: service_name, edit: true },
      { name: "Confidential information", value: sensitive, edit: true },
      { name: "Type of scheme", value: scheme_type },
      { name: "Registered under Care Standards Act 2000", value: registered_under_care_act },
      { name: "Housing stock owned by", value: owning_organisation.name, edit: true },
      { name: "Support services provided by", value: support_services_provider },
      { name: "Organisation providing support", value: managing_organisation&.name },
      { name: "Primary client group", value: primary_client_group },
      { name: "Has another client group", value: has_other_client_group },
      { name: "Secondary client group", value: secondary_client_group },
      { name: "Level of support given", value: support_type },
      { name: "Intended length of stay", value: intended_stay },
    ]
  end

  def synonyms
    locations.map(&:postcode).join(",")
  end

  def appended_text
    "(#{locations.count { |location| location.startdate.blank? || location.startdate <= Time.zone.today }} locations)"
  end

  def hint
    [primary_client_group, secondary_client_group].filter(&:present?).join(", ")
  end

  def care_acts_options_with_hints
    hints = { "Yes – part registered as a care home": "A proportion of units are registered as being a care home." }

    Scheme.registered_under_care_acts.keys.map { |key, _| OpenStruct.new(id: key, name: key.to_s.humanize, description: hints[key.to_sym]) }
  end
end
