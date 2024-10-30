class Form::Lettings::Pages::LeadTenantEthnicBackgroundArab < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "lead_tenant_ethnic_background_arab"
    @copy_key = "lettings.household_characteristics.ethnic.ethnic_background_arab"
    @depends_on = [{ "ethnic_group" => 4 }]
  end

  def questions
    @questions ||= [Form::Lettings::Questions::EthnicArab.new(nil, nil, self)]
  end
end
