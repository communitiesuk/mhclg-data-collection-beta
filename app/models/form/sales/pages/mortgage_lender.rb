class Form::Sales::Pages::MortgageLender < ::Form::Page
  def initialize(id, hsh, subsection, ownershipsch:)
    super(id, hsh, subsection)
    @ownershipsch = ownershipsch
    @copy_key = "sales.sale_information.mortgagelender"
    @description = ""
    @subsection = subsection
    @depends_on = [{
      "mortgageused" => 1,
    }]
  end

  def questions
    @questions ||= [
      Form::Sales::Questions::MortgageLender.new(nil, nil, self, ownershipsch: @ownershipsch),
    ]
  end
end
