require "webmock/rspec"

module RequestHelper
  def self.stub_http_requests
    WebMock.disable_net_connect!(allow_localhost: true)
    WebMock.stub_request(:get, /api\.postcodes\.io/)
      .to_return(status: 404, body: "{\"status\":404,\"error\":\"Postcode not found\"}", headers: {})

    WebMock.stub_request(:get, "https://api.postcodes.io/postcodes/AA11AA")
           .to_return(status: 200, body: "{\"status\":200,\"result\":{\"postcode\":\"AA1 1AA\",\"admin_district\":\"Westminster\",\"codes\":{\"admin_district\":\"E09000033\"}}}", headers: {})
    WebMock.stub_request(:get, "https://api.postcodes.io/postcodes/AA12AA")
           .to_return(status: 200, body: "{\"status\":200,\"result\":{\"postcode\":\"AA1 2AA\",\"admin_district\":\"Westminster\",\"codes\":{\"admin_district\":\"E09000033\"}}}", headers: {})
    WebMock.stub_request(:get, "https://api.postcodes.io/postcodes/NW1L5DP")
           .to_return(status: 200, body: "{\"status\":200,\"result\":{\"postcode\":\"NW1L 5DP\",\"admin_district\":\"Westminster\",\"codes\":{\"admin_district\":\"E09000033\"}}}", headers: {})
    WebMock.stub_request(:get, "https://api.postcodes.io/postcodes/ZZ11ZZ")
           .to_return(status: 200, body: "{\"status\":200,\"result\":{\"postcode\":\"ZZ1 1ZZ\",\"admin_district\":\"Westminster\",\"codes\":{\"admin_district\":\"E09000033\"}}}", headers: {})
    WebMock.stub_request(:get, "https://api.postcodes.io/postcodes/SW1A1AA")
           .to_return(status: 200, body: "{\"status\":200,\"result\":{\"postcode\":\"ZZ1 1ZZ\",\"admin_district\":\"Westminster\",\"codes\":{\"admin_district\":\"E09000033\"}}}", headers: {})

    body = { results: [{ DPA: { UPRN: "10033558653" } }] }.to_json
    WebMock.stub_request(:get, "https://api.os.uk/search/places/v1/find?key&maxresults=10&minmatch=0.4&query=Address%20line%201,%20SW1A%201AA")
           .to_return(status: 200, body:, headers: {})
    body = { results: [{ DPA: { "POSTCODE": "SW1A 1AA", "POST_TOWN": "London", "PO_BOX_NUMBER": "The Mall, City Of Westminster" } }] }.to_json
    WebMock.stub_request(:get, "https://api.os.uk/search/places/v1/uprn?dataset=DPA,LPI&key&uprn=1")
           .to_return(status: 200, body:, headers: {})
    WebMock.stub_request(:get, "https://api.os.uk/search/places/v1/uprn?dataset=DPA,LPI&key&uprn=10033558653")
           .to_return(status: 200, body:, headers: {})
    WebMock.stub_request(:get, "https://api.os.uk/search/places/v1/uprn?dataset=DPA,LPI&key=OS_DATA_KEY&uprn=10033558653")
           .to_return(status: 200, body:, headers: {})

    WebMock.stub_request(:post, /api.notifications.service.gov.uk\/v2\/notifications\/email/)
      .to_return(status: 200, body: "", headers: {})
    WebMock.stub_request(:post, /api.notifications.service.gov.uk\/v2\/notifications\/sms/)
      .to_return(status: 200, body: "", headers: {})

    body = {
      results: [
        {
          DPA: {
            "POSTCODE": "AA1 1AA",
            "POST_TOWN": "Test Town",
            "ORGANISATION_NAME": "1, Test Street",
          },
        },
      ],
    }.to_json

    WebMock.stub_request(:get, "https://api.os.uk/search/places/v1/uprn?dataset=DPA,LPI&key=OS_DATA_KEY&uprn=1")
    .to_return(status: 200, body:, headers: {})

    body = {
      results: [
        {
          DPA: {
            "POSTCODE": "LS16 6FT",
            "POST_TOWN": "Westminster",
            "PO_BOX_NUMBER": "Wrong Address Line1",
            "DOUBLE_DEPENDENT_LOCALITY": "Double Dependent Locality",
          },
        },
      ],
    }.to_json

    WebMock.stub_request(:get, "https://api.os.uk/search/places/v1/uprn?dataset=DPA,LPI&key&uprn=121")
     .to_return(status: 200, body:, headers: {})

    body = {
      results: [
        {
          DPA: {
            "POSTCODE": "BS1 1AD",
            "POST_TOWN": "Bristol",
            "ORGANISATION_NAME": "Some place",
          },
        },
      ],
    }.to_json

    WebMock.stub_request(:get, "https://api.os.uk/search/places/v1/uprn?dataset=DPA,LPI&key=OS_DATA_KEY&uprn=123")
    .to_return(status: 200, body:, headers: {})

    body = {
      results: [
        {
          DPA: {
            "POSTCODE": "EC1N 2TD",
            "POST_TOWN": "Newcastle",
            "ORGANISATION_NAME": "Some place",
          },
        },
      ],
    }.to_json

    WebMock.stub_request(:get, "https://api.os.uk/search/places/v1/uprn?dataset=DPA,LPI&key=OS_DATA_KEY&uprn=12")
    .to_return(status: 200, body:, headers: {})

    WebMock.stub_request(:get, "https://api.os.uk/search/places/v1/uprn?dataset=DPA,LPI&key=OS_DATA_KEY&uprn=1234567890123")
    .to_return(status: 404, body: "", headers: {})

    template = Addressable::Template.new "https://api.os.uk/search/places/v1/find?key=OS_DATA_KEY&maxresults=10&minmatch=0.4&query={+address_query}"
    WebMock.stub_request(:get, template)
      .to_return do |request|
      address = request.uri.query_values["query"].split(",")
      { status: 200, body: { results: [{ DPA: { MATCH: 0.9, BUILDING_NAME: "result #{address[0]}", POST_TOWN: "result town or city", POSTCODE: address[1], UPRN: "1" } }] }.to_json, headers: {} }
    end
  end

  def self.real_http_requests
    WebMock.allow_net_connect!
  end
end
