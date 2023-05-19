module TasklistHelper
  include GovukLinkHelper
  include CollectionTimeHelper

  def get_next_incomplete_section(log)
    log.form.subsections.find { |subsection| subsection.is_incomplete?(log) }
  end

  def get_subsections_count(log, status = :all)
    return log.form.subsections.count { |subsection| subsection.displayed_in_tasklist?(log) } if status == :all

    log.form.subsections.count { |subsection| subsection.status(log) == status && subsection.applicable_questions(log).count.positive? }
  end

  def next_question_page(subsection, log, current_user)
    if subsection.pages.first.routed_to?(log, current_user)
      subsection.pages.first.id
    else
      log.form.next_page_id(subsection.pages.first, log, current_user)
    end
  end

  def subsection_link(subsection, log, current_user)
    if subsection.status(log) != :cannot_start_yet
      next_page_path = next_page_or_check_answers(subsection, log, current_user).to_s
      govuk_link_to(subsection.label, next_page_path.dasherize, aria: { describedby: subsection.id.dasherize })
    else
      subsection.label
    end
  end

  def review_log_text(log)
    if log.collection_period_open?
      link = log.sales? ? review_sales_log_path(id: log, sales_log: true) : review_lettings_log_path(log)

      "You can #{govuk_link_to 'review and make changes to this log', link} until #{log.form.end_date.to_formatted_s(:govuk_date)}.".html_safe
    else
      start_year = log.startdate ? collection_start_year_for_date(log.startdate) : log.form.start_date.year

      "This log is from the #{start_year}/#{start_year + 1} collection window, which is now closed."
    end
  end

private

  def next_page_or_check_answers(subsection, log, current_user)
    path = if subsection.is_started?(log)
             "#{log.class.name.underscore}_#{subsection.id}_check_answers_path"
           else
             "#{log.class.name.underscore}_#{next_question_page(subsection, log, current_user)}_path"
           end

    if log.is_a? SalesLog
      send(path, sales_log_id: log.id || "new")
    else
      send(path, lettings_log_id: log.id || "new")
    end
  end
end
