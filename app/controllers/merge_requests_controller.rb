class MergeRequestsController < ApplicationController
  before_action :find_resource, exclude: %i[create new]
  before_action :authenticate_user!
  before_action :authenticate_scope!
  before_action :set_organisations_answer_options, only: %i[merging_organisations absorbing_organisation update_merging_organisations remove_merging_organisation update]

  def absorbing_organisation; end
  def merge_date; end
  def existing_absorbing_organisation; end
  def helpdesk_ticket; end
  def merge_start_confirmation; end
  def user_outcomes; end
  def relationship_outcomes; end
  def scheme_outcomes; end
  def logs_outcomes; end

  def create
    ActiveRecord::Base.transaction do
      @merge_request = MergeRequest.create!(merge_request_params.merge(status: :incomplete, requester: current_user))
    end
    redirect_to absorbing_organisation_merge_request_path(@merge_request)
  rescue ActiveRecord::RecordInvalid
    render_not_found
  end

  def update
    validate_response

    if @merge_request.errors.blank? && @merge_request.update(merge_request_params)
      add_merging_organsations if page == "merging_organisations"
      remove_absorbing_org_from_merging_organisations if page == "absorbing_organisation" && @merge_request.absorbing_organisation_id.present?

      redirect_to next_page_path
    else
      render previous_template, status: :unprocessable_entity
    end
  end

  def update_merging_organisations
    @new_merging_org_ids = params["merge_request"]["new_merging_org_ids"].split(" ")
    merge_request_organisation = MergeRequestOrganisation.new(merge_request_organisation_params)
    if merge_request_organisation.valid?
      @new_merging_org_ids.push(merge_request_organisation_params[:merging_organisation_id])
      render :merging_organisations
    else
      render :merging_organisations, status: :unprocessable_entity
    end
  end

  def remove_merging_organisation
    @new_merging_org_ids = params["merge_request"]["new_merging_org_ids"] || []
    org_id_to_remove = merge_request_organisation_params[:merging_organisation_id]
    @new_merging_org_ids.delete(org_id_to_remove)
    MergeRequestOrganisation.find_by(merge_request_organisation_params)&.destroy!
    render :merging_organisations
  end

  def delete
    @merge_request.discard!
    flash[:notice] = "The merge request has been deleted."
    redirect_to organisations_path(tab: "merge-requests")
  end

  def merging_organisations
    @new_merging_org_ids = []
  end

  def start_merge
    if @merge_request.status == "ready_to_merge"
      @merge_request.start_merge!
      ProcessMergeRequestJob.perform_later(merge_request: @merge_request)
    end

    redirect_to merge_request_path(@merge_request)
  end

private

  def page
    params.dig(:merge_request, :page)
  end

  def next_page_path
    return merge_request_path if is_referrer_type?("check_answers")

    case page
    when "absorbing_organisation"
      merging_organisations_merge_request_path(@merge_request)
    when "merging_organisations"
      merge_date_merge_request_path(@merge_request)
    when "merge_date"
      existing_absorbing_organisation_merge_request_path(@merge_request)
    when "existing_absorbing_organisation"
      helpdesk_ticket_merge_request_path(@merge_request)
    when "helpdesk_ticket"
      merge_request_path(@merge_request)
    end
  end

  def previous_template
    page
  end

  def set_organisations_answer_options
    answer_options = { "" => "Select an option" }

    if current_user.support?
      Organisation.all.pluck(:id, :name).each do |organisation|
        answer_options[organisation[0]] = organisation[1]
      end
    end

    @answer_options = answer_options
  end

  def merge_request_params
    merge_params = params.fetch(:merge_request, {}).permit(
      :requesting_organisation_id,
      :has_helpdesk_ticket,
      :helpdesk_ticket,
      :status,
      :absorbing_organisation_id,
      :merge_date,
      :existing_absorbing_organisation,
    )

    merge_params[:requesting_organisation_id] = current_user.organisation.id
    merge_params[:helpdesk_ticket] = nil if merge_params[:has_helpdesk_ticket] == "false"

    merge_params
  end

  def validate_response
    case page
    when "absorbing_organisation"
      if merge_request_params[:absorbing_organisation_id].blank?
        @merge_request.errors.add(:absorbing_organisation_id, :blank)
      end
    when "merge_date"
      day, month, year = merge_request_params["merge_date"].split("/")

      return @merge_request.errors.add(:merge_date, :blank) if [day, month, year].all?(&:blank?)

      if [day, month, year].none?(&:blank?) && Date.valid_date?(year.to_i, month.to_i, day.to_i)
        merge_request_params["merge_date"] = Time.zone.local(year.to_i, month.to_i, day.to_i)
        @merge_request.errors.add(:merge_date, :more_than_year_from_today) if Time.zone.local(year.to_i, month.to_i, day.to_i) - 1.year > Time.zone.today
      else
        @merge_request.errors.add(:merge_date, :invalid)
      end
    when "existing_absorbing_organisation"
      if merge_request_params[:existing_absorbing_organisation].nil?
        @merge_request.errors.add(:existing_absorbing_organisation, :blank)
      end
    when "helpdesk_ticket"
      @merge_request.has_helpdesk_ticket = merge_request_params[:has_helpdesk_ticket]
      @merge_request.helpdesk_ticket = merge_request_params[:helpdesk_ticket]
      if merge_request_params[:has_helpdesk_ticket].blank?
        @merge_request.errors.add(:has_helpdesk_ticket, :blank)
      elsif merge_request_params[:has_helpdesk_ticket] == "true" && merge_request_params[:helpdesk_ticket].blank?
        @merge_request.errors.add(:helpdesk_ticket, :blank)
      end
    end
  end

  def merge_request_organisation_params
    {
      merge_request: @merge_request,
      merging_organisation_id: params.dig(:merge_request, :merging_organisation),
    }
  end

  def find_resource
    return if params[:id].blank?

    @merge_request = MergeRequest.find(params[:id])
  end

  def authenticate_scope!
    unless current_user.support?
      render_not_found
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

  def add_merging_organsations
    new_merging_org_ids = params["merge_request"]["new_merging_org_ids"].split(" ")
    new_merging_org_ids.each do |org_id|
      MergeRequestOrganisation.create!(merge_request: @merge_request, merging_organisation_id: org_id)
    end
  end

  def remove_absorbing_org_from_merging_organisations
    if @merge_request.merge_request_organisations.where(merging_organisation_id: @merge_request.absorbing_organisation_id).exists?
      MergeRequestOrganisation.find_by(merge_request: @merge_request, merging_organisation_id: @merge_request.absorbing_organisation_id).destroy!
    end
  end
end
