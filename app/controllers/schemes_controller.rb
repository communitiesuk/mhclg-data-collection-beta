class SchemesController < ApplicationController
  include Pagy::Backend
  include Modules::SearchFilter

  before_action :authenticate_user!
  before_action :find_resource, except: %i[index]
  before_action :find_by_scheme_id, only: %i[edit]
  before_action :authenticate_scope!

  def index
    redirect_to schemes_organisation_path(current_user.organisation) unless current_user.support?
    all_schemes = Scheme.all

    @pagy, @schemes = pagy(filtered_collection(all_schemes, search_term))
    @searched = search_term.presence
    @total_count = all_schemes.size
  end

  def show
    @scheme = Scheme.find_by(id: params[:id])
  end

  def locations
    @scheme = Scheme.find_by(id: params[:id])
    @pagy, @locations = pagy(@scheme.locations)
    @total_count = @scheme.locations.size
  end

  def new
    @scheme = Scheme.new
  end

  def create
    @scheme = Scheme.new(clean_params)
    @scheme.save

    render "schemes/primary_client_group"
  end

  def primary_client_group
    @scheme = Scheme.find_by(id: params[:scheme_id])
    render "schemes/primary_client_group"
  end

  def confirm_secondary_group
    @scheme = Scheme.find_by(id: params[:scheme_id])
    if params[:scheme]
      required_params = params.require(:scheme).permit(:primary_client_group) if params
      @scheme.update(required_params) if required_params
    end
    render "schemes/confirm_secondary"
  end

  def secondary_client_group
    @scheme = Scheme.find_by(id: params[:scheme_id])
    if params[:confirmed]
      params[:confirmed][:selection] == "Yes" ? render("schemes/secondary_client_group") : render("schemes/support")
    else
      render "schemes/secondary_client_group"
    end
  end

  def support
    @scheme = Scheme.find_by(id: params[:scheme_id])
    if params[:scheme]
      required_params = params.require(:scheme).permit(:secondary_client_group)
      @scheme.update(required_params) if required_params
    end
    render "schemes/support"
  end

  def details
    @scheme = Scheme.find_by(id: params[:scheme_id])
    render "schemes/details"
  end

  def check_answers
    @scheme = Scheme.find_by(id: params[:scheme_id])
    if params[:scheme]
      required_params = params.require(:scheme).permit(:intended_stay, :support_type, :service_name, :sensitive, :organisation_id, :scheme_type, :registered_under_care_act, :total_units, :id, :confirmed)
      required_params[:sensitive] = required_params[:sensitive].to_i if required_params[:sensitive]
      @scheme.update(required_params)
    end
    render "schemes/check_answers"
  end

  def update
    @scheme = Scheme.find_by(id: params[:scheme_id])
    flash[:notice] = ("#{@scheme.service_name} has been created.")
    redirect_to schemes_path
  end

  private

  def clean_params
    code = "S#{SecureRandom.alphanumeric(5)}".upcase
    required_params = params.require(:scheme).permit(:service_name, :sensitive, :organisation_id, :scheme_type, :registered_under_care_act, :total_units, :id, :confirmed).merge(code: code)
    required_params[:sensitive] = required_params[:sensitive].to_i
    required_params
  end

  def search_term
    params["search"]
  end

  def find_by_scheme_id
    @scheme = Scheme.find_by(id: params[:scheme_id])
  end

  def find_resource
    @scheme = Scheme.find_by(id: params[:id])
  end

  def authenticate_scope!
    head :unauthorized and return unless current_user.data_coordinator? || current_user.support?

    if %w[show locations].include?(action_name) && !((current_user.organisation == @scheme.organisation) || current_user.support?)
      render_not_found and return
    end
  end
end
