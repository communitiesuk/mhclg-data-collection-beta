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

  def get_subsection_status(subsection_name, case_log, form, questions)
    applicable_questions = form.filter_conditional_questions(questions, case_log).keys
    if subsection_name == "declaration"
      return case_log.completed? ? :not_started : :cannot_start_yet
    end

    return :not_started if applicable_questions.all? { |question| case_log[question].blank? }
    return :completed if applicable_questions.all? { |question| case_log[question].present? }

    :in_progress
  end

  def get_next_incomplete_section(form, case_log)
    subsections = form.all_subsections.keys
    subsections.find { |subsection| is_incomplete?(subsection, case_log, form, form.questions_for_subsection(subsection)) }
  end

  def get_subsections_count(form, case_log, status = :all)
    subsections = form.all_subsections.keys
    return subsections.count if status == :all

    subsections.count { |subsection| get_subsection_status(subsection, case_log, form, form.questions_for_subsection(subsection)) == status }
  end

  def get_first_page_or_check_answers(subsection, case_log, form, questions)
    path = if is_started?(subsection, case_log, form, questions)
             "case_log_#{subsection}_check_answers_path"
           else
             "case_log_#{form.first_page_for_subsection(subsection)}_path"
           end
    send(path, case_log)
  end

private

  def is_incomplete?(subsection, case_log, form, questions)
    status = get_subsection_status(subsection, case_log, form, questions)
    %i[not_started in_progress].include?(status)
  end

  def is_started?(subsection, case_log, form, questions)
    status = get_subsection_status(subsection, case_log, form, questions)
    %i[in_progress completed].include?(status)
  end
end
