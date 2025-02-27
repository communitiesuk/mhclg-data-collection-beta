class BulkUpload::Lettings::Year2025::RowParser
  include ActiveModel::Model
  include ActiveModel::Attributes
  include InterruptionScreenHelper
  include FormattingHelper

  QUESTIONS = {
    field_1: "Which organisation owns this property?",
    field_2: "Which organisation manages this letting?",
    field_3: "What is the CORE username of the account this letting log should be assigned to?",
    field_4: "What is the needs type?",
    field_5: "What scheme does this letting belong to?",
    field_6: "Which location is this letting for?",
    field_7: "Is this letting a renewal?",
    field_8: "What is the tenancy start date?",
    field_9: "What is the tenancy start date?",
    field_10: "What is the tenancy start date?",
    field_11: "What is the rent type?",
    field_12: "Which 'Other' type of Intermediate Rent is this letting?",
    field_13: "What is the tenant code?",
    field_14: "What is the property reference?",
    field_15: "Has tenant seen the MHCLG privacy notice?",
    field_16: "What is the reason for the property being vacant?",
    field_17: "What type was the property most recently let as?",
    field_18: "If known, provide this property’s UPRN",
    field_19: "Address line 1",
    field_20: "Address line 2",
    field_21: "Town or city",
    field_22: "County",
    field_23: "Part 1 of the property's postcode",
    field_24: "Part 2 of the property's postcode",
    field_25: "What is the property's local authority?",
    field_26: "What type of unit is the property?",
    field_27: "Which type of building is the property?",
    field_28: "Is the property built or adapted to wheelchair-user standards?",
    field_29: "How many bedrooms does the property have?",
    field_30: "What is the void date?",
    field_31: "What is the void date?",
    field_32: "What is the void date?",
    field_33: "What date were any major repairs completed on?",
    field_34: "What date were any major repairs completed on?",
    field_35: "What date were any major repairs completed on?",
    field_36: "Is this letting sheltered accommodation?",
    field_37: "Is this a joint tenancy?",
    field_38: "Is this a starter tenancy?",
    field_39: "What is the type of tenancy?",
    field_40: "If 'Other', what is the type of tenancy?",
    field_41: "What is the length of the fixed-term tenancy to the nearest year?",
    field_42: "What is the lead tenant's age?",
    field_43: "Which of these best describes the lead tenant's gender identity?",
    field_44: "Which of these best describes the lead tenant's ethnic background?",
    field_45: "What is the lead tenant's nationality?",
    field_46: "Which of these best describes the lead tenant's working situation?",
    field_47: "Is person 2 the partner of the lead tenant?",
    field_48: "What is person 2's age?",
    field_49: "Which of these best describes person 2's gender identity?",
    field_50: "Which of these best describes person 2's working situation?",
    field_51: "Is person 3 the partner of the lead tenant?",
    field_52: "What is person 3's age?",
    field_53: "Which of these best describes person 3's gender identity?",
    field_54: "Which of these best describes person 3's working situation?",
    field_55: "Is person 4 the partner of the lead tenant?",
    field_56: "What is person 4's age?",
    field_57: "Which of these best describes person 4's gender identity?",
    field_58: "Which of these best describes person 4's working situation?",
    field_59: "Is person 5 the partner of the lead tenant?",
    field_60: "What is person 5's age?",
    field_61: "Which of these best describes person 5's gender identity?",
    field_62: "Which of these best describes person 5's working situation?",
    field_63: "Is person 6 the partner of the lead tenant?",
    field_64: "What is person 6's age?",
    field_65: "Which of these best describes person 6's gender identity?",
    field_66: "Which of these best describes person 6's working situation?",
    field_67: "Is person 7 the partner of the lead tenant?",
    field_68: "What is person 7's age?",
    field_69: "Which of these best describes person 7's gender identity?",
    field_70: "Which of these best describes person 7's working situation?",
    field_71: "Is person 8 the partner of the lead tenant?",
    field_72: "What is person 8's age?",
    field_73: "Which of these best describes person 8's gender identity?",
    field_74: "Which of these best describes person 8's working situation?",
    field_75: "Does anybody in the household have links to the UK armed forces?",
    field_76: "Is this person still serving in the UK armed forces?",
    field_77: "Was this person seriously injured or ill as a result of serving in the UK armed forces?",
    field_78: "Is anybody in the household pregnant?",
    field_79: "Does anybody in the household have any disabled access needs?",
    field_80: "Does anybody in the household have any disabled access needs?",
    field_81: "Does anybody in the household have any disabled access needs?",
    field_82: "Does anybody in the household have any disabled access needs?",
    field_83: "Does anybody in the household have any disabled access needs?",
    field_84: "Does anybody in the household have any disabled access needs?",
    field_85: "Does anybody in the household have a physical or mental health condition (or other illness) expected to last 12 months or more?",
    field_86: "Does this person's condition affect their dexterity?",
    field_87: "Does this person's condition affect their learning or understanding or concentrating?",
    field_88: "Does this person's condition affect their hearing?",
    field_89: "Does this person's condition affect their memory?",
    field_90: "Does this person's condition affect their mental health?",
    field_91: "Does this person's condition affect their mobility?",
    field_92: "Does this person's condition affect them socially or behaviourally?",
    field_93: "Does this person's condition affect their stamina or breathing or fatigue?",
    field_94: "Does this person's condition affect their vision?",
    field_95: "Does this person's condition affect them in another way?",
    field_96: "How long has the household continuously lived in the local authority area of the new letting?",
    field_97: "How long has the household been on the local authority waiting list for the new letting?",
    field_98: "What is the tenant’s main reason for the household leaving their last settled home?",
    field_99: "If 'Other', what was the main reason for leaving their last settled home?",
    field_100: "Where was the household immediately before this letting?",
    field_101: "Did the household experience homelessness immediately before this letting?",
    field_102: "Do you know the postcode of the household's last settled home?",
    field_103: "What is the postcode of the household's last settled home?",
    field_104: "What is the postcode of the household's last settled home?",
    field_105: "What is the local authority of the household's last settled home?",
    field_106: "Was the household given 'reasonable preference' by the local authority?",
    field_107: "Reasonable preference reason They were homeless or about to lose their home (within 56 days)",
    field_108: "Reasonable preference reason They were living in insanitary, overcrowded or unsatisfactory housing",
    field_109: "Reasonable preference reason They needed to move on medical and welfare reasons (including disability)",
    field_110: "Reasonable preference reason They needed to move to avoid hardship to themselves or others",
    field_111: "Reasonable preference reason Don't know",
    field_112: "Was the letting made under the Choice-Based Lettings (CBL)?",
    field_113: "Was the letting made under the Common Allocation Policy (CAP)?",
    field_114: "Was the letting made under the Common Housing Register (CHR)?",
    field_115: "Was the letting made under the Accessible Register?",
    field_116: "What was the source of referral for this letting?",
    field_117: "Do you know the household's combined total income after tax?",
    field_118: "How often does the household receive income?",
    field_119: "How much income does the household have in total?",
    field_120: "Is the tenant likely to be receiving any of these housing-related benefits?",
    field_121: "How much of the household's income is from Universal Credit, state pensions or benefits?",
    field_122: "Does the household pay rent or other charges for the accommodation?",
    field_123: "How often does the household pay rent and other charges?",
    field_124: "What is the basic rent?",
    field_125: "What is the service charge?",
    field_126: "What is the personal service charge?",
    field_127: "What is the support charge?",
    field_128: "After the household has received any housing-related benefits, will they still need to pay for rent and charges?",
    field_129: "What do you expect the outstanding amount to be?",
  }.freeze

  RENT_TYPE_BU_MAPPING = {
    1 => 0,
    2 => 1,
    3 => 2,
    4 => 3,
    5 => 4,
    6 => 5,
    7 => 6,
  }.freeze

  ERROR_BASE_KEY = "validations.lettings.2025.bulk_upload".freeze

  attribute :bulk_upload
  attribute :block_log_creation, :boolean, default: -> { false }

  attribute :field_blank

  attribute :field_1, :string
  attribute :field_2, :string
  attribute :field_3, :string
  attribute :field_4, :integer
  attribute :field_7, :integer
  attribute :field_8, :integer
  attribute :field_9, :integer
  attribute :field_10, :integer
  attribute :field_11, :integer
  attribute :field_12, :string
  attribute :field_13, :string
  attribute :field_14, :string
  attribute :field_5, :string
  attribute :field_6, :string
  attribute :field_18, :string
  attribute :field_19, :string
  attribute :field_20, :string
  attribute :field_21, :string
  attribute :field_22, :string
  attribute :field_23, :string
  attribute :field_24, :string
  attribute :field_25, :string
  attribute :field_17, :integer
  attribute :field_16, :integer
  attribute :field_26, :integer
  attribute :field_27, :integer
  attribute :field_28, :integer
  attribute :field_29, :integer
  attribute :field_30, :integer
  attribute :field_31, :integer
  attribute :field_32, :integer
  attribute :field_33, :integer
  attribute :field_34, :integer
  attribute :field_35, :integer
  attribute :field_37, :integer
  attribute :field_38, :integer
  attribute :field_39, :integer
  attribute :field_40, :string
  attribute :field_41, :integer
  attribute :field_36, :integer
  attribute :field_15, :integer
  attribute :field_42, :string
  attribute :field_43, :string
  attribute :field_44, :integer
  attribute :field_45, :integer
  attribute :field_46, :integer
  attribute :field_47, :integer
  attribute :field_48, :string
  attribute :field_49, :string
  attribute :field_50, :integer
  attribute :field_51, :integer
  attribute :field_52, :string
  attribute :field_53, :string
  attribute :field_54, :integer
  attribute :field_55, :integer
  attribute :field_56, :string
  attribute :field_57, :string
  attribute :field_58, :integer
  attribute :field_59, :integer
  attribute :field_60, :string
  attribute :field_61, :string
  attribute :field_62, :integer
  attribute :field_63, :integer
  attribute :field_64, :string
  attribute :field_65, :string
  attribute :field_66, :integer
  attribute :field_67, :integer
  attribute :field_68, :string
  attribute :field_69, :string
  attribute :field_70, :integer
  attribute :field_71, :integer
  attribute :field_72, :string
  attribute :field_73, :string
  attribute :field_74, :integer
  attribute :field_75, :integer
  attribute :field_76, :integer
  attribute :field_77, :integer
  attribute :field_78, :integer
  attribute :field_79, :integer
  attribute :field_80, :integer
  attribute :field_81, :integer
  attribute :field_82, :integer
  attribute :field_83, :integer
  attribute :field_84, :integer
  attribute :field_85, :integer
  attribute :field_86, :integer
  attribute :field_87, :integer
  attribute :field_88, :integer
  attribute :field_89, :integer
  attribute :field_90, :integer
  attribute :field_91, :integer
  attribute :field_92, :integer
  attribute :field_93, :integer
  attribute :field_94, :integer
  attribute :field_95, :integer
  attribute :field_96, :integer
  attribute :field_97, :integer
  attribute :field_98, :integer
  attribute :field_99, :string
  attribute :field_100, :integer
  attribute :field_101, :integer
  attribute :field_102, :integer
  attribute :field_103, :string
  attribute :field_104, :string
  attribute :field_105, :string
  attribute :field_106, :integer
  attribute :field_107, :integer
  attribute :field_108, :integer
  attribute :field_109, :integer
  attribute :field_110, :integer
  attribute :field_111, :integer
  attribute :field_112, :integer
  attribute :field_113, :integer
  attribute :field_114, :integer
  attribute :field_115, :integer
  attribute :field_116, :integer
  attribute :field_117, :integer
  attribute :field_118, :integer
  attribute :field_119, :decimal
  attribute :field_120, :integer
  attribute :field_121, :integer
  attribute :field_122, :integer
  attribute :field_123, :integer
  attribute :field_124, :decimal
  attribute :field_125, :decimal
  attribute :field_126, :decimal
  attribute :field_127, :decimal
  attribute :field_128, :integer
  attribute :field_129, :decimal

  validate :validate_valid_radio_option, on: :before_log

  validates :field_11,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "rent type."),
              category: :setup,
            },
            inclusion: {
              in: (1..7).to_a,
              message: I18n.t("#{ERROR_BASE_KEY}.invalid_option", question: "rent type."),
              unless: -> { field_11.blank? },
              category: :setup,
            },
            on: :after_log

  validates :field_7,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "property renewal."),
              category: :setup,
            },
            on: :after_log

  validates :field_8,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "tenancy start date (day)."),
              category: :setup,
            },
            on: :after_log

  validates :field_9,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "tenancy start date (month)."),
              category: :setup,
            },
            on: :after_log

  validates :field_10,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "tenancy start date (year)."),
              category: :setup,
            },
            format: {
              with: /\A(\d{2}|\d{4})\z/,
              message: I18n.t("#{ERROR_BASE_KEY}.startdate.year_not_two_or_four_digits"),
              category: :setup,
              unless: -> { field_10.blank? },
            },
            on: :after_log

  validates :field_5,
            presence: {
              if: proc { supported_housing? },
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "scheme code."),
              category: :setup,
            },
            on: :after_log

  validates :field_6,
            presence: {
              if: proc { supported_housing? },
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "location code."),
              category: :setup,
            },
            on: :after_log

  validates :field_112,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "was the letting made under the Choice-Based Lettings (CBL)?"),
              category: :not_answered,
            },
            inclusion: {
              in: [1, 2],
              message: I18n.t("#{ERROR_BASE_KEY}.invalid_option", question: "was the letting made under the Choice-Based Lettings (CBL)?"),
              if: -> { field_112.present? },
            },
            on: :after_log

  validates :field_113,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "was the letting made under the Common Allocation Policy (CAP)?"),
              category: :not_answered,
            },
            inclusion: {
              in: [1, 2],
              message: I18n.t("#{ERROR_BASE_KEY}.invalid_option", question: "was the letting made under the Common Allocation Policy (CAP)?"),
              if: -> { field_113.present? },
            },
            on: :after_log

  validates :field_114,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "was the letting made under the Common Housing Register (CHR)?"),
              category: :not_answered,
            },
            inclusion: {
              in: [1, 2],
              message: I18n.t("#{ERROR_BASE_KEY}.invalid_option", question: "was the letting made under the Common Housing Register (CHR)?"),
              if: -> { field_114.present? },
            },
            on: :after_log

  validates :field_115,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "was the letting made under the Accessible Register?"),
              category: :not_answered,
            },
            inclusion: {
              in: [1, 2],
              message: I18n.t("#{ERROR_BASE_KEY}.invalid_option", question: "was the letting made under the Accessible Register?"),
              if: -> { field_115.present? },
            },
            on: :after_log

  validates :field_42, format: { with: /\A\d{1,3}\z|\AR\z/, message: I18n.t("#{ERROR_BASE_KEY}.age.invalid", person_num: 1) }, on: :after_log
  validates :field_48, format: { with: /\A\d{1,3}\z|\AR\z/, message: I18n.t("#{ERROR_BASE_KEY}.age.invalid", person_num: 2) }, on: :after_log, if: proc { details_known?(2).zero? }
  validates :field_52, format: { with: /\A\d{1,3}\z|\AR\z/, message: I18n.t("#{ERROR_BASE_KEY}.age.invalid", person_num: 3) }, on: :after_log, if: proc { details_known?(3).zero? }
  validates :field_56, format: { with: /\A\d{1,3}\z|\AR\z/, message: I18n.t("#{ERROR_BASE_KEY}.age.invalid", person_num: 4) }, on: :after_log, if: proc { details_known?(4).zero? }
  validates :field_60, format: { with: /\A\d{1,3}\z|\AR\z/, message: I18n.t("#{ERROR_BASE_KEY}.age.invalid", person_num: 5) }, on: :after_log, if: proc { details_known?(5).zero? }
  validates :field_64, format: { with: /\A\d{1,3}\z|\AR\z/, message: I18n.t("#{ERROR_BASE_KEY}.age.invalid", person_num: 6) }, on: :after_log, if: proc { details_known?(6).zero? }
  validates :field_68, format: { with: /\A\d{1,3}\z|\AR\z/, message: I18n.t("#{ERROR_BASE_KEY}.age.invalid", person_num: 7) }, on: :after_log, if: proc { details_known?(7).zero? }
  validates :field_72, format: { with: /\A\d{1,3}\z|\AR\z/, message: I18n.t("#{ERROR_BASE_KEY}.age.invalid", person_num: 8) }, on: :after_log, if: proc { details_known?(8).zero? }

  validate :validate_needs_type_present, on: :after_log
  validate :validate_data_types, on: :after_log
  validate :validate_relevant_collection_window, on: :after_log
  validate :validate_la_with_local_housing_referral, on: :after_log
  validate :validate_cannot_be_la_referral_if_general_needs_and_la, on: :after_log
  validate :validate_leaving_reason_for_renewal, on: :after_log
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

  validate :validate_related_scheme_exists, on: :after_log
  validate :validate_related_location_exists, on: :after_log

  validate :validate_assigned_to_exists, on: :after_log
  validate :validate_assigned_to_related, on: :after_log
  validate :validate_assigned_to_when_support, on: :after_log
  validate :validate_all_charges_given, on: :after_log

  validate :validate_address_option_found, on: :after_log, unless: -> { supported_housing? }
  validate :validate_uprn_exists_if_any_key_address_fields_are_blank, on: :after_log, unless: -> { supported_housing? }
  validate :validate_address_fields, on: :after_log, unless: -> { supported_housing? }

  validate :validate_incomplete_soft_validations, on: :after_log
  validate :validate_nationality, on: :after_log
  validate :validate_reasonpref_reason_values, on: :after_log

  validate :validate_nulls, on: :after_log

  def self.question_for_field(field)
    QUESTIONS[field]
  end

  def valid?
    return @valid if @valid

    errors.clear

    return @valid = true if blank_row?

    super(:before_log)
    @before_errors = errors.dup

    log.valid?

    super(:after_log)
    errors.merge!(@before_errors)

    log.errors.each do |error|
      fields = field_mapping_for_errors[error.attribute] || []

      fields.each do |field|
        next if errors.include?(field)
        next if error.type == :skip_bu_error

        question = log.form.get_question(error.attribute, log)

        if question.present? && setup_question?(question)
          errors.add(field, error.message, category: :setup)
        else
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
    field_13
  end

  def property_ref
    field_14
  end

  def log_already_exists?
    return false if blank_row?

    @log_already_exists ||= LettingsLog
      .where(status: %w[not_started in_progress completed])
      .exists?(duplicate_check_fields.index_with { |field| log.public_send(field) })
  end

  def spreadsheet_duplicate_hash
    hash = attributes.slice(
      "field_1",   # owning org
      "field_8",   # startdate
      "field_9",   # startdate
      "field_10", # startdate
      "field_13", # tenancycode
      !general_needs? ? :field_6.to_s : nil, # location
      !supported_housing? ? "field_23" : nil,  # postcode
      !supported_housing? ? "field_24" : nil,  # postcode
      "field_42", # age1
      "field_43",  # sex1
      "field_46",  # ecstat1
    )
    if [field_124, field_125, field_126, field_127].all?(&:present?)
      hash.merge({ "tcharge" => [field_124, field_125, field_126, field_127].sum })
    else
      hash
    end
  end

  def add_duplicate_found_in_spreadsheet_errors
    spreadsheet_duplicate_hash.each_key do |field|
      if field == "tcharge"
        %w[field_124 field_125 field_126 field_127].each do |sub_field|
          errors.add(sub_field, I18n.t("#{ERROR_BASE_KEY}.spreadsheet_dupe"), category: :setup)
        end
      else
        errors.add(field, I18n.t("#{ERROR_BASE_KEY}.spreadsheet_dupe"), category: :setup)
      end
    end
  end

