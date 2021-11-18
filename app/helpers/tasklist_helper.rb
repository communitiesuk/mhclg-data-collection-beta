module TasklistHelper
  STATUSES = {
    not_started: "Not started",
    cannot_start_yet: "Cannot start yet",
    completed: "Completed",
    in_progress: "In progress",
  }.freeze

  STYLES = {
    not_started: "govuk-tag--grey",
    cannot_start_yet: "govuk-tag--grey",
    completed: "",
    in_progress: "govuk-tag--blue",
  }.freeze

  def get_next_incomplete_section(form, case_log)
    subsections = form.all_subsections.keys
    subsections.find { |subsection| is_incomplete?(subsection, case_log, form) }
  end

  def get_subsections_count(form, case_log, status = :all)
    subsections = form.all_subsections.keys
    return subsections.count if status == :all

    subsections.count { |subsection| form.subsection_status(subsection, case_log) == status }
  end

  def get_first_page_or_check_answers(subsection, case_log, form)
    path = if is_started?(subsection, case_log, form)
             "case_log_#{subsection}_check_answers_path"
           else
             "case_log_#{form.first_page_for_subsection(subsection)}_path"
           end
    send(path, case_log)
  end

  def subsection_link(subsection_key, subsection_value, status, form, case_log)
    next_page_path = status != :cannot_start_yet ? get_first_page_or_check_answers(subsection_key, case_log, form) : "#"
    link_to(subsection_value["label"], next_page_path, class: "task-name govuk-link")
  end

private

  def is_incomplete?(subsection, case_log, form)
    status = form.subsection_status(subsection, case_log)
    %i[not_started in_progress].include?(status)
  end

  def is_started?(subsection, case_log, form)
    status = form.subsection_status(subsection, case_log)
    %i[in_progress completed].include?(status)
  end
end
