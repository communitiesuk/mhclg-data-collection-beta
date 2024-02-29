require "net/http"

class AddressDataPresenter
  attr_reader :data

  def initialize(data)
    @data = data
  end

  def uprn
    data["UPRN"]
  end

  def address_line1
    [data["BUILDING_NUMBER"], data["BUILDING_NAME"], data["THOROUGHFARE_NAME"]].compact.join(", ")
  end

  def address_line2
    data["DEPENDENT_LOCALITY"]
  end

  def town_or_city
    data["POST_TOWN"]
  end

  def postcode
    data["POSTCODE"]
  end

  def address
    data["ADDRESS"]
  end

  # def match
  #   data["MATCH"]
  # end
  #
  # def match_description
  #   data["MATCH_DESCRIPTION"]
  # end
end
