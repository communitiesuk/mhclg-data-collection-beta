class Form::Sales::Pages::PreviousPropertyType < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "previous_property_type"
    @copy_key = "sales.sale_information.fromprop"
    @description = ""
    @subsection = subsection
    @depends_on = [
      {
        "soctenant" => 1,
      },
      {
        "soctenant" => 0,
      },
    ]
  end

  def questions
    @questions ||= [
      Form::Sales::Questions::Fromprop.new(nil, nil, self),
    ]
  end
end
