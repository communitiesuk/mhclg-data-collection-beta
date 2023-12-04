module LogsHelper
  def log_type_for_controller(controller)
    case controller.class.name
    when "LettingsLogsController" then "lettings"
    when "SalesLogsController" then "sales"
    else
      raise "Log type not found for #{controller.class}"
    end
  end

  def page_title
    case controller.class.name
    when "LettingsLogsController" then "Lettings logs"
    when "SalesLogsController" then "Sales logs"
    else
      case action_name
      when "lettings_logs" then "Lettings logs"
      when "sales_logs" then "Sales logs"
      else
        raise "Log type not found for #{controller.class}, #{action_name}"
      end
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

  def csv_download_url_for_controller(controller:, search:, codes_only:)
    case log_type_for_controller(controller)
    when "lettings" then csv_download_lettings_logs_path(search:, codes_only:)
    when "sales" then csv_download_sales_logs_path(search:, codes_only:)
    end
  end

  def logs_path_for_controller(controller)
    case log_type_for_controller(controller)
    when "lettings" then lettings_logs_path
    when "sales" then sales_logs_path
    end
  end

  def csv_download_url_by_log_type(log_type, organisation, search:, codes_only:)
    case log_type
    when :lettings then lettings_logs_csv_download_organisation_path(organisation, search:, codes_only:)
    when :sales then sales_logs_csv_download_organisation_path(organisation, search:, codes_only:)
    end
  end

  def logs_and_errors_warning(bulk_upload)
    this_or_these_errors = bulk_upload.bulk_upload_errors.count == 1 ? "This error" : "These errors"

    "You will upload #{pluralize(bulk_upload.total_logs_count, 'log')}. There are errors in #{pluralize(bulk_upload.logs_with_errors_count, 'log')}, and #{pluralize(bulk_upload.bulk_upload_errors.count, 'error')} in total. #{this_or_these_errors} will need to be fixed on the CORE site."
  end

  def logs_and_soft_validations_warning(bulk_upload)
    this_or_these_unexpected_answers = bulk_upload.bulk_upload_errors.count == 1 ? "This unexpected answer" : "These unexpected answers"

    "You will upload #{pluralize(bulk_upload.total_logs_count, 'log')}. There are unexpected answers in #{pluralize(bulk_upload.logs_with_errors_count, 'log')}, and #{pluralize(bulk_upload.bulk_upload_errors.count, 'unexpected answer')} in total. #{this_or_these_unexpected_answers} will be marked as correct."
  end

  def bulk_upload_error_summary(bulk_upload)
    "You have tried to upload #{bulk_upload.total_logs_count ? pluralize(bulk_upload.total_logs_count, 'log') : 'logs'}. There are errors in #{pluralize(bulk_upload.logs_with_errors_count, 'log')}, and #{pluralize(bulk_upload.bulk_upload_errors.count, 'error')} in total."
  end
end
