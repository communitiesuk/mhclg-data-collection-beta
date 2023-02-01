class Form::Lettings::Pages::LeadTenantAge < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "lead_tenant_age"
    @header = ""
    @depends_on = [{ "declaration" => 1 }]
    @description = ""
  end

  def questions
    @questions ||= [Form::Lettings::Questions::Age1Known.new(nil, nil, self), Form::Lettings::Questions::Age1.new(nil, nil, self)]
  end
end
