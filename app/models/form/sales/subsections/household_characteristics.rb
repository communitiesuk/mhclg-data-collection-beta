class Form::Sales::Subsections::HouseholdCharacteristics < ::Form::Subsection
  def initialize(id, hsh, section)
    super
    @id = "household_characteristics"
    @label = "Household characteristics"
    @section = section
    @depends_on = [{ "setup_completed?" => true }]
  end

  def pages
    @pages ||= [
      Form::Sales::Pages::BuyerInterview.new(nil, nil, self),
      Form::Sales::Pages::PrivacyNotice.new(nil, nil, self),
      Form::Sales::Pages::Age1.new(nil, nil, self),
      Form::Sales::Pages::GenderIdentity1.new(nil, nil, self),
      Form::Sales::Pages::Buyer1EthnicGroup.new(nil, nil, self),
      Form::Sales::Pages::Buyer1EthnicBackgroundBlack.new(nil, nil, self),
      Form::Sales::Pages::Buyer1EthnicBackgroundAsian.new(nil, nil, self),
      Form::Sales::Pages::Buyer1EthnicBackgroundArab.new(nil, nil, self),
      Form::Sales::Pages::Buyer1EthnicBackgroundMixed.new(nil, nil, self),
      Form::Sales::Pages::Buyer1EthnicBackgroundWhite.new(nil, nil, self),
      Form::Sales::Pages::Nationality1.new(nil, nil, self),
      Form::Sales::Pages::Buyer1WorkingSituation.new(nil, nil, self),
      Form::Sales::Pages::Buyer1IncomeValueCheck.new("working_situation_buyer_1_income_value_check", nil, self),
      Form::Sales::Pages::Buyer1LiveInProperty.new(nil, nil, self),
      Form::Sales::Pages::Buyer2RelationshipToBuyer1.new(nil, nil, self),
      Form::Sales::Pages::Age2.new(nil, nil, self),
      Form::Sales::Pages::GenderIdentity2.new(nil, nil, self),
      Form::Sales::Pages::Buyer2WorkingSituation.new(nil, nil, self),
      Form::Sales::Pages::Buyer2LiveInProperty.new(nil, nil, self),
      Form::Sales::Pages::NumberOfOthersInProperty.new(nil, nil, self),
      Form::Sales::Pages::Person1Known.new(nil, nil, self),
      Form::Sales::Pages::PersonAge.new("person_1_age", nil, self, person_index: 2),
      Form::Sales::Pages::PersonAge.new("person_1_age_joint_purchase", nil, self, person_index: 3),
      Form::Sales::Pages::PersonGenderIdentity.new("person_1_gender_identity", nil, self, person_index: 2),
      Form::Sales::Pages::PersonGenderIdentity.new("person_1_gender_identity_joint_purchase", nil, self, person_index: 3),
      Form::Sales::Pages::PersonWorkingSituation.new("person_1_working_situation", nil, self, person_index: 2),
      Form::Sales::Pages::PersonWorkingSituation.new("person_1_working_situation_joint_purchase", nil, self, person_index: 3),
      Form::Sales::Pages::Person2Known.new(nil, nil, self),
      Form::Sales::Pages::PersonAge.new("person_2_age", nil, self, person_index: 3),
      Form::Sales::Pages::PersonAge.new("person_2_age_joint_purchase", nil, self, person_index: 4),
      Form::Sales::Pages::PersonGenderIdentity.new("person_2_gender_identity", nil, self, person_index: 3),
      Form::Sales::Pages::PersonGenderIdentity.new("person_2_gender_identity_joint_purchase", nil, self, person_index: 4),
      Form::Sales::Pages::PersonWorkingSituation.new("person_2_working_situation", nil, self, person_index: 3),
      Form::Sales::Pages::PersonWorkingSituation.new("person_2_working_situation_joint_purchase", nil, self, person_index: 4),
      Form::Sales::Pages::Person3Known.new(nil, nil, self),
      Form::Sales::Pages::PersonAge.new("person_3_age", nil, self, person_index: 4),
      Form::Sales::Pages::PersonAge.new("person_3_age_joint_purchase", nil, self, person_index: 5),
      Form::Sales::Pages::PersonGenderIdentity.new("person_3_gender_identity", nil, self, person_index: 4),
      Form::Sales::Pages::PersonGenderIdentity.new("person_3_gender_identity_joint_purchase", nil, self, person_index: 5),
      Form::Sales::Pages::PersonWorkingSituation.new("person_3_working_situation", nil, self, person_index: 4),
      Form::Sales::Pages::PersonWorkingSituation.new("person_3_working_situation_joint_purchase", nil, self, person_index: 5),
      Form::Sales::Pages::Person4Known.new(nil, nil, self),
      Form::Sales::Pages::PersonAge.new("person_4_age", nil, self, person_index: 5),
      Form::Sales::Pages::PersonAge.new("person_4_age_joint_purchase", nil, self, person_index: 6),
      Form::Sales::Pages::PersonGenderIdentity.new("person_4_gender_identity", nil, self, person_index: 5),
      Form::Sales::Pages::PersonGenderIdentity.new("person_4_gender_identity_joint_purchase", nil, self, person_index: 6),
      Form::Sales::Pages::PersonWorkingSituation.new("person_4_working_situation", nil, self, person_index: 5),
      Form::Sales::Pages::PersonWorkingSituation.new("person_4_working_situation_joint_purchase", nil, self, person_index: 6),
    ]
  end
end
