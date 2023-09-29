module Imports
  class LettingsLogsFieldImportService < LogsImportService
    def update_field(field, folder)
      case field
      when "tenancycode"
        import_from(folder, :update_tenant_code)
      when "major_repairs"
        import_from(folder, :update_major_repairs)
      when "lettings_allocation"
        import_from(folder, :update_lettings_allocation)
      when "offered"
        import_from(folder, :update_offered)
      when "creation_method"
        import_from(folder, :update_creation_method)
      when "address"
        import_from(folder, :update_address)
      when "reason"
        import_from(folder, :update_reason)
      when "homeless"
        import_from(folder, :update_homelessness)
      when "created_by"
        import_from(folder, :update_created_by)
      when "sex_and_relat"
        import_from(folder, :update_sex_and_relat)
      when "general_needs_referral"
        import_from(folder, :update_general_needs_referral)
      when "person_details"
        import_from(folder, :update_person_details)
      when "childrens_care_referral"
        import_from(folder, :update_childrens_care_referral)
      when "old_form_id"
        import_from(folder, :update_old_form_id)
      else
        raise "Updating #{field} is not supported by the field import service"
      end
    end

  private

    def update_offered(xml_doc)
      return if meta_field_value(xml_doc, "form-name").include?("Sales")

      old_id = meta_field_value(xml_doc, "document-id")
      record = LettingsLog.find_by(old_id:)

      if record.present?
        if record.offered.present?
          @logger.info("lettings log #{record.id} has a value for offered, skipping update")
        else
          offered = safe_string_as_integer(xml_doc, "Q20")
          record.update!(offered:)
          @logger.info("lettings log #{record.id}'s offered value has been set to #{offered}")
        end
      else
        @logger.warn("lettings log with old id #{old_id} not found")
      end
    end

    def update_creation_method(xml_doc)
      return if meta_field_value(xml_doc, "form-name").include?("Sales")

      old_id = meta_field_value(xml_doc, "document-id")
      log = LettingsLog.find_by(old_id:)

      return @logger.warn "lettings log with old id #{old_id} not found" unless log

      upload_id = meta_field_value(xml_doc, "upload-id")

      if upload_id.nil?
        @logger.info "lettings log with old id #{old_id} entered manually, no need for update"
      elsif log.creation_method_bulk_upload?
        @logger.info "lettings log #{log.id} creation method already set to bulk upload, no need for update"
      else
        log.creation_method_bulk_upload!
        @logger.info "lettings log #{log.id} creation method set to bulk upload"
      end
    end

    def update_lettings_allocation(xml_doc)
      return if meta_field_value(xml_doc, "form-name").include?("Sales")

      old_id = meta_field_value(xml_doc, "document-id")
      previous_status = meta_field_value(xml_doc, "status")
      record = LettingsLog.find_by(old_id:)

      if record.present? && previous_status.include?("submitted")
        cbl = unsafe_string_as_integer(xml_doc, "Q15CBL")
        chr = unsafe_string_as_integer(xml_doc, "Q15CHR")
        cap = unsafe_string_as_integer(xml_doc, "Q15CAP")
        if cbl == 2 && record.cbl == 1
          record.update!(cbl: 0)
          @logger.info("lettings log #{record.id}'s cbl value has been updated'")
        end
        if chr == 2 && record.chr == 1
          record.update!(chr: 0)
          @logger.info("lettings log #{record.id}'s chr value has been updated'")
        end
        if cap == 2 && record.cap == 1
          record.update!(cap: 0)
          @logger.info("lettings log #{record.id}'s cap value has been updated'")
        end
        if cbl == 2 && chr == 2 && cap == 2 && record.letting_allocation_unknown.nil?
          record.update!(letting_allocation_unknown: 1)
          @logger.info("lettings log #{record.id}'s letting_allocation_unknown value has been updated'")
        end
      else
        @logger.warn("Could not find record matching legacy ID #{old_id}")
      end
    end

    def update_major_repairs(xml_doc)
      return if meta_field_value(xml_doc, "form-name").include?("Sales")

      old_id = meta_field_value(xml_doc, "document-id")
      record = LettingsLog.find_by(old_id:)

      if record.present?
        previous_status = meta_field_value(xml_doc, "status")
        major_repairs_date = compose_date(xml_doc, "MRCDAY", "MRCMONTH", "MRCYEAR")
        major_repairs = if major_repairs_date.present? && previous_status.include?("submitted")
                          1
                        elsif previous_status.include?("submitted")
                          0
                        end
        if major_repairs.present? && record.majorrepairs.nil? && record.status != "completed"
          record.update!(mrcdate: major_repairs_date, majorrepairs: major_repairs)
          @logger.info("lettings log #{record.id}'s major repair value has been updated'")
        elsif record.majorrepairs.present?
          @logger.info("lettings log #{record.id} has a value for major repairs, skipping update")
        end
      else
        @logger.warn("Could not find record matching legacy ID #{old_id}")
      end
    end

    def update_tenant_code(xml_doc)
      return if meta_field_value(xml_doc, "form-name").include?("Sales")

      old_id = meta_field_value(xml_doc, "document-id")
      record = LettingsLog.find_by(old_id:)

      if record.present?
        tenant_code = string_or_nil(xml_doc, "_2bTenCode")
        if tenant_code.present? && record.tenancycode.blank?
          record.update!(tenancycode: tenant_code)
        else
          @logger.info("lettings log #{record.id} has a value for tenancycode, skipping update")
        end
      else
        @logger.warn("Could not find record matching legacy ID #{old_id}")
      end
    end

    def update_address(xml_doc)
      return if meta_field_value(xml_doc, "form-name").include?("Sales")

      old_id = meta_field_value(xml_doc, "document-id")
      record = LettingsLog.find_by(old_id:)
      return @logger.info("lettings log #{record.id} is from previous collection year, skipping") if record.collection_start_year < 2023

      if record.present?
        if string_or_nil(xml_doc, "AddressLine1").present? && string_or_nil(xml_doc, "TownCity").present?
          record.la = string_or_nil(xml_doc, "Q28ONS")
          record.postcode_full = compose_postcode(xml_doc, "POSTCODE", "POSTCOD2")
          record.postcode_known = postcode_known(record)
          record.address_line1 = string_or_nil(xml_doc, "AddressLine1")
          record.address_line2 = string_or_nil(xml_doc, "AddressLine2")
          record.town_or_city = string_or_nil(xml_doc, "TownCity")
          record.county = string_or_nil(xml_doc, "County")
          record.uprn = nil
          record.uprn_known = 0
          record.uprn_confirmed = 0
          record.values_updated_at = Time.zone.now
          record.save!
          @logger.info("lettings log #{record.id} address_line1 value has been set to #{record.address_line1}")
          @logger.info("lettings log #{record.id} address_line2 value has been set to #{record.address_line2}")
          @logger.info("lettings log #{record.id} town_or_city value has been set to #{record.town_or_city}")
          @logger.info("lettings log #{record.id} county value has been set to #{record.county}")
          @logger.info("lettings log #{record.id} postcode_full value has been set to #{record.postcode_full}")
        else
          @logger.info("lettings log #{record.id} is missing either or both of address_line1 and town or city, skipping")
        end
      else
        @logger.warn("Could not find record matching legacy ID #{old_id}")
      end
    end

    def postcode_known(record)
      if record.postcode_full.nil?
        record.la.nil? ? nil : 0 # Assumes we selected No in the form since the LA is present
      else
        1
      end
    end

    def update_reason(xml_doc)
      return if meta_field_value(xml_doc, "form-name").include?("Sales")

      old_id = meta_field_value(xml_doc, "document-id")
      record = LettingsLog.find_by(old_id:)

      if record.present?
        if record.reason.present?
          @logger.info("lettings log #{record.id} has a value for reason, skipping update")
        else
          reason = unsafe_string_as_integer(xml_doc, "Q9a")
          reasonother = string_or_nil(xml_doc, "Q9aa")
          if reason == 20 && reasonother.blank?
            @logger.info("lettings log #{record.id}'s reason is other but other reason is not provided, skipping update")
          else
            record.update!(reason:, reasonother:, values_updated_at: Time.zone.now)
            @logger.info("lettings log #{record.id}'s reason value has been set to #{reason}")
            @logger.info("lettings log #{record.id}'s reasonother value has been set to #{reasonother}") if record.reasonother.present?
          end
        end
      else
        @logger.warn("lettings log with old id #{old_id} not found")
      end
    end

    def update_homelessness(xml_doc)
      return if meta_field_value(xml_doc, "form-name").include?("Sales")

      old_id = meta_field_value(xml_doc, "document-id")
      record = LettingsLog.find_by(old_id:)
      if record.present?
        return @logger.info("lettings log #{record.id} has a value for homeless and rp_homeless, skipping update") if record.rp_homeless == 1 && record.homeless.present?
        return @logger.info("lettings log #{record.id} has a value for homeless and reasonpref is not yes, skipping update") if record.reasonpref != 1 && record.homeless.present?
        return @logger.info("lettings log #{record.id} reimport values are not homeless - 1 (no) and rp_homeless - yes, skipping update") if unsafe_string_as_integer(xml_doc, "Q14b1").blank? || unsafe_string_as_integer(xml_doc, "Q13") != 1

        if record.rp_homeless != 1 && record.reasonpref == 1
          record.rp_homeless = 1
          @logger.info("updating lettings log #{record.id}'s rp_homeless value to 1")
        end
        if record.homeless.blank?
          record.homeless = 1
          @logger.info("updating lettings log #{record.id}'s homeless value to 1")
        end
        record.values_updated_at = Time.zone.now
        record.save!
      else
        @logger.warn("Could not find record matching legacy ID #{old_id}")
      end
    end

    # deletes and recreates the entire record if created_by is missing
    def update_created_by(xml_doc)
      return if meta_field_value(xml_doc, "form-name").include?("Sales")

      old_id = meta_field_value(xml_doc, "document-id")
      record = LettingsLog.find_by(old_id:)

      return @logger.warn("lettings log with old id #{old_id} not found") unless record
      return @logger.info("lettings log #{record.id} has created_by value, skipping update") if record.created_by.present?

      record.destroy!
      @logger.info("lettings log #{record.id} has been deleted")
      log_import_service = Imports::LettingsLogsImportService.new(nil, @logger)
      log_import_service.send(:create_log, xml_doc)
      @logger.info("lettings log \"#{record.old_id}\" has been reimported with id #{record.id}")
    end

    def update_sex_and_relat(xml_doc)
      return if meta_field_value(xml_doc, "form-name").include?("Sales")

      old_id = meta_field_value(xml_doc, "document-id")
      record = LettingsLog.find_by(old_id:)

      return @logger.warn("lettings log with old id #{old_id} not found") unless record
      return @logger.info("lettings log #{record.id} has no hhmemb value, skipping update") if record.hhmemb.blank?

      if record.sex1.present?
        @logger.info("lettings log #{record.id} has value for sex1, skipping person")
      else
        record.sex1 = sex(xml_doc, 1)
        @logger.info("lettings log #{record.id}'s sex1 value has been set to #{record.sex1}")
      end

      (2..record.hhmemb).each do |i|
        next @logger.info("lettings log #{record.id} has values for sex#{i} and relat#{i}, skipping person") if record["sex#{i}"] && record["relat#{i}"]
        next @logger.info("lettings log #{record.id} has value 'no' for details_known_#{i}, skipping person") if record.details_not_known_for_person?(i)

        if record["sex#{i}"].blank?
          record["sex#{i}"] = sex(xml_doc, i)
          @logger.info("lettings log #{record.id}'s sex#{i} value has been set to #{record["sex#{i}"]}")
        end

        if record["relat#{i}"].blank?
          record["relat#{i}"] = relat(xml_doc, i)
          @logger.info("lettings log #{record.id}'s relat#{i} value has been set to #{record["relat#{i}"]}")
        end
      end

      if record.changed?
        record.values_updated_at = Time.zone.now
        record.save!
      end
    end

    def update_general_needs_referral(xml_doc)
      return if meta_field_value(xml_doc, "form-name").include?("Sales")

      old_id = meta_field_value(xml_doc, "document-id")
      record = LettingsLog.find_by(old_id:)

      return @logger.warn("lettings log with old id #{old_id} not found") unless record
      return @logger.info("lettings log #{record.id} has a value for referral, skipping update") if record.referral.present?
      return @logger.info("lettings log #{record.id} is a supported housing log, skipping update") if record.needstype == 2
      return @logger.info("lettings log #{record.id}'s owning organisation's provider type is LA, skipping update") if record.owning_organisation.provider_type == "LA"
      return @logger.info("lettings log #{record.id} reimport referral value is not 4, skipping update") if unsafe_string_as_integer(xml_doc, "Q16") != 4

      record.update!(referral: 4, referral_value_check: 0, values_updated_at: Time.zone.now)
      @logger.info("lettings log #{record.id}'s referral value has been set to 4")
    end

    def update_person_details(xml_doc)
      return if meta_field_value(xml_doc, "form-name").include?("Sales")

      old_id = meta_field_value(xml_doc, "document-id")
      record = LettingsLog.find_by(old_id:)

      return @logger.warn("lettings log with old id #{old_id} not found") unless record
      return @logger.info("lettings log #{record.id} has no hhmemb, skipping update") unless record.hhmemb

      if (2..record.hhmemb).all? { |person_index| record.has_any_person_details?(person_index) || record.details_not_known_for_person?(person_index) }
        return @logger.info("lettings log #{record.id} has all household member details, skipping update")
      end
      if record.hhmemb == 8 || ((record.hhmemb + 1)..8).none? { |person_index| file_contains_person_details?(xml_doc, person_index) }
        return @logger.info("lettings log #{record.id} has no additional household member details, skipping update")
      end

      person_index = 2
      next_person_index = person_index + 1

      while person_exists_on_the_log?(record, person_index)
        if person_exists_on_the_log?(record, next_person_index)
          if record.has_any_person_details?(person_index) || record.details_not_known_for_person?(person_index)
            @logger.info("lettings log #{record.id} has details for person #{person_index}, skipping person")
            person_index += 1
            next_person_index += 1
            next
          end

          if !record.has_any_person_details?(next_person_index) && !record.details_not_known_for_person?(next_person_index)
            next_person_index += 1
            next
          end

          move_person_details(record, person_index, next_person_index)
        else
          reimport_person_details(record, xml_doc, person_index, next_person_index)
        end

        person_index += 1
        next_person_index += 1
      end

      record.values_updated_at = Time.zone.now
      record.save!
    end

    def age_known(xml_doc, person_index)
      age_refused = string_or_nil(xml_doc, "P#{person_index}AR")
      if age_refused.present?
        if age_refused.casecmp?("AGE_REFUSED") || age_refused.casecmp?("No")
          return 1 # No
        else
          return 0 # Yes
        end
      end
      0
    end

    def details_known(index, record)
      if record["age#{index}_known"] == 1 &&
          record["sex#{index}"] == "R" &&
          record["relat#{index}"] == "R" &&
          record["ecstat#{index}"] == 10
        1 # No
      else
        0 # Yes
      end
    end

    def file_contains_person_details?(xml_doc, person_index)
      safe_string_as_integer(xml_doc, "P#{person_index}Age").present? ||
        string_or_nil(xml_doc, "P#{person_index}Sex").present? ||
        unsafe_string_as_integer(xml_doc, "P#{person_index}Eco").present? ||
        string_or_nil(xml_doc, "P#{person_index}Rel").present?
    end

    def move_person_details(record, person_index, next_person_index)
      record["details_known_#{person_index}"] = record["details_known_#{next_person_index}"]
      record["age#{person_index}"] = record["age#{next_person_index}"]
      record["age#{person_index}_known"] = record["age#{next_person_index}_known"]
      record["sex#{person_index}"] = record["sex#{next_person_index}"]
      record["ecstat#{person_index}"] = record["ecstat#{next_person_index}"]
      record["relat#{person_index}"] = record["relat#{next_person_index}"]

      record["details_known_#{next_person_index}"] = nil
      record["age#{next_person_index}"] = nil
      record["age#{next_person_index}_known"] = nil
      record["sex#{next_person_index}"] = nil
      record["ecstat#{next_person_index}"] = nil
      record["relat#{next_person_index}"] = nil

      @logger.info("lettings log #{record.id}'s person #{next_person_index} details moved to person #{person_index} details")
    end

    def reimport_person_details(record, xml_doc, person_index, next_person_index)
      record["age#{person_index}"] = safe_string_as_integer(xml_doc, "P#{next_person_index}Age")
      record["age#{person_index}_known"] = age_known(xml_doc, next_person_index)
      record["sex#{person_index}"] = sex(xml_doc, next_person_index)
      record["ecstat#{person_index}"] = unsafe_string_as_integer(xml_doc, "P#{next_person_index}Eco")
      record["relat#{person_index}"] = relat(xml_doc, next_person_index)
      record["details_known_#{person_index}"] = details_known(person_index, record)
      @logger.info("lettings log #{record.id}, reimported person #{person_index} details")
    end

    def person_exists_on_the_log?(record, person_index)
      person_index <= record.hhmemb
    end

    def update_childrens_care_referral(xml_doc)
      return if meta_field_value(xml_doc, "form-name").include?("Sales")

      old_id = meta_field_value(xml_doc, "document-id")
      record = LettingsLog.find_by(old_id:)

      return @logger.warn("lettings log with old id #{old_id} not found") unless record
      return @logger.info("lettings log #{record.id} has a value for referral, skipping update") if record.referral.present?
      return @logger.info("lettings log #{record.id} reimport referral value is not 17, skipping update") if unsafe_string_as_integer(xml_doc, "Q16") != 17

      record.update!(referral: 17, values_updated_at: Time.zone.now)
      @logger.info("lettings log #{record.id}'s referral value has been set to 17")
    end

    def update_old_form_id(xml_doc)
      return if meta_field_value(xml_doc, "form-name").include?("Sales")

      old_id = meta_field_value(xml_doc, "document-id")
      record = LettingsLog.find_by(old_id:)

      if record.present?
        if record.old_form_id.present?
          @logger.info("lettings log #{record.id} has a value for old_form_id, skipping update")
        else
          old_form_id = safe_string_as_integer(xml_doc, "FORM")
          record.update!(old_form_id:)
          @logger.info("lettings log #{record.id}'s old_form_id value has been set to #{old_form_id}")
        end
      else
        @logger.warn("lettings log with old id #{old_id} not found")
      end
    end
  end
end
