class Form::Sales::Subsections::OtherHouseholdInformation < ::Form::Subsection
  def initialize(id, hsh, section)
    super
    @id = "other_household_information"
    @label = "Other household information"
    @depends_on = [{ "setup_completed?" => true }]
  end

  def pages
    @pages ||= [
      Form::Sales::Pages::ArmedForces.new(nil, nil, self),
      Form::Sales::Pages::BuyerStillServing.new(nil, nil, self),
      Form::Sales::Pages::ArmedForcesSpouse.new(nil, nil, self),
      Form::Sales::Pages::HouseholdDisability.new(nil, nil, self),
      Form::Sales::Pages::HouseholdWheelchairCheck.new("disability_wheelchair_check", nil, self),
      Form::Sales::Pages::HouseholdWheelchair.new(nil, nil, self),
      Form::Sales::Pages::HouseholdWheelchairCheck.new("wheelchair_check", nil, self),
    ]
  end
end
