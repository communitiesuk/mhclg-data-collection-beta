class Form::Lettings::Subsections::HouseholdCharacteristics < ::Form::Subsection
  def initialize(id, hsh, section)
    super
    @id = "household_characteristics"
    @label = "Household characteristics"
    @depends_on = [{ "non_location_setup_questions_completed?" => true }]
  end

  def pages
    @pages ||= [Form::Lettings::Pages::Declaration.new(nil, nil, self), Form::Lettings::Pages::HouseholdMembers.new(nil, nil, self), Form::Lettings::Pages::NoFemalesPregnantHouseholdLeadHhmembValueCheck.new(nil, nil, self), Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdLeadHhmembValueCheck.new(nil, nil, self), Form::Lettings::Pages::LeadTenantAge.new(nil, nil, self), Form::Lettings::Pages::NoFemalesPregnantHouseholdLeadAgeValueCheck.new(nil, nil, self), Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdLeadAgeValueCheck.new(nil, nil, self), Form::Lettings::Pages::LeadTenantGenderIdentity.new(nil, nil, self), Form::Lettings::Pages::NoFemalesPregnantHouseholdLeadValueCheck.new(nil, nil, self), Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdLeadValueCheck.new(nil, nil, self), Form::Lettings::Pages::LeadTenantEthnicGroup.new(nil, nil, self), Form::Lettings::Pages::LeadTenantEthnicBackgroundArab.new(nil, nil, self), Form::Lettings::Pages::LeadTenantEthnicBackgroundAsian.new(nil, nil, self), Form::Lettings::Pages::LeadTenantEthnicBackgroundBlack.new(nil, nil, self), Form::Lettings::Pages::LeadTenantEthnicBackgroundMixed.new(nil, nil, self), Form::Lettings::Pages::LeadTenantEthnicBackgroundWhite.new(nil, nil, self), Form::Lettings::Pages::LeadTenantNationality.new(nil, nil, self), Form::Lettings::Pages::LeadTenantWorkingSituation.new(nil, nil, self), Form::Lettings::Pages::LeadTenantUnderRetirementValueCheck.new(nil, nil, self), Form::Lettings::Pages::LeadTenantOverRetirementValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person2Known.new(nil, nil, self), Form::Lettings::Pages::Person2RelationshipToLead.new(nil, nil, self), Form::Lettings::Pages::Person2Age.new(nil, nil, self), Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson2AgeValueCheck.new(nil, nil, self), Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson2AgeValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person2GenderIdentity.new(nil, nil, self), Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson2ValueCheck.new(nil, nil, self), Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson2ValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person2WorkingSituation.new(nil, nil, self), Form::Lettings::Pages::Person2UnderRetirementValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person2OverRetirementValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person3Known.new(nil, nil, self), Form::Lettings::Pages::Person3RelationshipToLead.new(nil, nil, self), Form::Lettings::Pages::Person3Age.new(nil, nil, self), Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson3AgeValueCheck.new(nil, nil, self), Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson3AgeValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person3GenderIdentity.new(nil, nil, self), Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson3ValueCheck.new(nil, nil, self), Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson3ValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person3WorkingSituation.new(nil, nil, self), Form::Lettings::Pages::Person3UnderRetirementValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person3OverRetirementValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person4Known.new(nil, nil, self), Form::Lettings::Pages::Person4RelationshipToLead.new(nil, nil, self), Form::Lettings::Pages::Person4Age.new(nil, nil, self), Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson4AgeValueCheck.new(nil, nil, self), Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson4AgeValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person4GenderIdentity.new(nil, nil, self), Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson4ValueCheck.new(nil, nil, self), Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson4ValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person4WorkingSituation.new(nil, nil, self), Form::Lettings::Pages::Person4UnderRetirementValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person4OverRetirementValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person5Known.new(nil, nil, self), Form::Lettings::Pages::Person5RelationshipToLead.new(nil, nil, self), Form::Lettings::Pages::Person5Age.new(nil, nil, self), Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson5AgeValueCheck.new(nil, nil, self), Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson5AgeValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person5GenderIdentity.new(nil, nil, self), Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson5ValueCheck.new(nil, nil, self), Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson5ValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person5WorkingSituation.new(nil, nil, self), Form::Lettings::Pages::Person5UnderRetirementValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person5OverRetirementValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person6Known.new(nil, nil, self), Form::Lettings::Pages::Person6RelationshipToLead.new(nil, nil, self), Form::Lettings::Pages::Person6Age.new(nil, nil, self), Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson6AgeValueCheck.new(nil, nil, self), Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson6AgeValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person6GenderIdentity.new(nil, nil, self), Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson6ValueCheck.new(nil, nil, self), Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson6ValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person6WorkingSituation.new(nil, nil, self), Form::Lettings::Pages::Person6UnderRetirementValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person6OverRetirementValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person7Known.new(nil, nil, self), Form::Lettings::Pages::Person7RelationshipToLead.new(nil, nil, self), Form::Lettings::Pages::Person7Age.new(nil, nil, self), Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson7AgeValueCheck.new(nil, nil, self), Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson7AgeValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person7GenderIdentity.new(nil, nil, self), Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson7ValueCheck.new(nil, nil, self), Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson7ValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person7WorkingSituation.new(nil, nil, self), Form::Lettings::Pages::Person7UnderRetirementValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person7OverRetirementValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person8Known.new(nil, nil, self), Form::Lettings::Pages::Person8RelationshipToLead.new(nil, nil, self), Form::Lettings::Pages::Person8Age.new(nil, nil, self), Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson8AgeValueCheck.new(nil, nil, self), Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson8AgeValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person8GenderIdentity.new(nil, nil, self), Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson8ValueCheck.new(nil, nil, self), Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson8ValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person8WorkingSituation.new(nil, nil, self), Form::Lettings::Pages::Person8UnderRetirementValueCheck.new(nil, nil, self), Form::Lettings::Pages::Person8OverRetirementValueCheck.new(nil, nil, self)].compact
  end
end
