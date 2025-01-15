class LocationsController < ApplicationController
  include Pagy::Backend
  include Modules::SearchFilter

  before_action :authenticate_user!
  before_action :find_location, except: %i[create index]
  before_action :find_scheme
  before_action :scheme_and_location_present, except: %i[create index]
  before_action :session_filters, if: :current_user, only: %i[index]
  before_action -> { filter_manager.serialize_filters_to_session }, if: :current_user, only: %i[index]

  before_action :authorize_user, except: %i[index create]

  def index
    authorize @scheme

    @pagy, @locations = pagy(filter_manager.filtered_locations(@scheme.locations.visible, search_term, session_filters))
    @total_count = @scheme.locations.visible.size
    @searched = search_term.presence
    @filter_type = "scheme_locations"
  end

  def create
    @location = @scheme.locations.new

    authorize @location

    @location.save!

    redirect_to scheme_location_postcode_path(@scheme, @location, route: params[:route])
  end

  def postcode; end
  def update; end

  def update_postcode
    @location.postcode = location_params[:postcode]
    if @location.save(context: :postcode)
      if @location.location_code.blank? || @location.location_admin_district.blank?
        redirect_to scheme_location_local_authority_path(@scheme, @location, route: params[:route], referrer: params[:referrer])
      elsif return_to_check_your_answers?
        redirect_to scheme_location_check_answers_path(@scheme, @location, route: params[:route])
      elsif params[:referrer] == "details"
        redirect_to scheme_location_path(@scheme, @location)
      else
        redirect_to scheme_location_name_path(@scheme, @location, route: params[:route])
      end
    else
      render :postcode, status: :unprocessable_entity
    end
  end

  def local_authority; end

  def update_local_authority
    @location.location_admin_district = location_params[:location_admin_district]
    @location.location_code = Location.local_authorities_for_current_year.key(location_params[:location_admin_district])
    if @location.save(context: :location_admin_district)
      if return_to_check_your_answers? || params[:referrer] == "check_local_authority"
        redirect_to scheme_location_check_answers_path(@scheme, @location, route: params[:route])
      else
        redirect_to scheme_location_name_path(@scheme, @location, route: params[:route])
      end
    else
      render :local_authority, status: :unprocessable_entity
    end
  end

  def name; end

  def update_name
    @location.name = location_params[:name]
    if @location.save(context: :name)
      if return_to_check_your_answers?
        redirect_to scheme_location_check_answers_path(@scheme, @location, route: params[:route])
      elsif params[:referrer] == "details"
        redirect_to scheme_location_path(@scheme, @location)
      else
        redirect_to scheme_location_units_path(@scheme, @location, route: params[:route])
      end
    else
      render :name, status: :unprocessable_entity
    end
  end

  def units; end

  def update_units
    @location.units = location_params[:units]
    if @location.save(context: :units)
      if return_to_check_your_answers?
        redirect_to scheme_location_check_answers_path(@scheme, @location, route: params[:route])
      elsif params[:referrer] == "details"
        redirect_to scheme_location_path(@scheme, @location)
      else
        redirect_to scheme_location_type_of_unit_path(@scheme, @location, route: params[:route])
      end
    else
      render :units, status: :unprocessable_entity
    end
  end

  def type_of_unit; end

  def update_type_of_unit
    @location.type_of_unit = location_params[:type_of_unit]
    if @location.save(context: :type_of_unit)
      if return_to_check_your_answers?
        redirect_to scheme_location_check_answers_path(@scheme, @location, route: params[:route])
      elsif params[:referrer] == "details"
        redirect_to scheme_location_path(@scheme, @location)
      else
        redirect_to scheme_location_mobility_standards_path(@scheme, @location, route: params[:route])
      end
    else
      render :type_of_unit, status: :unprocessable_entity
    end
  end

  def mobility_standards; end

  def update_mobility_standards
    @location.mobility_type = location_params[:mobility_type]
    if @location.save(context: :mobility_type)
      if return_to_check_your_answers?
        redirect_to scheme_location_check_answers_path(@scheme, @location, route: params[:route])
      elsif params[:referrer] == "details"
        redirect_to scheme_location_path(@scheme, @location)
      else
        redirect_to scheme_location_availability_path(@scheme, @location, route: params[:route])
      end
    else
      render :mobility_standards, status: :unprocessable_entity
    end
  end

  def availability; end

  def update_availability
    day, month, year = location_params["startdate"].split("/")
    @location.startdate = if [day, month, year].none?(&:blank?) && Date.valid_date?(year.to_i, month.to_i, day.to_i)
                            Time.zone.local(year.to_i, month.to_i, day.to_i)
                          end
    if @location.save(context: :startdate)
      redirect_to scheme_location_check_answers_path(@scheme, @location, route: params[:route])
    else
      render :availability, status: :unprocessable_entity
    end
  end

  def check_answers; end

  def confirm
    flash[:notice] = helpers.location_creation_success_notice(@location)
    redirect_to scheme_locations_path(@scheme)
  end

  def show; end

  def new_deactivation
    @location_deactivation_period = if @location.deactivates_in_a_long_time?
                                      @location.open_deactivation || LocationDeactivationPeriod.new
                                    else
                                      LocationDeactivationPeriod.new
                                    end

    if params[:location_deactivation_period].blank?
      render "toggle_active", locals: { action: "deactivate" }
    else
      @location_deactivation_period.deactivation_date = toggle_date("deactivation_date")
      @location_deactivation_period.deactivation_date_type = params[:location_deactivation_period][:deactivation_date_type]
      @location_deactivation_period.location = @location
      if @location_deactivation_period.valid?
        redirect_to scheme_location_deactivate_confirm_path(@location, deactivation_date: @location_deactivation_period.deactivation_date, deactivation_date_type: @location_deactivation_period.deactivation_date_type)
      else
        render "toggle_active", locals: { action: "deactivate" }, status: :unprocessable_entity
      end
    end
  end

  def deactivate_confirm
    @affected_logs = @location.lettings_logs.visible.after_date(params[:deactivation_date])
    if @affected_logs.count.zero?
      deactivate
    else
      @deactivation_date = params[:deactivation_date]
      @deactivation_date_type = params[:deactivation_date_type]
    end
  end

  def deactivate
    if @location.open_deactivation&.update!(deactivation_date: params[:deactivation_date]) || @location.location_deactivation_periods.create!(deactivation_date: params[:deactivation_date])
      logs = reset_location_and_scheme_for_logs!

      flash[:notice] = deactivate_success_notice

      logs.group_by(&:assigned_to).transform_values(&:count).each do |user, count|
        next unless user

        LocationOrSchemeDeactivationMailer.send_deactivation_mail(
          user,
          count,
          url_for(controller: "lettings_logs", action: "update_logs"),
          @location.scheme.service_name,
          @location.postcode,
        ).deliver_later
      end
    end
    redirect_to scheme_location_path(@scheme, @location)
  end

  def new_reactivation
    @location_deactivation_period = @location.location_deactivation_periods.deactivations_without_reactivation.first
    render "toggle_active", locals: { action: "reactivate" }
  end

  def reactivate
    @location_deactivation_period = @location.location_deactivation_periods.deactivations_without_reactivation.first

    @location_deactivation_period.reactivation_date = toggle_date("reactivation_date")
    @location_deactivation_period.reactivation_date_type = params[:location_deactivation_period][:reactivation_date_type]

    if @location_deactivation_period.update(reactivation_date: toggle_date("reactivation_date"))
      flash[:notice] = reactivate_success_notice
      redirect_to scheme_location_path(@scheme, @location)
    else
      render "toggle_active", locals: { action: "reactivate" }, status: :unprocessable_entity
    end
  end

  def delete
    @location.discard!
    redirect_to scheme_locations_path(@scheme), notice: I18n.t("notification.location_deleted", postcode: @location.postcode)
  end

