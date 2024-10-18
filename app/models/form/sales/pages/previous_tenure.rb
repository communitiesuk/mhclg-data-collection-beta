class Form::Sales::Pages::PreviousTenure < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "shared_ownership_previous_tenure"
    @copy_key = "sales.sale_information.socprevten"
    @header = ""
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
      Form::Sales::Questions::PreviousTenure.new(nil, nil, self),
    ]
  end
end
