class Log < ApplicationRecord
  include CollectionTimeHelper

  self.abstract_class = true

  belongs_to :owning_organisation, class_name: "Organisation", optional: true
  belongs_to :assigned_to, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :updated_by, class_name: "User", optional: true
  belongs_to :bulk_upload, optional: true

  before_save :update_status!

  STATUS = {
    "not_started" => 0,
    "in_progress" => 1,
    "completed" => 2,
    "pending" => 3,
    "deleted" => 4,
  }.freeze
  enum :status, STATUS
  enum :status_cache, STATUS, prefix: true

  CREATION_METHOD = {
    "single log" => 1,
    "bulk upload" => 2,
  }.freeze
  enum :creation_method, CREATION_METHOD, prefix: true

  scope :visible, -> { where(status: %w[not_started in_progress completed]) }
  scope :exportable, -> { where(status: %w[not_started in_progress completed deleted]) }

  scope :filter_by_status, ->(status, _user = nil) { where status: }
  scope :filter_by_years, lambda { |years, _user = nil|
    first_year = years.shift
    query = filter_by_year(first_year)
    years.each { |year| query = query.or(filter_by_year(year)) }
    query.all
  }
  scope :filter_by_postcode, ->(postcode_full) { where("REPLACE(postcode_full, ' ', '') ILIKE ?", "%#{postcode_full.delete(' ')}%") }
  scope :filter_by_id, ->(id) { where(id:) }
  scope :filter_by_user, ->(selected_user, _user = nil) { selected_user.present? ? where(assigned_to: selected_user) : all }
  scope :filter_by_bulk_upload_id, lambda { |bulk_upload_id, user|
    joins(:bulk_upload)
      .where(bulk_upload: { id: bulk_upload_id, user: })
  }
  scope :assigned_to, ->(user) { where(assigned_to: user) }
  scope :imported, -> { where.not(old_id: nil) }
  scope :not_imported, -> { where(old_id: nil) }
  scope :has_old_form_id, -> { where.not(old_form_id: nil) }
  scope :imported_2023_with_old_form_id, -> { imported.filter_by_year(2023).has_old_form_id }
  scope :imported_2023, -> { imported.filter_by_year(2023) }
  scope :filter_by_organisation, ->(org, _user = nil) { where(owning_organisation: org).or(where(managing_organisation: org)) }
  scope :filter_by_owning_organisation, ->(owning_organisation, _user = nil) { where(owning_organisation:) }
  scope :filter_by_managing_organisation, ->(managing_organisation, _user = nil) { where(managing_organisation:) }
  scope :filter_by_user_text_search, ->(param, user) { where(assigned_to: User.visible(user).search_by(param)) }
  scope :filter_by_owning_organisation_text_search, ->(param, _user) { where(owning_organisation: Organisation.search_by(param)) }
  scope :filter_by_managing_organisation_text_search, ->(param, _user) { where(managing_organisation: Organisation.search_by(param)) }

  attr_accessor :skip_update_status, :skip_update_uprn_confirmed, :select_best_address_match, :skip_dpo_validation

  delegate :present?, to: :address_options, prefix: true

  def process_uprn_change!
    if uprn.present?
      service = UprnClient.new(uprn)
      service.call

      if service.error.present?
        errors.add(:uprn, :uprn_error, message: service.error)
        errors.add(:uprn_selection, :uprn_error, message: service.error)
        return
      end

      presenter = UprnDataPresenter.new(service.result)

      self.uprn_known = 1
      self.uprn_selection = uprn
      self.address_line1 = presenter.address_line1
      self.address_line2 = presenter.address_line2
      self.town_or_city = presenter.town_or_city
      self.postcode_full = presenter.postcode
      self.county = nil
      process_postcode_changes!
    end
  end

  def process_address_change!
    if uprn_selection.present? || select_best_address_match.present?
      if select_best_address_match
        service = AddressClient.new(address_string)
        service.call
        return nil if service.result.blank? || service.error.present?

        presenter = AddressDataPresenter.new(service.result.first)
        os_match_threshold_for_bulk_upload = 0.7
        if presenter.match >= os_match_threshold_for_bulk_upload
          self.uprn_selection = presenter.uprn
        else
          return nil
        end
      end

      if uprn_selection == "uprn_not_listed"
        self.uprn_known = 0
        self.uprn_confirmed = nil
        self.uprn = nil
        self.address_line1 = address_line1_input
        self.address_line2 = nil
        self.town_or_city = nil
        self.county = nil
        self.postcode_full = postcode_full_input if postcode_full_input.match(POSTCODE_REGEXP)
        process_postcode_changes!
      else
        self.uprn = uprn_selection
        self.uprn_confirmed = 1
        self.skip_update_uprn_confirmed = true
        process_uprn_change!
      end
    end
  end

  def address_string
    "#{address_line1_input}, #{postcode_full_input}"
  end

  def address_options
    if uprn.present?
      service = UprnClient.new(uprn)
      service.call
      if service.result.blank? || service.error.present?
        @address_options = []
        return @address_options
      end

      presenter = UprnDataPresenter.new(service.result)
      @address_options = [{ address: presenter.address, uprn: presenter.uprn }]
    else
      return @address_options if @address_options && @last_searched_address_string == address_string
      return if address_string.blank?

      @last_searched_address_string = address_string

      service = AddressClient.new(address_string)
      service.call
      if service.result.blank? || service.error.present?
        @address_options = []
        return @address_options
      end

      address_opts = []
      service.result.first(10).each do |result|
        presenter = AddressDataPresenter.new(result)
        address_opts.append({ address: presenter.address, uprn: presenter.uprn })
      end

      @address_options = address_opts
    end
  end

  def collection_start_year
    return @start_year if @start_year

    return unless startdate

    window_end_date = Time.zone.local(startdate.year, 4, 1)
    @start_year = startdate < window_end_date ? startdate.year - 1 : startdate.year
  end

  def recalculate_start_year!
    @start_year = nil
    collection_start_year
  end

  def setup_completed?
    form.setup_sections.all? { |sections| sections.subsections.all? { |subsection| subsection.status(self) == :completed } }
  end

  def lettings?
    false
  end

  def sales?
    false
  end

  def ethnic_refused?
    ethnic_group == 17
  end

  def collection_period_open?
    return false if older_than_previous_collection_year?

    form.new_logs_end_date > Time.zone.today
  end

  def collection_period_open_for_editing?
    return false if older_than_previous_collection_year?

    form.edit_end_date > Time.zone.today
  end

  def blank_invalid_non_setup_fields!
    setup_ids = form.setup_sections.flat_map(&:subsections).flat_map(&:questions).map(&:id)
    fields_to_keep = setup_ids + %w[hhmemb]

    2.times do
      next if valid?

      errors.each do |error|
        next if fields_to_keep.include?(error.attribute.to_s)

        question = form.questions.find { |q| q.id == error.attribute.to_s }
        if question&.type == "checkbox"
          question.answer_keys_without_dividers.each { |attribute| public_send("#{attribute}=", nil) }
        else
          public_send("#{error.attribute}=", nil)
        end
      end

      blank_compound_invalid_non_setup_fields!

      errors.clear
    end
  end

  (1..8).each do |person_num|
    define_method("plural_gender_for_person_#{person_num}") do
      plural_gender_for_person(person_num)
    end
  end

  (2..8).each do |person_num|
    define_method("person_#{person_num}_child_relation?") do
      send("relat#{person_num}") == "C"
    end
  end

  def discard!
    update!(status: "deleted", discarded_at: Time.zone.now)
  end

  def calculate_status
    return "deleted" if discarded_at.present?

    if all_subsections_completed? && errors.empty?
      "completed"
    elsif all_subsections_unstarted?
      "not_started"
    else
      "in_progress"
    end
  end

  def field_formatted_as_currency(field_name)
    field_value = public_send(field_name)
    format_as_currency(field_value)
  end

  def blank_compound_invalid_non_setup_fields!
    if errors.attribute_names.include? :postcode_full
      self.postcode_known = nil if lettings?
      self.pcodenk = nil if sales?
    end

    self.ppcodenk = nil if errors.attribute_names.include? :ppostcode_full
    self.previous_la_known = nil if errors.attribute_names.include? :prevloc

    if errors.of_kind?(:uprn, :uprn_error)
      self.uprn_known = nil
      self.uprn_confirmed = nil
      self.address_line1 = nil
      self.address_line2 = nil
      self.town_or_city = nil
      self.postcode_full = nil
      self.postcode_known = nil if lettings?
      self.pcodenk = nil if sales?
      self.county = nil
      process_postcode_changes!
    end
  end

  def collection_closed_for_editing?
    form.edit_end_date < Time.zone.now || older_than_previous_collection_year?
  end

  def duplicate_check_questions(current_user)
    duplicate_check_question_ids.map { |question_id|
      question = form.get_question(question_id, self)
      question if question.page.routed_to?(self, current_user)
    }.compact
  end

  def missing_answers_count
    form.questions.count do |question|
      !optional_fields.include?(question.id) && question.displayed_to_user?(self) && question.unanswered?(self) && !question.is_derived_or_has_inferred_check_answers_value?(self)
    end
  end

  def nationality_uk_or_prefers_not_to_say?
    nationality_all_group&.zero? || nationality_all_group == 826
  end

  def age_under_16?(person_num)
    public_send("age#{person_num}") && public_send("age#{person_num}") < 16
  end

  def age_known?(person_num)
    return false unless person_num.is_a?(Integer)

    !!public_send("age#{person_num}_known")&.zero?
  end

