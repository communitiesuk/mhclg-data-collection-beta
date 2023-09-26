class BulkUpload::Lettings::Year2022::RowParser
  include ActiveModel::Model
  include ActiveModel::Attributes
  include InterruptionScreenHelper

  QUESTIONS = {
    field_1: "What is the letting type?",
    field_2: "This question has been removed",
    field_3: "This question has been removed",
    field_4: "Management group code",
    field_5: "Scheme code",
    field_6: "This question has been removed",
    field_7: "What is the tenant code?",
    field_8: "Is this a starter tenancy?",
    field_9: "What is the tenancy type?",
    field_10: "If 'Other', what is the tenancy type?",
    field_11: "What is the length of the fixed-term tenancy to the nearest year?",
    field_12: "Age of person 1",
    field_13: "Age of person 2",
    field_14: "Age of person 3",
    field_15: "Age of person 4",
    field_16: "Age of person 5",
    field_17: "Age of person 6",
    field_18: "Age of person 7",
    field_19: "Age of person 8",
    field_20: "Gender identity of person 1",
    field_21: "Gender identity of person 2",
    field_22: "Gender identity of person 3",
    field_23: "Gender identity of person 4",
    field_24: "Gender identity of person 5",
    field_25: "Gender identity of person 6",
    field_26: "Gender identity of person 7",
    field_27: "Gender identity of person 8",
    field_28: "Relationship to person 1 for person 2",
    field_29: "Relationship to person 1 for person 3",
    field_30: "Relationship to person 1 for person 4",
    field_31: "Relationship to person 1 for person 5",
    field_32: "Relationship to person 1 for person 6",
    field_33: "Relationship to person 1 for person 7",
    field_34: "Relationship to person 1 for person 8",
    field_35: "Working situation of person 1",
    field_36: "Working situation of person 2",
    field_37: "Working situation of person 3",
    field_38: "Working situation of person 4",
    field_39: "Working situation of person 5",
    field_40: "Working situation of person 6",
    field_41: "Working situation of person 7",
    field_42: "Working situation of person 8",
    field_43: "What is the lead tenant's ethnic group?",
    field_44: "What is the lead tenant's nationality?",
    field_45: "Does anybody in the household have links to the UK armed forces?",
    field_46: "Was the person seriously injured or ill as a result of serving in the UK armed forces?",
    field_47: "Is anybody in the household pregnant?",
    field_48: "Is the tenant likely to be receiving benefits related to housing?",
    field_49: "How much of the household's income is from Universal Credit, state pensions or benefits?",
    field_50: "How much income does the household have in total?",
    field_51: "Do you know the household's income?",
    field_52: "What is the tenant's main reason for the household leaving their last settled home?",
    field_53: "If 'Other', what was the main reason for leaving their last settled home?",
    field_54: "This question has been removed",
    field_55: "Does anybody in the household have any disabled access needs?",
    field_56: "Does anybody in the household have any disabled access needs?",
    field_57: "Does anybody in the household have any disabled access needs?",
    field_58: "Does anybody in the household have any disabled access needs?",
    field_59: "Does anybody in the household have any disabled access needs?",
    field_60: "Does anybody in the household have any disabled access needs?",
    field_61: "Where was the household immediately before this letting?",
    field_62: "What is the local authority of the household's last settled home?",
    field_63: "Part 1 of postcode of last settled home",
    field_64: "Part 2 of postcode of last settled home",
    field_65: "Do you know the postcode of last settled home?",
    field_66: "How long has the household continuously lived in the local authority area of the new letting?",
    field_67: "How long has the household been on the waiting list for the new letting?",
    field_68: "Was the tenant homeless directly before this tenancy?",
    field_69: "Was the household given 'reasonable preference' by the local authority?",
    field_70: "Reasonable preference. They were homeless or about to lose their home (within 56 days)",
    field_71: "Reasonable preference. They were living in insanitary, overcrowded or unsatisfactory housing",
    field_72: "Reasonable preference. They needed to move on medical and welfare grounds (including a disability)",
    field_73: "Reasonable preference. They needed to move to avoid hardship to themselves or others",
    field_74: "Reasonable preference. Don't know",
    field_75: "Was the letting made under any of the following allocations systems?",
    field_76: "Was the letting made under any of the following allocations systems?",
    field_77: "Was the letting made under any of the following allocations systems?",
    field_78: "What was the source of referral for this letting?",
    field_79: "How often does the household pay rent and other charges?",
    field_80: "What is the basic rent?",
    field_81: "What is the service charge?",
    field_82: "What is the personal service charge?",
    field_83: "What is the support charge?",
    field_84: "Total Charge",
    field_85: "If this is a care home, how much does the household pay every [time period]?",
    field_86: "Does the household pay rent or other charges for the accommodation?",
    field_87: "After the household has received any housing-related benefits, will they still need to pay basic rent and other charges?",
    field_88: "What do you expect the outstanding amount to be?",
    field_89: "What is the void date?",
    field_90: "What is the void date?",
    field_91: "What is the void date?",
    field_92: "What date were major repairs completed on?",
    field_93: "What date were major repairs completed on?",
    field_94: "What date were major repairs completed on?",
    field_95: "This question has been removed",
    field_96: "What date did the tenancy start?",
    field_97: "What date did the tenancy start?",
    field_98: "What date did the tenancy start?",
    field_99: "Since becoming available, how many times has the property been previously offered?",
    field_100: "What is the property reference?",
    field_101: "How many bedrooms does the property have?",
    field_102: "What type of unit is the property?",
    field_103: "Which type of building is the property?",
    field_104: "Is the property built or adapted to wheelchair-user standards?",
    field_105: "What type was the property most recently let as?",
    field_106: "What is the reason for the property being vacant?",
    field_107: "What is the local authority of the property?",
    field_108: "Part 1 of postcode of the property",
    field_109: "Part 2 of postcode of the property",
    field_110: "This question has been removed",
    field_111: "Which organisation owns this property?",
    field_112: "Username field",
    field_113: "Which organisation manages this property?",
    field_114: "Is the person still serving in the UK armed forces?",
    field_115: "This question has been removed",
    field_116: "How often does the household receive income?",
    field_117: "Is this letting sheltered accommodation?",
    field_118: "Does anybody in the household have a physical or mental health condition (or other illness) expected to last for 12 months or more?",
    field_119: "Vision, for example blindness or partial sight",
    field_120: "Hearing, for example deafness or partial hearing",
    field_121: "Mobility, for example walking short distances or climbing stairs",
    field_122: "Dexterity, for example lifting and carrying objects, using a keyboard",
    field_123: "Learning or understanding or concentrating",
    field_124: "Memory",
    field_125: "Mental health",
    field_126: "Stamina or breathing or fatigue",
    field_127: "Socially or behaviourally, for example  associated with autism spectral disorder (ASD) which include Aspergers' or attention deficit hyperactivity disorder (ADHD)",
    field_128: "Other",
    field_129: "Is this letting a London Affordable Rent letting?",
    field_130: "Which type of Intermediate Rent is this letting?",
    field_131: "Which 'Other' type of Intermediate Rent is this letting?",
    field_132: "Data Protection",
    field_133: "Is this a joint tenancy?",
    field_134: "Is this letting a renewal?",
  }.freeze

  attribute :bulk_upload
  attribute :block_log_creation, :boolean, default: -> { false }

  attribute :field_blank

  attribute :field_1, :integer
  attribute :field_2
  attribute :field_3
  attribute :field_4, :string
  attribute :field_5, :integer
  attribute :field_6
  attribute :field_7, :string
  attribute :field_8, :integer
  attribute :field_9, :integer
  attribute :field_10, :string
  attribute :field_11, :integer
  attribute :field_12, :string
  attribute :field_13, :string
  attribute :field_14, :string
  attribute :field_15, :string
  attribute :field_16, :string
  attribute :field_17, :string
  attribute :field_18, :string
  attribute :field_19, :string
  attribute :field_20, :string
  attribute :field_21, :string
  attribute :field_22, :string
  attribute :field_23, :string
  attribute :field_24, :string
  attribute :field_25, :string
  attribute :field_26, :string
  attribute :field_27, :string
  attribute :field_28, :string
  attribute :field_29, :string
  attribute :field_30, :string
  attribute :field_31, :string
  attribute :field_32, :string
  attribute :field_33, :string
  attribute :field_34, :string
  attribute :field_35, :integer
  attribute :field_36, :integer
  attribute :field_37, :integer
  attribute :field_38, :integer
  attribute :field_39, :integer
  attribute :field_40, :integer
  attribute :field_41, :integer
  attribute :field_42, :integer
  attribute :field_43, :integer
  attribute :field_44, :integer
  attribute :field_45, :integer
  attribute :field_46, :integer
  attribute :field_47, :integer
  attribute :field_48, :integer
  attribute :field_49, :integer
  attribute :field_50, :decimal
  attribute :field_51, :integer
  attribute :field_52, :integer
  attribute :field_53, :string
  attribute :field_54
  attribute :field_55, :integer
  attribute :field_56, :integer
  attribute :field_57, :integer
  attribute :field_58, :integer
  attribute :field_59, :integer
  attribute :field_60, :integer
  attribute :field_61, :integer
  attribute :field_62, :string
  attribute :field_63, :string
  attribute :field_64, :string
  attribute :field_65, :integer
  attribute :field_66, :integer
  attribute :field_67, :integer
  attribute :field_68, :integer
  attribute :field_69, :integer
  attribute :field_70, :integer
  attribute :field_71, :integer
  attribute :field_72, :integer
  attribute :field_73, :integer
  attribute :field_74, :integer
  attribute :field_75, :integer
  attribute :field_76, :integer
  attribute :field_77, :integer
  attribute :field_78, :integer
  attribute :field_79, :integer
  attribute :field_80, :decimal
  attribute :field_81, :decimal
  attribute :field_82, :decimal
  attribute :field_83, :decimal
  attribute :field_84, :decimal
  attribute :field_85, :decimal
  attribute :field_86, :integer
  attribute :field_87, :integer
  attribute :field_88, :decimal
  attribute :field_89, :integer
  attribute :field_90, :integer
  attribute :field_91, :integer
  attribute :field_92, :integer
  attribute :field_93, :integer
  attribute :field_94, :integer
  attribute :field_95
  attribute :field_96, :integer
  attribute :field_97, :integer
  attribute :field_98, :integer
  attribute :field_99, :integer
  attribute :field_100, :string
  attribute :field_101, :integer
  attribute :field_102, :integer
  attribute :field_103, :integer
  attribute :field_104, :integer
  attribute :field_105, :integer
  attribute :field_106, :integer
  attribute :field_107, :string
  attribute :field_108, :string
  attribute :field_109, :string
  attribute :field_110
  attribute :field_111, :string
  attribute :field_112, :string
  attribute :field_113, :string
  attribute :field_114, :integer
  attribute :field_115
  attribute :field_116, :integer
  attribute :field_117, :integer
  attribute :field_118, :integer
  attribute :field_119, :integer
  attribute :field_120, :integer
  attribute :field_121, :integer
  attribute :field_122, :integer
  attribute :field_123, :integer
  attribute :field_124, :integer
  attribute :field_125, :integer
  attribute :field_126, :integer
  attribute :field_127, :integer
  attribute :field_128, :integer
  attribute :field_129, :integer
  attribute :field_130, :integer
  attribute :field_131, :string
  attribute :field_132, :integer
  attribute :field_133, :integer
  attribute :field_134, :integer

  validate :validate_valid_radio_option, on: :before_log

  validates :field_1,
            presence: {
              message: I18n.t("validations.not_answered", question: "letting type"),
              category: :setup,
            },
            inclusion: {
              in: (1..12).to_a,
              message: I18n.t("validations.invalid_option", question: "letting type"),
              category: :setup,
              unless: -> { field_1.blank? },
            },
            on: :after_log

  validates :field_12, format: { with: /\A\d{1,3}\z|\AR\z/, message: "Age of person 1 must be a number or the letter R" }, on: :after_log
  validates :field_13, format: { with: /\A\d{1,3}\z|\AR\z/, message: "Age of person 2 must be a number or the letter R" }, allow_blank: true, on: :after_log
  validates :field_14, format: { with: /\A\d{1,3}\z|\AR\z/, message: "Age of person 3 must be a number or the letter R" }, allow_blank: true, on: :after_log
  validates :field_15, format: { with: /\A\d{1,3}\z|\AR\z/, message: "Age of person 4 must be a number or the letter R" }, allow_blank: true, on: :after_log
  validates :field_16, format: { with: /\A\d{1,3}\z|\AR\z/, message: "Age of person 5 must be a number or the letter R" }, allow_blank: true, on: :after_log
  validates :field_17, format: { with: /\A\d{1,3}\z|\AR\z/, message: "Age of person 6 must be a number or the letter R" }, allow_blank: true, on: :after_log
  validates :field_18, format: { with: /\A\d{1,3}\z|\AR\z/, message: "Age of person 7 must be a number or the letter R" }, allow_blank: true, on: :after_log
  validates :field_19, format: { with: /\A\d{1,3}\z|\AR\z/, message: "Age of person 8 must be a number or the letter R" }, allow_blank: true, on: :after_log

  validates :field_96,
            presence: {
              message: I18n.t("validations.not_answered", question: "tenancy start date (day)"),
              category: :setup,
            }, on: :after_log

  validates :field_97,
            presence: {
              message: I18n.t("validations.not_answered", question: "tenancy start date (month)"),
              category: :setup,
            },
            on: :after_log

  validates :field_98,
            presence: {
              message: I18n.t("validations.not_answered", question: "tenancy start date (year)"),
              category: :setup,
            },
            format: {
              with: /\A\d{2}\z/,
              message: I18n.t("validations.setup.startdate.year_not_two_digits"),
              unless: -> { field_98.blank? },
              category: :setup,
            },
            on: :after_log

  validate :validate_data_types, on: :after_log
  validate :validate_relevant_collection_window, on: :after_log
  validate :validate_la_with_local_housing_referral, on: :after_log
  validate :validate_cannot_be_la_referral_if_general_needs_and_la, on: :after_log
  validate :validate_leaving_reason_for_renewal, on: :after_log
  validate :validate_lettings_type_matches_bulk_upload, on: :after_log
  validate :validate_only_one_housing_needs_type, on: :after_log
  validate :validate_no_disabled_needs_conjunction, on: :after_log
  validate :validate_dont_know_disabled_needs_conjunction, on: :after_log
  validate :validate_no_and_dont_know_disabled_needs_conjunction, on: :after_log
  validate :validate_no_housing_needs_questions_answered, on: :after_log
  validate :validate_reasonable_preference_homeless, on: :after_log
  validate :validate_condition_effects, on: :after_log
  validate :validate_if_log_already_exists, on: :after_log, if: -> { FeatureToggle.bulk_upload_duplicate_log_check_enabled? }

  validate :validate_owning_org_data_given, on: :after_log
  validate :validate_owning_org_exists, on: :after_log
  validate :validate_owning_org_owns_stock, on: :after_log
  validate :validate_owning_org_permitted, on: :after_log

  validate :validate_managing_org_data_given, on: :after_log
  validate :validate_managing_org_exists, on: :after_log
  validate :validate_managing_org_related, on: :after_log

  validate :validate_scheme_related, on: :after_log
  validate :validate_scheme_exists, on: :after_log
  validate :validate_scheme_data_given, on: :after_log

  validate :validate_location_related, on: :after_log
  validate :validate_location_exists, on: :after_log
  validate :validate_location_data_given, on: :after_log

  validate :validate_created_by_exists, on: :after_log
  validate :validate_created_by_related, on: :after_log
  validate :validate_rent_type, on: :after_log

  validate :validate_declaration_acceptance, on: :after_log

  validate :validate_incomplete_soft_validations, on: :after_log

  validate :validate_nulls, on: :after_log

  def self.question_for_field(field)
    QUESTIONS[field]
  end

  def valid?
    return @valid if @valid

    errors.clear

    return @valid = true if blank_row?

    super(:before_log)
    before_errors = errors.dup

    log.valid?

    super(:after_log)
    errors.merge!(before_errors)

    log.errors.each do |error|
      fields = field_mapping_for_errors[error.attribute] || []

      fields.each do |field|
        unless errors.include?(field)
          errors.add(field, error.message)
        end
      end
    end

    @valid = errors.blank?
  end

  def blank_row?
    attribute_set
      .to_hash
      .reject { |k, _| %w[bulk_upload block_log_creation field_blank].include?(k) }
      .values
      .reject(&:blank?)
      .compact
      .empty?
  end

  def log
    @log ||= LettingsLog.new(attributes_for_log)
  end

  def block_log_creation!
    self.block_log_creation = true
  end

  def block_log_creation?
    block_log_creation
  end

  def tenant_code
    field_7
  end

  def property_ref
    field_100
  end

  def log_already_exists?
    @log_already_exists ||= LettingsLog
      .where(status: %w[not_started in_progress completed])
      .exists?(duplicate_check_fields.index_with { |field| log.public_send(field) })
  end

  def spreadsheet_duplicate_hash
    attributes.slice(
      bulk_upload.needstype != 1 ? "field_5" : nil,   # location
      "field_12",  # age1
      "field_20",  # sex1
      "field_35",  # ecstat1
      "field_84",  # tcharge
      "field_96",  # startdate
      "field_97",  # startdate
      "field_98",  # startdate
      bulk_upload.needstype != 2 ? "field_108" : nil, # postcode
      bulk_upload.needstype != 2 ? "field_109" : nil, # postcode
      "field_111", # owning org
    )
  end

  def add_duplicate_found_in_spreadsheet_errors
    spreadsheet_duplicate_hash.each_key do |field|
      errors.add(field, :spreadsheet_dupe, category: :setup)
    end
  end

  def startdate
    Date.new(field_98 + 2000, field_97, field_96) if field_98.present? && field_97.present? && field_96.present?
  rescue Date::Error
    Date.new
  end

