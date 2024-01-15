module LogsHelper
  def log_type_for_controller(controller)
    case controller.class.name
    when "LettingsLogsController" then "lettings"
    when "SalesLogsController" then "sales"
    else
      raise "Log type not found for #{controller.class}"
    end
  end

  def bulk_upload_options(bulk_upload)
    array = bulk_upload ? [bulk_upload.id] : []
    array.index_with { |_bulk_upload_id| "With logs from bulk upload" }
  end

  def search_label_for_controller(controller)
    case log_type_for_controller(controller)
    when "lettings" then "Search by log ID, tenant code, property reference or postcode"
    when "sales" then "Search by log ID, purchaser code or postcode"
    end
  end

  def search_label_for_action(action_name)
    case action_name
    when "lettings_logs" then "Search by log ID, tenant code, property reference or postcode"
    when "sales_logs" then "Search by log ID, purchaser code or postcode"
    end
  end

  def csv_download_url_for_controller(controller:, search:, codes_only:)
    case controller.class.name
    when "LettingsLogsController" then csv_download_lettings_logs_path(search:, codes_only:)
    when "SalesLogsController" then csv_download_sales_logs_path(search:, codes_only:)
    end
  end

  def logs_path_for_controller(controller)
    case controller.class.name
    when "LettingsLogsController" then lettings_logs_path
    when "SalesLogsController" then sales_logs_path
    end
  end

  def csv_download_url_by_log_type(log_type, organisation, search:, codes_only:)
    case log_type
    when :lettings then lettings_logs_csv_download_organisation_path(organisation, search:, codes_only:)
    when :sales then sales_logs_csv_download_organisation_path(organisation, search:, codes_only:)
    end
  end

  def logs_and_errors_warning(bulk_upload)
    is_or_are = bulk_upload.total_logs_count == 1 ? "is" : "are"
    need_or_needs = bulk_upload.bulk_upload_errors.count == 1 ? "needs" : "need"

    "There #{is_or_are} #{pluralize(bulk_upload.total_logs_count, 'log')} in this bulk upload with #{pluralize(bulk_upload.bulk_upload_errors.count, 'error')} that still #{need_or_needs} to be fixed after upload."
  end

  def logs_and_soft_validations_warning(bulk_upload)
    this_or_these_unexpected_answers = bulk_upload.bulk_upload_errors.count == 1 ? "This unexpected answer" : "These unexpected answers"

    "You will upload #{pluralize(bulk_upload.total_logs_count, 'log')}. There are unexpected answers in #{pluralize(bulk_upload.logs_with_errors_count, 'log')}, and #{pluralize(bulk_upload.bulk_upload_errors.count, 'unexpected answer')} in total. #{this_or_these_unexpected_answers} will be marked as correct."
  end

  def bulk_upload_error_summary(bulk_upload)
    "You have tried to upload #{bulk_upload.total_logs_count ? pluralize(bulk_upload.total_logs_count, 'log') : 'logs'}. There are errors in #{pluralize(bulk_upload.logs_with_errors_count, 'log')}, and #{pluralize(bulk_upload.bulk_upload_errors.count, 'error')} in total."
  end

  def deleted_errors_warning_text(bulk_upload)
    unique_field_count = bulk_upload.bulk_upload_errors.uniq { |e| e.field }.count
    this_or_these = unique_field_count == 1 ? "this" : "these"
    it_is_or_they_are = unique_field_count == 1 ? "it is" : "they are"

    "#{pluralize(unique_field_count, "answer")} will be deleted because #{it_is_or_they_are} invalid. You will have to answer #{this_or_these} #{"question".pluralize(unique_field_count)} again on the site."
  end
end
