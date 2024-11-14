class Form::Sales::Sections::Household < ::Form::Section
  def initialize(id, hsh, form)
    super
    @id = "household"
    @label = "About the household"
    @description = ""
    @subsections = [
      Form::Sales::Subsections::HouseholdCharacteristics.new(nil, nil, self),
      Form::Sales::Subsections::HouseholdSituation.new(nil, nil, self),
      Form::Sales::Subsections::OtherHouseholdInformation.new(nil, nil, self),
    ]
  end
end
