class Form::Sales::Pages::PropertyPostcode < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "postcode_known"
    @header = ""
    @description = ""
    @subsection = subsection
  end

  def questions
    @questions ||= [
      Form::Sales::Questions::PropertyPostcode.new(nil, nil, self),
      Form::Sales::Questions::PostcodeFull.new(nil, nil, self),
    ]
  end
end