private

  def validate_valid_radio_option
    log.attributes.each do |question_id, _v|
      question = log.form.get_question(question_id, log)

      next unless question&.type == "radio"
      next if log[question_id].blank? || question.answer_options.key?(log[question_id].to_s) || !question.page.routed_to?(log, nil)

      fields = field_mapping_for_errors[question_id.to_sym] || []

      fields.each do |field|
        if setup_question?(question)
          errors.add(field, I18n.t("#{ERROR_BASE_KEY}.invalid_option", question: format_ending(QUESTIONS[field])), category: :setup)
        else
          errors.add(field, I18n.t("#{ERROR_BASE_KEY}.invalid_option", question: format_ending(QUESTIONS[field])))
        end
      end
    end
  end

  def validate_assigned_to_exists
    return if field_3.blank?

    unless assigned_to
      errors.add(:field_3, I18n.t("#{ERROR_BASE_KEY}.assigned_to.not_found"))
    end
  end

  def validate_assigned_to_when_support
    if field_3.blank? && bulk_upload.user.support?
      errors.add(:field_3, category: :setup, message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "what is the CORE username of the account this letting log should be assigned to?"))
    end
  end

  def validate_assigned_to_related
    return unless assigned_to
    return if assigned_to.organisation == owning_organisation || assigned_to.organisation == managing_organisation
    return if assigned_to.organisation == owning_organisation&.absorbing_organisation || assigned_to.organisation == managing_organisation&.absorbing_organisation

    block_log_creation!
    errors.add(:field_3, I18n.t("#{ERROR_BASE_KEY}.assigned_to.organisation_not_related"))
  end

  def assigned_to
    @assigned_to ||= User.where("lower(email) = ?", field_3&.downcase).first
  end

  def validate_uprn_exists_if_any_key_address_fields_are_blank
    if field_18.blank? && !key_address_fields_provided?
      %i[field_19 field_21 field_23 field_24].each do |field|
        errors.add(field, I18n.t("#{ERROR_BASE_KEY}.address.not_answered")) if send(field).blank?
      end
      errors.add(:field_18, I18n.t("#{ERROR_BASE_KEY}.address.not_answered", question: "UPRN."))
    end
  end

  def validate_address_option_found
    if log.uprn.nil? && field_18.blank? && key_address_fields_provided?
      error_message = if log.address_options_present? && log.address_options.size > 1
                        I18n.t("#{ERROR_BASE_KEY}.address.not_determined.multiple")
                      elsif log.address_options_present?
                        I18n.t("#{ERROR_BASE_KEY}.address.not_determined.one")
                      else
                        I18n.t("#{ERROR_BASE_KEY}.address.not_found")
                      end
      %i[field_19 field_20 field_21 field_22 field_23 field_24].each do |field|
        errors.add(field, error_message) if errors[field].blank?
      end
    end
  end

  def key_address_fields_provided?
    field_19.present? && field_21.present? && postcode_full.present?
  end

  def validate_address_fields
    if field_18.blank? || log.errors.attribute_names.include?(:uprn)
      if field_19.blank? && errors[:field_19].blank?
        errors.add(:field_19, I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "address line 1."))
      end

      if field_21.blank? && errors[:field_21].blank?
        errors.add(:field_21, I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "town or city."))
      end

      if field_23.blank? && errors[:field_23].blank?
        errors.add(:field_23, I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "part 1 of postcode."))
      end

      if field_24.blank? && errors[:field_24].blank?
        errors.add(:field_24, I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "part 2 of postcode."))
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
          if errors.none? { |e| field_mapping_for_errors[interruption_screen_question_id.to_sym].include?(e.attribute) }
            error_message = [display_title_text(question.page.title_text, log), display_informative_text(question.page.informative_text, log)].reject(&:empty?).join(" ")
            errors.add(field, message: error_message, category: :soft_validation)
          end
        end
      end
    end
  end

  def validate_nationality
    if field_45.present? && !valid_nationality_options.include?(field_45.to_s)
      errors.add(:field_45, I18n.t("#{ERROR_BASE_KEY}.nationality.invalid"))
    end
  end

  def validate_reasonpref_reason_values
    valid_reasonpref_reason_options = %w[0 1]
    %w[field_107 field_108 field_109 field_110 field_111].each do |field|
      next unless send(field).present? && !valid_reasonpref_reason_options.include?(send(field).to_s)

      question_text = QUESTIONS[field.to_sym]
      question_text[0] = question_text[0].downcase
      errors.add(field.to_sym, I18n.t("#{ERROR_BASE_KEY}.invalid_option", question: question_text))
    end
  end

  def duplicate_check_fields
    [
      "startdate",
      "age1",
      "sex1",
      "ecstat1",
      "owning_organisation",
      "tcharge",
      !supported_housing? ? "postcode_full" : nil,
      !general_needs? ? "location" : nil,
      "tenancycode",
      log.chcharge.present? ? "chcharge" : nil,
    ].compact
  end

  def validate_needs_type_present
    if field_4.blank?
      errors.add(:field_4, I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "needs type."), category: :setup)
    end
  end

  def validate_no_and_dont_know_disabled_needs_conjunction
    if field_83 == 1 && field_84 == 1
      errors.add(:field_83, I18n.t("#{ERROR_BASE_KEY}.housingneeds.no_and_dont_know_disabled_needs_conjunction"))
      errors.add(:field_84, I18n.t("#{ERROR_BASE_KEY}.housingneeds.no_and_dont_know_disabled_needs_conjunction"))
    end
  end

  def validate_dont_know_disabled_needs_conjunction
    if field_84 == 1 && [field_79, field_80, field_81, field_82].count(1).positive?
      %i[field_84 field_79 field_80 field_81 field_82].each do |field|
        errors.add(field, I18n.t("#{ERROR_BASE_KEY}.housingneeds.dont_know_disabled_needs_conjunction")) if send(field) == 1
      end
    end
  end

  def validate_no_disabled_needs_conjunction
    if field_83 == 1 && [field_79, field_80, field_81, field_82].count(1).positive?
      %i[field_83 field_79 field_80 field_81 field_82].each do |field|
        errors.add(field, I18n.t("#{ERROR_BASE_KEY}.housingneeds.no_disabled_needs_conjunction")) if send(field) == 1
      end
    end
  end

  def validate_only_one_housing_needs_type
    if [field_79, field_80, field_81].count(1) > 1
      %i[field_79 field_80 field_81].each do |field|
        errors.add(field, I18n.t("#{ERROR_BASE_KEY}.housingneeds_type.only_one_option_permitted")) if send(field) == 1
      end
    end
  end

  def validate_no_housing_needs_questions_answered
    if [field_79, field_80, field_81, field_82, field_83, field_84].all?(&:blank?)
      errors.add(:field_83, I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "anybody with disabled access needs."))
      errors.add(:field_82, I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "other access needs."))
      %i[field_79 field_80 field_81].each do |field|
        errors.add(field, I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "disabled access needs type."))
      end
    end
  end

  def validate_reasonable_preference_homeless
    reason_fields = %i[field_107 field_108 field_109 field_110 field_111]
    if field_106 == 1 && reason_fields.all? { |field| attributes[field.to_s].blank? }
      reason_fields.each do |field|
        errors.add(field, I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "reason for reasonable preference."))
      end
    end
  end

  def validate_condition_effects
    illness_option_fields = %i[field_94 field_88 field_91 field_86 field_87 field_89 field_90 field_93 field_92 field_95]
    if household_no_illness?
      illness_option_fields.each do |field|
        if attributes[field.to_s] == 1
          errors.add(field, I18n.t("#{ERROR_BASE_KEY}.condition_effects.no_choices"))
        end
      end
    elsif illness_option_fields.all? { |field| attributes[field.to_s].blank? }
      illness_option_fields.each do |field|
        errors.add(field, I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "how is person affected by condition or illness."))
      end
    end
  end

  def household_no_illness?
    field_85 != 1
  end

  def validate_leaving_reason_for_renewal
    if field_7 == 1 && ![50, 51, 52, 53].include?(field_98)
      errors.add(:field_98, I18n.t("#{ERROR_BASE_KEY}.reason.renewal_reason_needed"))
    end
  end

  def general_needs?
    field_4 == 1
  end

  def supported_housing?
    field_4 == 2
  end

  def validate_cannot_be_la_referral_if_general_needs_and_la
    if field_116 == 4 && general_needs? && owning_organisation && owning_organisation.la?
      errors.add :field_116, I18n.t("#{ERROR_BASE_KEY}.referral.general_needs_prp_referred_by_la")
    end
  end

  def validate_la_with_local_housing_referral
    if field_116 == 3 && owning_organisation && owning_organisation.la?
      errors.add(:field_116, I18n.t("#{ERROR_BASE_KEY}.referral.nominated_by_local_ha_but_la"))
    end
  end

  def validate_relevant_collection_window
    return if startdate.blank? || bulk_upload.form.blank?

    unless bulk_upload.form.valid_start_date_for_form?(startdate)
      errors.add(:field_8, I18n.t("#{ERROR_BASE_KEY}.startdate.outside_collection_window", year_combo: bulk_upload.year_combo, start_year: bulk_upload.year, end_year: bulk_upload.end_year), category: :setup)
      errors.add(:field_9, I18n.t("#{ERROR_BASE_KEY}.startdate.outside_collection_window", year_combo: bulk_upload.year_combo, start_year: bulk_upload.year, end_year: bulk_upload.end_year), category: :setup)
      errors.add(:field_10, I18n.t("#{ERROR_BASE_KEY}.startdate.outside_collection_window", year_combo: bulk_upload.year_combo, start_year: bulk_upload.year, end_year: bulk_upload.end_year), category: :setup)
    end
  end

  def validate_data_types
    unless attribute_set["field_11"].value_before_type_cast&.match?(/^\d+\.?0*$/)
      errors.add(:field_11, I18n.t("#{ERROR_BASE_KEY}.invalid_number", question: "rent type."))
    end
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
          if field.present? && errors.none? { |e| fields.include?(e.attribute) } && @before_errors.none? { |e| fields.include?(e.attribute) }
            errors.add(field, question.unanswered_error_message, category: :setup)
          end
        end
      else
        fields.each do |field|
          if errors.none? { |e| fields.include?(e.attribute) } && @before_errors.none? { |e| fields.include?(e.attribute) }
            errors.add(field, question.unanswered_error_message)
          end
        end
      end
    end
  end

  def validate_related_location_exists
    if scheme && field_6.present? && location.nil? && :field_6.present?
      block_log_creation!
      errors.add(:field_6, I18n.t("#{ERROR_BASE_KEY}.location.must_relate_to_org"), category: :setup)
    end
  end

  def validate_related_scheme_exists
    if field_5.present? && :field_5.present? && owning_organisation.present? && managing_organisation.present? && scheme.nil?
      block_log_creation!
      errors.add(:field_5, I18n.t("#{ERROR_BASE_KEY}.scheme.must_relate_to_org"), category: :setup)
    end
  end

  def validate_managing_org_related
    if owning_organisation && managing_organisation && !owning_organisation.can_be_managed_by?(organisation: managing_organisation)
      block_log_creation!

      if errors[:field_2].blank?
        errors.add(:field_2, I18n.t("#{ERROR_BASE_KEY}.managing_organisation.no_relationship"), category: :setup)
      end
    end
  end

  def validate_managing_org_exists
    if managing_organisation.nil?
      block_log_creation!

      if field_2.present? && errors[:field_2].blank?
        errors.add(:field_2, I18n.t("#{ERROR_BASE_KEY}.managing_organisation.not_found"), category: :setup)
      end
    end
  end

  def validate_managing_org_data_given
    if field_2.blank?
      block_log_creation!
      errors.add(:field_2, I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "managing organisation."), category: :setup)
    end
  end

  def validate_owning_org_owns_stock
    if owning_organisation && !owning_organisation.holds_own_stock?
      block_log_creation!

      if errors[:field_1].blank?
        errors.add(:field_1, I18n.t("#{ERROR_BASE_KEY}.owning_organisation.not_stock_owner"), category: :setup)
      end
    end
  end

  def validate_owning_org_exists
    if owning_organisation.nil?
      block_log_creation!

      if field_1.present? && errors[:field_1].blank?
        errors.add(:field_1, I18n.t("#{ERROR_BASE_KEY}.owning_organisation.not_found"), category: :setup)
      end
    end
  end

  def validate_owning_org_data_given
    if field_1.blank?
      block_log_creation!
      errors.add(:field_1, I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "owning organisation."), category: :setup)
    end
  end

  def validate_owning_org_permitted
    return unless owning_organisation
    return if bulk_upload_organisation.affiliated_stock_owners.include?(owning_organisation)

    block_log_creation!

    return if errors[:field_1].present?

    if bulk_upload.user.support?
      errors.add(:field_1, I18n.t("#{ERROR_BASE_KEY}.owning_organisation.not_permitted.support", org_name: bulk_upload_organisation.name), category: :setup)
    else
      errors.add(:field_1, I18n.t("#{ERROR_BASE_KEY}.owning_organisation.not_permitted.not_support"), category: :setup)
    end
  end

  def validate_all_charges_given
    return if supported_housing? && field_124 == 1

    blank_charge_fields, other_charge_fields = {
      field_124: "basic rent",
      field_125: "service charge",
      field_126: "personal service charge",
      field_127: "support charge",
    }.partition { |field, _| public_send(field).blank? }.map(&:to_h)

    blank_charge_fields.each do |field, charge|
      errors.add(field, I18n.t("#{ERROR_BASE_KEY}.charges.missing_charges", sentence_fragment: charge))
    end

    other_charge_fields.each do |field, _charge|
      blank_charge_fields.each do |_blank_field, blank_charge|
        errors.add(field, I18n.t("#{ERROR_BASE_KEY}.charges.missing_charges", sentence_fragment: blank_charge))
      end
    end
  end

  def all_charges_given?
    field_124.present? && field_125.present? && field_126.present? && field_127.present?
  end

  def setup_question?(question)
    log.form.setup_sections[0].subsections[0].questions.include?(question)
  end

  def validate_if_log_already_exists
    if log_already_exists?
      error_message = I18n.t("#{ERROR_BASE_KEY}.duplicate")

      errors.add(:field_1, error_message) # owning_organisation
      errors.add(:field_8, error_message) # startdate
      errors.add(:field_9, error_message) # startdate
      errors.add(:field_10, error_message) # startdate
      errors.add(:field_13, error_message) # tenancycode
      errors.add(:field_6, error_message) if !general_needs? && :field_6.present? # location
      errors.add(:field_5, error_message) if !general_needs? && :field_6.blank? # add to Scheme field as unclear whether log uses New or Old CORE ids
      errors.add(:field_23, error_message) unless supported_housing? # postcode_full
      errors.add(:field_24, error_message) unless supported_housing? # postcode_full
      errors.add(:field_25, error_message) unless supported_housing? # la
      errors.add(:field_42, error_message) # age1
      errors.add(:field_43, error_message) # sex1
      errors.add(:field_46, error_message) # ecstat1
      errors.add(:field_122, error_message) unless general_needs? # household_charge
      errors.add(:field_124, error_message) # brent
      errors.add(:field_125, error_message) # scharge
      errors.add(:field_126, error_message) # pscharge
      errors.add(:field_127, error_message) # chcharge
    end
  end

  def field_mapping_for_errors
    {
      lettype: [:field_11],
      tenancycode: [:field_13],
      postcode_known: %i[field_25 field_23 field_24],
      postcode_full: %i[field_25 field_23 field_24],
      la: %i[field_25],
      owning_organisation: [:field_1],
      managing_organisation: [:field_2],
      owning_organisation_id: [:field_1],
      managing_organisation_id: [:field_2],
      renewal: [:field_7],
      scheme_id: (:field_5.present? ? [:field_5] : nil),
      scheme: (:field_5.present? ? [:field_5] : nil),
      location_id: (:field_6.present? ? [:field_6] : nil),
      location: (:field_6.present? ? [:field_6] : nil),
      assigned_to: [:field_3],
      needstype: [:field_4],
      rent_type: %i[field_11],
      startdate: %i[field_8 field_9 field_10],
      unittype_gn: %i[field_26],
      builtype: %i[field_27],
      wchair: %i[field_28],
      beds: %i[field_29],
      joint: %i[field_37],
      startertenancy: %i[field_38],
      tenancy: %i[field_39],
      tenancyother: %i[field_40],
      tenancylength: %i[field_41],
      declaration: %i[field_15],

      age1_known: %i[field_42],
      age1: %i[field_42],
      age2_known: %i[field_48],
      age2: %i[field_48],
      age3_known: %i[field_52],
      age3: %i[field_52],
      age4_known: %i[field_56],
      age4: %i[field_56],
      age5_known: %i[field_60],
      age5: %i[field_60],
      age6_known: %i[field_64],
      age6: %i[field_64],
      age7_known: %i[field_68],
      age7: %i[field_68],
      age8_known: %i[field_72],
      age8: %i[field_72],

      sex1: %i[field_43],
      sex2: %i[field_49],
      sex3: %i[field_53],
      sex4: %i[field_57],
      sex5: %i[field_61],
      sex6: %i[field_65],
      sex7: %i[field_69],
      sex8: %i[field_73],

      ethnic_group: %i[field_44],
      ethnic: %i[field_44],
      nationality_all: %i[field_45],
      nationality_all_group: %i[field_45],

      relat2: %i[field_47],
      relat3: %i[field_51],
      relat4: %i[field_55],
      relat5: %i[field_59],
      relat6: %i[field_63],
      relat7: %i[field_67],
      relat8: %i[field_71],

      ecstat1: %i[field_46],
      ecstat2: %i[field_50],
      ecstat3: %i[field_54],
      ecstat4: %i[field_58],
      ecstat5: %i[field_62],
      ecstat6: %i[field_66],
      ecstat7: %i[field_70],
      ecstat8: %i[field_74],

      armedforces: %i[field_75],
      leftreg: %i[field_76],
      reservist: %i[field_77],
      preg_occ: %i[field_78],
      housingneeds: %i[field_78],

      illness: %i[field_85],

      layear: %i[field_96],
      waityear: %i[field_97],
      reason: %i[field_98],
      reasonother: %i[field_99],
      prevten: %i[field_100],
      homeless: %i[field_101],

      prevloc: %i[field_105],
      previous_la_known: %i[field_105],
      ppcodenk: %i[field_102],
      ppostcode_full: %i[field_103 field_104],

      reasonpref: %i[field_106],
      rp_homeless: %i[field_107],
      rp_insan_unsat: %i[field_108],
      rp_medwel: %i[field_109],
      rp_hardship: %i[field_110],
      rp_dontknow: %i[field_111],

      cbl: %i[field_112],
      cap: %i[field_113],
      chr: %i[field_114],
      accessible_register: %i[field_115],
      letting_allocation: %i[field_112 field_113 field_114 field_115],

      referral: %i[field_116],

      net_income_known: %i[field_117],
      incfreq: %i[field_118],
      earnings: %i[field_119],
      hb: %i[field_120],
      benefits: %i[field_121],

      period: %i[field_123],
      brent: %i[field_124],
      scharge: %i[field_125],
      pscharge: %i[field_126],
      supcharg: %i[field_127],
      tcharge: %i[field_124 field_125 field_126 field_127],
      household_charge: %i[field_122],
      hbrentshortfall: %i[field_128],
      tshortfall: %i[field_129],

      unitletas: %i[field_17],
      rsnvac: %i[field_16],
      sheltered: %i[field_36],

      illness_type_1: %i[field_94],
      illness_type_2: %i[field_88],
      illness_type_3: %i[field_91],
      illness_type_4: %i[field_86],
      illness_type_5: %i[field_87],
      illness_type_6: %i[field_89],
      illness_type_7: %i[field_90],
      illness_type_8: %i[field_93],
      illness_type_9: %i[field_92],
      illness_type_10: %i[field_95],

      irproduct_other: %i[field_12],

      propcode: %i[field_14],

      majorrepairs: %i[field_33 field_34 field_35],
      mrcdate: %i[field_33 field_34 field_35],

      voiddate: %i[field_30 field_31 field_32],

      uprn: [:field_18],
      address_line1: [:field_19],
      address_line2: [:field_20],
      town_or_city: [:field_21],
      county: [:field_22],
      uprn_selection: [:field_19],
    }.compact
  end

  def attribute_set
    @attribute_set ||= instance_variable_get(:@attributes)
  end

  def questions
    @questions ||= log.form.subsections.flat_map { |ss| ss.applicable_questions(log) }
  end

  def attributes_for_log
    attributes = {}

    attributes["lettype"] = nil # should get this from rent_type
    attributes["tenancycode"] = field_13
    attributes["owning_organisation"] = owning_organisation
    attributes["managing_organisation"] = managing_organisation
    attributes["renewal"] = renewal
    attributes["scheme"] = scheme
    attributes["location"] = location
    attributes["assigned_to"] = assigned_to || (bulk_upload.user.support? ? nil : bulk_upload.user)
    attributes["created_by"] = bulk_upload.user
    attributes["needstype"] = field_4
    attributes["rent_type"] = RENT_TYPE_BU_MAPPING[field_11]
    attributes["startdate"] = startdate
    attributes["unittype_gn"] = field_26
    attributes["builtype"] = field_27
    attributes["wchair"] = field_28
    attributes["beds"] = field_26 == 2 ? 1 : field_29
    attributes["joint"] = field_37
    attributes["startertenancy"] = field_38
    attributes["tenancy"] = field_39
    attributes["tenancyother"] = field_40
    attributes["tenancylength"] = field_41
    attributes["declaration"] = field_15

    attributes["age1_known"] = age1_known?
    attributes["age1"] = field_42 if attributes["age1_known"]&.zero? && field_42&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["age2_known"] = age2_known?
    attributes["age2"] = field_48 if attributes["age2_known"]&.zero? && field_48&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["age3_known"] = age3_known?
    attributes["age3"] = field_52 if attributes["age3_known"]&.zero? && field_52&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["age4_known"] = age4_known?
    attributes["age4"] = field_56 if attributes["age4_known"]&.zero? && field_56&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["age5_known"] = age5_known?
    attributes["age5"] = field_60 if attributes["age5_known"]&.zero? && field_60&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["age6_known"] = age6_known?
    attributes["age6"] = field_64 if attributes["age6_known"]&.zero? && field_64&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["age7_known"] = age7_known?
    attributes["age7"] = field_68 if attributes["age7_known"]&.zero? && field_68&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["age8_known"] = age8_known?
    attributes["age8"] = field_72 if attributes["age8_known"]&.zero? && field_72&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["sex1"] = field_43
    attributes["sex2"] = field_49
    attributes["sex3"] = field_53
    attributes["sex4"] = field_57
    attributes["sex5"] = field_61
    attributes["sex6"] = field_65
    attributes["sex7"] = field_69
    attributes["sex8"] = field_73

    attributes["ethnic_group"] = ethnic_group_from_ethnic
    attributes["ethnic"] = field_44
    attributes["nationality_all"] = field_45 if field_45.present? && valid_nationality_options.include?(field_45.to_s)
    attributes["nationality_all_group"] = nationality_group(attributes["nationality_all"])

    attributes["relat2"] = relationship_from_input_value(field_47)
    attributes["relat3"] = relationship_from_input_value(field_51)
    attributes["relat4"] = relationship_from_input_value(field_55)
    attributes["relat5"] = relationship_from_input_value(field_59)
    attributes["relat6"] = relationship_from_input_value(field_63)
    attributes["relat7"] = relationship_from_input_value(field_67)
    attributes["relat8"] = relationship_from_input_value(field_71)

    attributes["ecstat1"] = field_46
    attributes["ecstat2"] = field_50
    attributes["ecstat3"] = field_54
    attributes["ecstat4"] = field_58
    attributes["ecstat5"] = field_62
    attributes["ecstat6"] = field_66
    attributes["ecstat7"] = field_70
    attributes["ecstat8"] = field_74

    attributes["details_known_2"] = details_known?(2)
    attributes["details_known_3"] = details_known?(3)
    attributes["details_known_4"] = details_known?(4)
    attributes["details_known_5"] = details_known?(5)
    attributes["details_known_6"] = details_known?(6)
    attributes["details_known_7"] = details_known?(7)
    attributes["details_known_8"] = details_known?(8)

    attributes["armedforces"] = field_75
    attributes["leftreg"] = leftreg
    attributes["reservist"] = field_77

    attributes["preg_occ"] = field_78

    attributes["housingneeds"] = housingneeds
    attributes["housingneeds_type"] = housingneeds_type
    attributes["housingneeds_other"] = housingneeds_other

    attributes["illness"] = field_85

    attributes["layear"] = field_96
    attributes["waityear"] = field_97
    attributes["reason"] = field_98
    attributes["reasonother"] = field_99 if reason_is_other?
    attributes["prevten"] = field_100
    attributes["homeless"] = field_101

    attributes["prevloc"] = prevloc
    attributes["previous_la_known"] = previous_la_known
    attributes["ppcodenk"] = ppcodenk
    attributes["ppostcode_full"] = ppostcode_full

    attributes["reasonpref"] = field_106
    attributes["rp_homeless"] = field_107
    attributes["rp_insan_unsat"] = field_108
    attributes["rp_medwel"] = field_109
    attributes["rp_hardship"] = field_110
    attributes["rp_dontknow"] = field_111

    attributes["cbl"] = cbl
    attributes["chr"] = chr
    attributes["cap"] = cap
    attributes["accessible_register"] = accessible_register
    attributes["letting_allocation_unknown"] = letting_allocation_unknown

    attributes["referral"] = field_116

    attributes["net_income_known"] = net_income_known
    attributes["earnings"] = earnings
    attributes["incfreq"] = field_118
    attributes["hb"] = field_120
    attributes["benefits"] = field_121

    attributes["period"] = field_123
    attributes["brent"] = field_124 if all_charges_given?
    attributes["scharge"] = field_125 if all_charges_given?
    attributes["pscharge"] = field_126 if all_charges_given?
    attributes["supcharg"] = field_127 if all_charges_given?
    attributes["household_charge"] = supported_housing? ? field_122 : nil
    attributes["hbrentshortfall"] = field_128
    attributes["tshortfall_known"] = tshortfall_known
    attributes["tshortfall"] = field_129

    attributes["hhmemb"] = hhmemb

    attributes["unitletas"] = field_17
    attributes["rsnvac"] = rsnvac
    attributes["sheltered"] = field_36

    attributes["illness_type_1"] = field_94
    attributes["illness_type_2"] = field_88
    attributes["illness_type_3"] = field_91
    attributes["illness_type_4"] = field_86
    attributes["illness_type_5"] = field_87
    attributes["illness_type_6"] = field_89
    attributes["illness_type_7"] = field_90
    attributes["illness_type_8"] = field_93
    attributes["illness_type_9"] = field_92
    attributes["illness_type_10"] = field_95

    attributes["irproduct_other"] = field_12

    attributes["propcode"] = field_14

    attributes["majorrepairs"] = majorrepairs

    attributes["mrcdate"] = mrcdate

    attributes["voiddate"] = voiddate

    attributes["first_time_property_let_as_social_housing"] = first_time_property_let_as_social_housing

    if general_needs?
      attributes["uprn_known"] = field_18.present? ? 1 : 0
      attributes["uprn_confirmed"] = 1 if field_18.present?
      attributes["skip_update_uprn_confirmed"] = true
      attributes["uprn"] = field_18
      attributes["address_line1"] = field_19
      attributes["address_line1_as_entered"] = field_19
      attributes["address_line2"] = field_20
      attributes["address_line2_as_entered"] = field_20
      attributes["town_or_city"] = field_21
      attributes["town_or_city_as_entered"] = field_21
      attributes["county"] = field_22
      attributes["county_as_entered"] = field_22
      attributes["postcode_full"] = postcode_full
      attributes["postcode_full_as_entered"] = postcode_full
      attributes["postcode_known"] = postcode_known
      attributes["la"] = field_25
      attributes["la_as_entered"] = field_25

      attributes["address_line1_input"] = address_line1_input
      attributes["postcode_full_input"] = postcode_full
      attributes["select_best_address_match"] = true if field_18.blank?
    end

    attributes
  end

  def address_line1_input
    [field_19, field_20, field_21].compact.join(", ")
  end

  def postcode_known
    if postcode_full.present?
      1
    elsif field_25.present?
      0
    end
  end

  def postcode_full
    [field_23, field_24].compact_blank.join(" ") if field_23 || field_24
  end

  def owning_organisation
    Organisation.find_by_id_on_multiple_fields(field_1)
  end

  def managing_organisation
    Organisation.find_by_id_on_multiple_fields(field_2)
  end

  def renewal
    case field_7
    when 1
      1
    when 2
      0
    else
      field_7
    end
  end

  def rsnvac
    field_16
  end

  def scheme
    return if field_5.nil? || owning_organisation.nil? || managing_organisation.nil?

    @scheme ||= Scheme.where(id: (owning_organisation.owned_schemes + managing_organisation.owned_schemes).map(&:id)).find_by_id_on_multiple_fields(field_5.strip, field_6)
  end

  def location
    return if scheme.nil?

    @location ||= scheme.locations.find_by_id_on_multiple_fields(field_6)
  end

  def startdate
    year = field_10.to_s.strip.length.between?(1, 2) ? field_10 + 2000 : field_10
    Date.new(year, field_9, field_8) if field_10.present? && field_9.present? && field_8.present?
  rescue Date::Error
    Date.new
  end

  def ethnic_group_from_ethnic
    return nil if field_44.blank?

    case field_44
    when 1, 2, 3, 18, 20
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

  def age1_known?
    return 1 if field_42 == "R"

    0
  end

  [
    { person: 2, field: :field_48 },
    { person: 3, field: :field_52 },
    { person: 4, field: :field_56 },
    { person: 5, field: :field_60 },
    { person: 6, field: :field_64 },
    { person: 7, field: :field_68 },
    { person: 8, field: :field_72 },
  ].each do |hash|
    define_method("age#{hash[:person]}_known?") do
      return 1 if public_send(hash[:field]) == "R"
      return 0 if send("person_#{hash[:person]}_present?")
    end
  end

  def details_known?(person_n)
    send("person_#{person_n}_present?") ? 0 : 1
  end

  def person_2_present?
    field_47.present? || field_48.present? || field_49.present?
  end

  def person_3_present?
    field_51.present? || field_52.present? || field_53.present?
  end

  def person_4_present?
    field_55.present? || field_56.present? || field_57.present?
  end

  def person_5_present?
    field_59.present? || field_60.present? || field_61.present?
  end

  def person_6_present?
    field_63.present? || field_64.present? || field_65.present?
  end

  def person_7_present?
    field_67.present? || field_68.present? || field_69.present?
  end

  def person_8_present?
    field_71.present? || field_72.present? || field_73.present?
  end

  def leftreg
    field_76
  end

  def housingneeds
    if field_83 == 1
      2
    elsif field_84 == 1
      3
    elsif field_83.blank? || field_83&.zero?
      1
    end
  end

  def housingneeds_type
    if field_79 == 1
      0
    elsif field_80 == 1
      1
    elsif field_81 == 1
      2
    else
      3
    end
  end

  def housingneeds_other
    return 1 if field_82 == 1
    return 0 if [field_79, field_80, field_81].include?(1)
  end

  def prevloc
    field_105
  end

  def previous_la_known
    prevloc.present? ? 1 : 0
  end

  def ppcodenk
    case field_102
    when 1
      0
    when 2
      1
    end
  end

  def ppostcode_full
    "#{field_103} #{field_104}".strip.gsub(/\s+/, " ")
  end

  def cbl
    case field_112
    when 2
      0
    when 1
      1
    end
  end

  def cap
    case field_113
    when 2
      0
    when 1
      1
    end
  end

  def chr
    case field_114
    when 2
      0
    when 1
      1
    end
  end

  def accessible_register
    case field_115
    when 2
      0
    when 1
      1
    end
  end

  def letting_allocation_unknown
    [cbl, chr, cap, accessible_register].all?(0) ? 1 : 0
  end

  def net_income_known
    case field_117
    when 1
      0
    when 2
      1
    when 3
      2
    end
  end

  def earnings
    field_119.round if field_119.present?
  end

  def tshortfall_known
    field_128 == 1 ? 0 : 1
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

  def majorrepairs
    mrcdate.present? ? 1 : 0
  end

  def mrcdate
    year = field_35.to_s.strip.length.between?(1, 2) ? field_35 + 2000 : field_35
    Date.new(year, field_34, field_33) if field_35.present? && field_34.present? && field_33.present?
  rescue Date::Error
    Date.new
  end

  def voiddate
    year = field_32.to_s.strip.length.between?(1, 2) ? field_32 + 2000 : field_32
    Date.new(year, field_31, field_30) if field_32.present? && field_31.present? && field_30.present?
  rescue Date::Error
    Date.new
  end

  def first_time_property_let_as_social_housing
    case rsnvac
    when 15, 16, 17
      1
    else
      0
    end
  end

  def valid_nationality_options
    %w[0] + GlobalConstants::COUNTRIES_ANSWER_OPTIONS.keys # 0 is "Prefers not to say"
  end

  def nationality_group(nationality_value)
    return unless nationality_value
    return 0 if nationality_value.zero?
    return 826 if nationality_value == 826

    12
  end

  def reason_is_other?
    field_98 == 20
  end

  def bulk_upload_organisation
    Organisation.find(bulk_upload.organisation_id)
  end

  def relationship_from_input_value(value)
    case value
    when 1
      "P" # yes
    when 2
      "X" # no
    when 3
      "R" # refused
    end
  end
end
