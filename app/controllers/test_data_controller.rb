class TestDataController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  def create_test_lettings_log
    return render_not_found unless FeatureToggle.create_test_logs_enabled?

    log = FactoryBot.create(:lettings_log, :completed, assigned_to: current_user, ppostcode_full: "SW1A 1AA", manual_address_entry_selected: false)
    redirect_to lettings_log_path(log)
  end

  def create_setup_test_lettings_log
    return render_not_found unless FeatureToggle.create_test_logs_enabled?

    log = FactoryBot.create(:lettings_log, :setup_completed, assigned_to: current_user, manual_address_entry_selected: false)
    redirect_to lettings_log_path(log)
  end

  def create_2024_test_lettings_bulk_upload
    return render_not_found unless FeatureToggle.create_test_logs_enabled?

    file = Tempfile.new("test_lettings_log.csv")
    log = FactoryBot.create(:lettings_log, :completed, assigned_to: current_user, ppostcode_full: "SW1A 1AA")
    log_to_csv = BulkUpload::LettingsLogToCsv.new(log:, line_ending: "\n", overrides: { organisation_id: "ORG#{log.owning_organisation_id}", managing_organisation_id: "ORG#{log.owning_organisation_id}" })
    file.write(log_to_csv.default_field_numbers_row)
    file.write(log_to_csv.to_csv_row)
    file.rewind
    send_file file.path, type: "text/csv",
                         filename: "test_lettings_log.csv",
                         disposition: "attachment",
                         after_send: lambda {
                                       file.close
                                       file.unlink
                                     }
  end

  def create_test_sales_log
    return render_not_found unless FeatureToggle.create_test_logs_enabled?

    log = FactoryBot.create(:sales_log, :completed, assigned_to: current_user, manual_address_entry_selected: false)
    redirect_to sales_log_path(log)
  end

  def create_setup_test_sales_log
    return render_not_found unless FeatureToggle.create_test_logs_enabled?

    log = FactoryBot.create(:sales_log, :shared_ownership_setup_complete, assigned_to: current_user, manual_address_entry_selected: false)
    redirect_to sales_log_path(log)
  end

  def create_2024_test_sales_bulk_upload
    return render_not_found unless FeatureToggle.create_test_logs_enabled?

    file = Tempfile.new("test_sales_log.csv")

    log = FactoryBot.create(:sales_log, :completed, assigned_to: current_user, value: 180_000, deposit: 150_000)
    log_to_csv = BulkUpload::SalesLogToCsv.new(log:, line_ending: "\n", overrides: { organisation_id: "ORG#{log.owning_organisation_id}", managing_organisation_id: "ORG#{log.owning_organisation_id}" })
    file.write(log_to_csv.default_field_numbers_row)
    file.write(log_to_csv.to_csv_row)
    file.rewind
    send_file file.path, type: "text/csv",
                         filename: "test_sales_log.csv",
                         disposition: "attachment",
                         after_send: lambda {
                                       file.close
                                       file.unlink
                                     }
  end
end
