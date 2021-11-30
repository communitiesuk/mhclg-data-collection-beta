class OrganisationsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_organisation

  def users
    render "users"
  end

private

  def find_organisation
    @organisation = Organisation.find(params[:id])
  end
end
