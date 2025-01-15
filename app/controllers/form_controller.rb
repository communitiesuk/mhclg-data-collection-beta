class FormController < ApplicationController
  include CollectionTimeHelper

  before_action :authenticate_user!
  before_action :find_resource, only: %i[review]
  before_action :find_resource_by_named_id, except: %i[review]
  before_action :check_collection_period, only: %i[submit_form show_page]
  before_action :set_cache_headers, only: [:show_page]

  def submit_form
    if @log
      @page = form.get_page(params[@log.log_type][:page])
      return render_check_errors_page if params["check_errors"]

      shown_page_ids_with_unanswered_questions_before_update = @page.subsection.pages
                                                      .select { |page| page.routed_to?(@log, current_user) }
                                                      .select { |page| page.has_unanswered_questions?(@log) }
                                                      .map(&:id)

      responses_for_page = responses_for_page(@page)
      mandatory_questions_with_no_response = mandatory_questions_with_no_response(responses_for_page)

      if mandatory_questions_with_no_response.empty? && @log.update(responses_for_page.merge(updated_by: current_user))
        if previous_interruption_screen_page_id.present?
          updated_question = @page.questions.reject { |question| question.check_answer_label.blank? }.first
          updated_question_string = [updated_question&.question_number_string, updated_question&.check_answer_label.to_s.downcase].compact.join(": ")
          flash[:notice] = "You have successfully updated #{updated_question_string}"
        end

        update_duplication_tracking

        pages_requiring_update = pages_requiring_update(shown_page_ids_with_unanswered_questions_before_update)
        redirect_to(successful_redirect_path(pages_requiring_update))
      else
        @log.valid? if mandatory_questions_with_no_response.any?
        mandatory_questions_with_no_response.map do |question|
          @log.errors.add question.id.to_sym, question.unanswered_error_message, category: :not_answered
        end
        error_attributes = @log.errors.map(&:attribute)
        Rails.logger.info "User triggered validation(s) on: #{error_attributes.join(', ')}"
        @subsection = form.subsection_for_page(@page)
        flash[:errors] = @log.errors.each_with_object({}) do |error, result|
          if @page.questions.map(&:id).include?(error.attribute.to_s)
            result[error.attribute.to_s] = error.message
          end
        end
        flash[:log_data] = responses_for_page
        question_ids = (@log.errors.map(&:attribute) - [:base]).uniq
        flash[:pages_with_errors_count] = question_ids.map { |id| @log.form.get_question(id, @log)&.page&.id }.compact.uniq.count
        redirect_to send("#{@log.log_type}_#{@page.id}_path", @log, { referrer: request.params["referrer"], original_page_id: request.params["original_page_id"], related_question_ids: request.params["related_question_ids"] })
      end
    else
      render_not_found
    end
  end

  def check_answers
    if @log
      current_url = request.env["PATH_INFO"]
      subsection = form.get_subsection(current_url.split("/")[-2])
      render "form/check_answers", locals: { subsection:, current_user: }
    else
      render_not_found
    end
  end

  def review
    if @log
      render "form/review"
    else
      render_not_found
    end
  end

  def show_page
    if request.params["referrer"] == "interruption_screen" && request.headers["HTTP_REFERER"].present?
      @interruption_page_id = URI.parse(request.headers["HTTP_REFERER"]).path.split("/").last.underscore
      @interruption_page_referrer_type = from_referrer_query("referrer")
    end

    if adding_answer_from_check_errors_page?
      @related_question_ids = request.params["related_question_ids"]
      @original_page_id = request.params["original_page_id"]
      @check_errors = true
    end

    if @log
      page_id = request.path.split("/")[-1].underscore
      @page = form.get_page(page_id)
      @subsection = form.subsection_for_page(@page)
      @pages_with_errors_count = 0
      if @page.routed_to?(@log, current_user) || is_referrer_type?("interruption_screen") || adding_answer_from_check_errors_page?
        if updated_answer_from_check_errors_page?
          @questions = request.params["related_question_ids"].map { |id| @log.form.get_question(id, @log) }
          render "form/check_errors"
        else
          if flash[:errors].present?
            restore_previous_errors(flash[:errors])
            restore_error_field_values(flash[:log_data])
            @pages_with_errors_count = flash[:pages_with_errors_count]
          end
          render "form/page"
        end
      else
        redirect_to @log.lettings? ? lettings_log_path(@log) : sales_log_path(@log)
      end
    else
      render_not_found
    end
  end

