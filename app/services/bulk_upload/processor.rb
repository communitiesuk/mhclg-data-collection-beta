class BulkUpload::Processor
  include CollectionTimeHelper
  attr_reader :bulk_upload

  def blank_template_errors
    [
      I18n.t("validations.lettings.#{current_collection_start_year}.bulk_upload.blank_file"),
      I18n.t("validations.lettings.#{previous_collection_start_year}.bulk_upload.blank_file"),
      I18n.t("validations.sales.#{current_collection_start_year}.bulk_upload.blank_file"),
      I18n.t("validations.sales.#{previous_collection_start_year}.bulk_upload.blank_file"),
    ].freeze
  end

  def wrong_template_errors
    [
      *I18n.t("validations.lettings.#{current_collection_start_year}.bulk_upload.wrong_template", default: {}).values,
      *I18n.t("validations.lettings.#{previous_collection_start_year}.bulk_upload.wrong_template", default: {}).values,
      *I18n.t("validations.sales.#{current_collection_start_year}.bulk_upload.wrong_template", default: {}).values,
      *I18n.t("validations.sales.#{previous_collection_start_year}.bulk_upload.wrong_template", default: {}).values,
    ].freeze
  end

  def initialize(bulk_upload:)
    @bulk_upload = bulk_upload
  end

  def call
    destroy_any_existing_errors_from_prior_run

    download

    @bulk_upload.update!(total_logs_count: validator.total_logs_count)
    return handle_invalid_validator if validator.invalid?

    validator.call

    if validator.any_setup_errors?
      send_setup_errors_mail
    else
      block_creation_reason = validator.block_log_creation_reason

      if block_creation_reason.present?
        case block_creation_reason
        when "duplicate_logs"
          send_correct_duplicates_and_upload_again_mail
        else
          send_correct_and_upload_again_mail # summary/full report
        end
      else
        create_logs

        if validator.soft_validation_errors_only?
          send_check_soft_validations_mail
        elsif created_logs_but_incompleted?
          send_how_to_fix_upload_mail
        elsif created_logs_and_all_completed?
          bulk_upload.unpend
          send_success_mail
        end
      end
    end
  rescue StandardError => e
    Sentry.capture_exception(e)
    @bulk_upload.update!(failure_reason: "processing_error")
    send_failure_mail
  ensure
    downloader.delete_local_file!
    bulk_upload.update!(processing: false)
  end

  def approve
    bulk_upload.unpend
  end

  def approve_and_confirm_soft_validations
    bulk_upload.unpend_and_confirm_soft_validations
  end

private

  def destroy_any_existing_errors_from_prior_run
    bulk_upload.bulk_upload_errors.destroy_all
  end

  def send_how_to_fix_upload_mail
    BulkUploadMailer
      .send_how_to_fix_upload_mail(bulk_upload:)
      .deliver_later
  end

  def send_check_soft_validations_mail
    BulkUploadMailer
      .send_check_soft_validations_mail(bulk_upload:)
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

  def send_correct_duplicates_and_upload_again_mail
    BulkUploadMailer
      .send_correct_duplicates_and_upload_again_mail(bulk_upload:)
      .deliver_later
  end

  def send_success_mail
    BulkUploadMailer
      .send_bulk_upload_complete_mail(user:, bulk_upload:)
      .deliver_later
  end

  def created_logs_but_incompleted?
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

  def handle_invalid_validator
    if blank_template_errors.any? { |error| validator.errors.full_messages.include?(error) }
      @bulk_upload.update!(failure_reason: "blank_template")
    elsif wrong_template_errors.any? { |error| validator.errors.full_messages.include?(error) }
      @bulk_upload.update!(failure_reason: "wrong_template")
    else
      @bulk_upload.update!(failure_reason: "processing_error")
    end

    send_failure_mail(errors: validator.errors.full_messages)
  end
end
