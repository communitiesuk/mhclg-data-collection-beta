class Form::Sales::Subsections::HouseholdCharacteristics < ::Form::Subsection
  def initialize(id, hsh, section)
    super
    @id = "household_characteristics"
    @label = "Household characteristics"
    @depends_on = [{ "setup_completed?" => true, "company_buyer?" => false }]
  end

  def pages
    @pages ||= [
      (Form::Sales::Pages::BuyerInterview.new(nil, nil, self) unless form.start_year_after_2024?),
      Form::Sales::Pages::PrivacyNotice.new(nil, nil, self),
      Form::Sales::Pages::Age1.new(nil, nil, self),
      Form::Sales::Pages::RetirementValueCheck.new("age_1_retirement_value_check", nil, self, person_index: 1),
      Form::Sales::Pages::OldPersonsSharedOwnershipValueCheck.new("age_1_old_persons_shared_ownership_value_check", nil, self),
      Form::Sales::Pages::GenderIdentity1.new(nil, nil, self),
      Form::Sales::Pages::RetirementValueCheck.new("gender_1_retirement_value_check", nil, self, person_index: 1),
      Form::Sales::Pages::Buyer1EthnicGroup.new(nil, nil, self),
      Form::Sales::Pages::Buyer1EthnicBackgroundBlack.new(nil, nil, self),
      Form::Sales::Pages::Buyer1EthnicBackgroundAsian.new(nil, nil, self),
      Form::Sales::Pages::Buyer1EthnicBackgroundArab.new(nil, nil, self),
      Form::Sales::Pages::Buyer1EthnicBackgroundMixed.new(nil, nil, self),
      Form::Sales::Pages::Buyer1EthnicBackgroundWhite.new(nil, nil, self),
      Form::Sales::Pages::Buyer1Nationality.new(nil, nil, self),
      Form::Sales::Pages::Buyer1WorkingSituation.new(nil, nil, self),
      Form::Sales::Pages::RetirementValueCheck.new("working_situation_1_retirement_value_check", nil, self, person_index: 1),
      Form::Sales::Pages::Buyer1IncomeMinValueCheck.new("working_situation_buyer_1_income_min_value_check", nil, self),
      Form::Sales::Pages::Buyer1LiveInProperty.new(nil, nil, self),
      Form::Sales::Pages::BuyerLiveInValueCheck.new("buyer_1_live_in_property_value_check", nil, self, person_index: 1),
      Form::Sales::Pages::Buyer2RelationshipToBuyer1.new(nil, nil, self),
      Form::Sales::Pages::PersonStudentNotChildValueCheck.new("buyer_2_relationship_student_not_child_value_check", nil, self, person_index: 2),
      Form::Sales::Pages::Age2.new(nil, nil, self),
      Form::Sales::Pages::OldPersonsSharedOwnershipValueCheck.new("age_2_old_persons_shared_ownership_value_check", nil, self),
      Form::Sales::Pages::RetirementValueCheck.new("age_2_buyer_retirement_value_check", nil, self, person_index: 2),
      Form::Sales::Pages::PersonStudentNotChildValueCheck.new("buyer_2_age_student_not_child_value_check", nil, self, person_index: 2),
      Form::Sales::Pages::GenderIdentity2.new(nil, nil, self),
      Form::Sales::Pages::RetirementValueCheck.new("gender_2_buyer_retirement_value_check", nil, self, person_index: 2),
      buyer_2_ethnicity_nationality_pages,
      Form::Sales::Pages::Buyer2WorkingSituation.new(nil, nil, self),
      Form::Sales::Pages::RetirementValueCheck.new("working_situation_2_retirement_value_check_joint_purchase", nil, self, person_index: 2),
      Form::Sales::Pages::Buyer2IncomeMinValueCheck.new("working_situation_buyer_2_income_min_value_check", nil, self),
      Form::Sales::Pages::PersonStudentNotChildValueCheck.new("buyer_2_working_situation_student_not_child_value_check", nil, self, person_index: 2),
      Form::Sales::Pages::Buyer2LiveInProperty.new(nil, nil, self),
      Form::Sales::Pages::BuyerLiveInValueCheck.new("buyer_2_live_in_property_value_check", nil, self, person_index: 2),
      Form::Sales::Pages::NumberOfOthersInProperty.new("number_of_others_in_property", nil, self, joint_purchase: false),
      Form::Sales::Pages::NumberOfOthersInProperty.new("number_of_others_in_property_joint_purchase", nil, self, joint_purchase: true),
      Form::Sales::Pages::PersonKnown.new("person_2_known", nil, self, person_index: 2),
      Form::Sales::Pages::PersonRelationshipToBuyer1.new("person_2_relationship_to_buyer_1", nil, self, person_index: 2),
      Form::Sales::Pages::PersonStudentNotChildValueCheck.new("relationship_2_student_not_child_value_check", nil, self, person_index: 2),
      Form::Sales::Pages::PersonAge.new("person_2_age", nil, self, person_index: 2),
      Form::Sales::Pages::RetirementValueCheck.new("age_2_retirement_value_check", nil, self, person_index: 2),
      Form::Sales::Pages::PersonStudentNotChildValueCheck.new("age_2_student_not_child_value_check", nil, self, person_index: 2),
      Form::Sales::Pages::PersonGenderIdentity.new("person_2_gender_identity", nil, self, person_index: 2),
      Form::Sales::Pages::RetirementValueCheck.new("gender_2_retirement_value_check", nil, self, person_index: 2),
      Form::Sales::Pages::PersonWorkingSituation.new("person_2_working_situation", nil, self, person_index: 2),
      Form::Sales::Pages::RetirementValueCheck.new("working_situation_2_retirement_value_check", nil, self, person_index: 2),
      Form::Sales::Pages::PersonStudentNotChildValueCheck.new("working_situation_2_student_not_child_value_check", nil, self, person_index: 2),
      Form::Sales::Pages::PersonKnown.new("person_3_known", nil, self, person_index: 3),
      Form::Sales::Pages::PersonRelationshipToBuyer1.new("person_3_relationship_to_buyer_1", nil, self, person_index: 3),
      Form::Sales::Pages::PersonStudentNotChildValueCheck.new("relationship_3_student_not_child_value_check", nil, self, person_index: 3),
      Form::Sales::Pages::PersonAge.new("person_3_age", nil, self, person_index: 3),
      Form::Sales::Pages::RetirementValueCheck.new("age_3_retirement_value_check", nil, self, person_index: 3),
      Form::Sales::Pages::PersonStudentNotChildValueCheck.new("age_3_student_not_child_value_check", nil, self, person_index: 3),
      Form::Sales::Pages::PersonGenderIdentity.new("person_3_gender_identity", nil, self, person_index: 3),
      Form::Sales::Pages::RetirementValueCheck.new("gender_3_retirement_value_check", nil, self, person_index: 3),
      Form::Sales::Pages::PersonWorkingSituation.new("person_3_working_situation", nil, self, person_index: 3),
      Form::Sales::Pages::RetirementValueCheck.new("working_situation_3_retirement_value_check", nil, self, person_index: 3),
      Form::Sales::Pages::PersonStudentNotChildValueCheck.new("working_situation_3_student_not_child_value_check", nil, self, person_index: 3),
      Form::Sales::Pages::PersonKnown.new("person_4_known", nil, self, person_index: 4),
      Form::Sales::Pages::PersonRelationshipToBuyer1.new("person_4_relationship_to_buyer_1", nil, self, person_index: 4),
      Form::Sales::Pages::PersonStudentNotChildValueCheck.new("relationship_4_student_not_child_value_check", nil, self, person_index: 4),
      Form::Sales::Pages::PersonAge.new("person_4_age", nil, self, person_index: 4),
      Form::Sales::Pages::RetirementValueCheck.new("age_4_retirement_value_check", nil, self, person_index: 4),
      Form::Sales::Pages::PersonStudentNotChildValueCheck.new("age_4_student_not_child_value_check", nil, self, person_index: 4),
      Form::Sales::Pages::PersonGenderIdentity.new("person_4_gender_identity", nil, self, person_index: 4),
      Form::Sales::Pages::RetirementValueCheck.new("gender_4_retirement_value_check", nil, self, person_index: 4),
      Form::Sales::Pages::PersonWorkingSituation.new("person_4_working_situation", nil, self, person_index: 4),
      Form::Sales::Pages::RetirementValueCheck.new("working_situation_4_retirement_value_check", nil, self, person_index: 4),
      Form::Sales::Pages::PersonStudentNotChildValueCheck.new("working_situation_4_student_not_child_value_check", nil, self, person_index: 4),
      Form::Sales::Pages::PersonKnown.new("person_5_known", nil, self, person_index: 5),
      Form::Sales::Pages::PersonRelationshipToBuyer1.new("person_5_relationship_to_buyer_1", nil, self, person_index: 5),
      Form::Sales::Pages::PersonStudentNotChildValueCheck.new("relationship_5_student_not_child_value_check", nil, self, person_index: 5),
      Form::Sales::Pages::PersonAge.new("person_5_age", nil, self, person_index: 5),
      Form::Sales::Pages::RetirementValueCheck.new("age_5_retirement_value_check", nil, self, person_index: 5),
      Form::Sales::Pages::PersonStudentNotChildValueCheck.new("age_5_student_not_child_value_check", nil, self, person_index: 5),
      Form::Sales::Pages::PersonGenderIdentity.new("person_5_gender_identity", nil, self, person_index: 5),
      Form::Sales::Pages::RetirementValueCheck.new("gender_5_retirement_value_check", nil, self, person_index: 5),
      Form::Sales::Pages::PersonWorkingSituation.new("person_5_working_situation", nil, self, person_index: 5),
      Form::Sales::Pages::RetirementValueCheck.new("working_situation_5_retirement_value_check", nil, self, person_index: 5),
      Form::Sales::Pages::PersonStudentNotChildValueCheck.new("working_situation_5_student_not_child_value_check", nil, self, person_index: 5),
      Form::Sales::Pages::PersonKnown.new("person_6_known", nil, self, person_index: 6),
      Form::Sales::Pages::PersonRelationshipToBuyer1.new("person_6_relationship_to_buyer_1", nil, self, person_index: 6),
      Form::Sales::Pages::PersonStudentNotChildValueCheck.new("relationship_6_student_not_child_value_check", nil, self, person_index: 6),
      Form::Sales::Pages::PersonAge.new("person_6_age", nil, self, person_index: 6),
      Form::Sales::Pages::RetirementValueCheck.new("age_6_retirement_value_check", nil, self, person_index: 6),
      Form::Sales::Pages::PersonStudentNotChildValueCheck.new("age_6_student_not_child_value_check", nil, self, person_index: 6),
      Form::Sales::Pages::PersonGenderIdentity.new("person_6_gender_identity", nil, self, person_index: 6),
      Form::Sales::Pages::RetirementValueCheck.new("gender_6_retirement_value_check", nil, self, person_index: 6),
      Form::Sales::Pages::PersonWorkingSituation.new("person_6_working_situation", nil, self, person_index: 6),
      Form::Sales::Pages::RetirementValueCheck.new("working_situation_6_retirement_value_check", nil, self, person_index: 6),
      Form::Sales::Pages::PersonStudentNotChildValueCheck.new("working_situation_6_student_not_child_value_check", nil, self, person_index: 6),
    ].flatten.compact
  end

  def buyer_2_ethnicity_nationality_pages
    if form.start_date.year >= 2023
      [
        Form::Sales::Pages::Buyer2EthnicGroup.new(nil, nil, self),
        Form::Sales::Pages::Buyer2EthnicBackgroundBlack.new(nil, nil, self),
        Form::Sales::Pages::Buyer2EthnicBackgroundAsian.new(nil, nil, self),
        Form::Sales::Pages::Buyer2EthnicBackgroundArab.new(nil, nil, self),
        Form::Sales::Pages::Buyer2EthnicBackgroundMixed.new(nil, nil, self),
        Form::Sales::Pages::Buyer2EthnicBackgroundWhite.new(nil, nil, self),
        Form::Sales::Pages::Buyer2Nationality.new(nil, nil, self),
      ]
    end
  end

  def displayed_in_tasklist?(log)
    !log.company_buyer?
  end
end
