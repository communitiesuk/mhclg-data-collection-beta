class Form::Sales::Subsections::SharedOwnershipScheme < ::Form::Subsection
  def initialize(id, hsh, section)
    super
    @id = "shared_ownership_scheme"
    @label = "Shared ownership scheme"
    @section = section
    @depends_on = [{ "ownershipsch" => 1, "setup_completed?" => true }]
  end

  def pages
    @pages ||= [
      Form::Sales::Pages::Staircase.new(nil, nil, self),
      Form::Sales::Pages::AboutStaircase.new(nil, nil, self),
      Form::Sales::Pages::PreviousBedrooms.new(nil, nil, self),
    ]
  end

  def displayed_in_tasklist?(log)
    log.ownershipsch == 1
  end
end
