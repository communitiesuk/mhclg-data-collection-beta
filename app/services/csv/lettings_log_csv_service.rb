module Csv
  class LettingsLogCsvService
    def initialize(user:, export_type:, year:)
      @user = user
      @export_type = export_type
      @year = year
      @attributes = lettings_log_attributes
      @definitions = lettings_log_definitions
    end

    def prepare_csv(logs)
      CSV.generate(headers: true) do |csv|
        if @year >= 2023
          csv << @attributes.map do |attribute|
            record = @definitions.find { |r| r.variable == attribute.downcase }
            record&.tap { |r| r.update!(last_accessed: Time.zone.now) }&.definition
          end
        end
        csv << @attributes

        logs.find_each do |log|
          csv << @attributes.map { |attribute| value(attribute, log) }
        end
      end
    end

  private

    CUSTOM_CALL_CHAINS = {
      assigned_to: {
        labels: %i[assigned_to email],
        codes: %i[assigned_to email],
      },
      created_by: {
        labels: %i[created_by email],
        codes: %i[created_by email],
      },
      updated_by: {
        labels: %i[updated_by email],
        codes: %i[updated_by email],
      },
      location_code: {
        labels: %i[location id],
        codes: %i[location id],
      },
      location_postcode: {
        labels: %i[location postcode],
        codes: %i[location postcode],
      },
      location_name: {
        labels: %i[location name],
        codes: %i[location name],
      },
      location_units: {
        labels: %i[location units],
        codes: %i[location units],
      },
      location_type_of_unit: {
        labels: %i[location type_of_unit],
        codes: %i[location type_of_unit_before_type_cast],
      },
      location_mobility_type: {
        labels: %i[location mobility_type],
        codes: %i[location mobility_type_before_type_cast],
      },
      location_local_authority: {
        labels: %i[location location_admin_district],
        codes: %i[location location_admin_district],
      },
      location_startdate: {
        labels: %i[location startdate],
        codes: %i[location startdate],
      },
      scheme_service_name: {
        labels: %i[scheme service_name],
        codes: %i[scheme service_name],
      },
      scheme_confidential: {
        labels: %i[scheme sensitive],
        codes: %i[scheme sensitive_before_type_cast],
      },
      SCHTYPE: {
        labels: %i[scheme scheme_type],
        codes: %i[scheme scheme_type_before_type_cast],
      },
      scheme_registered_under_care_act: {
        labels: %i[scheme registered_under_care_act],
        codes: %i[scheme registered_under_care_act_before_type_cast],
      },
      scheme_owning_organisation_name: {
        labels: %i[scheme owning_organisation name],
        codes: %i[scheme owning_organisation name],
      },
      scheme_primary_client_group: {
        labels: %i[scheme primary_client_group],
        codes: %i[scheme primary_client_group_before_type_cast],
      },
      scheme_has_other_client_group: {
        labels: %i[scheme has_other_client_group],
        codes: %i[scheme has_other_client_group_before_type_cast],
      },
      scheme_secondary_client_group: {
        labels: %i[scheme secondary_client_group],
        codes: %i[scheme secondary_client_group_before_type_cast],
      },
      scheme_support_type: {
        labels: %i[scheme support_type],
        codes: %i[scheme support_type_before_type_cast],
      },
      scheme_intended_stay: {
        labels: %i[scheme intended_stay],
        codes: %i[scheme intended_stay_before_type_cast],
      },
      scheme_created_at: {
        labels: %i[scheme created_at],
        codes: %i[scheme created_at],
      },
      scheme_code: {
        labels: %i[scheme id_to_display],
        codes: %i[scheme id_to_display],
      },
      creation_method: {
        labels: %i[creation_method],
        codes: %i[creation_method_before_type_cast],
      },
      is_dpo: {
        labels: %i[assigned_to is_dpo?],
        codes: %i[assigned_to is_dpo?],
      },
      renttype_detail: {
        labels: %i[renttype_detail],
        codes: %i[renttype_detail_code],
      },
    }.freeze

    PERSON_DETAILS = {}.tap { |hash|
      hash["age1"] = { "refused_code" => "-9", "refused_label" => "Not known", "age_known_field" => "age1_known" }
      (2..8).each do |i|
        hash["age#{i}"] = { "refused_code" => "-9", "refused_label" => "Not known", "details_known_field" => "details_known_#{i}", "age_known_field" => "age#{i}_known" }
        hash["sex#{i}"] = { "refused_code" => "R", "refused_label" => "Prefers not to say", "details_known_field" => "details_known_#{i}" }
        hash["relat#{i}"] = { "refused_code" => "R", "refused_label" => "Prefers not to say", "details_known_field" => "details_known_#{i}" }
        hash["ecstat#{i}"] = { "refused_code" => "10", "refused_label" => "Prefers not to say", "details_known_field" => "details_known_#{i}" }
      end
    }.freeze

    FIELDS_ALWAYS_EXPORTED_AS_CODES = %w[
      la
      prevloc
    ].freeze

    FIELDS_ALWAYS_EXPORTED_AS_LABELS = {
      "la_label" => "la",
      "prevloc_label" => "prevloc",
    }.freeze

    SYSTEM_DATE_FIELDS = %w[
      created_at
      updated_at
    ].freeze

    USER_DATE_FIELDS = %w[
      mrcdate
      startdate
      voiddate
    ].freeze

    LETTYPE_LABELS = {
      1 => "Social rent general needs private registered provider",
      2 => "Social rent supported housing private registered provider",
      3 => "Social rent general needs local authority",
      4 => "Social rent supported housing local authority",
      5 => "Affordable rent general needs private registered provider",
      6 => "Affordable rent supported housing private registered provider",
      7 => "Affordable rent general needs local authority",
      8 => "Affordable rent supported housing local authority",
      9 => "Intermediate rent general needs private registered provider",
      10 => "Intermediate rent supported housing private registered provider",
      11 => "Intermediate rent general needs local authority",
      12 => "Intermediate rent supported housing local authority",
    }.freeze

    IRPRODUCT_LABELS = {
      1 => "Rent to Buy",
      2 => "London Living Rent",
      3 => "Other intermediate rent product",
    }.freeze

    LAR_LABELS = {
      1 => "Yes",
      2 => "No",
      3 => "Don't know",
    }.freeze

    NEWPROP_LABELS = {
      1 => "Yes",
      2 => "No",
    }.freeze

    INCREF_LABELS = {
      0 => "No",
      2 => "Yes",
      1 => "Prefers not to say",
    }.freeze

    RENTTYPE_LABELS = {
      1 => "Social Rent",
      2 => "Affordable Rent",
      3 => "Intermediate Rent",
    }.freeze

    UPRN_KNOWN_LABELS = {
      0 => "No",
      1 => "Yes",
    }.freeze

    LABELS = {
      "lettype" => LETTYPE_LABELS,
      "irproduct" => IRPRODUCT_LABELS,
      "lar" => LAR_LABELS,
      "newprop" => NEWPROP_LABELS,
      "incref" => INCREF_LABELS,
      "renttype" => RENTTYPE_LABELS,
      "uprn_known" => UPRN_KNOWN_LABELS,
    }.freeze

    CONVENTIONAL_YES_NO_ATTRIBUTES = %w[illness_type_1 illness_type_2 illness_type_3 illness_type_4 illness_type_5 illness_type_6 illness_type_7 illness_type_8 illness_type_9 illness_type_10 refused cbl cap chr accessible_register letting_allocation_none housingneeds_a housingneeds_b housingneeds_c housingneeds_d housingneeds_e housingneeds_f housingneeds_g housingneeds_h has_benefits nocharge postcode_known].freeze

    YES_OR_BLANK_ATTRIBUTES = %w[declaration rp_homeless rp_insan_unsat rp_medwel rp_hardship rp_dontknow].freeze

    ATTRIBUTE_MAPPINGS = {
      "owning_organisation_id" => %w[owning_organisation_name],
      "managing_organisation_id" => %w[managing_organisation_name],
      "assigned_to_id" => [],
      "scheme_id" => [],
      "location_id" => [],
      "rent_type" => %w[renttype renttype_detail],
      "hb" => %w[hb has_benefits],
      "age1" => %w[refused hhtype totchild totelder totadult age1],
      "housingneeds_type" => %w[housingneeds_type housingneeds_a housingneeds_b housingneeds_c housingneeds_f housingneeds_g housingneeds_h],
      "net_income_known" => %w[net_income_known incref],
      "irproduct_other" => %w[irproduct irproduct_other lar],
      "la" => %w[is_la_inferred la_label la],
      "prevloc" => %w[is_previous_la_inferred prevloc_label prevloc],
      "needstype" => %w[needstype lettype],
      "voiddate" => %w[voiddate vacdays],
      "rsnvac" => %w[rsnvac newprop],
      "household_charge" => %w[household_charge nocharge],
      "brent" => %w[brent wrent rent_value_check],
      "scharge" => %w[scharge wscharge],
      "pscharge" => %w[pscharge wpschrge],
      "supcharg" => %w[supcharg wsupchrg],
      "tcharge" => %w[tcharge wtcharge],
      "chcharge" => %w[chcharge wchchrg],
      "tshortfall" => %w[tshortfall wtshortfall],
      "letting_allocation_unknown" => %w[letting_allocation_none],
    }.freeze

    ATTRIBUTE_MAPPINGS_2024 = {
      "uprn" => %w[uprn_known uprn],
    }.freeze

    def attribute_mappings
      if @year >= 2024
        ATTRIBUTE_MAPPINGS.merge(ATTRIBUTE_MAPPINGS_2024)
      else
        ATTRIBUTE_MAPPINGS
      end
    end

    ORDERED_ADDRESS_FIELDS = %w[uprn address_line1 address_line2 town_or_city county postcode_full is_la_inferred la_label la uprn_known uprn_selection address_search_value_check address_line1_input postcode_full_input address_line1_as_entered address_line2_as_entered town_or_city_as_entered county_as_entered postcode_full_as_entered la_as_entered].freeze

    SUPPORT_ONLY_ATTRIBUTES = %w[postcode_known is_la_inferred totchild totelder totadult net_income_known previous_la_known is_previous_la_inferred age1_known age2_known age3_known age4_known age5_known age6_known age7_known age8_known details_known_2 details_known_3 details_known_4 details_known_5 details_known_6 details_known_7 details_known_8 wrent wscharge wpschrge wsupchrg wtcharge wtshortfall old_form_id old_id tshortfall_known hhtype la prevloc updated_by_id uprn_confirmed address_line1_input postcode_full_input uprn_selection address_line1_as_entered address_line2_as_entered town_or_city_as_entered county_as_entered postcode_full_as_entered la_as_entered created_by].freeze

    SCHEME_AND_LOCATION_ATTRIBUTES = %w[scheme_code scheme_service_name scheme_confidential SCHTYPE scheme_registered_under_care_act scheme_owning_organisation_name scheme_primary_client_group scheme_has_other_client_group scheme_secondary_client_group scheme_support_type scheme_intended_stay scheme_created_at location_code location_postcode location_name location_units location_type_of_unit location_mobility_type location_local_authority location_startdate].freeze

    def lettings_log_attributes
      ordered_questions = FormHandler.instance.ordered_questions_for_year(@year, "lettings")
      soft_validations_attributes = soft_validations_attributes(ordered_questions)
      ordered_questions.reject! { |q| q.id.match?(/age\d_known|nationality_all_group|rent_value_check/) }
      attributes = insert_derived_and_related_attributes(ordered_questions)
      order_address_fields_for_support(attributes)
      final_attributes = non_question_fields + attributes + SCHEME_AND_LOCATION_ATTRIBUTES
      @user.support? ? final_attributes : final_attributes - SUPPORT_ONLY_ATTRIBUTES - soft_validations_attributes
    end

    def lettings_log_definitions
      CsvVariableDefinition.lettings.group_by { |record| [record.variable, record.definition] }
                           .map do |_, options|
        exact_match = options.find { |definition| definition.year == @year }
        next exact_match if exact_match

        options.max_by(&:year)
      end
    end

    def insert_derived_and_related_attributes(ordered_questions)
      ordered_questions.flat_map do |question|
        if question.type == "checkbox"
          question.answer_options.keys.reject { |key| key == "divider" }.map { |key|
            attribute_mappings.fetch(key, key)
          }.flatten
        else
          attribute_mappings.fetch(question.id, question.id)
        end
      end
    end

    def order_address_fields_for_support(attributes)
      if @user.support? && @year >= 2024
        first_address_field_index = attributes.find_index { |q| all_address_fields.include?(q) }
        if first_address_field_index
          attributes.reject! { |q| all_address_fields.include?(q) }
          attributes.insert(first_address_field_index, *ORDERED_ADDRESS_FIELDS)
        end
      end
    end

    def all_address_fields
      ORDERED_ADDRESS_FIELDS + %w[uprn_confirmed]
    end

    def non_question_fields
      case @year
      when 2022
        %w[id status created_by assigned_to is_dpo created_at updated_by updated_at creation_method old_id old_form_id collection_start_year]
      when 2023
        %w[id status duplicate_set_id created_by assigned_to is_dpo created_at updated_by updated_at creation_method old_id old_form_id collection_start_year]
      when 2024
        %w[id status duplicate_set_id created_by assigned_to is_dpo created_at updated_by updated_at creation_method collection_start_year bulk_upload_id]
      else
        %w[id status duplicate_set_id created_by assigned_to is_dpo created_at updated_by updated_at creation_method collection_start_year bulk_upload_id]
      end
    end

    def soft_validations_attributes(ordered_questions)
      ordered_questions.select { |q| q.type == "interruption_screen" }.map(&:id)
    end

    def value(attribute, log)
      attribute = "rent_type" if attribute == "rent_type_detail" # rent_type_detail is the requested column header for rent_type, so as not to confuse with renttype. It can be exported as label or code.
      if CUSTOM_CALL_CHAINS.key? attribute.to_sym
        call_chain = CUSTOM_CALL_CHAINS[attribute.to_sym][@export_type.to_sym]
        call_chain.reduce(log) { |object, next_call| object&.public_send(next_call) }
      elsif FIELDS_ALWAYS_EXPORTED_AS_CODES.include? attribute
        log.public_send(attribute)
      elsif FIELDS_ALWAYS_EXPORTED_AS_LABELS.key? attribute
        attribute = FIELDS_ALWAYS_EXPORTED_AS_LABELS[attribute]
        value = log.public_send(attribute)
        get_label(value, attribute, log)
      elsif SYSTEM_DATE_FIELDS.include? attribute
        log.public_send(attribute)&.iso8601
      elsif USER_DATE_FIELDS.include? attribute
        log.public_send(attribute)&.strftime("%F")
      elsif PERSON_DETAILS.any? { |key, _value| key == attribute } && (person_details_not_known?(log, attribute) || age_not_known?(log, attribute))
        case @export_type
        when "codes"
          PERSON_DETAILS.find { |key, _value| key == attribute }[1]["refused_code"]
        when "labels"
          PERSON_DETAILS.find { |key, _value| key == attribute }[1]["refused_label"]
        end
      else
        value = log.public_send(attribute)
        case @export_type
        when "codes"
          value
        when "labels"
          answer_label = get_label(value, attribute, log)
          answer_label || label_if_boolean_value(value) || (YES_OR_BLANK_ATTRIBUTES.include?(attribute) && value != 1 ? nil : value)
        end
      end
    end

    def person_details_not_known?(log, attribute)
      details_known_field = PERSON_DETAILS.find { |key, _value| key == attribute }[1]["details_known_field"]
      log[details_known_field] == 1 # 1 for lettings logs, 2 for sales logs
    end

    def age_not_known?(log, attribute)
      age_known_field = PERSON_DETAILS.find { |key, _value| key == attribute }[1]["age_known_field"]
      log[age_known_field] == 1
    end

    def get_label(value, attribute, log)
      return LABELS[attribute][value] if LABELS.key?(attribute)
      return conventional_yes_no_label(value) if CONVENTIONAL_YES_NO_ATTRIBUTES.include?(attribute)
      return "Yes" if YES_OR_BLANK_ATTRIBUTES.include?(attribute) && value == 1

      log.form
         .get_question(attribute, log)
         &.label_from_value(value)
    end

    def label_if_boolean_value(value)
      return "Yes" if value == true
      return "No" if value == false
    end

    def conventional_yes_no_label(value)
      return "Yes" if value == 1
      return "No" if value&.zero?
    end
  end
end
