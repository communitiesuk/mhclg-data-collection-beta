class Location < ApplicationRecord
  validate :validate_postcode
  belongs_to :scheme

  attr_accessor :add_another_location

  WHEELCHAIR_ADAPTATIONS = {
    Yes: 1,
    No: 0,
  }.freeze

  enum wheelchair_adaptation: WHEELCHAIR_ADAPTATIONS

  TYPE_OF_UNIT = {
    "Self-contained flat or bedsit": 1,
    "Self-contained flat or bedsit with common facilities": 2,
    "Shared flat": 3,
    "Shared house or hostel": 4,
    "Bungalow": 5,
    "Self-contained house": 6,
  }.freeze

  enum type_of_unit: TYPE_OF_UNIT

  def display_attributes
    [
      { name: "Location code ", value: location_code, suffix: false },
      { name: "Postcode", value: postcode, suffix: county },
      { name: "Type of unit", value: type_of_unit, suffix: false },
      { name: "Type of building", value: type_of_building, suffix: false },
      { name: "Wheelchair adaptation", value: wheelchair_adaptation, suffix: false },
    ]
  end

private

  def validate_postcode
    if postcode.nil? || !postcode&.match(POSTCODE_REGEXP)
      error_message = I18n.t("validations.postcode")
      errors.add :postcode, error_message
    end
  end
end