private

  def authorize_user
    authorize(@location || Location)
  end

  def scheme_and_location_present
    render_not_found and return unless @location && @scheme
  end

  def find_scheme
    @scheme = if %w[create index].include?(action_name)
                Scheme.find(params[:scheme_id])
              else
                @location&.scheme
              end
  end

  def find_location
    @location = params[:location_id].present? ? Location.find_by(id: params[:location_id]) : Location.find_by(id: params[:id])
  end

  def location_params
    required_params = params.require(:location).permit(:postcode, :location_admin_district, :location_code, :name, :units, :type_of_unit, :mobility_type, :startdate).merge(scheme_id: @scheme.id)
    required_params[:postcode] = PostcodeService.clean(required_params[:postcode]) if required_params[:postcode]
    required_params[:location_admin_district] = nil if required_params[:location_admin_district] == "Select an option"
    required_params
  end

  def search_term
    params["search"]
  end

  def deactivate_success_notice
    case @location.status
    when :deactivated
      "#{@location.name} has been deactivated"
    when :deactivating_soon
      "#{@location.name} will deactivate on #{params[:deactivation_date].to_time.to_formatted_s(:govuk_date)}"
    end
  end

  def reactivate_success_notice
    case @location.status
    when :active
      "#{@location.name} has been reactivated"
    when :reactivating_soon
      "#{@location.name} will reactivate on #{toggle_date('reactivation_date').to_time.to_formatted_s(:govuk_date)}"
    end
  end

  def reset_location_and_scheme_for_logs!
    logs = @location.lettings_logs.visible.after_date(params[:deactivation_date].to_time)
    logs.update!(location: nil, scheme: nil, unresolved: true)
    logs
  end

  def toggle_date(key)
    if params[:location_deactivation_period].blank?
      return
    elsif params[:location_deactivation_period]["#{key}_type".to_sym] == "default"
      return FormHandler.instance.start_date_of_earliest_open_for_editing_collection_period
    end

    day, month, year = params[:location_deactivation_period][key.to_s].split("/")
    return nil if [day, month, year].any?(&:blank?)

    Time.zone.local(year.to_i, month.to_i, day.to_i) if Date.valid_date?(year.to_i, month.to_i, day.to_i)
  end

  def return_to_check_your_answers?
    params[:referrer] == "check_answers"
  end
  helper_method :return_to_check_your_answers?

  def filter_manager
    FilterManager.new(current_user:, session:, params:, filter_type: "scheme_locations")
  end

  def session_filters
    filter_manager.session_filters
  end
end
