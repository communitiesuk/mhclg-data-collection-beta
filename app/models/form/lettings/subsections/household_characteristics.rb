class Form::Lettings::Subsections::HouseholdCharacteristics < ::Form::Subsection
  def initialize(id, hsh, section)
    super
    @id = "household_characteristics"
    @label = "Household characteristics"
    @depends_on = [{ "non_location_setup_questions_completed?" => true }]
  end

  def pages
    @pages ||= [Form::Lettings::Pages::Declaration.new(nil, nil, self),
                Form::Lettings::Pages::HouseholdMembers.new(nil, nil, self),
                Form::Lettings::Pages::NoFemalesPregnantHouseholdLeadHhmembValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdLeadHhmembValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::LeadTenantAge.new(nil, nil, self),
                Form::Lettings::Pages::NoFemalesPregnantHouseholdLeadAgeValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdLeadAgeValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::LeadTenantGenderIdentity.new(nil, nil, self),
                Form::Lettings::Pages::NoFemalesPregnantHouseholdLeadValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdLeadValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::LeadTenantEthnicGroup.new(nil, nil, self),
                Form::Lettings::Pages::LeadTenantEthnicBackgroundArab.new(nil, nil, self),
                Form::Lettings::Pages::LeadTenantEthnicBackgroundAsian.new(nil, nil, self),
                Form::Lettings::Pages::LeadTenantEthnicBackgroundBlack.new(nil, nil, self),
                Form::Lettings::Pages::LeadTenantEthnicBackgroundMixed.new(nil, nil, self),
                Form::Lettings::Pages::LeadTenantEthnicBackgroundWhite.new(nil, nil, self),
                Form::Lettings::Pages::LeadTenantNationality.new(nil, nil, self),
                Form::Lettings::Pages::LeadTenantWorkingSituation.new(nil, nil, self),
                Form::Lettings::Pages::LeadTenantUnderRetirementValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::LeadTenantOverRetirementValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::PersonKnown.new(nil, nil, self, person_index: 2),
                Form::Lettings::Pages::PersonRelationshipToLead.new(nil, nil, self, person_index: 2),
                Form::Lettings::Pages::PersonAge.new(nil, nil, self, person_index: 2),
                Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson2AgeValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson2AgeValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::PersonGenderIdentity.new(nil, nil, self, person_index: 2),
                Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson2ValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson2ValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::PersonWorkingSituation.new(nil, nil, self, person_index: 2),
                Form::Lettings::Pages::PersonUnderRetirementValueCheck.new(nil, nil, self, person_index: 2),
                Form::Lettings::Pages::PersonOverRetirementValueCheck.new(nil, nil, self, person_index: 2),
                Form::Lettings::Pages::PersonKnown.new(nil, nil, self, person_index: 3),
                Form::Lettings::Pages::PersonRelationshipToLead.new(nil, nil, self, person_index: 3),
                Form::Lettings::Pages::PersonAge.new(nil, nil, self, person_index: 3),
                Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson3AgeValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson3AgeValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::PersonGenderIdentity.new(nil, nil, self, person_index: 3),
                Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson3ValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson3ValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::PersonWorkingSituation.new(nil, nil, self, person_index: 3),
                Form::Lettings::Pages::PersonUnderRetirementValueCheck.new(nil, nil, self, person_index: 3),
                Form::Lettings::Pages::PersonOverRetirementValueCheck.new(nil, nil, self, person_index: 3),
                Form::Lettings::Pages::PersonKnown.new(nil, nil, self, person_index: 4),
                Form::Lettings::Pages::PersonRelationshipToLead.new(nil, nil, self, person_index: 4),
                Form::Lettings::Pages::PersonAge.new(nil, nil, self, person_index: 4),
                Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson4AgeValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson4AgeValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::PersonGenderIdentity.new(nil, nil, self, person_index: 4),
                Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson4ValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson4ValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::PersonWorkingSituation.new(nil, nil, self, person_index: 4),
                Form::Lettings::Pages::PersonUnderRetirementValueCheck.new(nil, nil, self, person_index: 4),
                Form::Lettings::Pages::PersonOverRetirementValueCheck.new(nil, nil, self, person_index: 4),
                Form::Lettings::Pages::PersonKnown.new(nil, nil, self, person_index: 5),
                Form::Lettings::Pages::PersonRelationshipToLead.new(nil, nil, self, person_index: 5),
                Form::Lettings::Pages::PersonAge.new(nil, nil, self, person_index: 5),
                Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson5AgeValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson5AgeValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::PersonGenderIdentity.new(nil, nil, self, person_index: 5),
                Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson5ValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson5ValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::PersonWorkingSituation.new(nil, nil, self, person_index: 5),
                Form::Lettings::Pages::PersonUnderRetirementValueCheck.new(nil, nil, self, person_index: 5),
                Form::Lettings::Pages::PersonOverRetirementValueCheck.new(nil, nil, self, person_index: 5),
                Form::Lettings::Pages::PersonKnown.new(nil, nil, self, person_index: 6),
                Form::Lettings::Pages::PersonRelationshipToLead.new(nil, nil, self, person_index: 6),
                Form::Lettings::Pages::PersonAge.new(nil, nil, self, person_index: 6),
                Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson6AgeValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson6AgeValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::PersonGenderIdentity.new(nil, nil, self, person_index: 6),
                Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson6ValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson6ValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::PersonWorkingSituation.new(nil, nil, self, person_index: 6),
                Form::Lettings::Pages::PersonUnderRetirementValueCheck.new(nil, nil, self, person_index: 6),
                Form::Lettings::Pages::PersonOverRetirementValueCheck.new(nil, nil, self, person_index: 6),
                Form::Lettings::Pages::PersonKnown.new(nil, nil, self, person_index: 7),
                Form::Lettings::Pages::PersonRelationshipToLead.new(nil, nil, self, person_index: 7),
                Form::Lettings::Pages::PersonAge.new(nil, nil, self, person_index: 7),
                Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson7AgeValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson7AgeValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::PersonGenderIdentity.new(nil, nil, self, person_index: 7),
                Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson7ValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson7ValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::PersonWorkingSituation.new(nil, nil, self, person_index: 7),
                Form::Lettings::Pages::PersonUnderRetirementValueCheck.new(nil, nil, self, person_index: 7),
                Form::Lettings::Pages::PersonOverRetirementValueCheck.new(nil, nil, self, person_index: 7),
                Form::Lettings::Pages::PersonKnown.new(nil, nil, self, person_index: 8),
                Form::Lettings::Pages::PersonRelationshipToLead.new(nil, nil, self, person_index: 8),
                Form::Lettings::Pages::PersonAge.new(nil, nil, self, person_index: 8),
                Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson8AgeValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson8AgeValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::PersonGenderIdentity.new(nil, nil, self, person_index: 8),
                Form::Lettings::Pages::NoFemalesPregnantHouseholdPerson8ValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::FemalesInSoftAgeRangeInPregnantHouseholdPerson8ValueCheck.new(nil, nil, self),
                Form::Lettings::Pages::PersonWorkingSituation.new(nil, nil, self, person_index: 8),
                Form::Lettings::Pages::PersonUnderRetirementValueCheck.new(nil, nil, self, person_index: 8),
                Form::Lettings::Pages::PersonOverRetirementValueCheck.new(nil, nil, self, person_index: 8)].compact
  end
end
