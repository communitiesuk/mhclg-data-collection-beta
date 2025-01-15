class SchemesController < ApplicationController
  include Pagy::Backend
  include Modules::SearchFilter

  before_action :authenticate_user!
  before_action :find_resource, except: %i[index create new changes email_csv download_csv csv_confirmation]
  before_action :redirect_if_scheme_confirmed, only: %i[primary_client_group confirm_secondary_client_group secondary_client_group support details]
  before_action :authorize_user, except: %i[email_csv download_csv csv_confirmation]
  before_action :session_filters, if: :current_user, only: %i[index email_csv download_csv]
  before_action -> { filter_manager.serialize_filters_to_session }, if: :current_user, only: %i[index email_csv download_csv]

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  def index
    redirect_to schemes_organisation_path(current_user.organisation) unless current_user.support?
    all_visible_schemes = Scheme.visible

    @pagy, @schemes = pagy(filter_manager.filtered_schemes(all_visible_schemes, search_term, session_filters))
    @searched = search_term.presence
    @total_count = all_visible_schemes.size
    @filter_type = "schemes"
  end

  def show
    @scheme = Scheme.find_by(id: params[:id])

    authorize @scheme

    render_not_found and return unless @scheme
  end

  def new_deactivation
    @scheme_deactivation_period = if @scheme.deactivates_in_a_long_time?
                                    @scheme.open_deactivation || SchemeDeactivationPeriod.new
                                  else
                                    SchemeDeactivationPeriod.new
                                  end

    if params[:scheme_deactivation_period].blank?
      render "toggle_active", locals: { action: "deactivate" }
    else
      @scheme_deactivation_period.deactivation_date = toggle_date("deactivation_date")
      @scheme_deactivation_period.deactivation_date_type = params[:scheme_deactivation_period][:deactivation_date_type]
      @scheme_deactivation_period.scheme = @scheme
      if @scheme_deactivation_period.valid?
        redirect_to scheme_deactivate_confirm_path(@scheme, deactivation_date: @scheme_deactivation_period.deactivation_date, deactivation_date_type: @scheme_deactivation_period.deactivation_date_type)
      else
        render "toggle_active", locals: { action: "deactivate" }, status: :unprocessable_entity
      end
    end
  end

  def deactivate_confirm
    @deactivation_date = Time.zone.parse(params[:deactivation_date])
    @affected_logs = @scheme.lettings_logs.visible.after_date(@deactivation_date)
    @deactivation_date_type = params[:deactivation_date_type]

    scheme_locations = @scheme.locations.confirmed

    @affected_locations = scheme_locations.select do |location|
      %i[active deactivating_soon reactivating_soon activating_soon].include?(location.status_at(@deactivation_date))
    end

    if @affected_logs.count.zero? && @affected_locations.count.zero?
      deactivate
    end
  end

  def deactivate
    deactivation_date = params[:deactivation_date]
    if @scheme.open_deactivation&.update!(deactivation_date:) || @scheme.scheme_deactivation_periods.create!(deactivation_date:)
      logs = reset_location_and_scheme_for_logs!

      flash[:notice] = deactivate_success_notice

      logs.group_by(&:assigned_to).transform_values(&:count).each do |user, count|
        next unless user

        LocationOrSchemeDeactivationMailer.send_deactivation_mail(
          user,
          count,
          url_for(controller: "lettings_logs", action: "update_logs"),
          @scheme.service_name,
        ).deliver_later
      end
    end
    redirect_to scheme_details_path(@scheme)
  end

  def new_reactivation
    @scheme_deactivation_period = @scheme.scheme_deactivation_periods.deactivations_without_reactivation.first
    render "toggle_active", locals: { action: "reactivate" }
  end

  def reactivate
    @scheme_deactivation_period = @scheme.scheme_deactivation_periods.deactivations_without_reactivation.first

    @scheme_deactivation_period.reactivation_date = toggle_date("reactivation_date")
    @scheme_deactivation_period.reactivation_date_type = params[:scheme_deactivation_period][:reactivation_date_type]

    if @scheme_deactivation_period.update(reactivation_date: toggle_date("reactivation_date"))
      flash[:notice] = reactivate_success_notice
      redirect_to scheme_details_path(@scheme)
    else
      render "toggle_active", locals: { action: "reactivate" }, status: :unprocessable_entity
    end
  end

  def new
    @scheme = Scheme.new
  end

  def create
    @scheme = Scheme.new(scheme_params)

    authorize @scheme

    validation_errors scheme_params

    if @scheme.errors.empty? && @scheme.save
      if @scheme.owning_organisation.merge_date.present?
        deactivation = SchemeDeactivationPeriod.new(scheme: @scheme, deactivation_date: @scheme.owning_organisation.merge_date)
        deactivation.save!(validate: false)
      end
      redirect_to scheme_primary_client_group_path(@scheme)
    else
      if @scheme.errors.any? { |error| error.attribute == :owning_organisation }
        @scheme.errors.add(:owning_organisation_id, message: @scheme.errors[:organisation])
        @scheme.errors.delete(:owning_organisation)
      end
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    render_not_found and return unless @scheme
  end

  def update
    render_not_found and return unless @scheme

    authorize @scheme

    check_answers = params[:scheme][:check_answers]
    page = params[:scheme][:page]
    scheme_previously_confirmed = @scheme.confirmed?

    validation_errors scheme_params
    if @scheme.errors.empty? && @scheme.update(scheme_params)
      @scheme.update!(secondary_client_group: nil) if @scheme.has_other_client_group == "No"
      if scheme_params[:confirmed] == "true" || @scheme.confirmed?
        if check_answers && should_direct_via_secondary_client_group_page?(page)
          redirect_to scheme_secondary_client_group_path(@scheme, referrer: "has-other-client-group")
        else
          @scheme.locations.update!(confirmed: true)
          flash[:notice] = if scheme_previously_confirmed
                             "#{@scheme.service_name} has been updated."
                           else
                             "#{@scheme.service_name} has been created."
                           end
          redirect_to scheme_path(@scheme)
        end
      elsif check_answers
        if should_direct_via_secondary_client_group_page?(page)
          redirect_to scheme_secondary_client_group_path(@scheme, referrer: "has-other-client-group")
        else
          redirect_to scheme_check_answers_path(@scheme)
        end
      else
        redirect_to next_page_path params[:scheme][:page]
      end
    else
      render current_template(page), status: :unprocessable_entity
    end
  end

  def primary_client_group
    render_not_found and return unless @scheme

    render "schemes/primary_client_group"
  end

  def confirm_secondary_client_group
    render_not_found and return unless @scheme

    render "schemes/confirm_secondary"
  end

  def secondary_client_group
    render_not_found and return unless @scheme

    render "schemes/secondary_client_group"
  end

  def support
    render_not_found and return unless @scheme

    render "schemes/support"
  end

  def details
    render_not_found and return unless @scheme

    render "schemes/details"
  end

  def check_answers
    render_not_found and return unless @scheme

    render "schemes/check_answers"
  end

  def edit_name
    render_not_found and return unless @scheme

    render "schemes/edit_name"
  end

  def changes
    render "schemes/changes"
  end

  def download_csv
    unpaginated_filtered_schemes = filter_manager.filtered_schemes(current_user.schemes, search_term, session_filters)

    render "download_csv", locals: { search_term:, post_path: email_csv_schemes_path, download_type: params[:download_type], schemes: unpaginated_filtered_schemes }
  end

  def email_csv
    all_orgs = params["organisation_select"] == "all"
    SchemeEmailCsvJob.perform_later(current_user, search_term, session_filters, all_orgs, nil, params[:download_type])
    redirect_to csv_confirmation_schemes_path
  end

  def csv_confirmation; end

  def delete
    @scheme.discard!
    redirect_to schemes_organisation_path(@scheme.owning_organisation), notice: I18n.t("notification.scheme_deleted", service_name: @scheme.service_name)
  end

