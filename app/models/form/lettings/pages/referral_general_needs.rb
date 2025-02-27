class Form::Lettings::Pages::ReferralGeneralNeeds < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "referral_prp"
    @copy_key = "lettings.household_situation.referral.general_needs.prp"
    @depends_on = [{ "owning_organisation_provider_type" => "PRP", "needstype" => 1, "renewal" => 0 }]
  end

  def questions
    @questions ||= [Form::Lettings::Questions::ReferralGeneralNeeds.new(nil, nil, self)]
  end
end
