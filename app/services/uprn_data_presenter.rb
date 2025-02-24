require "net/http"

class UprnDataPresenter
  attr_reader :data

  def initialize(data)
    @data = data
  end

  def postcode
    result_from_lpi? ? data["POSTCODE_LOCATOR"] : data["POSTCODE"]
  end

  def address_line1
    if result_from_lpi?
      data.values_at(
        "ORGANISATION",
        "SAO_TEXT",
        "PAO_START_NUMBER",
        "STREET_DESCRIPTION",
        "LOCALITY_NAME",
        "ADMINISTRATIVE_AREA",
      ).compact
       .join(", ")
       .titleize
    else
      data.values_at(
        "PO_BOX_NUMBER",
        "ORGANISATION_NAME",
        "DEPARTMENT_NAME",
        "SUB_BUILDING_NAME",
        "BUILDING_NAME",
        "BUILDING_NUMBER",
        "DEPENDENT_THOROUGHFARE_NAME",
        "THOROUGHFARE_NAME",
      ).compact
       .join(", ")
       .titleize
    end
  end

  def address_line2
    data.values_at(
      "DOUBLE_DEPENDENT_LOCALITY", "DEPENDENT_LOCALITY"
    ).compact
     .join(", ")
     .titleize
     .presence
  end

  def town_or_city
    result_from_lpi? ? data["TOWN_NAME"].titleize : data["POST_TOWN"].titleize
  end

  def result_from_lpi?
    data["LPI_KEY"].present?
  end

  def uprn
    data["UPRN"]
  end

  def address
    data["ADDRESS"]
  end
end
