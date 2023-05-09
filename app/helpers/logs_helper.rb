module LogsHelper
  def log_type_for_controller(controller)
    case controller.class.to_s
    when "LettingsLogsController"
      "lettings"
    when "SalesLogsController"
      "sales"
    else
      raise "Log type not found for #{controller.class}"
    end
  end

  def bulk_upload_path_for_controller(controller, id:)
    case log_type_for_controller(controller)
    when "lettings"
      bulk_upload_lettings_log_path(id:)
    when "sales"
      bulk_upload_sales_log_path(id:)
    end
  end

  def bulk_upload_options(bulk_upload)
    array = bulk_upload ? [bulk_upload.id] : []
    array.index_with { |_bulk_upload_id| "With logs from bulk upload" }
  end

  def search_label_for_controller(controller)
    case log_type_for_controller(controller)
    when "lettings"
      "Search by log ID, tenant code, property reference or postcode"
    when "sales"
      "Search by log ID, purchaser code or postcode"
    end
  end

  def csv_download_url_for_controller(controller_type:, search:, codes_only:)
    case log_type_for_controller(controller_type)
    when "lettings" then csv_download_lettings_logs_path(search:, codes_only:)
    when "sales" then csv_download_sales_logs_path(search:, codes_only:)
    end
  end

  def csv_download_url_by_log_type(log_type, organisation, search:, codes_only:)
    if log_type == :lettings
      lettings_logs_csv_download_organisation_path(organisation, search:, codes_only:)
    else
      sales_logs_csv_download_organisation_path(organisation, search:, codes_only:)
    end
  end
end
