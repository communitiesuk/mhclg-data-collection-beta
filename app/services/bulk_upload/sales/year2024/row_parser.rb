class BulkUpload::Sales::Year2024::RowParser
  include ActiveModel::Model
  include ActiveModel::Attributes
  include InterruptionScreenHelper
  include FormattingHelper

  QUESTIONS = {
    field_1: "Which organisation owned this property before the sale?",
    field_2: "Which organisation is reporting this sale?",
    field_3: "Username",
    field_4: "What is the day of the sale completion date? - DD",
    field_5: "What is the month of the sale completion date? - MM",
    field_6: "What is the year of the sale completion date? - YY",
    field_7: "What is the purchaser code?",
    field_8: "Was this purchase made through an ownership scheme?",
    field_9: "What is the type of shared ownership sale?",
    field_10: "What is the type of discounted ownership sale?",
    field_11: "What is the type of outright sale?",

    field_12: "If 'other', what is the 'other' type?",
    field_13: "Is the buyer a company?",
    field_14: "Will the buyers live in the property?",
    field_15: "Is this a joint purchase?",
    field_16: "Are there more than two joint purchasers of this property?",
    field_17: "Was the buyer interviewed for any of the answers you will provide on this log?",
    field_18: "Data Protection question",
    field_19: "How many bedrooms does the property have?",
    field_20: "What type of unit is the property?",
    field_21: "Which type of bulding is the property?",
    field_22: "If known, enter this property's UPRN",
    field_23: "Address line 1",

    field_24: "Address line 2",
    field_25: "Town or city",
    field_26: "County",
    field_27: "Part 1 of postcode of property",
    field_28: "Part 2 of postcode of property",
    field_29: "What is the local authority of the property?",
    field_30: "Is the property built or adapted to wheelchair user standards?",
    field_31: "Age of buyer 1",

    field_32: "Gender identity of buyer 1",
    field_33: "What is buyer 1's ethnic group?",
    field_34: "What is buyer 1's nationality?",
    field_35: "Working situation of buyer 1",
    field_36: "Will buyer 1 live in the property?",
    field_37: "Relationship to buyer 1 for person 2",
    field_38: "Age of person 2",
    field_39: "Gender identity of person 2",
    field_40: "Which of the following best describes buyer 2's ethnic background?",

    field_41: "What is buyer 2's nationality?",
    field_42: "What is buyer 2 or person 2's working situation?",
    field_43: "Will buyer 2 live in the property?",
    field_44: "Besides the buyers, how many people will live in the property?",
    field_45: "Relationship to buyer 1 for person 3",
    field_46: "Age of person 3",
    field_47: "Gender identity of person 3",
    field_48: "Working situation of person 3",
    field_49: "Relationship to buyer 1 for person 4",

    field_50: "Age of person 4",
    field_51: "Gender identity of person 4",
    field_52: "Working situation of person 4",
    field_53: "Relationship to buyer 1 for person 5",
    field_54: "Age of person 5",
    field_55: "Gender identity of person 5",
    field_56: "Working situation of person 5",
    field_57: "Relationship to buyer 1 for person 6",
    field_58: "Age of person 6",
    field_59: "Gender identity of person 6",

    field_60: "Working situation of person 6",
    field_61: "What was buyer 1's previous tenure?",
    field_62: "Do you know the postcode of buyer 1's last settled home?",
    field_63: "Part 1 of postcode of buyer 1's last settled home",
    field_64: "Part 2 of postcode of buyer 1's last settled home",
    field_65: "What is the local authority of buyer 1's last settled home?",
    field_66: "Was the buyer registered with their PRP (HA)?",
    field_67: "Was the buyer registered with another PRP (HA)?",
    field_68: "Was the buyer registered with the local authority?",
    field_69: "Was the buyer registered with a Help to Buy agent?",

    field_70: "At the time of purchase, was buyer 2 living at the same address as buyer 1?",
    field_71: "What was buyer 2's previous tenure?",
    field_72: "Has the buyer ever served in the UK Armed Forces and for how long?",
    field_73: "Is the buyer still serving in the UK armed forces?",
    field_74: "Are any of the buyers a spouse or civil partner of a UK Armed Forces regular who died in service within the last 2 years?",
    field_75: "Does anyone in the household consider themselves to have a disability?",
    field_76: "Does anyone in the household use a wheelchair?",
    field_77: "What is buyer 1's gross annual income?",
    field_78: "Was buyer 1's income used for a mortgage application?",
    field_79: "What is buyer 2's gross annual income?",

    field_80: "Was buyer 2's income used for a mortgage application?",
    field_81: "Were the buyers receiving any of these housing-related benefits immediately before buying this property?",
    field_82: "What is the total amount the buyers had in savings before they paid any deposit for the property?",
    field_83: "Have any of the purchasers previously owned a property?",
    field_84: "Was the previous property under shared ownership?",
    field_85: "How long have the buyers been living in the property before the purchase? - Shared ownership",
    field_86: "Is this a staircasing transaction?",
    field_87: "What percentage of the property has been bought in this staircasing transaction?",
    field_88: "What percentage of the property does the buyer now own in total?",
    field_89: "Was this transaction part of a back-to-back staircasing transaction to facilitate sale of the home on the open market?",

    field_90: "Is this a resale?",
    field_91: "What is the day of the exchange of contracts date?",
    field_92: "What is the month of the exchange of contracts date?",
    field_93: "What is the year of the exchange of contracts date?",
    field_94: "What is the day of the practical completion or handover date?",
    field_95: "What is the month of the practical completion or handover date?",
    field_96: "What is the year of the practical completion or handover date?",
    field_97: "Was the household re-housed under a local authority nominations agreement?",
    field_98: "How many bedrooms did the buyer's previous property have?",

    field_99: "What was the type of the buyer's previous property?",
    field_100: "What was the rent type of the buyer's previous property?",
    field_101: "What was the full purchase price?",
    field_102: "What was the initial percentage equity stake purchased?",
    field_103: "Was a mortgage used for the purchase of this property? - Shared ownership",
    field_104: "What is the mortgage amount?",
    field_105: "What is the name of the mortgage lender? - Shared ownership",
    field_106: "If 'other', what is the name of the mortgage lender?",
    field_107: "What is the length of the mortgage in years? - Shared ownership",
    field_108: "Does this include any extra borrowing?",

    field_109: "How much was the cash deposit paid on the property?",
    field_110: "How much cash discount was given through Social Homebuy?",
    field_111: "What is the basic monthly rent?",
    field_112: "What are the total monthly leasehold charges for the property?",
    field_113: "How long have the buyers been living in the property before the purchase? - Discounted ownership",
    field_114: "What was the full purchase price?",
    field_115: "What was the amount of any loan, grant, discount or subsidy given?",
    field_116: "What was the percentage discount?",
    field_117: "Was a mortgage used for the purchase of this property? - Discounted ownership",
    field_118: "What is the mortgage amount?",

    field_119: "What is the name of the mortgage lender? - Discounted ownership",
    field_120: "If 'other', what is the name of the mortgage lender?",
    field_121: "What is the length of the mortgage in years? - Discounted ownership",
    field_122: "Does this include any extra borrowing?",
    field_123: "How much was the cash deposit paid on the property?",
    field_124: "What are the total monthly leasehold charges for the property?",
    field_125: "What is the full purchase price?",
    field_126: "Was a mortgage used for the purchase of this property? - Outright sale",
    field_127: "What is the mortgage amount?",

    field_128: "What is the length of the mortgage in years? - Outright sale",
    field_129: "Does this include any extra borrowing?",
    field_130: "How much was the cash deposit paid on the property?",
    field_131: "What are the total monthly leasehold charges for the property?",
  }.freeze

  ERROR_BASE_KEY = "validations.sales.2024.bulk_upload".freeze

  attribute :bulk_upload
  attribute :block_log_creation, :boolean, default: -> { false }

  attribute :field_blank

  attribute :field_1, :string
  attribute :field_2, :string
  attribute :field_3, :string
  attribute :field_4, :integer
  attribute :field_5, :integer
  attribute :field_6, :integer
  attribute :field_7, :string
  attribute :field_8, :integer
  attribute :field_9, :integer
  attribute :field_10, :integer
  attribute :field_11, :integer

  attribute :field_12, :string
  attribute :field_13, :integer
  attribute :field_14, :integer
  attribute :field_15, :integer
  attribute :field_16, :integer
  attribute :field_17, :integer
  attribute :field_18, :integer
  attribute :field_19, :integer
  attribute :field_20, :integer
  attribute :field_21, :integer
  attribute :field_22, :string
  attribute :field_23, :string

  attribute :field_24, :string
  attribute :field_25, :string
  attribute :field_26, :string
  attribute :field_27, :string
  attribute :field_28, :string
  attribute :field_29, :string
  attribute :field_30, :integer
  attribute :field_31, :string

  attribute :field_32, :string
  attribute :field_33, :integer
  attribute :field_34, :integer
  attribute :field_35, :integer
  attribute :field_36, :integer
  attribute :field_37, :string
  attribute :field_38, :string
  attribute :field_39, :string
  attribute :field_40, :integer

  attribute :field_41, :integer
  attribute :field_42, :integer
  attribute :field_43, :integer
  attribute :field_44, :integer
  attribute :field_45, :string
  attribute :field_46, :string
  attribute :field_47, :string
  attribute :field_48, :integer
  attribute :field_49, :string

  attribute :field_50, :string
  attribute :field_51, :string
  attribute :field_52, :integer
  attribute :field_53, :string
  attribute :field_54, :string
  attribute :field_55, :string
  attribute :field_56, :integer
  attribute :field_57, :string
  attribute :field_58, :string
  attribute :field_59, :string

  attribute :field_60, :integer
  attribute :field_61, :integer
  attribute :field_62, :integer
  attribute :field_63, :string
  attribute :field_64, :string
  attribute :field_65, :string
  attribute :field_66, :integer
  attribute :field_67, :integer
  attribute :field_68, :integer
  attribute :field_69, :integer

  attribute :field_70, :integer
  attribute :field_71, :string
  attribute :field_72, :integer
  attribute :field_73, :integer
  attribute :field_74, :integer
  attribute :field_75, :integer
  attribute :field_76, :integer
  attribute :field_77, :string
  attribute :field_78, :integer
  attribute :field_79, :string

  attribute :field_80, :integer
  attribute :field_81, :integer
  attribute :field_82, :string
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

  attribute :field_99, :integer
  attribute :field_100, :integer
  attribute :field_101, :integer
  attribute :field_102, :integer
  attribute :field_103, :integer
  attribute :field_104, :integer
  attribute :field_105, :integer
  attribute :field_106, :string
  attribute :field_107, :integer
  attribute :field_108, :integer

  attribute :field_109, :integer
  attribute :field_110, :integer
  attribute :field_111, :decimal
  attribute :field_112, :decimal
  attribute :field_113, :integer
  attribute :field_114, :integer
  attribute :field_115, :integer
  attribute :field_116, :integer
  attribute :field_117, :integer
  attribute :field_118, :integer

  attribute :field_119, :integer
  attribute :field_120, :string
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
  attribute :field_131, :integer

  validates :field_4,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "sale completion date (day)."),
              category: :setup,
            },
            on: :after_log

  validates :field_5,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "sale completion date (month)."),
              category: :setup,
            }, on: :after_log

  validates :field_6,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "sale completion date (year)."),
              category: :setup,
            },
            format: {
              with: /\A(\d{2}|\d{4})\z/,
              message: I18n.t("#{ERROR_BASE_KEY}.saledate.year_not_two_or_four_digits"),
              category: :setup,
              if: proc { field_6.present? },
            }, on: :after_log

  validates :field_8,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "purchase made under ownership scheme."),
              category: :setup,
            },
            on: :after_log

  validates :field_9,
            inclusion: {
              in: [2, 30, 18, 16, 24, 28, 31, 32],
              if: proc { field_9.present? },
              category: :setup,
              question: QUESTIONS[:field_9].downcase,
            },
            on: :before_log

  validates :field_9,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "type of shared ownership sale."),
              category: :setup,
              if: :shared_ownership?,
            },
            on: :after_log

  validates :field_10,
            inclusion: {
              in: [8, 14, 27, 9, 29, 21, 22],
              if: proc { field_10.present? },
              category: :setup,
              question: QUESTIONS[:field_10].downcase,
            },
            on: :before_log

  validates :field_10,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "type of discounted ownership sale."),
              category: :setup,
              if: :discounted_ownership?,
            },
            on: :after_log

  validates :field_116,
            numericality: {
              message: I18n.t("#{ERROR_BASE_KEY}.numeric.within_range", field: "Percentage discount", min: "0%", max: "70%"),
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 70,
              if: :discounted_ownership?,
              allow_blank: true,
            },
            on: :before_log

  validates :field_11,
            inclusion: {
              in: [10, 12],
              if: proc { field_11.present? },
              category: :setup,
              question: QUESTIONS[:field_11].downcase,
            },
            on: :before_log

  validates :field_11,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "type of outright sale."),
              category: :setup,
              if: :outright_sale?,
            },
            on: :after_log

  validates :field_12,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "type of outright sale."),
              category: :setup,
              if: proc { field_11 == 12 },
            },
            on: :after_log

  validates :field_13,
            inclusion: {
              in: [1, 2],
              if: proc { outright_sale? && field_13.present? },
              category: :setup,
              question: QUESTIONS[:field_13].downcase,
            },
            on: :before_log

  validates :field_13,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "company buyer."),
              category: :setup,
              if: :outright_sale?,
            },
            on: :after_log

  validates :field_14,
            inclusion: {
              in: [1, 2],
              if: proc { outright_sale? && field_14.present? },
              category: :setup,
              question: QUESTIONS[:field_14].downcase,
            },
            on: :before_log

  validates :field_14,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "buyers living in property."),
              category: :setup,
              if: :outright_sale?,
            },
            on: :after_log

  validates :field_15,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "joint purchase."),
              category: :setup,
              if: :joint_purchase_asked?,
            },
            on: :after_log

  validates :field_16,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "more than 2 joint buyers."),
              category: :setup,
              if: :joint_purchase?,
            },
            on: :after_log

  validate :validate_buyer1_economic_status, on: :before_log
  validate :validate_address_option_found, on: :after_log
  validate :validate_buyer2_economic_status, on: :before_log
  validate :validate_valid_radio_option, on: :before_log

  validate :validate_owning_org_data_given, on: :after_log
  validate :validate_owning_org_exists, on: :after_log
  validate :validate_owning_org_owns_stock, on: :after_log
  validate :validate_owning_org_permitted, on: :after_log

  validate :validate_assigned_to_exists, on: :after_log
  validate :validate_assigned_to_related, on: :after_log
  validate :validate_assigned_to_when_support, on: :after_log
  validate :validate_managing_org_related, on: :after_log
  validate :validate_relevant_collection_window, on: :after_log
  validate :validate_incomplete_soft_validations, on: :after_log

  validate :validate_uprn_exists_if_any_key_address_fields_are_blank, on: :after_log
  validate :validate_address_fields, on: :after_log
  validate :validate_if_log_already_exists, on: :after_log, if: -> { FeatureToggle.bulk_upload_duplicate_log_check_enabled? }

  validate :validate_nationality, on: :after_log
  validate :validate_buyer_2_nationality, on: :after_log

  validate :validate_nulls, on: :after_log

  def self.question_for_field(field)
    QUESTIONS[field]
  end

  def attribute_set
    @attribute_set ||= instance_variable_get(:@attributes)
  end

  def blank_row?
    attribute_set
      .to_hash
      .reject { |k, _| %w[bulk_upload block_log_creation].include?(k) }
      .values
      .reject(&:blank?)
      .compact
      .empty?
  end

  def log
    @log ||= SalesLog.new(attributes_for_log)
  end

  def valid?
    errors.clear

    return true if blank_row?

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

    errors.blank?
  end

  def block_log_creation?
    block_log_creation
  end

  def inspect
    "#<BulkUpload::Sales::Year2024::RowParser:#{object_id}>"
  end

  def log_already_exists?
    return false if blank_row?

    @log_already_exists ||= SalesLog
      .where(status: %w[not_started in_progress completed])
      .exists?(duplicate_check_fields.index_with { |field| log.public_send(field) })
  end

  def purchaser_code
    field_7
  end

  def spreadsheet_duplicate_hash
    attributes.slice(
      "field_1",  # owning org
      "field_4",  # saledate
      "field_5",  # saledate
      "field_6",  # saledate
      "field_7",  # purchaser_code
      "field_27", # postcode
      "field_28", # postcode
      "field_31", # age1
      "field_32", # sex1
      "field_35", # ecstat1
    )
  end

  def add_duplicate_found_in_spreadsheet_errors
    spreadsheet_duplicate_hash.each_key do |field|
      errors.add(field, I18n.t("#{ERROR_BASE_KEY}.spreadsheet_dupe"), category: :setup)
    end
  end

