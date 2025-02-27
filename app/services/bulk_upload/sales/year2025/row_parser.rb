class BulkUpload::Sales::Year2025::RowParser
  include ActiveModel::Model
  include ActiveModel::Attributes
  include InterruptionScreenHelper
  include FormattingHelper

  QUESTIONS = {
    field_1: "What is the day of the sale completion date? - DD",
    field_2: "What is the month of the sale completion date? - MM",
    field_3: "What is the year of the sale completion date? - YY",
    field_4: "Which organisation owned this property before the sale?",
    field_5: "Which organisation is reporting this sale?",
    field_6: "Username",
    field_7: "What is the purchaser code?",
    field_8: "What is the sale type?",
    field_9: "What is the type of shared ownership sale?",
    field_10: "Is this a staircasing transaction?",
    field_11: "What is the type of discounted ownership sale?",
    field_12: "Is this a joint purchase?",
    field_13: "Are there more than two joint purchasers of this property?",
    field_14: "Was the buyer interviewed for any of the answers you will provide on this log?",
    field_15: "Data Protection question",

    field_16: "If known, enter this property's UPRN",
    field_17: "Address line 1",
    field_18: "Address line 2",
    field_19: "Town or city",
    field_20: "County",
    field_21: "Part 1 of postcode of property",
    field_22: "Part 2 of postcode of property",
    field_23: "What is the local authority of the property?",
    field_24: "What type of unit is the property?",
    field_25: "How many bedrooms does the property have?",
    field_26: "Which type of building is the property?",
    field_27: "Is the property built or adapted to wheelchair user standards?",

    field_28: "Age of buyer 1",
    field_29: "Gender identity of buyer 1",
    field_30: "What is buyer 1's ethnic group?",
    field_31: "What is buyer 1's nationality?",
    field_32: "Working situation of buyer 1",
    field_33: "Will buyer 1 live in the property?",
    field_34: "Is buyer 2 or person 2 the partner of buyer 1?",
    field_35: "Age of person 2",
    field_36: "Gender identity of person 2",
    field_37: "Which of the following best describes buyer 2's ethnic background?",
    field_38: "What is buyer 2's nationality?",
    field_39: "What is buyer 2 or person 2's working situation?",
    field_40: "Will buyer 2 live in the property?",
    field_41: "Besides the buyers, how many people will live in the property?",

    field_42: "Is person 3 the partner of buyer 1?",
    field_43: "Age of person 3",
    field_44: "Gender identity of person 3",
    field_45: "Working situation of person 3",
    field_46: "Is person 4 the partner of buyer 1?",
    field_47: "Age of person 4",
    field_48: "Gender identity of person 4",
    field_49: "Working situation of person 4",
    field_50: "Is person 5 the partner of buyer 1?",
    field_51: "Age of person 5",
    field_52: "Gender identity of person 5",
    field_53: "Working situation of person 5",
    field_54: "Is person 6 the partner of buyer 1?",
    field_55: "Age of person 6",
    field_56: "Gender identity of person 6",
    field_57: "Working situation of person 6",

    field_58: "What was buyer 1's previous tenure?",
    field_59: "Do you know the postcode of buyer 1's last settled home?",
    field_60: "Part 1 of postcode of buyer 1's last settled home",
    field_61: "Part 2 of postcode of buyer 1's last settled home",
    field_62: "What is the local authority of buyer 1's last settled home?",
    field_63: "At the time of purchase, was buyer 2 living at the same address as buyer 1?",
    field_64: "What was buyer 2's previous tenure?",

    field_65: "Has the buyer ever served in the UK Armed Forces and for how long?",
    field_66: "Is the buyer still serving in the UK armed forces?",
    field_67: "Are any of the buyers a spouse or civil partner of a UK Armed Forces regular who died in service within the last 2 years?",
    field_68: "Does anyone in the household consider themselves to have a disability?",
    field_69: "Does anyone in the household use a wheelchair?",

    field_70: "What is buyer 1's gross annual income?",
    field_71: "Was buyer 1's income used for a mortgage application?",
    field_72: "What is buyer 2's gross annual income?",
    field_73: "Was buyer 2's income used for a mortgage application?",
    field_74: "Were the buyers receiving any of these housing-related benefits immediately before buying this property?",
    field_75: "What is the total amount the buyers had in savings before they paid any deposit for the property?",
    field_76: "Have any of the purchasers previously owned a property?",
    field_77: "Was the previous property under shared ownership?",

    field_78: "Is this a resale?",
    field_79: "How long have the buyers been living in the property before the purchase? - Shared ownership",
    field_80: "What is the day of the practical completion or handover date?",
    field_81: "What is the month of the practical completion or handover date?",
    field_82: "What is the year of the practical completion or handover date?",
    field_83: "How many bedrooms did the buyer's previous property have?",
    field_84: "What was the type of the buyer's previous property?",
    field_85: "What was the rent type of the buyer's previous property?",
    field_86: "What was the full purchase price?",
    field_87: "What was the initial percentage share purchased?",
    field_88: "Was a mortgage used for the purchase of this property? - Shared ownership",
    field_89: "What is the mortgage amount?",
    field_90: "What is the length of the mortgage in years? - Shared ownership",
    field_91: "How much was the cash deposit paid on the property?",
    field_92: "How much cash discount was given through Social Homebuy?",
    field_93: "What is the basic monthly rent?",
    field_94: "What are the total monthly service charges for the property?",
    field_95: "What are the total monthly estate management fees for the property?",

    field_96: "What percentage of the property has been bought in this staircasing transaction?",
    field_97: "What percentage of the property does the buyer now own in total?",
    field_98: "Was this transaction part of a back-to-back staircasing transaction to facilitate sale of the home on the open market?",
    field_99: "Is this the first time the buyer has engaged in staircasing in the home?",
    field_100: "What was the day of the initial purchase of a share in the property? DD",
    field_101: "What was the month of the initial purchase of a share in the property? MM",
    field_102: "What was the year of the initial purchase of a share in the property? YYYY",
    field_103: "Including this time, how many times has the shared owner engaged in staircasing in the home?",
    field_104: "What was the day of the last staircasing transaction? DD",
    field_105: "What was the month of the last staircasing transaction? MM",
    field_106: "What was the year of the last staircasing transaction? YYYY",
    field_107: "What is the full purchase price for this staircasing transaction?",
    field_108: "What was the percentage share purchased in the initial transaction?",
    field_109: "Was a mortgage used for this staircasing transaction?",
    field_110: "What was the basic monthly rent prior to staircasing?",
    field_111: "What is the basic monthly rent after staircasing?",

    field_112: "How long have the buyers been living in the property before the purchase? - Discounted ownership",
    field_113: "What was the full purchase price?",
    field_114: "What was the amount of any loan, grant, discount or subsidy given?",
    field_115: "What was the percentage discount?",
    field_116: "Was a mortgage used for the purchase of this property? - Discounted ownership",
    field_117: "What is the mortgage amount?",
    field_118: "What is the length of the mortgage in years? - Discounted ownership",
    field_119: "Does this include any extra borrowing?",
    field_120: "How much was the cash deposit paid on the property?",
    field_121: "What are the total monthly leasehold charges for the property?",
  }.freeze

  ERROR_BASE_KEY = "validations.sales.2025.bulk_upload".freeze

  attribute :bulk_upload
  attribute :block_log_creation, :boolean, default: -> { false }

  attribute :field_blank

  attribute :field_1, :integer
  attribute :field_2, :integer
  attribute :field_3, :integer
  attribute :field_4, :string
  attribute :field_5, :string
  attribute :field_6, :string
  attribute :field_7, :string
  attribute :field_8, :integer
  attribute :field_9, :integer
  attribute :field_10, :integer
  attribute :field_11, :integer
  attribute :field_12, :integer
  attribute :field_13, :integer
  attribute :field_14, :integer
  attribute :field_15, :integer

  attribute :field_16, :string
  attribute :field_17, :string
  attribute :field_18, :string
  attribute :field_19, :string
  attribute :field_20, :string
  attribute :field_21, :string
  attribute :field_22, :string
  attribute :field_23, :string
  attribute :field_24, :integer
  attribute :field_25, :integer
  attribute :field_26, :integer
  attribute :field_27, :integer

  attribute :field_28, :string
  attribute :field_29, :string
  attribute :field_30, :integer
  attribute :field_31, :integer
  attribute :field_32, :integer
  attribute :field_33, :integer
  attribute :field_34, :integer
  attribute :field_35, :string
  attribute :field_36, :string
  attribute :field_37, :integer
  attribute :field_38, :integer
  attribute :field_39, :integer
  attribute :field_40, :integer
  attribute :field_41, :integer

  attribute :field_42, :integer
  attribute :field_43, :string
  attribute :field_44, :string
  attribute :field_45, :integer
  attribute :field_46, :integer
  attribute :field_47, :string
  attribute :field_48, :string
  attribute :field_49, :integer
  attribute :field_50, :integer
  attribute :field_51, :string
  attribute :field_52, :string
  attribute :field_53, :integer
  attribute :field_54, :integer
  attribute :field_55, :string
  attribute :field_56, :string
  attribute :field_57, :integer

  attribute :field_58, :integer
  attribute :field_59, :integer
  attribute :field_60, :string
  attribute :field_61, :string
  attribute :field_62, :string
  attribute :field_63, :integer
  attribute :field_64, :string

  attribute :field_65, :integer
  attribute :field_66, :integer
  attribute :field_67, :integer
  attribute :field_68, :integer
  attribute :field_69, :integer

  attribute :field_70, :string
  attribute :field_71, :integer
  attribute :field_72, :string
  attribute :field_73, :integer
  attribute :field_74, :integer
  attribute :field_75, :string
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
  attribute :field_93, :decimal
  attribute :field_94, :decimal
  attribute :field_95, :decimal

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
  attribute :field_106, :integer
  attribute :field_107, :integer
  attribute :field_108, :integer
  attribute :field_109, :integer
  attribute :field_110, :integer
  attribute :field_111, :decimal

  attribute :field_112, :integer
  attribute :field_113, :integer
  attribute :field_114, :integer
  attribute :field_115, :integer
  attribute :field_116, :integer
  attribute :field_117, :integer
  attribute :field_118, :integer
  attribute :field_119, :integer
  attribute :field_120, :integer
  attribute :field_121, :integer

  validates :field_1,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "sale completion date (day)."),
              category: :setup,
            },
            on: :after_log

  validates :field_2,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "sale completion date (month)."),
              category: :setup,
            }, on: :after_log

  validates :field_3,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "sale completion date (year)."),
              category: :setup,
            },
            format: {
              with: /\A(\d{2}|\d{4})\z/,
              message: I18n.t("#{ERROR_BASE_KEY}.saledate.year_not_two_or_four_digits"),
              category: :setup,
              if: proc { field_3.present? },
            }, on: :after_log

  validates :field_8,
            inclusion: {
              in: [1, 2],
              if: proc { field_8.present? },
              category: :setup,
              question: QUESTIONS[:field_8].downcase,
            },
            on: :before_log

  validates :field_8,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "shared ownership sale type."),
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
              in: [1, 2],
              if: proc { field_10.present? },
              category: :setup,
              question: QUESTIONS[:field_10].downcase,
            },
            on: :before_log

  validates :field_10,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "staircasing transaction."),
              category: :setup,
              if: :shared_ownership?,
            },
            on: :after_log

  validates :field_11,
            inclusion: {
              in: [8, 9, 14, 21, 22, 27, 29],
              if: proc { field_11.present? },
              category: :setup,
              question: QUESTIONS[:field_11].downcase,
            },
            on: :before_log

  validates :field_11,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "type of discounted ownership sale."),
              category: :setup,
              if: :discounted_ownership?,
            },
            on: :after_log

  validates :field_115,
            numericality: {
              message: I18n.t("#{ERROR_BASE_KEY}.numeric.within_range", field: "Percentage discount", min: "0%", max: "70%"),
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 70,
              if: :discounted_ownership?,
              allow_blank: true,
            },
            on: :before_log

  validates :field_12,
            presence: {
              message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "joint purchase."),
              category: :setup,
              if: :joint_purchase_asked?,
            },
            on: :after_log

  validates :field_13,
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
    "#<BulkUpload::Sales::Year2025::RowParser:#{object_id}>"
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
      "field_4",  # owning org
      "field_1",  # saledate
      "field_2",  # saledate
      "field_3",  # saledate
      "field_7",  # purchaser_code
      "field_21", # postcode
      "field_22", # postcode
      "field_28", # age1
      "field_29", # sex1
      "field_32", # ecstat1
    )
  end

  def add_duplicate_found_in_spreadsheet_errors
    spreadsheet_duplicate_hash.each_key do |field|
      errors.add(field, I18n.t("#{ERROR_BASE_KEY}.spreadsheet_dupe"), category: :setup)
    end
  end

