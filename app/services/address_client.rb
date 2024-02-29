require "net/http"

class AddressClient
  attr_reader :address
  attr_accessor :error

  ADDRESS = "api.os.uk".freeze
  PATH = "/search/places/v1/find".freeze

  def initialize(address)
    @address = address
  end

  def call
    unless response.is_a?(Net::HTTPSuccess) && result.present?
      @error = "Address is not recognised. Check the address, or enter the UPRN"
    end
  rescue JSON::ParserError
    @error = "Address is not recognised. Check the address, or enter the UPRN"
  end

  def result
    @result ||= JSON.parse(response.body)["results"]&.map { |address| address["DPA"] }
  end

private

  def http_client
    client = Net::HTTP.new(ADDRESS, 443)
    client.use_ssl = true
    client.verify_mode = OpenSSL::SSL::VERIFY_PEER
    client.max_retries = 3
    client.read_timeout = 10 # seconds
    client
  end

  def endpoint_uri
    uri = URI(PATH)
    params = {
      query: address,
      key: ENV["OS_DATA_KEY"],
      matchprecision: 3,
      maxresults: 10,
    }
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end

  def response
    @response ||= http_client.request_get(endpoint_uri)
  end
end
