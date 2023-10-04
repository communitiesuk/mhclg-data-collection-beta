class CsvDownloadMailer < NotifyMailer
  CSV_DOWNLOAD_TEMPLATE_ID = "7890e3b9-8c0d-4d08-bafe-427fd7cd95bf".freeze
  CSV_MISSING_LETTINGS_ADDRESSES_DOWNLOAD_TEMPLATE_ID = "7602b6c2-4f44-4da6-8a68-944e39cd8a05".freeze
  CSV_MISSING_SALES_ADDRESSES_DOWNLOAD_TEMPLATE_ID = "1ee6da00-a65e-4a39-b5e5-1846debcb5f8".freeze

  def send_csv_download_mail(user, link, duration)
    send_email(
      user.email,
      CSV_DOWNLOAD_TEMPLATE_ID,
      { name: user.name, link:, duration: ActiveSupport::Duration.build(duration).inspect },
    )
  end

  def send_missing_lettings_addresses_csv_download_mail(user, link, duration, issue_types)
    send_email(
      user.email,
      CSV_MISSING_LETTINGS_ADDRESSES_DOWNLOAD_TEMPLATE_ID,
      { name: user.name, issue_explanation: issue_explanation(issue_types), how_to_fix: how_to_fix(issue_types, link, "lettings"), duration: ActiveSupport::Duration.build(duration).inspect },
    )
  end

  def send_missing_sales_addresses_csv_download_mail(user, link, duration, issue_types)
    send_email(
      user.email,
      CSV_MISSING_SALES_ADDRESSES_DOWNLOAD_TEMPLATE_ID,
      { name: user.name, issue_explanation: issue_explanation(issue_types), how_to_fix: how_to_fix(issue_types, link, "sales"), duration: ActiveSupport::Duration.build(duration).inspect },
    )
  end

private

  def issue_explanation(issue_types)
    issue_type_explanations = {
      "missing_address" => "- Full address required: The UPRN in some logs is incorrect, so address data was not imported.\n",
      "missing_town" => "- Missing town or city: The town or city in some logs is missing. This data is required in the new version of CORE.\n",
      "wrong_uprn" => "- UPRN may be incorrect: The UPRN in some logs may be incorrect, so wrong address data was imported. We think this is an issue because in some logs the UPRN is the same as the tenant code or property reference, and because your organisation has submitted logs for properties in Bristol for the first time.\n",
    }

    "Some address data is missing or incorrect. We've detected the following issues in your logs imported to the new version of CORE:\n\n#{issue_types.map { |issue_type| issue_type_explanations[issue_type] }.join('')}"
  end

  def how_to_fix(issue_types, link, log_type)
    [
      "You need to:\n\n",
      "- download [this spreadsheet for #{log_type} logs](#{link})\n",
      issue_types.include?("missing_address") || issue_types.include?("missing_town") ? "- fill in the missing address data\n" : "",
      if issue_types == %w[wrong_uprn]
        "- check the address data\n"
      else
        !issue_types.include?("wrong_uprn") ? "- check that the existing address data is correct\n" : "- check the existing address data\n"
      end,
      issue_types.include?("wrong_uprn") ? "- correct any errors\n" : "",
    ].join("")
  end
end
