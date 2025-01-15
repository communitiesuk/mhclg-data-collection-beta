class Form
  attr_reader :form_definition, :sections, :subsections, :pages, :questions,
              :start_date, :new_logs_end_date, :submission_deadline, :type, :name, :setup_definition,
              :setup_sections, :form_sections, :unresolved_log_redirect_page_id, :edit_end_date

  DEADLINES = {
    2022 => {
      submission_deadline: Time.zone.local(2023, 6, 9),
      new_logs_end_date: Time.zone.local(2023, 11, 20),
      edit_end_date: Time.zone.local(2023, 11, 20),
    },
    2023 => {
      submission_deadline: Time.zone.local(2024, 6, 7),
      new_logs_end_date: Time.zone.local(2024, 7, 22),
      edit_end_date: Time.zone.local(2024, 7, 22),
    },
    2024 => {
      submission_deadline: Time.zone.local(2025, 6, 6),
    },
    :default => {
      submission_deadline: ->(start_year) { Time.zone.local(start_year + 1, 6, 1) },
      new_logs_end_date: ->(start_year) { Time.zone.local(start_year + 1, 12, 31) },
      edit_end_date: ->(start_year) { Time.zone.local(start_year + 1, 12, 31) },
    },
  }.freeze

  def initialize(form_path, start_year = "", sections_in_form = [], type = "lettings")
    if sales_or_start_year_after_2022?(type, start_year)
      @start_date = Time.zone.local(start_year, 4, 1)
      @new_logs_end_date = DEADLINES.dig(start_year, :new_logs_end_date) || DEADLINES[:default][:new_logs_end_date].call(start_year)
      @submission_deadline = DEADLINES.dig(start_year, :submission_deadline) || DEADLINES[:default][:submission_deadline].call(start_year)
      @setup_sections = type == "sales" ? [Form::Sales::Sections::Setup.new(nil, nil, self)] : [Form::Lettings::Sections::Setup.new(nil, nil, self)]
      @form_sections = sections_in_form.map { |sec| sec.new(nil, nil, self) }
      @type = type
      @sections = setup_sections + form_sections
      @subsections = sections.flat_map(&:subsections)
      @pages = subsections.flat_map(&:pages)
      @questions = pages.flat_map(&:questions)
      @form_definition = {
        "form_type" => type,
        "start_date" => start_date,
        "end_date" => new_logs_end_date,
        "sections" => sections,
      }
      @unresolved_log_redirect_page_id = "tenancy_start_date" if type == "lettings"
      @edit_end_date = DEADLINES.dig(start_year, :edit_end_date) || DEADLINES[:default][:edit_end_date].call(start_year)
    else
      raise "No form definition file exists for given year".freeze unless File.exist?(form_path)

      @setup_sections = [Form::Lettings::Sections::Setup.new(nil, nil, self)]
      @form_definition = JSON.parse(File.open(form_path).read)
      @form_sections = form_definition["sections"].map { |id, s| Form::Section.new(id, s, self) }
      @type = form_definition["form_type"]
      @sections =  setup_sections + form_sections
      @subsections = sections.flat_map(&:subsections)
      @pages = subsections.flat_map(&:pages)
      @questions = pages.flat_map(&:questions)
      @start_date = Time.iso8601(form_definition["start_date"])
      @new_logs_end_date = Time.zone.local(@start_date.year + 1, 11, 20)
      @submission_deadline = Time.zone.local(@start_date.year + 1, 6, 9)
      @edit_end_date = Time.zone.local(@start_date.year + 1, 11, 20)
      @unresolved_log_redirect_page_id = form_definition["unresolved_log_redirect_page_id"]
    end
    @name = "#{start_date.year}_#{new_logs_end_date.year}_#{type}"
  end

  def get_subsection(id)
    subsections.find { |s| s.id == id.to_s.underscore }
  end

  def get_page(id)
    pages.find { |p| p.id == id.to_s.underscore }
  end

  def get_question(id, log, current_user = nil)
    all_questions = questions.select { |q| q.id == id.to_s.underscore }
    routed_question = all_questions.find { |q| q.page.routed_to?(log, current_user) } if log
    routed_question || all_questions[0]
  end

  def subsection_for_page(page)
    subsections.find { |s| s.pages.find { |p| p.id == page.id } }
  end

  def next_page_id(page, log, current_user, ignore_answered: false)
    return page.next_unresolved_page_id || :check_answers if log.unresolved

    page_ids = subsection_for_page(page).pages.map(&:id)
    page_index = page_ids.index(page.id)
    page_id = if page.interruption_screen? && log[page.questions[0].id] == 1 && page.routed_to?(log, current_user)
                previous_page_id(page, log, current_user)
              else
                page_ids[page_index + 1]
              end
    next_page = get_page(page_id)

    return :check_answers if next_page.nil?
    return next_page.id if next_page.routed_to?(log, current_user) &&
      (!ignore_answered || next_page.has_unanswered_questions?(log))

    next_page_id(next_page, log, current_user, ignore_answered:)
  end

  def next_page_redirect_path(page, log, current_user, ignore_answered: false)
    next_page_id = next_page_id(page, log, current_user, ignore_answered:)
    if next_page_id == :check_answers
      "#{type}_log_#{subsection_for_page(page).id}_check_answers_path"
    else
      "#{type}_log_#{next_page_id}_path"
    end
  end

  def previous_page_id(page, log, current_user)
    page_ids = subsection_for_page(page).pages.map(&:id)
    page_index = page_ids.index(page.id)
    return :tasklist if page_index.zero?

    page_id = page_ids[page_index - 1]
    previous_page = get_page(page_id)

    return previous_page.id if previous_page.routed_to?(log, current_user)

    previous_page_id(previous_page, log, current_user)
  end

  def previous_page_redirect_path(page, log, current_user, referrer)
    previous_page_id = previous_page_id(page, log, current_user)
    if referrer == "check_answers"
      "#{type}_log_#{subsection_for_page(page).id}_check_answers_path"
    elsif previous_page_id == :tasklist
      "#{type}_log_path"
    else
      "#{type}_log_#{previous_page_id}_path"
    end
  end

  def cancel_path(page, log)
    "#{log.log_type}_#{page.subsection.id}_check_answers_path"
  end

  def unresolved_log_path
    "#{type}_log_#{unresolved_log_redirect_page_id}_path"
  end

  def next_incomplete_section_redirect_path(subsection, log)
    subsection_ids = subsections.map(&:id)

    if log.status == "completed" || log.calculate_status == "completed" # if a log's status in in progress but then fields are made optional, all its subsections are complete, resulting in a stack error
      return first_question_in_last_subsection(subsection_ids)
    end

    next_subsection = next_subsection(subsection, log, subsection_ids)

    case next_subsection.status(log)
    when :completed
      next_incomplete_section_redirect_path(next_subsection, log)
    when :in_progress
      "#{next_subsection.id}/check_answers".dasherize
    when :not_started
      first_question_in_subsection = next_subsection.pages.find { |page| page.routed_to?(log, nil) }
      first_question_in_subsection ? first_question_in_subsection.id.to_s.dasherize : next_incomplete_section_redirect_path(next_subsection, log)
    else
      "error"
    end
  end

  def first_question_in_last_subsection(subsection_ids)
    next_subsection = get_subsection(subsection_ids[subsection_ids.length - 1])
    first_question_in_subsection = next_subsection.pages.first.id
    first_question_in_subsection.to_s.dasherize
  end

  def next_subsection(subsection, log, subsection_ids)
    next_subsection_id_index = subsection_ids.index(subsection.id) + 1
    next_subsection = get_subsection(subsection_ids[next_subsection_id_index])

    if subsection_ids[subsection_ids.length - 1] == subsection.id && log.status != "completed"
      next_subsection = get_subsection(subsection_ids[0])
    end

    next_subsection
  end

  def all_subsections_except_declaration_completed?(log)
    subsection_ids = subsections.map(&:id)
    subsection_ids.delete_at(subsection_ids.length - 1)
    return true if subsection_ids.all? { |subsection_id| get_subsection(subsection_id).status(log) == :completed }

    false
  end

  def conditional_question_conditions
    conditions = questions.map { |q| Hash(q.id => q.conditional_for) if q.conditional_for.present? }.compact
    conditions.map { |c|
      c.map { |k, v| v.keys.map { |key| Hash(from: k, to: key, cond: v[key]) } }
    }.flatten
  end

  def invalidated_pages(log, current_user = nil)
    pages.reject { |p| p.routed_to?(log, current_user) }
  end

  def reset_not_routed_questions_and_invalid_answers(log)
    reset_checkbox_questions_if_not_routed(log)

    reset_radio_questions_if_not_routed_or_invalid_answers(log)

    reset_free_user_input_questions_if_not_routed(log)
  end

  def reset_checkbox_questions_if_not_routed(log)
    checkbox_questions = routed_and_not_routed_questions_by_type(log, type: "checkbox")
    clear_checkbox_attributes(log, checkbox_questions[:routed], checkbox_questions[:not_routed])

    checkbox_questions_recalculated = routed_and_not_routed_questions_by_type(log, type: "checkbox")
    newly_not_routed_checkbox_questions = checkbox_questions_recalculated[:not_routed].reject { |question| checkbox_questions[:not_routed].include?(question) }
    clear_checkbox_attributes(log, checkbox_questions_recalculated[:routed], newly_not_routed_checkbox_questions)
  end

  def reset_radio_questions_if_not_routed_or_invalid_answers(log)
    radio_questions = routed_and_not_routed_questions_by_type(log, type: "radio")
    clear_radio_attributes(log, radio_questions[:routed], radio_questions[:not_routed])

    radio_questions_recalculated = routed_and_not_routed_questions_by_type(log, type: "radio")
    newly_not_routed_radio_questions = radio_questions_recalculated[:not_routed].reject { |question| radio_questions[:not_routed].include?(question) }
    clear_radio_attributes(log, radio_questions_recalculated[:routed], newly_not_routed_radio_questions)
  end

  def reset_free_user_input_questions_if_not_routed(log)
    non_radio_or_checkbox_questions = routed_and_not_routed_questions_by_type(log)
    clear_free_user_input_attributes(log, non_radio_or_checkbox_questions[:routed], non_radio_or_checkbox_questions[:not_routed])

    non_radio_or_checkbox_questions_recalculated = routed_and_not_routed_questions_by_type(log)
    newly_not_routed_non_radio_or_checkbox_questions = non_radio_or_checkbox_questions_recalculated[:not_routed].reject { |question| non_radio_or_checkbox_questions[:not_routed].include?(question) }
    clear_free_user_input_attributes(log, non_radio_or_checkbox_questions_recalculated[:routed], newly_not_routed_non_radio_or_checkbox_questions)
  end

  def clear_checkbox_attributes(log, routed_questions, not_routed_questions)
    not_routed_questions.each do |not_routed_question|
      valid_options = routed_questions
                        .select { |q| q.id == not_routed_question.id }
                        .flat_map { |q| q.answer_options.keys }
      not_routed_question.answer_options.each_key do |invalid_option|
        clear_attribute(log, invalid_option) if log.respond_to?(invalid_option) && valid_options.exclude?(invalid_option) && log.public_send(invalid_option).present?
      end
    end
  end

  def clear_radio_attributes(log, routed_questions, not_routed_questions)
    valid_radio_options = routed_questions
                            .group_by(&:id)
                            .transform_values! { |q_array| q_array.flat_map { |q| q.answer_options.keys } }
    not_routed_questions.each do |not_routed_question|
      question_id = not_routed_question.id
      clear_attribute(log, question_id) if log.respond_to?(question_id) && log.public_send(question_id).present? && !valid_radio_options.key?(question_id)
    end
    valid_radio_options.each do |question_id, valid_options|
      clear_attribute(log, question_id) if log.respond_to?(question_id) && valid_options.exclude?(log.public_send(question_id).to_s)
    end
  end

  def clear_free_user_input_attributes(log, routed_questions, not_routed_questions)
    enabled_question_ids = routed_questions.map(&:id)
    not_routed_questions.each do |not_routed_question|
      question_id = not_routed_question.id
      clear_attribute(log, question_id) if log.public_send(question_id).present? && enabled_question_ids.exclude?(question_id)
    end
  end

  def routed_and_not_routed_questions_by_type(log, type: nil, current_user: nil)
    questions_by_type = if type
                          questions.reject { |q| q.type != type || q.disable_clearing_if_not_routed_or_dynamic_answer_options }
                        else
                          questions.reject { |q| %w[radio checkbox].include?(q.type) || q.disable_clearing_if_not_routed_or_dynamic_answer_options }
                        end
    routed, not_routed = questions_by_type.partition { |q| q.page.routed_to?(log, current_user) || q.derived?(log) }
    { routed:, not_routed: }
  end

  def clear_attribute(log, attribute)
    Rails.logger.debug("Cleared #{attribute} value")
    log.public_send("#{attribute}=", nil)
  end

  def readonly_questions
    questions.select(&:read_only?)
  end

  def numeric_questions
    questions.select { |q| q.type == "numeric" }
  end

  def previous_page(page_ids, page_index, log, current_user)
    prev_page = get_page(page_ids[page_index - 1])
    return prev_page.id if prev_page.routed_to?(log, current_user)

    previous_page(page_ids, page_index - 1, log, current_user)
  end

  def send_chain(arr, log)
    Array(arr).inject(log) { |o, a| o.public_send(*a) }
  end

  def depends_on_met(depends_on, log)
    return true unless depends_on

    depends_on.any? do |conditions_set|
      return false unless conditions_set

      conditions_set.all? do |question, value|
        if value.is_a?(Hash) && value.key?("operator")
          operator = value["operator"]
          operand = value["operand"]
          log[question]&.send(operator, operand)
        else
          parts = question.split(".")
          log_value = send_chain(parts, log)

          value.nil? ? log_value == value : !log_value.nil? && log_value == value
        end
      end
    end
  end

  def inspect
    "#<#{self.class} @type=#{type} @name=#{name}>"
  end

  def valid_start_date_for_form?(start_date)
    start_date >= self.start_date && start_date <= new_logs_end_date
  end

  def sales_or_start_year_after_2022?(type, start_year)
    type == "sales" || (start_year && start_year.to_i > 2022)
  end

  def start_year_2024_or_later?
    start_date && start_date.year >= 2024
  end

  def start_year_2025_or_later?
    start_date && start_date.year >= 2025
  end
end
