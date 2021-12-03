class OrganisationsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_resource
  before_action :authenticate_scope!

  def show
    redirect_to details_organisation_path(@organisation)
  end

  def users
    if current_user.data_coordinator?
      render "users"
    else
      head :unauthorized
    end
  end

  def details
    render "show"
  end

private

  def authenticate_scope!
    head :not_found if current_user.organisation != @organisation
  end

  def find_resource
    @organisation = Organisation.find(params[:id])
  end
end
