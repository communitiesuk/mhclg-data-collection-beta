class Form::Lettings::Pages::LeadTenantEthnicBackgroundBlack < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "lead_tenant_ethnic_background_black"
    @copy_key = "lettings.household_characteristics.ethnic.ethnic_background_black"
    @depends_on = [{ "ethnic_group" => 3 }]
  end

  def questions
    @questions ||= [Form::Lettings::Questions::EthnicBlack.new(nil, nil, self)]
  end
end
