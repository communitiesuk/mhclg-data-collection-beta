desc "Bulk update logs with invalid rp_dontknow values"
task recalculate_invalid_rpdontknow: :environment do
  validation_trigger_condition = "rp_dontknow = 1 AND (rp_homeless = 1 OR rp_insan_unsat = 1 OR rp_medwel = 1 OR rp_hardship = 1)"

  LettingsLog.filter_by_year(2024).where(validation_trigger_condition).find_each do |log|
    log.rp_dontknow = 0

    unless log.save
      Rails.logger.info "Could not save changes to lettings log #{log.id}"
    end
  end
end