private

  def validate_declaration_acceptance
    unless field_132 == 1
      errors.add(:field_132, I18n.t("validations.declaration.missing"), category: :setup)
    end
  end

  def validate_valid_radio_option
    log.attributes.each do |question_id, _v|
      question = log.form.get_question(question_id, log)

      next unless question&.type == "radio"
      next if log[question_id].blank? || question.answer_options.key?(log[question_id].to_s) || !question.page.routed_to?(log, nil)

      fields = field_mapping_for_errors[question_id.to_sym] || []

      fields.each do |field|
        if setup_question?(question)
          errors.add(field, I18n.t("validations.invalid_option", question: QUESTIONS[field]), category: :setup)
        else
          errors.add(field, I18n.t("validations.invalid_option", question: QUESTIONS[field]))
        end
      end
    end
  end

  def validate_created_by_exists
    return if field_112.blank?

    unless created_by
      errors.add(:field_112, "User with the specified email could not be found")
    end
  end

  def validate_created_by_related
    return unless created_by

    unless (created_by.organisation == owning_organisation) || (created_by.organisation == managing_organisation)
      block_log_creation!
      errors.add(:field_112, "User must be related to owning organisation or managing organisation")
    end
  end

  def created_by
    @created_by ||= User.find_by(email: field_112)
  end

  def duplicate_check_fields
    [
      "startdate",
      "age1",
      "sex1",
      "ecstat1",
      "owning_organisation",
      "tcharge",
      bulk_upload.needstype != 2 ? "postcode_full" : nil,
      bulk_upload.needstype != 1 ? "location" : nil,
      log.chcharge.present? ? "chcharge" : nil,
    ].compact
  end

  def validate_location_related
    return if scheme.blank? || location.blank?

    unless location.scheme == scheme
      block_log_creation!
      errors.add(:field_5, "Scheme code must relate to a location that is owned by owning organisation or managing organisation")
    end
  end

  def location
    return if scheme.nil?

    @location ||= scheme.locations.find_by_id_on_multiple_fields(field_5)
  end

  def validate_location_exists
    if scheme && field_5.present? && location.nil?
      errors.add(:field_5, "Location could not be found with the provided scheme code", category: :setup)
    end
  end

  def validate_location_data_given
    if bulk_upload.supported_housing? && field_5.blank?
      errors.add(:field_5, I18n.t("validations.not_answered", question: "scheme code"), category: :setup)
    end
  end

  def validate_scheme_related
    return unless field_4.present? && scheme.present?

    owned_by_owning_org = owning_organisation && scheme.owning_organisation == owning_organisation
    owned_by_managing_org = managing_organisation && scheme.owning_organisation == managing_organisation

    unless owned_by_owning_org || owned_by_managing_org
      block_log_creation!
      errors.add(:field_4, "This management group code does not belong to your organisation, or any of your stock owners / managing agents", category: :setup)
    end
  end

  def validate_scheme_exists
    if field_4.present? && scheme.nil?
      errors.add(:field_4, "The management group code is not correct", category: :setup)
    end
  end

  def validate_scheme_data_given
    if bulk_upload.supported_housing? && field_4.blank?
      errors.add(:field_4, I18n.t("validations.not_answered", question: "management group code"), category: :setup)
    end
  end

  def validate_managing_org_related
    if owning_organisation && managing_organisation && !owning_organisation.can_be_managed_by?(organisation: managing_organisation)
      block_log_creation!

      if errors[:field_113].blank?
        errors.add(:field_113, "This managing organisation does not have a relationship with the owning organisation", category: :setup)
      end
    end
  end

  def validate_managing_org_exists
    if managing_organisation.nil?
      block_log_creation!

      if errors[:field_113].blank?
        errors.add(:field_113, "The managing organisation code is incorrect", category: :setup)
      end
    end
  end

  def validate_managing_org_data_given
    if field_113.blank?
      block_log_creation!
      errors.add(:field_113, I18n.t("validations.not_answered", question: "managing organisation"), category: :setup)
    end
  end

  def validate_owning_org_owns_stock
    if owning_organisation && !owning_organisation.holds_own_stock?
      block_log_creation!

      if errors[:field_111].blank?
        errors.add(:field_111, "The owning organisation code provided is for an organisation that does not own stock", category: :setup)
      end
    end
  end

  def validate_owning_org_exists
    if owning_organisation.nil?
      block_log_creation!

      if errors[:field_111].blank?
        errors.add(:field_111, "The owning organisation code is incorrect", category: :setup)
      end
    end
  end

  def validate_owning_org_data_given
    if field_111.blank?
      block_log_creation!

      if errors[:field_111].blank?
        errors.add(:field_111, I18n.t("validations.not_answered", question: "owning organisation"), category: :setup)
      end
    end
  end

  def validate_owning_org_permitted
    if owning_organisation && !bulk_upload.user.organisation.affiliated_stock_owners.include?(owning_organisation)
      block_log_creation!

      if errors[:field_111].blank?
        errors.add(:field_111, "You do not have permission to add logs for this owning organisation", category: :setup)
      end
    end
  end

  def validate_no_and_dont_know_disabled_needs_conjunction
    if field_59 == 1 && field_60 == 1
      errors.add(:field_59, I18n.t("validations.household.housingneeds.no_and_dont_know_disabled_needs_conjunction"))
      errors.add(:field_60, I18n.t("validations.household.housingneeds.no_and_dont_know_disabled_needs_conjunction"))
    end
  end

  def validate_dont_know_disabled_needs_conjunction
    if field_60 == 1 && [field_55, field_56, field_57, field_58].count(1).positive?
      %i[field_60 field_55 field_56 field_57 field_58].each do |field|
        errors.add(field, I18n.t("validations.household.housingneeds.dont_know_disabled_needs_conjunction")) if send(field) == 1
      end
    end
  end

  def validate_no_disabled_needs_conjunction
    if field_59 == 1 && [field_55, field_56, field_57, field_58].count(1).positive?
      %i[field_59 field_55 field_56 field_57 field_58].each do |field|
        errors.add(field, I18n.t("validations.household.housingneeds.no_disabled_needs_conjunction")) if send(field) == 1
      end
    end
  end

  def validate_only_one_housing_needs_type
    if [field_55, field_56, field_57].count(1) > 1
      %i[field_55 field_56 field_57].each do |field|
        errors.add(field, I18n.t("validations.household.housingneeds_type.only_one_option_permitted")) if send(field) == 1
      end
    end
  end

  def validate_no_housing_needs_questions_answered
    if [field_55, field_56, field_57, field_58, field_59, field_60].all?(&:blank?)
      errors.add(:field_59, I18n.t("validations.not_answered", question: "anybody with disabled access needs"))
      errors.add(:field_58, I18n.t("validations.not_answered", question: "other access needs"))
      %i[field_55 field_56 field_57].each do |field|
        errors.add(field, I18n.t("validations.not_answered", question: "disabled access needs type"))
      end
    end
  end

  def validate_reasonable_preference_homeless
    reason_fields = %i[field_70 field_71 field_72 field_73 field_74]
    if field_69 == 1 && reason_fields.all? { |field| attributes[field.to_s].blank? }
      reason_fields.each do |field|
        errors.add(field, I18n.t("validations.not_answered", question: "reason for reasonable preference"))
      end
    end
  end

  def validate_condition_effects
    illness_option_fields = %i[field_119 field_120 field_121 field_122 field_123 field_124 field_125 field_126 field_127 field_128]
    if household_no_illness?
      illness_option_fields.each do |field|
        if attributes[field.to_s] == 1
          errors.add(field, I18n.t("validations.household.condition_effects.no_choices"))
        end
      end
    elsif illness_option_fields.all? { |field| attributes[field.to_s].blank? }
      illness_option_fields.each do |field|
        errors.add(field, I18n.t("validations.not_answered", question: "how is person affected by condition or illness"))
      end
    end
  end

  def household_no_illness?
    field_118 != 1
  end

  def validate_lettings_type_matches_bulk_upload
    if [1, 3, 5, 7, 9, 11].include?(field_1) && !bulk_upload.general_needs?
      errors.add(:field_1, I18n.t("validations.setup.lettype.supported_housing_mismatch"))
    end

    if [2, 4, 6, 8, 10, 12].include?(field_1) && !bulk_upload.supported_housing?
      errors.add(:field_1, I18n.t("validations.setup.lettype.general_needs_mismatch"))
    end
  end

  def validate_cannot_be_la_referral_if_general_needs_and_la
    if field_78 == 4 && bulk_upload.general_needs? && owning_organisation && owning_organisation.la?
      errors.add :field_78, I18n.t("validations.household.referral.la_general_needs.prp_referred_by_la")
    end
  end

  def validate_la_with_local_housing_referral
    if field_78 == 3 && owning_organisation && owning_organisation.la?
      errors.add(:field_78, I18n.t("validations.household.referral.nominated_by_local_ha_but_la"))
    end
  end

  def validate_leaving_reason_for_renewal
    if field_134 == 1 && ![40, 42].include?(field_52)
      errors.add(:field_52, I18n.t("validations.household.reason.renewal_reason_needed"))
    end
  end

  def validate_relevant_collection_window
    return if start_date.blank? || bulk_upload.form.blank?

    unless bulk_upload.form.valid_start_date_for_form?(start_date)
      errors.add(:field_96, I18n.t("validations.date.outside_collection_window", year_combo: bulk_upload.year_combo, start_year: bulk_upload.year, end_year: bulk_upload.end_year), category: :setup)
      errors.add(:field_97, I18n.t("validations.date.outside_collection_window", year_combo: bulk_upload.year_combo, start_year: bulk_upload.year, end_year: bulk_upload.end_year), category: :setup)
      errors.add(:field_98, I18n.t("validations.date.outside_collection_window", year_combo: bulk_upload.year_combo, start_year: bulk_upload.year, end_year: bulk_upload.end_year), category: :setup)
    end
  end

  def start_date
    return if field_98.blank? || field_97.blank? || field_96.blank?

    Date.parse("20#{field_98.to_s.rjust(2, '0')}-#{field_97}-#{field_96}")
  rescue StandardError
    nil
  end

  def attribute_set
    @attribute_set ||= instance_variable_get(:@attributes)
  end

  def validate_data_types
    unless attribute_set["field_1"].value_before_type_cast&.match?(/^\d+\.?0*$/)
      errors.add(:field_1, I18n.t("validations.invalid_number", question: "letting type"))
    end
  end

  def validate_rent_type
    if [9, 10, 11, 12].include?(field_1) && field_130.blank?
      errors.add(:field_130, I18n.t("validations.not_answered", question: "intermediate rent type"), category: :setup)
    elsif [5, 6, 7, 8].include?(field_1) && field_129.blank?
      errors.add(:field_129, I18n.t("validations.not_answered", question: "affordable rent type"), category: :setup)
    end
  end

  def postcode_full
    "#{field_108} #{field_109}" if field_108 && field_109
  end

  def postcode_known
    if postcode_full.present?
      1
    elsif field_107.present?
      0
    end
  end

  def questions
    @questions ||= log.form.subsections.flat_map { |ss| ss.applicable_questions(log) }
  end

  def validate_nulls
    field_mapping_for_errors.each do |error_key, fields|
      question_id = error_key.to_s
      question = questions.find { |q| q.id == question_id }

      next unless question
      next if log.optional_fields.include?(question.id)
      next if question.completed?(log)

      if setup_question?(question)
        fields.each do |field|
          if errors.select { |e| fields.include?(e.attribute) }.none?
            errors.add(field, I18n.t("validations.not_answered", question: question.error_display_label&.downcase), category: :setup)
          end
        end
      else
        fields.each do |field|
          unless errors.any? { |e| fields.include?(e.attribute) }
            errors.add(field, I18n.t("validations.not_answered", question: question.error_display_label&.downcase))
          end
        end
      end
    end
  end

  def validate_incomplete_soft_validations
    routed_to_soft_validation_questions = log.form.questions.filter { |q| q.type == "interruption_screen" && q.page.routed_to?(log, nil) }.compact
    routed_to_soft_validation_questions.each do |question|
      next if question.completed?(log)

      question.page.interruption_screen_question_ids.each do |interruption_screen_question_id|
        next if log.form.questions.none? { |q| q.id == interruption_screen_question_id && q.page.routed_to?(log, nil) }

        field_mapping_for_errors[interruption_screen_question_id.to_sym]&.each do |field|
          if errors.none? { |e| e.options[:category] == :soft_validation && field_mapping_for_errors[interruption_screen_question_id.to_sym].include?(e.attribute) }
            error_message = [display_title_text(question.page.title_text, log), display_informative_text(question.page.informative_text, log)].reject(&:empty?).join(". ")
            errors.add(field, message: error_message, category: :soft_validation)
          end
        end
      end
    end
  end

  def setup_question?(question)
    log.form.setup_sections[0].subsections[0].questions.include?(question)
  end

  def validate_if_log_already_exists
    if log_already_exists?
      error_message = "This is a duplicate log"

      errors.add(:field_5, error_message) if bulk_upload.needstype != 1 # location
      errors.add(:field_7, error_message) # tenancycode
      errors.add(:field_12, error_message) # age1
      errors.add(:field_20, error_message) # sex1
      errors.add(:field_35, error_message) # ecstat1
      errors.add(:field_84, error_message) # tcharge
      errors.add(:field_85, error_message) if log.chcharge.present? # chcharge
      errors.add(:field_86, error_message) if bulk_upload.needstype != 1 # household_charge
      errors.add(:field_96, error_message) # startdate
      errors.add(:field_97, error_message) # startdate
      errors.add(:field_98, error_message) # startdate
      errors.add(:field_108, error_message) if bulk_upload.needstype != 2  # postcode_full
      errors.add(:field_109, error_message) if bulk_upload.needstype != 2  # postcode_full
      errors.add(:field_111, error_message) # owning_organisation
    end
  end

  def field_mapping_for_errors
    {
      lettype: [:field_1],
      tenancycode: [:field_7],
      postcode_known: %i[field_107 field_108 field_109],
      postcode_full: %i[field_107 field_108 field_109],
      la: %i[field_107],
      owning_organisation: [:field_111],
      managing_organisation: [:field_113],
      owning_organisation_id: [:field_111],
      managing_organisation_id: [:field_113],
      renewal: [:field_134],
      scheme: %i[field_4 field_5],
      created_by: [:field_112],
      needstype: [],
      rent_type: %i[field_1 field_129 field_130],
      startdate: %i[field_98 field_97 field_96],
      unittype_gn: %i[field_102],
      builtype: %i[field_103],
      wchair: %i[field_104],
      beds: %i[field_101],
      joint: %i[field_133],
      startertenancy: %i[field_8],
      tenancy: %i[field_9],
      tenancyother: %i[field_10],
      tenancylength: %i[field_11],
      declaration: %i[field_132],

      age1_known: %i[field_12],
      age1: %i[field_12],
      age2_known: %i[field_13],
      age2: %i[field_13],
      age3_known: %i[field_14],
      age3: %i[field_14],
      age4_known: %i[field_15],
      age4: %i[field_15],
      age5_known: %i[field_16],
      age5: %i[field_16],
      age6_known: %i[field_17],
      age6: %i[field_17],
      age7_known: %i[field_18],
      age7: %i[field_18],
      age8_known: %i[field_19],
      age8: %i[field_19],

      sex1: %i[field_20],
      sex2: %i[field_21],
      sex3: %i[field_22],
      sex4: %i[field_23],
      sex5: %i[field_24],
      sex6: %i[field_25],
      sex7: %i[field_26],
      sex8: %i[field_27],

      ethnic_group: %i[field_43],
      ethnic: %i[field_43],
      national: %i[field_44],

      relat2: %i[field_28],
      relat3: %i[field_29],
      relat4: %i[field_30],
      relat5: %i[field_31],
      relat6: %i[field_32],
      relat7: %i[field_33],
      relat8: %i[field_34],

      ecstat1: %i[field_35],
      ecstat2: %i[field_36],
      ecstat3: %i[field_37],
      ecstat4: %i[field_38],
      ecstat5: %i[field_39],
      ecstat6: %i[field_40],
      ecstat7: %i[field_41],
      ecstat8: %i[field_42],

      armedforces: %i[field_45],
      leftreg: %i[field_114],
      reservist: %i[field_46],

      preg_occ: %i[field_47],

      housingneeds: %i[field_47],

      illness: %i[field_118],

      layear: %i[field_66],
      waityear: %i[field_67],
      reason: %i[field_52],
      reasonother: %i[field_53],
      prevten: %i[field_61],
      homeless: %i[field_68],

      prevloc: %i[field_62],
      previous_la_known: %i[field_62],
      ppcodenk: %i[field_65],
      ppostcode_full: %i[field_63 field_64],

      reasonpref: %i[field_69],
      rp_homeless: %i[field_70],
      rp_insan_unsat: %i[field_71],
      rp_medwel: %i[field_72],
      rp_hardship: %i[field_73],
      rp_dontknow: %i[field_74],

      cbl: %i[field_75],
      chr: %i[field_76],
      cap: %i[field_77],
      letting_allocation: %i[field_75 field_76 field_77],

      referral: %i[field_78],

      net_income_known: %i[field_51],
      earnings: %i[field_50],
      incfreq: %i[field_116],
      hb: %i[field_48],
      benefits: %i[field_49],

      period: %i[field_79],
      brent: %i[field_80],
      scharge: %i[field_81],
      pscharge: %i[field_82],
      supcharg: %i[field_83],
      tcharge: %i[field_84],
      chcharge: %i[field_85],
      household_charge: %i[field_86],
      hbrentshortfall: %i[field_87],
      tshortfall: %i[field_88],

      unitletas: %i[field_105],
      rsnvac: %i[field_106],
      sheltered: %i[field_117],

      illness_type_1: %i[field_119],
      illness_type_2: %i[field_120],
      illness_type_3: %i[field_121],
      illness_type_4: %i[field_122],
      illness_type_5: %i[field_123],
      illness_type_6: %i[field_124],
      illness_type_7: %i[field_125],
      illness_type_8: %i[field_126],
      illness_type_9: %i[field_127],
      illness_type_10: %i[field_128],

      irproduct_other: %i[field_131],

      offered: %i[field_99],

      propcode: %i[field_100],

      majorrepairs: %i[field_92 field_93 field_94],
      mrcdate: %i[field_92 field_93 field_94],

      voiddate: %i[field_89 field_90 field_91],
      is_carehome: %i[field_85],
    }
  end

  def renttype
    case field_1
    when 1, 2, 3, 4
      :social
    when 5, 6, 7, 8
      :affordable
    when 9, 10, 11, 12
      :intermediate
    end
  end

  def rent_type
    case renttype
    when :social
      Imports::LettingsLogsImportService::RENT_TYPE[:social_rent]
    when :affordable
      if field_129 == 1
        Imports::LettingsLogsImportService::RENT_TYPE[:london_affordable_rent]
      else
        Imports::LettingsLogsImportService::RENT_TYPE[:affordable_rent]
      end
    when :intermediate
      case field_130
      when 1
        Imports::LettingsLogsImportService::RENT_TYPE[:rent_to_buy]
      when 2
        Imports::LettingsLogsImportService::RENT_TYPE[:london_living_rent]
      when 3
        Imports::LettingsLogsImportService::RENT_TYPE[:other_intermediate_rent_product]
      end
    end
  end

  def owning_organisation
    Organisation.find_by_id_on_multiple_fields(field_111)
  end

  def managing_organisation
    Organisation.find_by_id_on_multiple_fields(field_113)
  end

  def attributes_for_log
    attributes = {}

    attributes["lettype"] = field_1
    attributes["tenancycode"] = field_7
    attributes["la"] = field_107
    attributes["postcode_known"] = postcode_known
    attributes["postcode_full"] = postcode_full
    attributes["owning_organisation"] = owning_organisation
    attributes["managing_organisation"] = managing_organisation
    attributes["renewal"] = renewal
    attributes["scheme"] = scheme
    attributes["location"] = location
    attributes["created_by"] = created_by || bulk_upload.user
    attributes["needstype"] = bulk_upload.needstype
    attributes["rent_type"] = rent_type
    attributes["startdate"] = startdate
    attributes["unittype_gn"] = field_102
    attributes["builtype"] = field_103
    attributes["wchair"] = field_104
    attributes["beds"] = field_101
    attributes["joint"] = field_133
    attributes["startertenancy"] = field_8
    attributes["tenancy"] = field_9
    attributes["tenancyother"] = field_10
    attributes["tenancylength"] = field_11
    attributes["declaration"] = field_132

    attributes["age1_known"] = age1_known?
    attributes["age1"] = field_12 if attributes["age1_known"].zero? && field_12&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["age2_known"] = age2_known?
    attributes["age2"] = field_13 if attributes["age2_known"].zero? && field_13&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["age3_known"] = age3_known?
    attributes["age3"] = field_14 if attributes["age3_known"].zero? && field_14&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["age4_known"] = age4_known?
    attributes["age4"] = field_15 if attributes["age4_known"].zero? && field_15&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["age5_known"] = age5_known?
    attributes["age5"] = field_16 if attributes["age5_known"].zero? && field_16&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["age6_known"] = age6_known?
    attributes["age6"] = field_17 if attributes["age6_known"].zero? && field_17&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["age7_known"] = age7_known?
    attributes["age7"] = field_18 if attributes["age7_known"].zero? && field_18&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["age8_known"] = age8_known?
    attributes["age8"] = field_19 if attributes["age8_known"].zero? && field_19&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["sex1"] = field_20
    attributes["sex2"] = field_21
    attributes["sex3"] = field_22
    attributes["sex4"] = field_23
    attributes["sex5"] = field_24
    attributes["sex6"] = field_25
    attributes["sex7"] = field_26
    attributes["sex8"] = field_27

    attributes["ethnic_group"] = ethnic_group_from_ethnic
    attributes["ethnic"] = field_43
    attributes["national"] = field_44

    attributes["relat2"] = field_28
    attributes["relat3"] = field_29
    attributes["relat4"] = field_30
    attributes["relat5"] = field_31
    attributes["relat6"] = field_32
    attributes["relat7"] = field_33
    attributes["relat8"] = field_34

    attributes["ecstat1"] = field_35
    attributes["ecstat2"] = field_36
    attributes["ecstat3"] = field_37
    attributes["ecstat4"] = field_38
    attributes["ecstat5"] = field_39
    attributes["ecstat6"] = field_40
    attributes["ecstat7"] = field_41
    attributes["ecstat8"] = field_42

    attributes["details_known_2"] = details_known?(2)
    attributes["details_known_3"] = details_known?(3)
    attributes["details_known_4"] = details_known?(4)
    attributes["details_known_5"] = details_known?(5)
    attributes["details_known_6"] = details_known?(6)
    attributes["details_known_7"] = details_known?(7)
    attributes["details_known_8"] = details_known?(8)

    attributes["armedforces"] = field_45
    attributes["leftreg"] = leftreg
    attributes["reservist"] = field_46

    attributes["preg_occ"] = field_47

    attributes["housingneeds"] = housingneeds
    attributes["housingneeds_type"] = housingneeds_type
    attributes["housingneeds_other"] = housingneeds_other

    attributes["illness"] = field_118

    attributes["layear"] = field_66
    attributes["waityear"] = field_67
    attributes["reason"] = field_52
    attributes["reasonother"] = field_53
    attributes["prevten"] = field_61
    attributes["homeless"] = homeless

    attributes["prevloc"] = prevloc
    attributes["previous_la_known"] = previous_la_known
    attributes["ppcodenk"] = ppcodenk
    attributes["ppostcode_full"] = ppostcode_full

    attributes["reasonpref"] = field_69
    attributes["rp_homeless"] = field_70
    attributes["rp_insan_unsat"] = field_71
    attributes["rp_medwel"] = field_72
    attributes["rp_hardship"] = field_73
    attributes["rp_dontknow"] = field_74

    attributes["cbl"] = cbl
    attributes["chr"] = chr
    attributes["cap"] = cap
    attributes["letting_allocation_unknown"] = letting_allocation_unknown

    attributes["referral"] = field_78

    attributes["net_income_known"] = net_income_known
    attributes["earnings"] = earnings
    attributes["incfreq"] = field_116
    attributes["hb"] = field_48
    attributes["benefits"] = field_49

    attributes["period"] = field_79
    attributes["brent"] = field_80
    attributes["scharge"] = field_81
    attributes["pscharge"] = field_82
    attributes["supcharg"] = field_83
    attributes["tcharge"] = field_84
    attributes["chcharge"] = field_85
    attributes["is_carehome"] = field_85.present? ? 1 : 0
    attributes["household_charge"] = field_86
    attributes["hbrentshortfall"] = field_87
    attributes["tshortfall_known"] = tshortfall_known
    attributes["tshortfall"] = field_88

    attributes["hhmemb"] = hhmemb

    attributes["unitletas"] = field_105
    attributes["rsnvac"] = rsnvac
    attributes["sheltered"] = field_117

    attributes["illness_type_1"] = field_119
    attributes["illness_type_2"] = field_120
    attributes["illness_type_3"] = field_121
    attributes["illness_type_4"] = field_122
    attributes["illness_type_5"] = field_123
    attributes["illness_type_6"] = field_124
    attributes["illness_type_7"] = field_125
    attributes["illness_type_8"] = field_126
    attributes["illness_type_9"] = field_127
    attributes["illness_type_10"] = field_128

    attributes["irproduct_other"] = field_131

    attributes["offered"] = field_99

    attributes["propcode"] = field_100

    attributes["majorrepairs"] = majorrepairs

    attributes["mrcdate"] = mrcdate

    attributes["voiddate"] = voiddate

    attributes["first_time_property_let_as_social_housing"] = first_time_property_let_as_social_housing

    attributes
  end

  def first_time_property_let_as_social_housing
    case rsnvac
    when 15, 16, 17
      1
    else
      0
    end
  end

  def rsnvac
    field_106
  end

  def voiddate
    Date.new(field_91 + 2000, field_90, field_89) if field_91.present? && field_90.present? && field_89.present?
  rescue Date::Error
    Date.new
  end

  def majorrepairs
    mrcdate.present? ? 1 : 0
  end

  def mrcdate
    Date.new(field_94 + 2000, field_93, field_92) if field_94.present? && field_93.present? && field_92.present?
  rescue Date::Error
    Date.new
  end

  def prevloc
    field_62
  end

  def previous_la_known
    prevloc.present? ? 1 : 0
  end

  def ppcodenk
    case field_65
    when 1
      0
    when 2
      1
    end
  end

  def earnings
    field_50.round if field_50.present?
  end

  def net_income_known
    case field_51
    when 1
      0
    when 2
      1
    when 3
      1
    when 4
      2
    end
  end

  def leftreg
    field_114
  end

  def homeless
    case field_68
    when 1
      1
    when 12
      11
    end
  end

  def renewal
    case field_134
    when 1
      1
    when 2
      0
    when nil
      rsnvac == 14 ? 1 : 0
    else
      field_134
    end
  end

  def age1_known?
    return 1 if field_12 == "R"
    return 1 if field_12.blank?

    0
  end

  [
    { person: 2, field: :field_13 },
    { person: 3, field: :field_14 },
    { person: 4, field: :field_15 },
    { person: 5, field: :field_16 },
    { person: 6, field: :field_17 },
    { person: 7, field: :field_18 },
    { person: 8, field: :field_19 },
  ].each do |hash|
    define_method("age#{hash[:person]}_known?") do
      return 1 if public_send(hash[:field]) == "R"
      return 0 if send("person_#{hash[:person]}_present?")
      return 1 if public_send(hash[:field]).blank?

      0
    end
  end

  def details_known?(person_n)
    send("person_#{person_n}_present?") ? 0 : 1
  end

  def hhmemb
    [
      person_2_present?,
      person_3_present?,
      person_4_present?,
      person_5_present?,
      person_6_present?,
      person_7_present?,
      person_8_present?,
    ].count(true) + 1
  end

  def person_2_present?
    field_13.present? || field_21.present? || field_28.present?
  end

  def person_3_present?
    field_14.present? || field_22.present? || field_29.present?
  end

  def person_4_present?
    field_15.present? || field_23.present? || field_30.present?
  end

  def person_5_present?
    field_16.present? || field_24.present? || field_31.present?
  end

  def person_6_present?
    field_17.present? || field_25.present? || field_32.present?
  end

  def person_7_present?
    field_18.present? || field_26.present? || field_33.present?
  end

  def person_8_present?
    field_19.present? || field_27.present? || field_34.present?
  end

  def tshortfall_known
    field_87 == 1 ? 0 : 1
  end

  def letting_allocation_unknown
    [cbl, chr, cap].all?(0) ? 1 : 0
  end

  def cbl
    case field_75
    when 2
      0
    when 1
      1
    end
  end

  def chr
    case field_76
    when 2
      0
    when 1
      1
    end
  end

  def cap
    case field_77
    when 2
      0
    when 1
      1
    end
  end

  def ppostcode_full
    "#{field_63} #{field_64}".strip.gsub(/\s+/, " ")
  end

  def housingneeds
    if field_59 == 1
      2
    elsif field_60 == 1
      3
    elsif field_59.blank? || field_59&.zero?
      1
    end
  end

  def housingneeds_type
    if field_55 == 1
      0
    elsif field_56 == 1
      1
    elsif field_57 == 1
      2
    else
      3
    end
  end

  def housingneeds_other
    return 1 if field_58 == 1
    return 0 if [field_55, field_56, field_57].include?(1)
  end

  def ethnic_group_from_ethnic
    return nil if field_43.blank?

    case field_43
    when 1, 2, 3, 18
      0
    when 4, 5, 6, 7
      1
    when 8, 9, 10, 11, 15
      2
    when 12, 13, 14
      3
    when 16, 19
      4
    when 17
      17
    end
  end

  def scheme
    @scheme ||= Scheme.find_by_id_on_multiple_fields(field_4)
  end
end
