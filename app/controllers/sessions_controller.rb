class SessionsController < ApplicationController
  def clear_filters
    session[session_name_for(params[:filter_type])] = "{}"
    path_params = params[:path_params].presence || {}

    if path_params[:organisation_id].present?
      redirect_to send("#{params[:filter_type]}_organisation_path", id: path_params[:organisation_id], scheme_id: path_params[:scheme_id], search: path_params[:search])
    else
      redirect_to send("#{params[:filter_type]}_path", scheme_id: path_params[:scheme_id], search: path_params[:search])
    end
  end

private

  def session_name_for(filter_type)
    "#{filter_type}_filters"
  end
end
