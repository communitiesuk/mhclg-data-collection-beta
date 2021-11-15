class CaseLogsController < ApplicationController
  skip_before_action :verify_authenticity_token, if: :json_api_request?
  before_action :authenticate, if: :json_api_request?

  def index
    @completed_case_logs = CaseLog.completed
    @in_progress_case_logs = CaseLog.not_completed
  end

  def create
    case_log = CaseLog.create(api_case_log_params)
    respond_to do |format|
      format.html { redirect_to case_log }
      format.json do
        if case_log.persisted?
          render json: case_log, status: :created
        else
          render json: { errors: case_log.errors.messages }, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    if (case_log = CaseLog.find_by(id: params[:id]))
      if case_log.update(api_case_log_params)
        render json: case_log, status: :ok
      else
        render json: { errors: case_log.errors.messages }, status: :unprocessable_entity
      end
    else
      render json: { error: "Case Log #{params[:id]} not found" }, status: :not_found
    end
  end

  def show
    respond_to do |format|
      # We don't have a dedicated non-editable show view
      format.html { edit }
      format.json do
        if (case_log = CaseLog.find_by(id: params[:id]))
          render json: case_log, status: :ok
        else
          render json: { error: "Case Log #{params[:id]} not found" }, status: :not_found
        end
      end
    end
  end

  def edit
    @form = FormHandler.instance.get_form("2021_2022")
    @case_log = CaseLog.find(params[:id])
    render :edit
  end

  def submit_form
    form = FormHandler.instance.get_form("2021_2022")
    @case_log = CaseLog.find(params[:id])
    @case_log.page = params[:case_log][:page]
    responses_for_page = responses_for_page(@case_log.page)
    if @case_log.update(responses_for_page) && @case_log.has_no_unresolved_soft_errors?
      redirect_path = get_next_page_path(form, @case_log.page, @case_log)
      redirect_to(send(redirect_path, @case_log))
    else
      page_info = form.all_pages[@case_log.page]
      render "form/page", locals: { form: form, page_key: @case_log.page, page_info: page_info }, status: :unprocessable_entity
    end
  end

  def destroy
    if (case_log = CaseLog.find_by(id: params[:id]))
      if case_log.discard
        head :no_content
      else
        render json: { errors: case_log.errors.messages }, status: :unprocessable_entity
      end
    else
      render json: { error: "Case Log #{params[:id]} not found" }, status: :not_found
    end
  end

  def check_answers
    form = FormHandler.instance.get_form("2021_2022")
    @case_log = CaseLog.find(params[:case_log_id])
    current_url = request.env["PATH_INFO"]
    subsection = current_url.split("/")[-2]
    render "form/check_answers", locals: { subsection: subsection, form: form }
  end

  form = FormHandler.instance.get_form("2021_2022")
  form.all_pages.map do |page_key, page_info|
    define_method(page_key) do |_errors = {}|
      @case_log = CaseLog.find(params[:case_log_id])
      render "form/page", locals: { form: form, page_key: page_key, page_info: page_info }
    end
  end

private

  API_ACTIONS = %w[create show update destroy].freeze

  def responses_for_page(page)
    form = FormHandler.instance.get_form("2021_2022")
    form.expected_responses_for_page(page).each_with_object({}) do |(question_key, question_info), result|
      question_params = params["case_log"][question_key]
      if question_info["type"] == "date"
        day = params["case_log"]["#{question_key}(3i)"]
        month = params["case_log"]["#{question_key}(2i)"]
        year = params["case_log"]["#{question_key}(1i)"]
        next unless day.present? && month.present? && year.present?

        result[question_key] = Date.new(year.to_i, month.to_i, day.to_i)
      end
      next unless question_params

      if %w[checkbox validation_override].include?(question_info["type"])
        question_info["answer_options"].keys.reject { |x| x.match(/divider/) }.each do |option|
          result[option] = question_params.include?(option) ? 1 : 0
        end
      else
        result[question_key] = question_params
      end
      result
    end
  end

  def json_api_request?
    API_ACTIONS.include?(request["action"]) && request.format.json?
  end

  def authenticate
    http_basic_authenticate_or_request_with name: ENV["API_USER"], password: ENV["API_KEY"]
  end

  def api_case_log_params
    return {} unless params[:case_log]

    params.require(:case_log).permit(CaseLog.editable_fields)
  end

  def get_next_page_path(form, page, case_log = {})
    content = form.all_pages[page]

    if content.key?("conditional_route_to")
      content["conditional_route_to"].each do |route, conditions|
        if conditions.keys.all? { |x| case_log[x].present? } && conditions.all? { |k, v| v.include?(case_log[k]) }
          return "case_log_#{route}_path"
        end
      end
    end
    form.next_page_redirect_path(page)
  end
end
