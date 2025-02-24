class BulkUpload < ApplicationRecord
  enum :log_type, { lettings: "lettings", sales: "sales" }
  enum :rent_type_fix_status, { not_applied: "not_applied", applied: "applied", not_needed: "not_needed" }
  enum :failure_reason, { blank_template: "blank_template", wrong_template: "wrong_template", processing_error: "processing_error" }

  belongs_to :user

  has_many :bulk_upload_errors, dependent: :destroy

  has_many :lettings_logs
  has_many :sales_logs

  after_initialize :generate_identifier, unless: :identifier
  after_initialize :initialize_processing, if: :new_record?

  scope :search_by_filename, ->(filename) { where("filename ILIKE ?", "%#{filename}%") }
  scope :search_by_user_name, ->(name) { where(user_id: User.where("name ILIKE ?", "%#{name}%").select(:id)) }
  scope :search_by_user_email, ->(email) { where(user_id: User.where("email ILIKE ?", "%#{email}%").select(:id)) }
  scope :search_by_organisation_name, ->(name) { where(organisation_id: Organisation.where("name ILIKE ?", "%#{name}%").select(:id)) }

  scope :search_by, lambda { |param|
    search_by_filename(param)
      .or(search_by_user_name(param))
      .or(search_by_user_email(param))
      .or(search_by_organisation_name(param))
  }

  scope :filter_by_id, ->(id) { where(id:) }
  scope :filter_by_years, ->(years, _user = nil) { where(year: years) }
  scope :filter_by_uploaded_by, ->(user_id, _user = nil) { where(user_id:) }
  scope :filter_by_user_text_search, ->(param, _user = nil) { where(user_id: User.search_by(param).select(:id)) }
  scope :filter_by_user, ->(user_id, _user = nil) { user_id.present? ? where(user_id:) : all }
  scope :filter_by_uploading_organisation, ->(organisation_id, _user = nil) { where(organisation_id:) }

  has_paper_trail

  def completed?
    incomplete_logs = logs.where.not(status: "completed")
    !incomplete_logs.exists?
  end

  def status
    return :processing if processing
    return :blank_template if failure_reason == "blank_template"
    return :wrong_template if failure_reason == "wrong_template"
    return :processing_error if failure_reason == "processing_error"

    if logs.visible.exists?
      return :errors_fixed_in_service if completed? && bulk_upload_errors.any?
      return :logs_uploaded_with_errors if bulk_upload_errors.any?
    end

    if bulk_upload_errors.important.any?
      :important_errors
    elsif bulk_upload_errors.critical.any?
      :critical_errors
    elsif bulk_upload_errors.potential.any?
      :potential_errors
    else
      :logs_uploaded_no_errors
    end
  end

  def year_combo
    "#{year} to #{year + 1}"
  end

  def end_year
    year + 1
  end

  def logs
    if lettings?
      lettings_logs
    else
      sales_logs
    end
  end

  def form
    @form ||= if lettings?
                FormHandler.instance.lettings_form_for_start_year(year)
              else
                FormHandler.instance.sales_form_for_start_year(year)
              end
  end

  def general_needs?
    needstype == 1
  end

  def supported_housing?
    needstype == 2
  end

  def prefix_namespace
    type_class = case log_type
                 when "lettings"
                   "Lettings"
                 when "sales"
                   "Sales"
                 else
                   raise "unknown log type"
                 end

    year_class = case year
                 when 2025
                   "Year2025"
                 when 2024
                   "Year2024"
                 when 2023
                   "Year2023"
                 else
                   raise "unknown year"
                 end

    "BulkUpload::#{type_class}::#{year_class}".constantize
  end

  def unpend
    logs.find_each do |log|
      log.skip_update_status = true
      log.status = log.status_cache
      log.save!
    end
  end

  def fields_to_confirm(log)
    log.form.questions.select { |q| q.type == "interruption_screen" }.uniq(&:id).map(&:id)
  end

  def unpend_and_confirm_soft_validations
    logs.find_each do |log|
      fields_to_confirm(log).each { |field| log[field] = 0 }
      log.status = log.status_cache
      log.save!
    end
  end

  def logs_with_errors_count
    bulk_upload_errors.distinct.count("row")
  end

  def remaining_logs_with_errors_count
    logs.filter_by_status("in_progress").count
  end

  def remaining_errors_count
    logs.filter_by_status("in_progress").map(&:missing_answers_count).sum(0)
  end

  def moved_user_name
    User.find_by(id: moved_user_id)&.name
  end

  def organisation
    Organisation.find_by(id: organisation_id)
  end

private

  def generate_identifier
    self.identifier ||= SecureRandom.uuid
  end

  def initialize_processing
    self.processing = true if processing.nil?
  end
end
