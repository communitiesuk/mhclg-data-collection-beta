class OrganisationsController < ApplicationController
  include Pagy::Backend
  include Modules::SearchFilter
  include DuplicateLogsHelper

  before_action :authenticate_user!
  before_action :find_resource, except: %i[index new create search]
  before_action :authenticate_scope!, except: %i[index search]
  before_action :session_filters, if: -> { current_user.support? || current_user.organisation.has_managing_agents? }, only: %i[lettings_logs sales_logs email_lettings_csv download_lettings_csv email_sales_csv download_sales_csv]
  before_action :session_filters, only: %i[users schemes email_schemes_csv download_schemes_csv]
  before_action -> { filter_manager.serialize_filters_to_session }, if: -> { current_user.support? || current_user.organisation.has_managing_agents? }, only: %i[lettings_logs sales_logs email_lettings_csv download_lettings_csv email_sales_csv download_sales_csv]
  before_action -> { filter_manager.serialize_filters_to_session }, only: %i[users schemes email_schemes_csv download_schemes_csv]

  def index
    redirect_to organisation_path(current_user.organisation) unless current_user.support?

    all_organisations = Organisation.order(:name)
    @pagy, @organisations = pagy(filtered_collection(all_organisations.visible, search_term))
    @merge_requests = MergeRequest.visible
                                  .joins("LEFT JOIN organisations ON organisations.id = merge_requests.absorbing_organisation_id")
                                  .order("organisations.name, merge_requests.merge_date DESC NULLS LAST, merge_requests.id")
    @searched = search_term.presence
    @total_count = all_organisations.visible.size
  end

  def schemes
    organisation_schemes = Scheme.visible.where(owning_organisation: [@organisation] + @organisation.parent_organisations + @organisation.absorbed_organisations.visible.merged_during_open_collection_period)

    @pagy, @schemes = pagy(filter_manager.filtered_schemes(organisation_schemes, search_term, session_filters))
    @searched = search_term.presence
    @total_count = organisation_schemes.size
    @filter_type = "schemes"
  end

  def download_schemes_csv
    organisation_schemes = Scheme.where(owning_organisation: [@organisation] + @organisation.parent_organisations)
    unpaginated_filtered_schemes = filter_manager.filtered_schemes(organisation_schemes, search_term, session_filters)

    render "schemes/download_csv", locals: { search_term:, post_path: schemes_email_csv_organisation_path, download_type: params[:download_type], schemes: unpaginated_filtered_schemes }
  end

  def email_schemes_csv
    SchemeEmailCsvJob.perform_later(current_user, search_term, session_filters, false, @organisation, params[:download_type])
    redirect_to schemes_csv_confirmation_organisation_path
  end

  def duplicate_schemes
    authorize @organisation

    get_duplicate_schemes_and_locations
  end

  def show
    redirect_to details_organisation_path(@organisation)
  end

  def users
    organisation_users = @organisation.users.visible.sorted_by_organisation_and_role
    unpaginated_filtered_users = filter_manager.filtered_users(organisation_users, search_term, session_filters)

    respond_to do |format|
      format.html do
        @pagy, @users = pagy(unpaginated_filtered_users)
        @searched = search_term.presence
        @total_count = @organisation.users.visible.size
        @filter_type = "users"

        if current_user.support?
          render "users", layout: "application"
        else
          render "users/index"
        end
      end
      format.csv do
        send_data byte_order_mark + unpaginated_filtered_users.to_csv, filename: "users-#{@organisation.name}-#{Time.zone.now}.csv"
      end
    end
  end

  def details
    render "show"
  end

  def new
    @organisation = Organisation.new
    @rent_periods = helpers.rent_periods_with_checked_attr
    render "new", layout: "application"
  end

  def create
    selected_rent_periods = rent_period_params[:rent_periods].compact_blank
    @organisation = Organisation.new(org_params)
    if @organisation.save
      OrganisationRentPeriod.transaction do
        selected_rent_periods.each { |period| OrganisationRentPeriod.create!(organisation: @organisation, rent_period: period) }
      end
      flash[:notice] = I18n.t("organisation.created", organisation: @organisation.name)
      redirect_to organisation_path @organisation
    else
      @rent_periods = helpers.rent_periods_with_checked_attr(checked_periods: selected_rent_periods)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    if current_user.data_coordinator? || current_user.support?
      current_allowed_rent_periods = @organisation.organisation_rent_periods.pluck(:rent_period).map(&:to_s)
      @used_rent_periods = @organisation.lettings_logs.pluck(:period).uniq.compact.map(&:to_s)
      @rent_periods = helpers.rent_periods_with_checked_attr(checked_periods: current_allowed_rent_periods)
      render "edit", layout: "application"
    else
      head :unauthorized
    end
  end

  def deactivate
    authorize @organisation

    render "toggle_active", locals: { action: "deactivate" }
  end

  def reactivate
    authorize @organisation

    render "toggle_active", locals: { action: "reactivate" }
  end

  def update
    if (current_user.data_coordinator? && org_params[:active].nil?) || current_user.support?
      if @organisation.update(org_params)
        case org_params[:active]
        when "false"
          @organisation.users.filter_by_active.each do |user|
            user.deactivate!(reactivate_with_organisation: true)
          end
          flash[:notice] = I18n.t("organisation.deactivated", organisation: @organisation.name)
        when "true"
          users_to_reactivate = @organisation.users.where(reactivate_with_organisation: true)
          users_to_reactivate.each do |user|
            user.reactivate!
            user.send_confirmation_instructions
          end
          flash[:notice] = I18n.t("organisation.reactivated", organisation: @organisation.name)
        else
          flash[:notice] = I18n.t("organisation.updated")
        end
        if rent_period_params[:rent_periods].present?
          selected_rent_periods = rent_period_params[:rent_periods].compact_blank
          used_rent_periods = @organisation.lettings_logs.pluck(:period).uniq.compact.map(&:to_s)
          rent_periods_to_delete = rent_period_params[:all_rent_periods] - selected_rent_periods - used_rent_periods
          OrganisationRentPeriod.transaction do
            selected_rent_periods.each { |period| OrganisationRentPeriod.create(organisation: @organisation, rent_period: period) }
            OrganisationRentPeriod.where(organisation: @organisation, rent_period: rent_periods_to_delete).destroy_all
          end
        end
        redirect_to details_organisation_path(@organisation)
      else
        @used_rent_periods = @organisation.lettings_logs.pluck(:period).uniq.compact.map(&:to_s)
        @rent_periods = helpers.rent_periods_with_checked_attr(checked_periods: selected_rent_periods)
        render :edit, status: :unprocessable_entity
      end
    else
      head :unauthorized
    end
  end

  def delete
    authorize @organisation

    @organisation.discard!
    redirect_to organisations_path, notice: I18n.t("notification.organisation_deleted", name: @organisation.name)
  end

  def delete_confirmation
    authorize @organisation
  end

  def lettings_logs
    organisation_logs = LettingsLog.visible.filter_by_organisation(@organisation.absorbed_organisations + [@organisation]).filter_by_years_or_nil(FormHandler.instance.years_of_available_lettings_forms)
    unpaginated_filtered_logs = filter_manager.filtered_logs(organisation_logs, search_term, session_filters)

    @search_term = search_term
    @pagy, @logs = pagy(unpaginated_filtered_logs)
    @delete_logs_path = delete_lettings_logs_organisation_path(search: @search_term)
    @searched = search_term.presence
    @total_count = organisation_logs.size
    @log_type = :lettings
    @filter_type = "lettings_logs"
    @duplicate_sets_count = duplicate_sets_count(current_user, @organisation)
    render "logs", layout: "application"
  end

  def download_lettings_csv
    redirect_to lettings_logs_filters_years_organisation_path(search: search_term, codes_only: codes_only_export?) and return if session_filters["years"].blank? || session_filters["years"].count != 1

    organisation_logs = LettingsLog.visible.where(owning_organisation_id: @organisation.id)
    unpaginated_filtered_logs = filter_manager.filtered_logs(organisation_logs, search_term, session_filters)
    codes_only = params.require(:codes_only) == "true"

    render "logs/download_csv", locals: { search_term:, count: unpaginated_filtered_logs.size, post_path: lettings_logs_email_csv_organisation_path, codes_only:, session_filters:, filter_type: "lettings_logs", download_csv_back_link: lettings_logs_organisation_path(@organisation) }
  end

  def email_lettings_csv
    EmailCsvJob.perform_later(current_user, search_term, session_filters, false, @organisation, codes_only_export?, "lettings", session_filters["years"].first.to_i)
    redirect_to lettings_logs_csv_confirmation_organisation_path
  end

  def sales_logs
    organisation_logs = SalesLog.visible.filter_by_organisation(@organisation.absorbed_organisations + [@organisation]).filter_by_years_or_nil(FormHandler.instance.years_of_available_sales_forms)
    unpaginated_filtered_logs = filter_manager.filtered_logs(organisation_logs, search_term, session_filters)

    respond_to do |format|
      format.html do
        @search_term = search_term
        @pagy, @logs = pagy(unpaginated_filtered_logs)
        @delete_logs_path = delete_sales_logs_organisation_path(search: @search_term)
        @searched = search_term.presence
        @total_count = organisation_logs.size
        @log_type = :sales
        @filter_type = "sales_logs"
        @duplicate_sets_count = duplicate_sets_count(current_user, @organisation)
        render "logs", layout: "application"
      end

      format.csv do
        send_data byte_order_mark + unpaginated_filtered_logs.to_csv, filename: "sales-logs-#{@organisation.name}-#{Time.zone.now}.csv"
      end
    end
  end

  def download_sales_csv
    redirect_to sales_logs_filters_years_organisation_path(search: search_term, codes_only: codes_only_export?) and return if session_filters["years"].blank? || session_filters["years"].count != 1

    organisation_logs = SalesLog.visible.where(owning_organisation_id: @organisation.id)
    unpaginated_filtered_logs = filter_manager.filtered_logs(organisation_logs, search_term, session_filters)
    codes_only = params.require(:codes_only) == "true"

    render "logs/download_csv", locals: { search_term:, count: unpaginated_filtered_logs.size, post_path: sales_logs_email_csv_organisation_path, codes_only:, session_filters:, filter_type: "sales_logs", download_csv_back_link: sales_logs_organisation_path(@organisation) }
  end

  def email_sales_csv
    EmailCsvJob.perform_later(current_user, search_term, session_filters, false, @organisation, codes_only_export?, "sales", session_filters["years"].first.to_i)
    redirect_to sales_logs_csv_confirmation_organisation_path
  end

  def merge_request
    @merge_request = MergeRequest.new
    render "merge_requests/merge_request"
  end

  def data_sharing_agreement
    @data_protection_confirmation = @organisation.data_protection_confirmation
  end

  def confirm_data_sharing_agreement
    return render_not_found unless current_user.is_dpo?
    return render_not_found if @organisation.data_protection_confirmed?

    if @organisation.data_protection_confirmation
      @organisation.data_protection_confirmation.update!(
        confirmed: true,
        data_protection_officer: current_user,
        signed_at: Time.zone.now,
        organisation_name: @organisation.name,
        organisation_address: @organisation.address_row,
        organisation_phone_number: @organisation.phone,
        data_protection_officer_email: current_user.email,
        data_protection_officer_name: current_user.name,
      )
    else
      DataProtectionConfirmation.create!(
        organisation: @organisation,
        confirmed: true,
        data_protection_officer: current_user,
        signed_at: Time.zone.now,
        organisation_name: @organisation.name,
        organisation_address: @organisation.address_row,
        organisation_phone_number: @organisation.phone,
        data_protection_officer_email: current_user.email,
        data_protection_officer_name: current_user.name,
      )
    end

    flash[:notice] = "You have accepted the Data Sharing Agreement"
    flash[:notification_banner_body] = "Your organisation can now submit logs."

    redirect_to details_organisation_path(@organisation)
  end

  def changes
    render "schemes/changes"
  end

  def search
    org_options = current_user.support? ? Organisation.all : Organisation.affiliated_organisations(current_user.organisation)
    organisations = org_options.search_by(params["query"]).limit(20)

    org_data = organisations.each_with_object({}) do |org, hash|
      hash[org.id] = { value: org.name }
    end

    render json: org_data.to_json
  end

  def confirm_duplicate_schemes
    authorize @organisation

    if scheme_duplicates_checked_params[:scheme_duplicates_checked] == "true"
      @organisation.schemes_deduplicated_at = Time.zone.now
      if @organisation.save
        flash[:notice] = I18n.t("organisation.duplicate_schemes_confirmed")
        redirect_to schemes_organisation_path(@organisation)
      end
    else
      @organisation.errors.add(:scheme_duplicates_checked, I18n.t("validations.organisation.scheme_duplicates_not_resolved"))
      get_duplicate_schemes_and_locations
      render :duplicate_schemes, status: :unprocessable_entity
    end
  end