private

  def restore_error_field_values(previous_responses)
    return unless previous_responses

    previous_responses_to_reset = previous_responses.reject do |key, value|
      if @log.form.get_question(key, @log)&.type == "date" && value.present?
        year = value.split("-").first.to_i
        year&.zero?
      else
        false
      end
    end

    @log.assign_attributes(previous_responses_to_reset)
  end

  def restore_previous_errors(previous_errors)
    return unless previous_errors

    previous_errors.each do |attribute, message|
      @log.errors.add attribute, message.html_safe
    end
  end

  def responses_for_page(page)
    page.questions.each_with_object({}) do |question, result|
      question_params = params[@log.log_type][question.id]
      if question.type == "date"
        day, month, year = params[@log.log_type][question.id].split("/")
        next unless [day, month, year].any?(&:present?)

        result[question.id] = if Date.valid_date?(year.to_i, month.to_i, day.to_i) && year.to_i.positive?
                                Date.new(year.to_i, month.to_i, day.to_i)
                              else
                                Date.new(0, 1, 1)
                              end
      end

      if question.id == "saledate" && set_managing_organisation_to_assigned_to_organisation?(result["saledate"])
        result["managing_organisation_id"] = @log.assigned_to.organisation_id
      end

      next unless question_params

      if %w[checkbox validation_override].include?(question.type)
        question.answer_keys_without_dividers.each do |option|
          result[option] = question_params.include?(option) ? 1 : 0
        end
      elsif question.type != "date"
        result[question.id] = question_params
      end

      if question.id == "owning_organisation_id"
        owning_organisation = result["owning_organisation_id"].present? ? Organisation.find(result["owning_organisation_id"]) : nil

        result["managing_organisation_id"] = owning_organisation.id if set_managing_organisation_to_owning_organisation?(owning_organisation)
      end

      result
    end
  end

  def find_resource
    @log = if params.key?("sales_log")
             current_user.sales_logs.visible.find_by(id: params[:id])
           else
             current_user.lettings_logs.visible.find_by(id: params[:id])
           end
  end

  def find_resource_by_named_id
    @log = if params[:sales_log_id].present?
             current_user.sales_logs.visible.find_by(id: params[:sales_log_id])
           else
             current_user.lettings_logs.visible.find_by(id: params[:lettings_log_id])
           end
  end

  def is_referrer_type?(referrer_type)
    from_referrer_query("referrer") == referrer_type
  end

  def from_referrer_query(query_param)
    referrer = request.headers["HTTP_REFERER"]
    return unless referrer

    query_params = URI.parse(referrer).query
    return unless query_params

    parsed_params = CGI.parse(query_params)
    parsed_params[query_param]&.first
  end

  def original_duplicate_log_id_from_query
    query_params = URI.parse(request.url).query

    return unless query_params

    parsed_params = CGI.parse(query_params)
    parsed_params["original_log_id"]&.first
  end

  def previous_interruption_screen_page_id
    params[@log.log_type]["interruption_page_id"]
  end

  def previous_interruption_screen_referrer
    params[@log.log_type]["interruption_page_referrer_type"].presence
  end

  def page_has_duplicate_check_question
    @page.questions.any? { |q| @log.duplicate_check_question_ids.include?(q.id) }
  end

  def update_duplication_tracking
    return unless page_has_duplicate_check_question

    class_name = @log.log_type
    dynamic_duplicates = current_user.send(class_name.pluralize).duplicate_logs(@log)

    if dynamic_duplicates.any?
      saved_duplicates = @log.duplicates
      if saved_duplicates.none? || duplicates_changed?(dynamic_duplicates, saved_duplicates)
        duplicate_set_id = dynamic_duplicates.first.duplicate_set_id || new_duplicate_set_id(@log)
        update_logs_with_duplicate_set_id(@log, dynamic_duplicates, duplicate_set_id)
        saved_duplicates.first.update!(duplicate_set_id: nil) if saved_duplicates.count == 1
      end
    else
      remove_fixed_duplicate_set_ids(@log)
    end
  end

  def successful_redirect_path(pages_to_check)
    class_name = @log.log_type

    if is_referrer_type?("duplicate_logs") || is_referrer_type?("duplicate_logs_banner")
      original_log = current_user.send(class_name.pluralize).find_by(id: from_referrer_query("original_log_id"))

      if original_log.present? && current_user.send(class_name.pluralize).duplicate_logs(original_log).any?
        if @log.duplicate_set_id.nil?
          flash[:notice] = deduplication_success_banner
        end
        return send("#{class_name}_duplicate_logs_path", original_log, original_log_id: original_log.id, referrer: params[:referrer], organisation_id: params[:organisation_id])
      else
        flash[:notice] = deduplication_success_banner
        return send("#{class_name}_duplicate_logs_path", "#{class_name}_id".to_sym => from_referrer_query("first_remaining_duplicate_id"), original_log_id: from_referrer_query("original_log_id"), referrer: params[:referrer], organisation_id: params[:organisation_id])
      end
    end

    unless @log.duplicate_set_id.nil?
      return send("#{@log.log_type}_duplicate_logs_path", @log, original_log_id: @log.id)
    end

    if is_referrer_type?("check_answers")
      next_page_id = form.next_page_id(@page, @log, current_user)
      next_page = form.get_page(next_page_id)
      previous_page = form.previous_page_id(@page, @log, current_user)

      if next_page&.interruption_screen? || next_page_id == previous_page || CONFIRMATION_PAGE_IDS.include?(next_page_id)
        return redirect_path_to_question(next_page, pages_to_check)
      elsif pages_to_check.any?
        return redirect_path_to_question(pages_to_check[0], pages_to_check)
      else
        return send("#{@log.log_type}_#{form.subsection_for_page(@page).id}_check_answers_path", @log)
      end
    end
    if previous_interruption_screen_page_id.present?
      return send("#{@log.log_type}_#{previous_interruption_screen_page_id}_path", @log, { referrer: previous_interruption_screen_referrer, original_log_id: original_duplicate_log_id_from_query }.compact)
    end

    if params[@log.log_type]["check_errors"]
      @page = form.get_page(params[@log.log_type]["page"])
      flash[:notice] = "You have successfully updated #{@page.questions.map(&:check_answer_label).to_sentence}"
      original_page_id = params[@log.log_type]["original_page_id"]
      related_question_ids = params[@log.log_type]["related_question_ids"].split(" ")
      return send("#{@log.log_type}_#{original_page_id}_path", @log, { check_errors: true, related_question_ids: }.compact)
    end

    if params["referrer"] == "check_errors"
      @page = form.get_page(params[@log.log_type]["page"])
      flash[:notice] = "You have successfully updated #{@page.questions.map(&:check_answer_label).to_sentence}"
      return send("#{@log.log_type}_#{params['original_page_id']}_path", @log, { check_errors: true, related_question_ids: params["related_question_ids"] }.compact)
    end

    is_new_answer_from_check_answers = is_referrer_type?("check_answers_new_answer")
    redirect_path = form.next_page_redirect_path(@page, @log, current_user, ignore_answered: is_new_answer_from_check_answers)
    referrer = is_new_answer_from_check_answers ? "check_answers_new_answer" : nil

    send(redirect_path, @log, { referrer: })
  end

  def redirect_path_to_question(page_to_show, unanswered_pages)
    remaining_pages = unanswered_pages.excluding(page_to_show)
    remaining_page_ids = remaining_pages.any? ? remaining_pages.map(&:id).join(",") : nil
    send("#{@log.log_type}_#{page_to_show.id}_path", @log, { referrer: "check_answers", unanswered_pages: remaining_page_ids })
  end

  def pages_requiring_update(previously_visible_empty_page_ids)
    return [] unless is_referrer_type?("check_answers")

    currently_shown_pages = @page.subsection.pages
                                    .select { |page| page.routed_to?(@log, current_user) }

    existing_unanswered_pages = request.params["unanswered_pages"].nil? ? [] : request.params["unanswered_pages"].split(",")
    currently_shown_pages
                       .reject { |page| previously_visible_empty_page_ids.include?(page.id) && !existing_unanswered_pages.include?(page.id) }
                       .select { |page| page.has_unanswered_questions?(@log) }
  end

  def form
    @log&.form
  end

  def mandatory_questions_with_no_response(responses_for_page)
    session["fields"] = {}
    calc_questions = @page.questions.map(&:result_field)
    @page.questions.select do |question|
      next if calc_questions.include?(question.id)

      question_is_required?(question) && question_missing_response?(responses_for_page, question)
    end
  end

  def question_is_required?(question)
    @log.optional_fields.exclude?(question.id) && required_questions.include?(question.id)
  end

  def required_questions
    @required_questions ||= begin
      log = @log
      log.assign_attributes(responses_for_page(@page))
      @page.subsection.applicable_questions(log).select { |q| q.enabled?(log) }.map(&:id)
    end
  end

  def question_missing_response?(responses_for_page, question)
    if %w[checkbox validation_override].include?(question.type)
      answered = question.answer_keys_without_dividers.map do |option|
        session["fields"][option] = @log[option] = params[@log.log_type][question.id].include?(option) ? 1 : 0
        params[@log.log_type][question.id].exclude?(option)
      end
      answered.all?
    else
      session["fields"][question.id] = @log[question.id] = responses_for_page[question.id]
      responses_for_page[question.id].nil? || responses_for_page[question.id].blank?
    end
  end

  def check_collection_period
    return unless @log

    unless @log.collection_period_open_for_editing?
      redirect_to @log.lettings? ? lettings_log_path(@log) : sales_log_path(@log)
    end
  end

  CONFIRMATION_PAGE_IDS = %w[uprn_confirmation uprn_selection].freeze

  def deduplication_success_banner
    deduplicated_log_link = "<a class=\"govuk-notification-banner__link govuk-!-font-weight-bold\" href=\"#{send("#{@log.log_type}_path", @log)}\">Log #{@log.id}</a>"
    changed_labels = {
      property_postcode: "postcode",
      lead_tenant_age: "lead tenant’s age",
      rent_4_weekly: "household rent and charges",
      rent_bi_weekly: "household rent and charges",
      rent_monthly: "household rent and charges",
      rent_or_other_charges: "household rent and charges",
      address: "postcode",
    }
    changed_question_label = changed_labels[@page.id.to_sym] || (@page.questions.first.check_answer_label.to_s.presence || @page.questions.first.header.to_s).downcase

    I18n.t("notification.duplicate_logs.deduplication_success_banner", log_link: deduplicated_log_link, changed_question_label:).html_safe
  end

  def remove_fixed_duplicate_set_ids(log)
    duplicate_set_id = log.duplicate_set_id
    return unless duplicate_set_id

    log.update!(duplicate_set_id: nil)
    LettingsLog.find_by(duplicate_set_id:)&.update!(duplicate_set_id: nil) if log.lettings? && LettingsLog.where(duplicate_set_id:).count == 1
    SalesLog.find_by(duplicate_set_id:)&.update!(duplicate_set_id: nil) if log.sales? && SalesLog.where(duplicate_set_id:).count == 1
  end

  def new_duplicate_set_id(log)
    if log.lettings?
      LettingsLog.maximum(:duplicate_set_id).to_i + 1
    else
      SalesLog.maximum(:duplicate_set_id).to_i + 1
    end
  end

  def duplicates_changed?(dynamic_duplicates, saved_duplicates)
    dynamic_duplicates.present? && saved_duplicates.present? && dynamic_duplicates.order(:id).pluck(:id) != saved_duplicates.order(:id).pluck(:id)
  end

  def update_logs_with_duplicate_set_id(log, dynamic_duplicates, duplicate_set_id)
    log.update!(duplicate_set_id:)
    dynamic_duplicates.each do |duplicate|
      duplicate.update!(duplicate_set_id: log.duplicate_set_id) if duplicate.duplicate_set_id != log.duplicate_set_id
    end
  end

  def set_managing_organisation_to_owning_organisation?(owning_organisation)
    return true if current_user.support? && @log.managing_organisation.blank? && owning_organisation&.managing_agents&.empty?
    return true if owning_organisation&.absorbing_organisation == current_user.organisation
    return true if @log.managing_organisation&.absorbing_organisation == current_user.organisation && owning_organisation == current_user.organisation

    false
  end

  def set_managing_organisation_to_assigned_to_organisation?(saledate)
    return false if current_user.support?
    return false if collection_start_year_for_date(saledate) >= 2024

    true
  end

  def render_check_errors_page
    if params[@log.log_type]["clear_question_ids"].present?
      question_ids = params[@log.log_type]["clear_question_ids"].split(" ")
      question_ids.each do |question_id|
        question = @log.form.get_question(question_id, @log)
        next if question.subsection.id == "setup"

        question.page.questions.map(&:id).each { |id| @log[id] = nil }
        @log.previous_la_known = nil if question.id == "ppostcode_full"
      end
      @log.save!
      @questions = params[@log.log_type].keys.reject { |id| %w[clear_question_ids page].include?(id) }.map { |id| @log.form.get_question(id, @log) }
    else
      responses_for_page = responses_for_page(@page)
      @log.assign_attributes(responses_for_page)
      @log.valid?
      @log.reload
      error_attributes = @log.errors.map(&:attribute)
      @questions = @log.form.questions.select { |q| error_attributes.include?(q.id.to_sym) && q.page.routed_to?(@log, current_user) }
    end
    render "form/check_errors"
  end

  def adding_answer_from_check_errors_page?
    request.params["referrer"] == "check_errors"
  end

  def updated_answer_from_check_errors_page?
    params["check_errors"]
  end

  def set_cache_headers
    response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Mon, 01 Jan 1990 00:00:00 GMT"
  end
end
