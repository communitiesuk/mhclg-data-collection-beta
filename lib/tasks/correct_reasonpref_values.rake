desc "Correct invalid BU reasonable preference values"
task correct_reasonpref_values: :environment do
  %w[rp_homeless rp_hardship rp_medwel rp_insan_unsat rp_dontknow].each do |field|
    field_invalid = "#{field} != 1 AND #{field} != 0 AND #{field} is NOT NULL"

    LettingsLog.filter_by_year(2024).where(field_invalid).find_each do |lettings_log|
      lettings_log[field] = 0
      unless lettings_log.save
        Rails.logger.info("Failed to save reasonpref for LettingsLog with id #{lettings_log.id}: #{lettings_log.errors.full_messages}")
      end
    end

    LettingsLog.filter_by_year(2023).where(field_invalid).update_all("#{field}": 0)
  end
end
