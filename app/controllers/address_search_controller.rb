class AddressSearchController < ApplicationController
  before_action :authenticate_user!
  before_action :set_log, only: %i[manual_input search_input]

  def index
    query = params[:query]

    if query.match?(/\A\d+\z/) && query.length > 5
      # Query is all numbers and greater than 5 digits, assume it's a UPRN
      service = UprnClient.new(query)
      service.call

      if service.error.present?
        render json: { error: service.error }, status: :not_found
      else
        presenter = UprnDataPresenter.new(service.result)
        render json: [{ text: presenter.address, value: presenter.uprn }]
      end
    elsif query.match?(/[a-zA-Z]/)
      # Query contains letters, assume it's an address
      service = AddressClient.new(query, { minmatch: 0.2 })
      service.call

      if service.error.present?
        render json: { error: service.error }, status: :not_found
      else
        results = service.result.map do |result|
          presenter = AddressDataPresenter.new(result)
          { text: presenter.address, value: presenter.uprn }
        end
        render json: results
      end
    else
      # Query is ambiguous, use both APIs and merge results
      address_service = AddressClient.new(query, { minmatch: 0.2 })
      uprn_service = UprnClient.new(query)

      address_service.call
      uprn_service.call

      results = ([uprn_service.result] || []) + (address_service.result || [])

      if address_service.error.present? && uprn_service.error.present?
        render json: { error: "Address and UPRN are not recognised." }, status: :not_found
      else
        formatted_results = results.map do |result|
          presenter = AddressDataPresenter.new(result)
          { text: presenter.address, value: presenter.uprn }
        end
        render json: formatted_results
      end
    end
  end

  def manual_input
    @log.update!(manual_address_entry_selected: true)
    redirect_to polymorphic_url([@log, :address])
  end

  def search_input
    @log.update!(manual_address_entry_selected: false)
    redirect_to polymorphic_url([@log, :address_search])
  end

private

  def set_log
    @log = current_user.send("#{params[:log_type]}s").find(params[:log_id])
  end
end
