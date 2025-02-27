require "net/http"

class AddressClient
  attr_reader :address
  attr_accessor :error

  ADDRESS = "api.os.uk".freeze
  PATH = "/search/places/v1/find".freeze

  def initialize(address, options = {})
    @address = address
    @options = options
  end

  def call
    unless response.is_a?(Net::HTTPSuccess) && result.present?
      @error = "Address is not recognised. Check the address, or enter the UPRN"
    end
  rescue JSON::ParserError
    @error = "Address is not recognised. Check the address, or enter the UPRN"
  end

  def result
    if response.is_a?(Net::HTTPSuccess)
      @result ||= JSON.parse(response.body)["results"]&.map { |address| address["DPA"] }
    else
      @result = nil
    end
  end

private

  def http_client
    client = Net::HTTP.new(ADDRESS, 443)
    client.use_ssl = true
    client.verify_mode = OpenSSL::SSL::VERIFY_PEER
    client.max_retries = 3
    client.read_timeout = 30 # seconds
    client
  end

  def endpoint_uri
    uri = URI(PATH)
    params = {
      query: address,
      key: ENV["OS_DATA_KEY"],
      maxresults: @options[:maxresults] || 10,
      minmatch: @options[:minmatch] || 0.4,
    }
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end

  def response
    @response ||= http_client.request_get(endpoint_uri)
  end
end