private

  def authorize_user
    authorize(@scheme || Scheme)
  end

  def validation_errors(scheme_params)
    scheme_params.each_key do |key|
      if scheme_params[key].to_s.empty?
        @scheme.errors.add(key.to_sym)
      end
    end
  end

  def should_direct_via_secondary_client_group_page?(page)
    page == "confirm-secondary" && @scheme.has_other_client_group == "Yes" && @scheme.secondary_client_group.nil?
  end

  def current_template(page)
    if page.include?("primary")
      "schemes/primary_client_group"
    elsif page.include?("confirm")
      "schemes/confirm_secondary"
    elsif page.include?("secondary-client")
      "schemes/secondary_client_group"
    elsif page.include?("support")
      "schemes/support"
    elsif page.include?("details")
      "schemes/details"
    elsif page.include?("edit")
      "schemes/edit_name"
    elsif page.include?("check-answers")
      "schemes/check_answers"
    end
  end

  def next_page_path(page)
    case page
    when "primary-client-group"
      scheme_confirm_secondary_client_group_path(@scheme)
    when "confirm-secondary"
      @scheme.has_other_client_group == "Yes" ? scheme_secondary_client_group_path(@scheme) : scheme_support_path(@scheme)
    when "secondary-client-group"
      scheme_support_path(@scheme)
    when "support"
      scheme_check_answers_path(@scheme)
    when "details"
      scheme_primary_client_group_path(@scheme)
    when "edit-name"
      scheme_check_answers_path(@scheme)
    when "check-answers"
      schemes_path(scheme_id: @scheme.id)
    end
  end

  def scheme_params
    required_params = params.require(:scheme).permit(:service_name,
                                                     :sensitive,
                                                     :scheme_type,
                                                     :registered_under_care_act,
                                                     :owning_organisation_id,
                                                     :id,
                                                     :has_other_client_group,
                                                     :primary_client_group,
                                                     :secondary_client_group,
                                                     :support_type,
                                                     :arrangement_type,
                                                     :intended_stay,
                                                     :confirmed)

    required_params[:sensitive] = required_params[:sensitive].to_i if required_params[:sensitive]

    if current_user.data_coordinator? && current_user.organisation.stock_owners.count.zero?
      required_params[:owning_organisation_id] = current_user.organisation_id
    end
    required_params
  end

  def search_term
    params["search"]
  end

  def find_resource
    @scheme = Scheme.find_by(id: params[:id]) || Scheme.find_by(id: params[:scheme_id])

    raise ActiveRecord::RecordNotFound unless @scheme

    @scheme
  end

  def redirect_if_scheme_confirmed
    redirect_to @scheme if @scheme.confirmed? && !current_user.support?
  end

  def deactivate_success_notice
    case @scheme.status
    when :deactivated
      "#{@scheme.service_name} has been deactivated"
    when :deactivating_soon
      "#{@scheme.service_name} will deactivate on #{params[:deactivation_date].to_time.to_formatted_s(:govuk_date)}"
    end
  end

  def reactivate_success_notice
    case @scheme.status
    when :active
      "#{@scheme.service_name} has been reactivated"
    when :reactivating_soon
      "#{@scheme.service_name} will reactivate on #{toggle_date('reactivation_date').to_time.to_formatted_s(:govuk_date)}"
    end
  end

  def toggle_date(key)
    if params[:scheme_deactivation_period].blank?
      return
    elsif params[:scheme_deactivation_period]["#{key}_type".to_sym] == "default"
      return FormHandler.instance.start_date_of_earliest_open_for_editing_collection_period
    end

    day, month, year = params[:scheme_deactivation_period][key.to_s].split("/")
    return nil if [day, month, year].any?(&:blank?)

    Time.zone.local(year.to_i, month.to_i, day.to_i) if Date.valid_date?(year.to_i, month.to_i, day.to_i)
  end

  def reset_location_and_scheme_for_logs!
    logs = @scheme.lettings_logs.visible.after_date(params[:deactivation_date].to_time)
    logs.update!(location: nil, scheme: nil, unresolved: true)
    logs
  end

  def filter_manager
    FilterManager.new(current_user:, session:, params:, filter_type: "schemes")
  end

  def session_filters
    filter_manager.session_filters
  end
end
