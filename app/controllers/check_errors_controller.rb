class CheckErrorsController < ApplicationController
  include DuplicateLogsHelper

  before_action :authenticate_user!
  before_action :find_resource_by_named_id

  def confirm_clear_answer
    return render_not_found unless @log

    @related_question_ids = params[@log.log_type].keys.reject { |id| id == "page_id" }
    @page = @log.form.get_page(params[@log.log_type]["page_id"])

    if params["clear_all"]
      @questions_to_clear = @related_question_ids.map { |id|
        question = @log.form.get_question(id, @log)
        next if question.subsection.id == "setup"

        question.page.questions.map(&:id)
      }.flatten.compact

      render :confirm_clear_all_answers
    else
      question_id = @related_question_ids.find { |id| !params[id].nil? }
      @question = @log.form.get_question(question_id, @log)
    end
  end

private

  def find_resource_by_named_id
    @log = if params[:sales_log_id].present?
             current_user.sales_logs.visible.find_by(id: params[:sales_log_id])
           else
             current_user.lettings_logs.visible.find_by(id: params[:lettings_log_id])
           end
  end
end
