class Form::Sales::Pages::Staircase < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "staircasing"
    @depends_on = [{ "ownershipsch" => 1 }]
    @copy_key = "sales.#{subsection.id}.staircasing"
  end

  def questions
    @questions ||= [
      Form::Sales::Questions::Staircase.new(nil, nil, self),
    ]
  end
end