private

  # Handle logs that are older than previous collection start date
  def older_than_previous_collection_year?
    return false unless startdate

    startdate < previous_collection_start_date
  end

  def plural_gender_for_person(person_num)
    gender = public_send("sex#{person_num}".to_sym)
    return unless gender

    if %w[M X].include?(gender)
      "male and non-binary people"
    elsif gender == "F"
      "females"
    end
  end

  def update_status!
    return if skip_update_status

    if status == "pending"
      self.status_cache = calculate_status
    else
      self.status = calculate_status
    end
  end

  def all_subsections_completed?
    form.subsections.all? { |subsection| subsection.complete?(self) || subsection.not_displayed_in_tasklist?(self) }
  end

  def all_subsections_unstarted?
    not_started_statuses = %i[not_started cannot_start_yet]
    form.subsections.all? { |subsection| not_started_statuses.include? subsection.status(self) }
  end

  def reset_invalidated_dependent_fields!
    return unless form

    form.reset_not_routed_questions_and_invalid_answers(self)
    reset_assigned_to!
  end

  PIO = PostcodeService.new

  LA_CHANGES = {
    2025 => {
      "E08000016" => "E08000038", # Barnsley
      "E08000019" => "E08000039", # Sheffield
    },
  }.freeze

  BACKWARDS_LA_CHANGES = {
    2024 => {
      "E08000038" => "E08000016", # Barnsley
      "E08000039" => "E08000019", # Sheffield
    },
  }.freeze

  def get_inferred_la(postcode)
    result = PIO.lookup(postcode)
    location_code = result[:location_code] if result
    if LA_CHANGES[form.start_date.year]&.key?(location_code)
      LA_CHANGES[form.start_date.year][location_code]
    elsif BACKWARDS_LA_CHANGES[form.start_date.year]&.key?(location_code)
      BACKWARDS_LA_CHANGES[form.start_date.year][location_code]
    elsif !LA_CHANGES.value?(location_code)
      location_code
    end
  end

  def upcase_and_remove_whitespace(string)
    string.present? ? string.upcase.gsub(/\s+/, "") : string
  end

  def reset_location_fields!
    reset_log_location(is_la_inferred, "la", "is_la_inferred", "postcode_full", 1)
  end

  def reset_previous_location_fields!
    reset_log_location(is_previous_la_inferred, "prevloc", "is_previous_la_inferred", "ppostcode_full", previous_la_known)
  end

  def reset_log_location(is_inferred, la_key, is_inferred_key, postcode_key, is_la_known)
    if is_inferred || is_la_known != 1
      self[la_key] = nil
    end
    self[is_inferred_key] = false
    self[postcode_key] = nil
  end
end
