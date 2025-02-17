class AddressSearchController < ApplicationController
  before_action :authenticate_user!

  def index
    query = params[:query]

    if query.match?(/\A\d+\z/) && query.length > 5
      # Query is all numbers and greater than 5 digits, assume it's a UPRN
      service = UprnClient.new(query)
      service.call

      if service.error.present?
        render json: { error: service.error }, status: :unprocessable_entity
      else
        presenter = UprnDataPresenter.new(service.result)
        render json: [{ address: presenter.address, uprn: presenter.uprn }]
      end
    elsif query.match?(/[a-zA-Z]/)
      # Query contains letters, assume it's an address
      service = AddressClient.new(query)
      service.call

      if service.error.present?
        render json: { error: service.error }, status: :unprocessable_entity
      else
        results = service.result.map do |result|
          presenter = AddressDataPresenter.new(result)
          { address: presenter.address, uprn: presenter.uprn }
        end
        render json: results
      end
    else
      # Query is ambiguous, use both APIs and merge results
      address_service = AddressClient.new(query)
      uprn_service = UprnClient.new(query)

      address_service.call
      uprn_service.call

      results = (address_service.result || []) + (uprn_service.result || [])

      if address_service.error.present? && uprn_service.error.present?
        render json: { error: "Address and UPRN are not recognised. Check the input." }, status: :unprocessable_entity
      else
        formatted_results = results.map do |result|
          presenter = AddressDataPresenter.new(result)
          { address: presenter.address, uprn: presenter.uprn }
        end
        render json: formatted_results
      end
    end
  end

  def manual_input
    log = params[:log_type] == "lettings_log" ? current_user.lettings_logs.find(params[:log_id]) : current_user.sales_logs.find(params[:log_id])
    log.update!(manual_address_entry_selected: true)
    redirect_to manual_address_link(log)
  end

  def search_input
    log = params[:log_type] == "lettings_log" ? current_user.lettings_logs.find(params[:log_id]) : current_user.sales_logs.find(params[:log_id])
    log.update!(manual_address_entry_selected: false)
    redirect_to search_address_link(log)
  end

private

  def manual_address_link(log)
    base_url = send("#{log.log_type}_url", log)
    "#{base_url}/address"
  end

  def search_address_link(log)
    base_url = send("#{log.log_type}_url", log)
    "#{base_url}/address-search"
  end
end
