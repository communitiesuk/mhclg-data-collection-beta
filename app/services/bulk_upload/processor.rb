require 'pp'

class BulkUpload::Processor
  attr_reader :bulk_upload

  def initialize(bulk_upload:)
    @bulk_upload = bulk_upload
  end

  def call
    download

    return send_failure_mail(errors: validator.errors.full_messages) if validator.invalid?

    validator.call

    if validator.any_setup_errors?
      send_setup_errors_mail
    elsif validator.create_logs?
      create_logs

      if created_logs_but_incompleted?
        send_how_fix_upload_mail
      end

      if created_logs_and_all_completed?
        bulk_upload.unpend
        send_success_mail
      end
    else
      send_correct_and_upload_again_mail # summary/full report
    end
  rescue StandardError => e
    Sentry.capture_exception(e)
    send_failure_mail
  ensure
    downloader.delete_local_file!
  end

  def approve
    bulk_upload.unpend
  end

private

  def send_how_fix_upload_mail
    BulkUploadMailer
      .send_how_fix_upload_mail(bulk_upload:)
      .deliver_later
  end

  def send_setup_errors_mail
    BulkUploadMailer
      .send_bulk_upload_failed_file_setup_error_mail(bulk_upload:)
      .deliver_later
  end

  def send_correct_and_upload_again_mail
    BulkUploadMailer
      .send_correct_and_upload_again_mail(bulk_upload:)
      .deliver_later
  end

  def send_success_mail
    BulkUploadMailer
      .send_bulk_upload_complete_mail(user:, bulk_upload:)
      .deliver_later
  end

  def created_logs_but_incompleted?
    puts "\n" * 10
    puts "incomplete logs are..."
    pp bulk_upload.logs.where.not(status_cache: %w[completed])
    puts "\n" * 10
    bulk_upload.logs.where.not(status_cache: %w[completed]).count.positive?
  end

  def created_logs_and_all_completed?
    bulk_upload.logs.group(:status_cache).count.keys == %w[completed]
  end

  def send_failure_mail(errors: [])
    BulkUploadMailer
      .send_bulk_upload_failed_service_error_mail(bulk_upload:, errors:)
      .deliver_later
  end

  def user
    bulk_upload.user
  end

  def create_logs
    log_creator_class.new(
      bulk_upload:,
      path: downloader.path,
    ).call
  end

  def log_creator_class
    case bulk_upload.log_type
    when "lettings"
      BulkUpload::Lettings::LogCreator
    when "sales"
      BulkUpload::Sales::LogCreator
    else
      raise "Log creator not found for #{bulk_upload.log_type}"
    end
  end

  def downloader
    @downloader ||= BulkUpload::Downloader.new(bulk_upload:)
  end

  def download
    downloader.call
  end

  def validator
    @validator ||= validator_class.new(
      bulk_upload:,
      path: downloader.path,
    )
  end

  def validator_class
    case bulk_upload.log_type
    when "lettings"
      BulkUpload::Lettings::Validator
    when "sales"
      BulkUpload::Sales::Validator
    else
      raise "Validator not found for #{bulk_upload.log_type}"
    end
  end
end