private

  def prevtenbuy2
    case field_64
    when "R"
      0
    else
      field_64
    end
  end

  def infer_buyer2_ethnic_group_from_ethnic
    case field_37
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
      field_37
    end
  end

  def validate_uprn_exists_if_any_key_address_fields_are_blank
    if field_16.blank? && !key_address_fields_provided?
      %i[field_17 field_19 field_21 field_22].each do |field|
        errors.add(field, I18n.t("#{ERROR_BASE_KEY}.address.not_answered")) if send(field).blank?
      end
      errors.add(:field_16, I18n.t("#{ERROR_BASE_KEY}.address.not_answered", question: "UPRN."))
    end
  end

  def validate_address_option_found
    if log.uprn.nil? && field_16.blank? && key_address_fields_provided?
      error_message = if log.address_options_present?
                        I18n.t("#{ERROR_BASE_KEY}.address.not_determined")
                      else
                        I18n.t("#{ERROR_BASE_KEY}.address.not_found")
                      end
      %i[field_17 field_18 field_19 field_20 field_21 field_22].each do |field|
        errors.add(field, error_message) if errors[field].blank?
      end
    end
  end

  def key_address_fields_provided?
    field_17.present? && field_19.present? && postcode_full.present?
  end

  def validate_address_fields
    if field_16.blank? || log.errors.attribute_names.include?(:uprn)
      if field_17.blank? && errors[:field_17].blank?
        errors.add(:field_17, I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "address line 1."))
      end

      if field_19.blank? && errors[:field_19].blank?
        errors.add(:field_19, I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "town or city."))
      end

      if field_21.blank? && errors[:field_21].blank?
        errors.add(:field_21, I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "part 1 of postcode."))
      end

      if field_22.blank? && errors[:field_22].blank?
        errors.add(:field_22, I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "part 2 of postcode."))
      end
    end
  end

  def shared_ownership?
    field_8 == 1
  end

  def discounted_ownership?
    field_8 == 2
  end

  def joint_purchase?
    field_12 == 1
  end

  def joint_purchase_asked?
    shared_ownership? || discounted_ownership? || field_13 == 2
  end

  def shared_or_discounted_but_not_staircasing?
    (shared_ownership? || discounted_ownership?) && field_10 != 1
  end

  def shared_ownership_initial_purchase?
    field_8 == 1 && field_10 != 1
  end

  def staircasing?
    field_8 == 1 && field_10 == 1
  end

  def two_buyers_share_address?
    field_63 == 2
  end

  def not_resale?
    field_78 == 2
  end

  def buyer_1_previous_tenure_not_1_or_2?
    field_58 != 1 && field_58 != 2
  end

  def mortgage_used?
    field_88 == 2
  end

  def social_homebuy?
    field_9 == 18
  end

  def buyers_own_all?
    field_97 == 100
  end

  def buyer_staircased_before?
    field_99 == 1
  end

  def rtb_like_sale_type?
    [9, 14, 27, 29].include?(field_11)
  end

  def field_mapping_for_errors
    {
      purchid: %i[field_7],
      saledate: %i[field_1 field_2 field_3],
      noint: %i[field_14],
      age1_known: %i[field_28],
      age1: %i[field_28],
      age2_known: %i[field_35],
      age2: %i[field_35],
      age3_known: %i[field_43],
      age3: %i[field_43],
      age4_known: %i[field_47],
      age4: %i[field_47],
      age5_known: %i[field_51],
      age5: %i[field_51],
      age6_known: %i[field_55],
      age6: %i[field_55],
      sex1: %i[field_29],
      sex2: %i[field_36],
      sex3: %i[field_44],

      sex4: %i[field_48],
      sex5: %i[field_52],
      sex6: %i[field_56],
      relat2: %i[field_34],
      relat3: %i[field_42],
      relat4: %i[field_46],
      relat5: %i[field_49],
      relat6: %i[field_54],

      ecstat1: %i[field_32],
      ecstat2: %i[field_39],
      ecstat3: %i[field_45],

      ecstat4: %i[field_49],
      ecstat5: %i[field_53],
      ecstat6: %i[field_57],
      ethnic_group: %i[field_30],
      ethnic: %i[field_30],
      nationality_all: %i[field_31],
      nationality_all_group: %i[field_31],
      income1nk: %i[field_70],
      income1: %i[field_70],
      income2nk: %i[field_72],
      income2: %i[field_72],
      inc1mort: %i[field_71],
      inc2mort: %i[field_73],
      savingsnk: %i[field_75],
      savings: %i[field_75],
      prevown: %i[field_76],
      prevten: %i[field_58],
      prevloc: %i[field_62],
      previous_la_known: %i[field_62],
      ppcodenk: %i[field_59],
      ppostcode_full: %i[field_60 field_61],
      disabled: %i[field_68],

      wheel: %i[field_69],
      beds: %i[field_25],
      proptype: %i[field_24],
      builtype: %i[field_26],
      la_known: %i[field_23],
      la: %i[field_23],

      is_la_inferred: %i[field_23],
      pcodenk: %i[field_21 field_22],
      postcode_full: %i[field_21 field_22],
      wchair: %i[field_27],

      type: %i[field_9 field_11 field_8],
      resale: %i[field_78],
      hodate: %i[field_80 field_81 field_82],

      frombeds: %i[field_83],
      fromprop: %i[field_84],
      value: value_fields,
      equity: equity_fields,
      mortgage: mortgage_fields,
      extrabor: extrabor_fields,
      deposit: deposit_fields,
      cashdis: %i[field_92],
      mrent: mrent_fields,

      has_mscharge: mscharge_fields,
      mscharge: mscharge_fields,
      grant: %i[field_114],
      discount: %i[field_115],
      owning_organisation_id: %i[field_4],
      managing_organisation_id: [:field_5],
      assigned_to: %i[field_6],
      hhregres: %i[field_65],
      hhregresstill: %i[field_66],
      armedforcesspouse: %i[field_67],

      hb: %i[field_74],
      mortlen: mortlen_fields,
      proplen: proplen_fields,

      jointmore: %i[field_13],
      staircase: %i[field_10],
      privacynotice: %i[field_15],
      ownershipsch: %i[field_8],

      jointpur: %i[field_12],
      buy1livein: %i[field_33],
      buy2livein: %i[field_40],
      hholdcount: %i[field_41],
      stairbought: %i[field_96],
      stairowned: %i[field_97],
      socprevten: %i[field_85],
      mortgageused: mortgageused_fields,

      uprn: %i[field_16],
      address_line1: %i[field_17],
      address_line2: %i[field_18],
      town_or_city: %i[field_19],
      county: %i[field_20],
      uprn_selection: [:field_17],

      ethnic_group2: %i[field_37],
      ethnicbuy2: %i[field_37],
      nationality_all_buyer2: %i[field_38],
      nationality_all_buyer2_group: %i[field_38],

      buy2living: %i[field_63],
      prevtenbuy2: %i[field_64],

      prevshared: %i[field_77],

      staircasesale: %i[field_98],
      firststair: %i[field_99],
      numstair: %i[field_103],
      mrentprestaircasing: %i[field_110],
      lasttransaction: %i[field_104 field_105 field_106],
      initialpurchase: %i[field_100 field_101 field_102],

    }
  end

  def attributes_for_log
    attributes = {}

    attributes["purchid"] = purchaser_code
    attributes["saledate"] = saledate
    attributes["noint"] = field_14

    attributes["age1_known"] = age1_known?
    attributes["age1"] = field_28 if attributes["age1_known"]&.zero? && field_28&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["age2_known"] = age2_known?
    attributes["age2"] = field_35 if attributes["age2_known"]&.zero? && field_35&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["age3_known"] = age3_known?
    attributes["age3"] = field_43 if attributes["age3_known"]&.zero? && field_43&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["age4_known"] = age4_known?
    attributes["age4"] = field_47 if attributes["age4_known"]&.zero? && field_47&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["age5_known"] = age5_known?
    attributes["age5"] = field_51 if attributes["age5_known"]&.zero? && field_51&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["age6_known"] = age6_known?
    attributes["age6"] = field_55 if attributes["age6_known"]&.zero? && field_55&.match(/\A\d{1,3}\z|\AR\z/)

    attributes["sex1"] = field_29
    attributes["sex2"] = field_36
    attributes["sex3"] = field_44
    attributes["sex4"] = field_48
    attributes["sex5"] = field_52
    attributes["sex6"] = field_56

    attributes["relat2"] = if field_34 == 1
                             "P"
                           else
                             (field_34 == 2 ? "X" : "R")
                           end
    attributes["relat3"] = if field_42 == 1
                             "P"
                           else
                             (field_42 == 2 ? "X" : "R")
                           end
    attributes["relat4"] = if field_46 == 1
                             "P"
                           else
                             (field_46 == 2 ? "X" : "R")
                           end
    attributes["relat5"] = if field_49 == 1
                             "P"
                           else
                             (field_49 == 2 ? "X" : "R")
                           end
    attributes["relat6"] = if field_54 == 1
                             "P"
                           else
                             (field_54 == 2 ? "X" : "R")
                           end

    attributes["ecstat1"] = field_32
    attributes["ecstat2"] = field_39
    attributes["ecstat3"] = field_45
    attributes["ecstat4"] = field_49
    attributes["ecstat5"] = field_53
    attributes["ecstat6"] = field_57

    attributes["details_known_2"] = details_known?(2)
    attributes["details_known_3"] = details_known?(3)
    attributes["details_known_4"] = details_known?(4)
    attributes["details_known_5"] = details_known?(5)
    attributes["details_known_6"] = details_known?(6)

    attributes["ethnic_group"] = ethnic_group_from_ethnic
    attributes["ethnic"] = field_30
    attributes["nationality_all"] = field_31 if field_31.present? && valid_nationality_options.include?(field_31.to_s)
    attributes["nationality_all_group"] = nationality_group(attributes["nationality_all"])

    attributes["income1nk"] = field_70 == "R" ? 1 : 0
    attributes["income1"] = field_70.to_i if attributes["income1nk"]&.zero? && field_70&.match(/\A\d+\z/)

    attributes["income2nk"] = field_72 == "R" ? 1 : 0
    attributes["income2"] = field_72.to_i if attributes["income2nk"]&.zero? && field_72&.match(/\A\d+\z/)

    attributes["inc1mort"] = field_71
    attributes["inc2mort"] = field_73

    attributes["savingsnk"] = field_75 == "R" ? 1 : 0
    attributes["savings"] = field_75.to_i if attributes["savingsnk"]&.zero? && field_75&.match(/\A\d+\z/)
    attributes["prevown"] = field_76

    attributes["prevten"] = field_58
    attributes["prevloc"] = field_62
    attributes["previous_la_known"] = previous_la_known
    attributes["ppcodenk"] = previous_postcode_known
    attributes["ppostcode_full"] = ppostcode_full

    attributes["disabled"] = field_68
    attributes["wheel"] = field_69
    attributes["beds"] = field_25
    attributes["proptype"] = field_24
    attributes["builtype"] = field_26
    attributes["la_known"] = field_23.present? ? 1 : 0
    attributes["la"] = field_23
    attributes["la_as_entered"] = field_23
    attributes["is_la_inferred"] = false
    attributes["pcodenk"] = 0 if postcode_full.present?
    attributes["postcode_full"] = postcode_full
    attributes["postcode_full_as_entered"] = postcode_full
    attributes["wchair"] = field_27

    attributes["type"] = sale_type
    attributes["resale"] = field_78

    attributes["hodate"] = hodate

    attributes["frombeds"] = field_83
    attributes["fromprop"] = field_84

    attributes["value"] = value
    attributes["equity"] = equity
    attributes["mortgage"] = mortgage
    attributes["extrabor"] = extrabor
    attributes["deposit"] = deposit

    attributes["cashdis"] = field_92
    attributes["mrent"] = mrent
    attributes["mscharge"] = mscharge if mscharge&.positive?
    attributes["has_mscharge"] = attributes["mscharge"].present? ? 1 : 0
    attributes["grant"] = field_114
    attributes["discount"] = field_115

    attributes["owning_organisation"] = owning_organisation
    attributes["managing_organisation"] = managing_organisation
    attributes["assigned_to"] = assigned_to || (bulk_upload.user.support? ? nil : bulk_upload.user)
    attributes["created_by"] = bulk_upload.user
    attributes["hhregres"] = field_65
    attributes["hhregresstill"] = field_66
    attributes["armedforcesspouse"] = field_67

    attributes["hb"] = field_74

    attributes["mortlen"] = mortlen

    attributes["proplen"] = proplen if proplen&.positive?
    attributes["proplen_asked"] = attributes["proplen"]&.present? ? 0 : 1
    attributes["jointmore"] = field_13
    attributes["staircase"] = field_10
    attributes["privacynotice"] = field_15
    attributes["ownershipsch"] = field_8
    attributes["jointpur"] = field_12
    attributes["buy1livein"] = field_33
    attributes["buy2livein"] = field_40
    attributes["hholdcount"] = field_41
    attributes["stairbought"] = field_96
    attributes["stairowned"] = field_97
    attributes["socprevten"] = field_85
    attributes["soctenant"] = infer_soctenant_from_prevten_and_prevtenbuy2
    attributes["mortgageused"] = mortgageused

    attributes["uprn"] = field_16
    attributes["uprn_known"] = field_16.present? ? 1 : 0
    attributes["uprn_confirmed"] = 1 if field_16.present?
    attributes["skip_update_uprn_confirmed"] = true
    attributes["address_line1"] = field_17
    attributes["address_line1_as_entered"] = field_17
    attributes["address_line2"] = field_18
    attributes["address_line2_as_entered"] = field_18
    attributes["town_or_city"] = field_19
    attributes["town_or_city_as_entered"] = field_19
    attributes["county"] = field_20
    attributes["county_as_entered"] = field_20
    attributes["address_line1_input"] = address_line1_input
    attributes["postcode_full_input"] = postcode_full
    attributes["select_best_address_match"] = true if field_16.blank?
    attributes["manual_address_entry_selected"] = field_16.blank?

    attributes["ethnic_group2"] = infer_buyer2_ethnic_group_from_ethnic
    attributes["ethnicbuy2"] = field_37
    attributes["nationality_all_buyer2"] = field_38 if field_38.present? && valid_nationality_options.include?(field_38.to_s)
    attributes["nationality_all_buyer2_group"] = nationality_group(attributes["nationality_all_buyer2"])

    attributes["buy2living"] = field_63
    attributes["prevtenbuy2"] = prevtenbuy2

    attributes["prevshared"] = field_77

    attributes["staircasesale"] = field_98

    attributes["firststair"] = field_99
    attributes["numstair"] = field_103
    attributes["mrentprestaircasing"] = field_110
    attributes["lasttransaction"] = lasttransaction
    attributes["initialpurchase"] = initialpurchase

    attributes["management_fee"] = field_95
    attributes["has_management_fee"] = field_95.present? && field_95.positive? ? 1 : 0

    attributes
  end

  def address_line1_input
    [field_17, field_18, field_19].compact.join(", ")
  end

  def saledate
    year = field_3.to_s.strip.length.between?(1, 2) ? field_3 + 2000 : field_3
    Date.new(year, field_2, field_1) if field_3.present? && field_2.present? && field_1.present?
  rescue Date::Error
    Date.new
  end

  def hodate
    year = field_82.to_s.strip.length.between?(1, 2) ? field_82 + 2000 : field_82
    Date.new(year, field_81, field_80) if field_82.present? && field_81.present? && field_80.present?
  rescue Date::Error
    Date.new
  end

  def lasttransaction
    year = field_106.to_s.strip.length.between?(1, 2) ? field_106 + 2000 : field_106
    Date.new(year, field_105, field_104) if field_106.present? && field_105.present? && field_104.present?
  rescue Date::Error
    Date.new
  end

  def initialpurchase
    year = field_102.to_s.strip.length.between?(1, 2) ? field_102 + 2000 : field_102
    Date.new(year, field_101, field_100) if field_102.present? && field_101.present? && field_100.present?
  rescue Date::Error
    Date.new
  end

  def age1_known?
    return 1 if field_28 == "R"

    0
  end

  [
    { person: 2, field: :field_35 },
    { person: 3, field: :field_43 },
    { person: 4, field: :field_47 },
    { person: 5, field: :field_51 },
    { person: 6, field: :field_55 },
  ].each do |hash|
    define_method("age#{hash[:person]}_known?") do
      return 1 if public_send(hash[:field]) == "R"
      return 0 if send("person_#{hash[:person]}_present?")
    end
  end

  def person_2_present?
    field_35.present? || field_36.present? || field_34.present?
  end

  def person_3_present?
    field_43.present? || field_44.present? || field_42.present?
  end

  def person_4_present?
    field_47.present? || field_48.present? || field_46.present?
  end

  def person_5_present?
    field_51.present? || field_52.present? || field_49.present?
  end

  def person_6_present?
    field_55.present? || field_56.present? || field_54.present?
  end

  def details_known?(person_n)
    send("person_#{person_n}_present?") ? 1 : 2
  end

  def ethnic_group_from_ethnic
    return nil if field_30.blank?

    case field_30
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
    [field_21, field_22].compact_blank.join(" ") if field_21 || field_22
  end

  def ppostcode_full
    "#{field_60} #{field_61}" if field_60 && field_61
  end

  def sale_type
    return field_9 if shared_ownership?
    return field_11 if discounted_ownership?
  end

  def value
    return field_86 if shared_ownership_initial_purchase?
    return field_113 if discounted_ownership?
    return field_107 if staircasing?
  end

  def equity
    return field_87 if shared_ownership_initial_purchase?
    return field_108 if staircasing?
  end

  def mortgage
    return field_89 if shared_ownership?
    return field_117 if discounted_ownership?
  end

  def extrabor
    return field_119 if discounted_ownership?
  end

  def deposit
    return field_91 if shared_ownership?
    return field_120 if discounted_ownership?
  end

  def mrent
    return field_93 if shared_ownership_initial_purchase?
    return field_111 if staircasing?
  end

  def mscharge
    return field_94 if shared_ownership?
    return field_121 if discounted_ownership?
  end

  def mortlen
    return field_90 if shared_ownership?
    return field_118 if discounted_ownership?
  end

  def proplen
    return field_79 if shared_ownership?
    return field_112 if discounted_ownership?
  end

  def mortgageused
    return field_88 if shared_ownership_initial_purchase?
    return field_116 if discounted_ownership?
    return field_109 if staircasing?
  end

  def value_fields
    return [:field_86] if shared_ownership_initial_purchase?
    return [:field_113] if discounted_ownership?
    return [:field_107] if staircasing?

    %i[field_86 field_113 field_107]
  end

  def equity_fields
    return [:field_87] if shared_ownership_initial_purchase?
    return [:field_108] if staircasing?

    %i[field_87 field_108]
  end

  def mortgage_fields
    return [:field_89] if shared_ownership?
    return [:field_117] if discounted_ownership?

    %i[field_89 field_117]
  end

  def extrabor_fields
    return [:field_119] if discounted_ownership?

    %i[field_119]
  end

  def deposit_fields
    return [:field_91] if shared_ownership?
    return [:field_120] if discounted_ownership?

    %i[field_91 field_120]
  end

  def mrent_fields
    return [:field_93] if shared_ownership_initial_purchase?
    return [:field_111] if staircasing?

    %i[field_93 field_111]
  end

  def mscharge_fields
    return [:field_94] if shared_ownership?
    return [:field_121] if discounted_ownership?

    %i[field_94 field_121]
  end

  def mortlen_fields
    return [:field_90] if shared_ownership?
    return [:field_118] if discounted_ownership?

    %i[field_90 field_118]
  end

  def proplen_fields
    return [:field_79] if shared_ownership?
    return [:field_112] if discounted_ownership?

    %i[field_79 field_112]
  end

  def mortgageused_fields
    return [:field_88] if shared_ownership_initial_purchase?
    return [:field_116] if discounted_ownership?
    return [:field_109] if staircasing?

    %i[field_88 field_116 field_109]
  end

  def owning_organisation
    @owning_organisation ||= Organisation.find_by_id_on_multiple_fields(field_4)
  end

  def assigned_to
    @assigned_to ||= User.where("lower(email) = ?", field_6&.downcase).first
  end

  def previous_la_known
    field_62.present? ? 1 : 0
  end

  def previous_postcode_known
    return 1 if field_59 == 2

    0 if field_59 == 1
  end

  def infer_soctenant_from_prevten_and_prevtenbuy2
    return unless shared_ownership?

    if [1, 2].include?(field_58) || [1, 2].include?(field_64.to_i)
      1
    else
      2
    end
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
    if field_4.blank?
      block_log_creation!

      if errors[:field_4].blank?
        errors.add(:field_4, I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "owning organisation."), category: :setup)
      end
    end
  end

  def validate_owning_org_exists
    if owning_organisation.nil?
      block_log_creation!

      if field_4.present? && errors[:field_4].blank?
        errors.add(:field_4, I18n.t("#{ERROR_BASE_KEY}.owning_organisation.not_found"), category: :setup)
      end
    end
  end

  def validate_owning_org_owns_stock
    if owning_organisation && !owning_organisation.holds_own_stock?
      block_log_creation!

      if errors[:field_4].blank?
        errors.add(:field_4, I18n.t("#{ERROR_BASE_KEY}.owning_organisation.not_stock_owner"), category: :setup)
      end
    end
  end

  def validate_owning_org_permitted
    return unless owning_organisation
    return if bulk_upload_organisation.affiliated_stock_owners.include?(owning_organisation)

    block_log_creation!

    return if errors[:field_4].present?

    if bulk_upload.user.support?
      errors.add(:field_4, I18n.t("#{ERROR_BASE_KEY}.owning_organisation.not_permitted.support", name: bulk_upload_organisation.name), category: :setup)
    else
      errors.add(:field_4, I18n.t("#{ERROR_BASE_KEY}.owning_organisation.not_permitted.not_support"), category: :setup)
    end
  end

  def validate_assigned_to_exists
    return if field_6.blank?

    unless assigned_to
      errors.add(:field_6, I18n.t("#{ERROR_BASE_KEY}.assigned_to.not_found"))
    end
  end

  def validate_assigned_to_when_support
    if field_6.blank? && bulk_upload.user.support?
      errors.add(:field_6, category: :setup, message: I18n.t("#{ERROR_BASE_KEY}.not_answered", question: "what is the CORE username of the account this sales log should be assigned to?"))
    end
  end

  def validate_assigned_to_related
    return unless assigned_to
    return if assigned_to.organisation == owning_organisation || assigned_to.organisation == managing_organisation
    return if assigned_to.organisation == owning_organisation&.absorbing_organisation || assigned_to.organisation == managing_organisation&.absorbing_organisation

    block_log_creation!
    errors.add(:field_6, I18n.t("#{ERROR_BASE_KEY}.assigned_to.organisation_not_related"), category: :setup)
  end

  def managing_organisation
    Organisation.find_by_id_on_multiple_fields(field_5)
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

      if errors[:field_5].blank?
        errors.add(:field_5, I18n.t("#{ERROR_BASE_KEY}.assigned_to.managing_organisation_not_related"), category: :setup)
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
    return if errors.key?(:field_1) || errors.key?(:field_2) || errors.key?(:field_3)

    unless bulk_upload.form.valid_start_date_for_form?(saledate)
      errors.add(:field_1, I18n.t("#{ERROR_BASE_KEY}.saledate.outside_collection_window", year_combo: bulk_upload.year_combo, start_year: bulk_upload.year, end_year: bulk_upload.end_year), category: :setup)
      errors.add(:field_2, I18n.t("#{ERROR_BASE_KEY}.saledate.outside_collection_window", year_combo: bulk_upload.year_combo, start_year: bulk_upload.year, end_year: bulk_upload.end_year), category: :setup)
      errors.add(:field_3, I18n.t("#{ERROR_BASE_KEY}.saledate.outside_collection_window", year_combo: bulk_upload.year_combo, start_year: bulk_upload.year, end_year: bulk_upload.end_year), category: :setup)
    end
  end

  def validate_if_log_already_exists
    if log_already_exists?
      error_message = I18n.t("#{ERROR_BASE_KEY}.duplicate")

      errors.add(:field_4, error_message) # Owning org
      errors.add(:field_1, error_message) # Sale completion date
      errors.add(:field_2, error_message) # Sale completion date
      errors.add(:field_3, error_message) # Sale completion date
      errors.add(:field_21, error_message) # Postcode
      errors.add(:field_22, error_message) # Postcode
      errors.add(:field_28, error_message) # Buyer 1 age
      errors.add(:field_29, error_message) # Buyer 1 gender
      errors.add(:field_32, error_message) # Buyer 1 working situation
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
    if field_32 == 9
      if field_28.present? && field_28.to_i >= 16
        errors.add(:field_32, I18n.t("#{ERROR_BASE_KEY}.ecstat1.buyer_cannot_be_over_16_and_child"))
        errors.add(:field_28, I18n.t("#{ERROR_BASE_KEY}.age1.buyer_cannot_be_over_16_and_child"))
      else
        errors.add(:field_32, I18n.t("#{ERROR_BASE_KEY}.ecstat1.buyer_cannot_be_child"))
      end
    end
  end

  def validate_buyer2_economic_status
    return unless joint_purchase?

    if field_39 == 9
      if field_35.present? && field_35.to_i >= 16
        errors.add(:field_39, I18n.t("#{ERROR_BASE_KEY}.ecstat2.buyer_cannot_be_over_16_and_child"))
        errors.add(:field_35, I18n.t("#{ERROR_BASE_KEY}.age2.buyer_cannot_be_over_16_and_child"))
      else
        errors.add(:field_39, I18n.t("#{ERROR_BASE_KEY}.ecstat2.buyer_cannot_be_child"))
      end
    end
  end

  def validate_nationality
    if field_31.present? && !valid_nationality_options.include?(field_31.to_s)
      errors.add(:field_31, I18n.t("#{ERROR_BASE_KEY}.nationality.invalid"))
    end
  end

  def validate_buyer_2_nationality
    if field_38.present? && !valid_nationality_options.include?(field_38.to_s)
      errors.add(:field_38, I18n.t("#{ERROR_BASE_KEY}.nationality.invalid"))
    end
  end

  def valid_nationality_options
    %w[0] + GlobalConstants::COUNTRIES_ANSWER_OPTIONS.keys # 0 is "Prefers not to say"
  end

  def bulk_upload_organisation
    Organisation.find(bulk_upload.organisation_id)
  end
end