private

  def prevtenbuy2
    case field_71
    when "R"
      0
    else
      field_71
    end
  end

  def infer_buyer2_ethnic_group_from_ethnic
    case field_40
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
    else
      field_40
    end
  end

  def validate_uprn_exists_if_any_key_address_fields_are_blank
    if field_22.blank? && !key_address_fields_provided?
      %i[field_23 field_25 field_27 field_28].each do |field|
        errors.add(field, I18n.t("#{ERROR_BASE_KEY}.address.not_answered")) if send(field).blank?
      end
      errors.add(:field_22, I18n.t("#{ERROR_BASE_KEY}.address.not_answered", question: "UPRN."))
    end
  end

  def validate_address_option_found
    if log.uprn.nil? && field_22.blank? && key_address_fields_provided?
      error_message = if log.address_options_present? && log.address_options.size > 1
                        I18n.t("#{ERROR_BASE_KEY}.address.not_determined.multiple")
                      elsif log.address_options_present?
                        I18n.t("#{ERROR_BASE_KEY}.address.not_determined.one")
                      else
                        I18n.t("#{ERROR_BASE_KEY}.address.not_found")
                      end
      %i[field_23 field_24 field_25 field_26 field_27 field_28].each do |field|
        errors.add(field, error_message) if errors[field].blank?
      end
    end
  end

  def key_address_fields_provided?
    field_23.present? && field_25.present? && postcode_full.present?
  end

  def validate_address_fields
    if field_22.blank? || log.errors.attribute_names.include?(:uprn)
      if field_23.blank? && errors[:field_23].blank?
        errors.add(:field_23, I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "address line 1."))
      end

      if field_25.blank? && errors[:field_25].blank?
        errors.add(:field_25, I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "town or city."))
      end

      if field_27.blank? && errors[:field_27].blank?
        errors.add(:field_27, I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "part 1 of postcode."))
      end

      if field_28.blank? && errors[:field_28].blank?
        errors.add(:field_28, I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "part 2 of postcode."))
      end
    end
  end

  def shared_ownership?
    field_8 == 1
  end

  def discounted_ownership?
    field_8 == 2
  end

  def outright_sale?
    field_8 == 3
  end

  def joint_purchase?
    field_15 == 1
  end

  def joint_purchase_asked?
    shared_ownership? || discounted_ownership? || field_13 == 2
  end

  def field_mapping_for_errors
    {
      purchid: %i[field_7],
      saledate: %i[field_4 field_5 field_6],
      noint: %i[field_17],
      age1_known: %i[field_31],
      age1: %i[field_31],
      age2_known: %i[field_38],
      age2: %i[field_38],
      age3_known: %i[field_46],
      age3: %i[field_46],
      age4_known: %i[field_50],
      age4: %i[field_50],
      age5_known: %i[field_54],
      age5: %i[field_54],
      age6_known: %i[field_58],
      age6: %i[field_58],
      sex1: %i[field_32],
      sex2: %i[field_39],
      sex3: %i[field_47],

      sex4: %i[field_51],
      sex5: %i[field_55],
      sex6: %i[field_59],
      relat2: %i[field_37],
      relat3: %i[field_45],
      relat4: %i[field_49],
      relat5: %i[field_53],
      relat6: %i[field_57],

      ecstat1: %i[field_35],
      ecstat2: %i[field_42],
      ecstat3: %i[field_48],

      ecstat4: %i[field_52],
      ecstat5: %i[field_56],
      ecstat6: %i[field_60],
      ethnic_group: %i[field_33],
      ethnic: %i[field_33],
      nationality_all: %i[field_34],
      nationality_all_group: %i[field_34],
      income1nk: %i[field_77],
      income1: %i[field_77],
      income2nk: %i[field_79],
      income2: %i[field_79],
      inc1mort: %i[field_78],
      inc2mort: %i[field_80],
      savingsnk: %i[field_82],
      savings: %i[field_82],
      prevown: %i[field_83],
      prevten: %i[field_61],
      prevloc: %i[field_65],
      previous_la_known: %i[field_65],
      ppcodenk: %i[field_62],
      ppostcode_full: %i[field_63 field_64],
      pregyrha: %i[field_66],
      pregla: %i[field_68],
      pregghb: %i[field_69],
      pregother: %i[field_67],
      disabled: %i[field_75],

      wheel: %i[field_76],
      beds: %i[field_19],
      proptype: %i[field_20],
      builtype: %i[field_21],
      la_known: %i[field_29],
      la: %i[field_29],

      is_la_inferred: %i[field_29],
      pcodenk: %i[field_27 field_28],
      postcode_full: %i[field_27 field_28],
      wchair: %i[field_30],

      type: %i[field_9 field_10 field_11 field_8],
      resale: %i[field_90],
      hodate: %i[field_94 field_95 field_96],
      exdate: %i[field_91 field_92 field_93],

      lanomagr: %i[field_97],
      frombeds: %i[field_98],
      fromprop: %i[field_99],
      value: value_fields,
      equity: %i[field_102],
      mortgage: mortgage_fields,
      extrabor: extrabor_fields,
      deposit: deposit_fields,
      cashdis: %i[field_110],
      mrent: %i[field_111],

      has_mscharge: mscharge_fields,
      mscharge: mscharge_fields,
      grant: %i[field_115],
      discount: %i[field_116],
      othtype: %i[field_12],
      owning_organisation_id: %i[field_1],
      managing_organisation_id: [:field_2],
      assigned_to: %i[field_3],
      hhregres: %i[field_72],
      hhregresstill: %i[field_73],
      armedforcesspouse: %i[field_74],

      mortgagelender: mortgagelender_fields,
      mortgagelenderother: mortgagelenderother_fields,

      hb: %i[field_81],
      mortlen: mortlen_fields,
      proplen: proplen_fields,

      jointmore: %i[field_16],
      staircase: %i[field_86],
      privacynotice: %i[field_18],
      ownershipsch: %i[field_8],
      companybuy: %i[field_13],
      buylivein: %i[field_14],

      jointpur: %i[field_15],
      buy1livein: %i[field_36],
      buy2livein: %i[field_43],
      hholdcount: %i[field_44],
      stairbought: %i[field_87],
      stairowned: %i[field_88],
      socprevten: %i[field_100],
      mortgageused: mortgageused_fields,

      uprn: %i[field_22],
      address_line1: %i[field_23],
      address_line2: %i[field_24],
      town_or_city: %i[field_25],
      county: %i[field_26],
      uprn_selection: [:field_23],

      ethnic_group2: %i[field_40],
      ethnicbuy2: %i[field_40],
      nationality_all_buyer2: %i[field_41],
      nationality_all_buyer2_group: %i[field_41],

      buy2living: %i[field_70],
      prevtenbuy2: %i[field_71],

      prevshared: %i[field_84],

      staircasesale: %i[field_89],
    }
  end

  def attributes_for_log
    attributes = {}

    attributes["purchid"] = purchaser_code
    attributes["saledate"] = saledate
    attributes["noint"] = field_17

    attributes["age1_known"] = age1_known?
    attributes["age1"] = field_31 if attributes["age1_known"]&.zero? && field_31&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["age2_known"] = age2_known?
    attributes["age2"] = field_38 if attributes["age2_known"]&.zero? && field_38&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["age3_known"] = age3_known?
    attributes["age3"] = field_46 if attributes["age3_known"]&.zero? && field_46&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["age4_known"] = age4_known?
    attributes["age4"] = field_50 if attributes["age4_known"]&.zero? && field_50&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["age5_known"] = age5_known?
    attributes["age5"] = field_54 if attributes["age5_known"]&.zero? && field_54&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["age6_known"] = age6_known?
    attributes["age6"] = field_58 if attributes["age6_known"]&.zero? && field_58&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["sex1"] = field_32
    attributes["sex2"] = field_39
    attributes["sex3"] = field_47
    attributes["sex4"] = field_51
    attributes["sex5"] = field_55
    attributes["sex6"] = field_59

    attributes["relat2"] = field_37
    attributes["relat3"] = field_45
    attributes["relat4"] = field_49
    attributes["relat5"] = field_53
    attributes["relat6"] = field_57

    attributes["ecstat1"] = field_35
    attributes["ecstat2"] = field_42
    attributes["ecstat3"] = field_48
    attributes["ecstat4"] = field_52
    attributes["ecstat5"] = field_56
    attributes["ecstat6"] = field_60

    attributes["details_known_2"] = details_known?(2)
    attributes["details_known_3"] = details_known?(3)
    attributes["details_known_4"] = details_known?(4)
    attributes["details_known_5"] = details_known?(5)
    attributes["details_known_6"] = details_known?(6)

    attributes["ethnic_group"] = ethnic_group_from_ethnic
    attributes["ethnic"] = field_33
    attributes["nationality_all"] = field_34 if field_34.present? && valid_nationality_options.include?(field_34.to_s)
    attributes["nationality_all_group"] = nationality_group(attributes["nationality_all"])

    attributes["income1nk"] = field_77 == "R" ? 1 : 0
    attributes["income1"] = field_77.to_i if attributes["income1nk"]&.zero? && field_77&.match(/\A\d+\z/)

    attributes["income2nk"] = field_79 == "R" ? 1 : 0
    attributes["income2"] = field_79.to_i if attributes["income2nk"]&.zero? && field_79&.match(/\A\d+\z/)

    attributes["inc1mort"] = field_78
    attributes["inc2mort"] = field_80

    attributes["savingsnk"] = field_82 == "R" ? 1 : 0
    attributes["savings"] = field_82.to_i if attributes["savingsnk"]&.zero? && field_82&.match(/\A\d+\z/)
    attributes["prevown"] = field_83

    attributes["prevten"] = field_61
    attributes["prevloc"] = field_65
    attributes["previous_la_known"] = previous_la_known
    attributes["ppcodenk"] = previous_postcode_known
    attributes["ppostcode_full"] = ppostcode_full

    attributes["pregyrha"] = field_66
    attributes["pregla"] = field_68
    attributes["pregghb"] = field_69
    attributes["pregother"] = field_67
    attributes["pregblank"] = no_buyer_organisation

    attributes["disabled"] = field_75
    attributes["wheel"] = field_76
    attributes["beds"] = field_19
    attributes["proptype"] = field_20
    attributes["builtype"] = field_21
    attributes["la_known"] = field_29.present? ? 1 : 0
    attributes["la"] = field_29
    attributes["la_as_entered"] = field_29
    attributes["is_la_inferred"] = false
    attributes["pcodenk"] = 0 if postcode_full.present?
    attributes["postcode_full"] = postcode_full
    attributes["postcode_full_as_entered"] = postcode_full
    attributes["wchair"] = field_30

    attributes["type"] = sale_type
    attributes["resale"] = field_90

    attributes["hodate"] = hodate
    attributes["exdate"] = exdate

    attributes["lanomagr"] = field_97

    attributes["frombeds"] = field_98
    attributes["fromprop"] = field_99

    attributes["value"] = value
    attributes["equity"] = field_102
    attributes["mortgage"] = mortgage
    attributes["extrabor"] = extrabor
    attributes["deposit"] = deposit

    attributes["cashdis"] = field_110
    attributes["mrent"] = field_111
    attributes["mscharge"] = mscharge if mscharge&.positive?
    attributes["has_mscharge"] = attributes["mscharge"].present? ? 1 : 0
    attributes["grant"] = field_115
    attributes["discount"] = field_116

    attributes["othtype"] = field_12

    attributes["owning_organisation"] = owning_organisation
    attributes["managing_organisation"] = managing_organisation
    attributes["assigned_to"] = assigned_to || (bulk_upload.user.support? ? nil : bulk_upload.user)
    attributes["created_by"] = bulk_upload.user
    attributes["hhregres"] = field_72
    attributes["hhregresstill"] = field_73
    attributes["armedforcesspouse"] = field_74

    attributes["mortgagelender"] = mortgagelender
    attributes["mortgagelenderother"] = mortgagelenderother

    attributes["hb"] = field_81

    attributes["mortlen"] = mortlen

    attributes["proplen"] = proplen if proplen&.positive?
    attributes["proplen_asked"] = attributes["proplen"]&.present? ? 0 : 1
    attributes["jointmore"] = field_16
    attributes["staircase"] = field_86
    attributes["privacynotice"] = field_18
    attributes["ownershipsch"] = field_8
    attributes["companybuy"] = field_13
    attributes["buylivein"] = field_14
    attributes["jointpur"] = field_15
    attributes["buy1livein"] = field_36
    attributes["buy2livein"] = field_43
    attributes["hholdcount"] = field_44
    attributes["stairbought"] = field_87
    attributes["stairowned"] = field_88
    attributes["socprevten"] = field_100
    attributes["soctenant"] = infer_soctenant_from_prevten_and_prevtenbuy2
    attributes["mortgageused"] = mortgageused

    attributes["uprn"] = field_22
    attributes["uprn_known"] = field_22.present? ? 1 : 0
    attributes["uprn_confirmed"] = 1 if field_22.present?
    attributes["skip_update_uprn_confirmed"] = true
    attributes["address_line1"] = field_23
    attributes["address_line1_as_entered"] = field_23
    attributes["address_line2"] = field_24
    attributes["address_line2_as_entered"] = field_24
    attributes["town_or_city"] = field_25
    attributes["town_or_city_as_entered"] = field_25
    attributes["county"] = field_26
    attributes["county_as_entered"] = field_26
    attributes["address_line1_input"] = address_line1_input
    attributes["postcode_full_input"] = postcode_full
    attributes["select_best_address_match"] = true if field_22.blank?
    attributes["manual_address_entry_selected"] = field_22.blank?

    attributes["ethnic_group2"] = infer_buyer2_ethnic_group_from_ethnic
    attributes["ethnicbuy2"] = field_40
    attributes["nationality_all_buyer2"] = field_41 if field_41.present? && valid_nationality_options.include?(field_41.to_s)
    attributes["nationality_all_buyer2_group"] = nationality_group(attributes["nationality_all_buyer2"])

    attributes["buy2living"] = field_70
    attributes["prevtenbuy2"] = prevtenbuy2

    attributes["prevshared"] = field_84

    attributes["staircasesale"] = field_89

    attributes
  end

  def address_line1_input
    [field_23, field_24, field_25].compact.join(", ")
  end

  def saledate
    year = field_6.to_s.strip.length.between?(1, 2) ? field_6 + 2000 : field_6
    Date.new(year, field_5, field_4) if field_6.present? && field_5.present? && field_4.present?
  rescue Date::Error
    Date.new
  end

  def hodate
    year = field_96.to_s.strip.length.between?(1, 2) ? field_96 + 2000 : field_96
    Date.new(year, field_95, field_94) if field_96.present? && field_95.present? && field_94.present?
  rescue Date::Error
    Date.new
  end

  def exdate
    year = field_93.to_s.strip.length.between?(1, 2) ? field_93 + 2000 : field_93
    Date.new(year, field_92, field_91) if field_93.present? && field_92.present? && field_91.present?
  rescue Date::Error
    Date.new
  end

  def age1_known?
    return 1 if field_31 == "R"

    0
  end

  [
    { person: 2, field: :field_38 },
    { person: 3, field: :field_46 },
    { person: 4, field: :field_50 },
    { person: 5, field: :field_54 },
    { person: 6, field: :field_58 },
  ].each do |hash|
    define_method("age#{hash[:person]}_known?") do
      return 1 if public_send(hash[:field]) == "R"
      return 0 if send("person_#{hash[:person]}_present?")
    end
  end

  def person_2_present?
    field_38.present? || field_39.present? || field_37.present?
  end

  def person_3_present?
    field_46.present? || field_47.present? || field_45.present?
  end

  def person_4_present?
    field_50.present? || field_51.present? || field_49.present?
  end

  def person_5_present?
    field_54.present? || field_55.present? || field_53.present?
  end

  def person_6_present?
    field_58.present? || field_59.present? || field_57.present?
  end

  def details_known?(person_n)
    send("person_#{person_n}_present?") ? 1 : 2
  end

  def ethnic_group_from_ethnic
    return nil if field_33.blank?

    case field_33
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

  def postcode_full
    [field_27, field_28].compact_blank.join(" ") if field_27 || field_28
  end

  def ppostcode_full
    "#{field_63} #{field_64}" if field_63 && field_64
  end

  def sale_type
    return field_9 if shared_ownership?
    return field_10 if discounted_ownership?
    return field_11 if outright_sale?
  end

  def value
    return field_101 if shared_ownership?
    return field_114 if discounted_ownership?
    return field_125 if outright_sale?
  end

  def mortgage
    return field_104 if shared_ownership?
    return field_118 if discounted_ownership?
    return field_127 if outright_sale?
  end

  def extrabor
    return field_108 if shared_ownership?
    return field_122 if discounted_ownership?
    return field_129 if outright_sale?
  end

  def deposit
    return field_109 if shared_ownership?
    return field_123 if discounted_ownership?
    return field_130 if outright_sale?
  end

  def mscharge
    return field_112 if shared_ownership?
    return field_124 if discounted_ownership?
    return field_131 if outright_sale?
  end

  def mortgagelender
    return field_105 if shared_ownership?
    return field_119 if discounted_ownership?
  end

  def mortgagelenderother
    return field_106 if shared_ownership?
    return field_120 if discounted_ownership?
  end

  def mortlen
    return field_107 if shared_ownership?
    return field_121 if discounted_ownership?
    return field_128 if outright_sale?
  end

  def proplen
    return field_85 if shared_ownership?
    return field_113 if discounted_ownership?
  end

  def mortgageused
    return field_103 if shared_ownership?
    return field_117 if discounted_ownership?
    return field_126 if outright_sale?
  end

  def value_fields
    return [:field_101] if shared_ownership?
    return [:field_114] if discounted_ownership?
    return [:field_125] if outright_sale?

    %i[field_101 field_114 field_125]
  end

  def mortgage_fields
    return [:field_104] if shared_ownership?
    return [:field_118] if discounted_ownership?
    return [:field_127] if outright_sale?

    %i[field_104 field_118 field_127]
  end

  def extrabor_fields
    return [:field_108] if shared_ownership?
    return [:field_122] if discounted_ownership?
    return [:field_129] if outright_sale?

    %i[field_108 field_122 field_129]
  end

  def deposit_fields
    return [:field_109] if shared_ownership?
    return [:field_123] if discounted_ownership?
    return [:field_130] if outright_sale?

    %i[field_109 field_123 field_130]
  end

  def mscharge_fields
    return [:field_112] if shared_ownership?
    return [:field_124] if discounted_ownership?
    return [:field_131] if outright_sale?

    %i[field_112 field_124 field_131]
  end

  def mortgagelender_fields
    return [:field_105] if shared_ownership?
    return [:field_119] if discounted_ownership?

    %i[field_105 field_119]
  end

  def mortgagelenderother_fields
    return [:field_106] if shared_ownership?
    return [:field_120] if discounted_ownership?

    %i[field_106 field_120]
  end

  def mortlen_fields
    return [:field_107] if shared_ownership?
    return [:field_121] if discounted_ownership?
    return [:field_128] if outright_sale?

    %i[field_107 field_121 field_128]
  end

  def proplen_fields
    return [:field_85] if shared_ownership?
    return [:field_113] if discounted_ownership?

    %i[field_85 field_113]
  end

  def mortgageused_fields
    return [:field_103] if shared_ownership?
    return [:field_117] if discounted_ownership?
    return [:field_126] if outright_sale?

    %i[field_103 field_117 field_126]
  end

  def owning_organisation
    @owning_organisation ||= Organisation.find_by_id_on_multiple_fields(field_1)
  end

  def assigned_to
    @assigned_to ||= User.where("lower(email) = ?", field_3&.downcase).first
  end

  def previous_la_known
    field_65.present? ? 1 : 0
  end

  def previous_postcode_known
    return 1 if field_62 == 2

    0 if field_62 == 1
  end

  def infer_soctenant_from_prevten_and_prevtenbuy2
    return unless shared_ownership?

    if [1, 2].include?(field_61) || [1, 2].include?(field_71.to_i)
      1
    else
      2
    end
  end

  def no_buyer_organisation
    [field_66, field_67, field_68, field_69].all?(&:blank?) ? 1 : nil?
  end

  def block_log_creation!
    self.block_log_creation = true
  end

  def questions
    @questions ||= log.form.subsections.flat_map { |ss| ss.applicable_questions(log) }
  end

  def duplicate_check_fields
    %w[
      saledate
      age1
      sex1
      ecstat1
      owning_organisation
      postcode_full
      purchid
    ]
  end

  def validate_owning_org_data_given
    if field_1.blank?
      block_log_creation!

      if errors[:field_1].blank?
        errors.add(:field_1, I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "owning organisation."), category: :setup)
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

  def validate_owning_org_owns_stock
    if owning_organisation && !owning_organisation.holds_own_stock?
      block_log_creation!

      if errors[:field_1].blank?
        errors.add(:field_1, I18n.t("#{ERROR_BASE_KEY}.owning_organisation.not_stock_owner"), category: :setup)
      end
    end
  end

  def validate_owning_org_permitted
    return unless owning_organisation
    return if bulk_upload_organisation.affiliated_stock_owners.include?(owning_organisation)

    block_log_creation!

    return if errors[:field_1].present?

    if bulk_upload.user.support?
      errors.add(:field_1, I18n.t("#{ERROR_BASE_KEY}.owning_organisation.not_permitted.support", name: bulk_upload_organisation.name), category: :setup)
    else
      errors.add(:field_1, I18n.t("#{ERROR_BASE_KEY}.owning_organisation.not_permitted.not_support"), category: :setup)
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
      errors.add(:field_3, category: :setup, message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "what is the CORE username of the account this sales log should be assigned to?"))
    end
  end

  def validate_assigned_to_related
    return unless assigned_to
    return if assigned_to.organisation == owning_organisation || assigned_to.organisation == managing_organisation
    return if assigned_to.organisation == owning_organisation&.absorbing_organisation || assigned_to.organisation == managing_organisation&.absorbing_organisation

    block_log_creation!
    errors.add(:field_3, I18n.t("#{ERROR_BASE_KEY}.assigned_to.organisation_not_related"), category: :setup)
  end

  def managing_organisation
    Organisation.find_by_id_on_multiple_fields(field_2)
  end

  def nationality_group(nationality_value)
    return unless nationality_value
    return 0 if nationality_value.zero?
    return 826 if nationality_value == 826

    12
  end

  def validate_managing_org_related
    if owning_organisation && managing_organisation && !owning_organisation.can_be_managed_by?(organisation: managing_organisation)
      block_log_creation!

      if errors[:field_2].blank?
        errors.add(:field_2, I18n.t("#{ERROR_BASE_KEY}.assigned_to.managing_organisation_not_related"), category: :setup)
      end
    end
  end

  def setup_question?(question)
    log.form.setup_sections[0].subsections[0].questions.include?(question)
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
          if errors.none? { |e| fields.include?(e.attribute) } && @before_errors.none? { |e| fields.include?(e.attribute) }
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

  def validate_valid_radio_option
    log.attributes.each do |question_id, _v|
      question = log.form.get_question(question_id, log)

      next if question_id == "type"

      next unless question&.type == "radio"
      next if log[question_id].blank? || question.answer_options.key?(log[question_id].to_s) || !question.page.routed_to?(log, nil)

      fields = field_mapping_for_errors[question_id.to_sym] || []

      if setup_question?(question)
        fields.each do |field|
          if errors[field].none?
            block_log_creation!
            errors.add(field, I18n.t("#{ERROR_BASE_KEY}.invalid_option", question: format_ending(QUESTIONS[field])), category: :setup)
          end
        end
      else
        fields.each do |field|
          unless errors.any? { |e| fields.include?(e.attribute) }
            errors.add(field, I18n.t("#{ERROR_BASE_KEY}.invalid_option", question: format_ending(QUESTIONS[field])))
          end
        end
      end
    end
  end

  def validate_relevant_collection_window
    return if saledate.blank? || bulk_upload.form.blank?
    return if errors.key?(:field_4) || errors.key?(:field_5) || errors.key?(:field_6)

    unless bulk_upload.form.valid_start_date_for_form?(saledate)
      errors.add(:field_4, I18n.t("#{ERROR_BASE_KEY}.saledate.outside_collection_window", year_combo: bulk_upload.year_combo, start_year: bulk_upload.year, end_year: bulk_upload.end_year), category: :setup)
      errors.add(:field_5, I18n.t("#{ERROR_BASE_KEY}.saledate.outside_collection_window", year_combo: bulk_upload.year_combo, start_year: bulk_upload.year, end_year: bulk_upload.end_year), category: :setup)
      errors.add(:field_6, I18n.t("#{ERROR_BASE_KEY}.saledate.outside_collection_window", year_combo: bulk_upload.year_combo, start_year: bulk_upload.year, end_year: bulk_upload.end_year), category: :setup)
    end
  end

  def validate_if_log_already_exists
    if log_already_exists?
      error_message = I18n.t("#{ERROR_BASE_KEY}.duplicate")

      errors.add(:field_1, error_message) # Owning org
      errors.add(:field_4, error_message) # Sale completion date
      errors.add(:field_5, error_message) # Sale completion date
      errors.add(:field_6, error_message) # Sale completion date
      errors.add(:field_27, error_message) # Postcode
      errors.add(:field_28, error_message) # Postcode
      errors.add(:field_31, error_message) # Buyer 1 age
      errors.add(:field_32, error_message) # Buyer 1 gender
      errors.add(:field_35, error_message) # Buyer 1 working situation
      errors.add(:field_7, error_message) # Purchaser code
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
            error_message = [display_title_text(question.page.title_text, log), display_informative_text(question.page.informative_text, log)].reject(&:empty?).join(" ")
            errors.add(field, message: error_message, category: :soft_validation)
          end
        end
      end
    end
  end

  def validate_buyer1_economic_status
    if field_35 == 9
      if field_31.present? && field_31.to_i >= 16
        errors.add(:field_35, I18n.t("#{ERROR_BASE_KEY}.ecstat1.buyer_cannot_be_over_16_and_child"))
        errors.add(:field_31, I18n.t("#{ERROR_BASE_KEY}.age1.buyer_cannot_be_over_16_and_child"))
      else
        errors.add(:field_35, I18n.t("#{ERROR_BASE_KEY}.ecstat1.buyer_cannot_be_child"))
      end
    end
  end

  def validate_buyer2_economic_status
    return unless joint_purchase?

    if field_42 == 9
      if field_38.present? && field_38.to_i >= 16
        errors.add(:field_42, I18n.t("#{ERROR_BASE_KEY}.ecstat2.buyer_cannot_be_over_16_and_child"))
        errors.add(:field_38, I18n.t("#{ERROR_BASE_KEY}.age2.buyer_cannot_be_over_16_and_child"))
      else
        errors.add(:field_42, I18n.t("#{ERROR_BASE_KEY}.ecstat2.buyer_cannot_be_child"))
      end
    end
  end

  def validate_nationality
    if field_34.present? && !valid_nationality_options.include?(field_34.to_s)
      errors.add(:field_34, I18n.t("#{ERROR_BASE_KEY}.nationality.invalid"))
    end
  end

  def validate_buyer_2_nationality
    if field_41.present? && !valid_nationality_options.include?(field_41.to_s)
      errors.add(:field_41, I18n.t("#{ERROR_BASE_KEY}.nationality.invalid"))
    end
  end

  def valid_nationality_options
    %w[0] + GlobalConstants::COUNTRIES_ANSWER_OPTIONS.keys # 0 is "Prefers not to say"
  end

  def bulk_upload_organisation
    Organisation.find(bulk_upload.organisation_id)
  end
end
