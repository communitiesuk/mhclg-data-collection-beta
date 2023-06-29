class FormController < ApplicationController
  before_action :authenticate_user!
  before_action :find_resource, only: %i[review]
  before_action :find_resource_by_named_id, except: %i[review]
  before_action :check_collection_period, only: %i[submit_form show_page]

  def submit_form
    if @log
      @page = form.get_page(params[@log.model_name.param_key][:page])
      responses_for_page = responses_for_page(@page)
      mandatory_questions_with_no_response = mandatory_questions_with_no_response(responses_for_page)

      if mandatory_questions_with_no_response.empty? && @log.update(responses_for_page.merge(updated_by: current_user))
        flash[:notice] = "You have successfully updated #{@page.questions.map(&:check_answer_label).reject { |e| e.to_s.empty? }.first&.downcase}" if previous_interruption_screen_page_id.present?
        redirect_to(successful_redirect_path)
      else
        mandatory_questions_with_no_response.map do |question|
          @log.errors.add question.id.to_sym, question.unanswered_error_message
        end
        Rails.logger.info "User triggered validation(s) on: #{@log.errors.map(&:attribute).join(', ')}"
        @subsection = form.subsection_for_page(@page)
        restore_error_field_values(@page&.questions)
        render "form/page"
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
      @interruption_page_referrer_type = referrer_from_query
    end

    if @log
      page_id = request.path.split("/")[-1].underscore
      @page = form.get_page(page_id)
      @subsection = form.subsection_for_page(@page)
      if @page.routed_to?(@log, current_user) || is_referrer_type?("interruption_screen")
        render "form/page"
      else
        redirect_to @log.lettings? ? lettings_log_path(@log) : sales_log_path(@log)
      end
    else
      render_not_found
    end
  end

private

  def restore_error_field_values(questions)
    return unless questions

    questions.each do |question|
      if question&.type == "date" && @log.attributes.key?(question.id)
        @log[question.id] = @log.send("#{question.id}_was")
      end
    end
  end

  def responses_for_page(page)
    page.questions.each_with_object({}) do |question, result|
      question_params = params[@log.model_name.param_key][question.id]
      if question.type == "date"
        day = params[@log.model_name.param_key]["#{question.id}(3i)"]
        month = params[@log.model_name.param_key]["#{question.id}(2i)"]
        year = params[@log.model_name.param_key]["#{question.id}(1i)"]
        next unless [day, month, year].any?(&:present?)

        result[question.id] = if Date.valid_date?(year.to_i, month.to_i, day.to_i) && year.to_i.between?(2000, 2200)
                                Date.new(year.to_i, month.to_i, day.to_i)
                              else
                                Date.new(0, 1, 1)
                              end
      end
      next unless question_params

      if %w[checkbox validation_override].include?(question.type)
        question.answer_keys_without_dividers.each do |option|
          result[option] = question_params.include?(option) ? 1 : 0
        end
      else
        result[question.id] = question_params
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
    referrer_from_query == referrer_type
  end

  def referrer_from_query
    referrer = request.headers["HTTP_REFERER"]
    return unless referrer

    query_params = URI.parse(referrer).query
    return unless query_params

    parsed_params = CGI.parse(query_params)
    return unless parsed_params["referrer"]

    parsed_params["referrer"][0]
  end

  def previous_interruption_screen_page_id
    params[@log.model_name.param_key]["interruption_page_id"]
  end

  def previous_interruption_screen_referrer
    params[@log.model_name.param_key]["interruption_page_referrer_type"].presence
  end

  def successful_redirect_path
    if is_referrer_type?("check_answers")
      next_page_id = form.next_page_id(@page, @log, current_user)
      next_page = form.get_page(next_page_id)
      previous_page = form.previous_page_id(@page, @log, current_user)

      if next_page&.interruption_screen? || next_page_id == previous_page || CONFIRMATION_PAGE_IDS.include?(next_page_id)
        return send("#{@log.class.name.underscore}_#{next_page_id}_path", @log, { referrer: "check_answers" })
      else
        return send("#{@log.model_name.param_key}_#{form.subsection_for_page(@page).id}_check_answers_path", @log)
      end
    end
    if previous_interruption_screen_page_id.present?
      return send("#{@log.class.name.underscore}_#{previous_interruption_screen_page_id}_path", @log, { referrer: previous_interruption_screen_referrer }.compact)
    end

    redirect_path = form.next_page_redirect_path(@page, @log, current_user)
    send(redirect_path, @log)
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
        session["fields"][option] = @log[option] = params[@log.model_name.param_key][question.id].include?(option) ? 1 : 0
        params[@log.model_name.param_key][question.id].exclude?(option)
      end
      answered.all?
    else
      session["fields"][question.id] = @log[question.id] = responses_for_page[question.id]
      responses_for_page[question.id].nil? || responses_for_page[question.id].blank?
    end
  end

  def check_collection_period
    return unless @log

    redirect_to lettings_log_path(@log) unless @log.collection_period_open?
  end

  CONFIRMATION_PAGE_IDS = %w[uprn_confirmation].freeze
end
