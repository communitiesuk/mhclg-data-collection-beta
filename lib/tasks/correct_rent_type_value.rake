desc "Alter rent_type values for bulk uploaded lettings logs for 2024 where they were not mapped correctly"
task correct_rent_type_value: :environment do
  rent_type_detail_mapping = {
    1 => 0,
    2 => 1,
    3 => 2,
    4 => 3,
    5 => 4,
    6 => 5,
  }
  affected_uploads = BulkUpload.where(log_type: "lettings", year: 2024)
  affected_uploads.each do |upload|
    upload.logs.where.not(rent_type: nil).each do |log|
      current_rent_type = log.rent_type
      rent_type_at_upload = log.versions.length == 1 ? log.rent_type : log.versions.first.next.reify.rent_type
      next unless rent_type_at_upload == current_rent_type

      log.rent_type = rent_type_detail_mapping[rent_type_at_upload]
      log.skip_update_status = true if log.status == "pending"
      if log.save
        Rails.logger.info("Log #{log.id} rent_type updated from #{rent_type_at_upload} to #{log.rent_type}")
      else
        Rails.logger.error("Log #{log.id} rent_type could not be updated from #{rent_type_at_upload} to #{log.rent_type}. Error: #{log.errors.full_messages.join(', ')}")
      end
    end
  end
end