private

  def filter_type
    if params[:action].include?("lettings")
      "lettings_logs"
    elsif params[:action].include?("sales")
      "sales_logs"
    elsif params[:action].include?("users")
      "users"
    elsif params[:action].include?("schemes")
      "schemes"
    end
  end

  def session_filters
    filter_manager.session_filters
  end

  def filter_manager
    FilterManager.new(current_user:, session:, params:, filter_type:)
  end

  def org_params
    params.require(:organisation).permit(:name, :address_line1, :address_line2, :postcode, :phone, :holds_own_stock, :provider_type, :housing_registration_no, :active)
  end

  def rent_period_params
    params.require(:organisation).permit(rent_periods: [], all_rent_periods: [])
  end

  def scheme_duplicates_checked_params
    params.require(:organisation).permit(:scheme_duplicates_checked)
  end

  def codes_only_export?
    params.require(:codes_only) == "true"
  end

  def search_term
    params["search"]
  end

  def authenticate_scope!
    if %w[create new lettings_logs sales_logs download_lettings_csv email_lettings_csv email_sales_csv download_sales_csv delete_confirmation delete].include? action_name
      head :unauthorized and return unless current_user.support?
    elsif current_user.organisation != @organisation && !current_user.support?
      render_not_found
    end
  end

  def find_resource
    @organisation = Organisation.find(params[:id])
  end

  def get_duplicate_schemes_and_locations
    duplicate_scheme_sets = @organisation.owned_schemes.duplicate_sets
    @duplicate_schemes = duplicate_scheme_sets.map { |set| set.map { |id| @organisation.owned_schemes.find(id) } }
    @duplicate_locations = []
    @organisation.owned_schemes.each do |scheme|
      duplicate_location_sets = scheme.locations.duplicate_sets
      next unless duplicate_location_sets.any?

      duplicate_location_sets.each do |duplicate_set|
        @duplicate_locations << { scheme: scheme, locations: duplicate_set.map { |id| scheme.locations.find(id) } }
      end
    end
  end
end
