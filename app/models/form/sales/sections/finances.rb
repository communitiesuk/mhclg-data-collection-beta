class Form::Sales::Sections::Finances < ::Form::Section
  def initialize(id, hsh, form)
    super
    @id = "finances"
    @label = "Finances"
    @description = ""
    @subsections = [
      Form::Sales::Subsections::IncomeBenefitsAndSavings.new(nil, nil, self),
    ]
  end
end
