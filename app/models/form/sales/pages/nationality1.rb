class Form::Sales::Pages::Nationality1 < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "buyer_1_nationality"
    @header = ""
    @subsection = subsection
  end

  def questions
    @questions ||= [
      Form::Sales::Questions::Nationality1.new(nil, nil, self),
      Form::Sales::Questions::OtherNationality1.new(nil, nil, self),
    ]
  end
end
