class Form::Sales::Pages::Person < ::Form::Page
  def initialize(id, hsh, subsection, person_index)
    super(id, hsh, subsection)
    @person_index = person_index
  end

  def person_display_number
    joint_purchase? ? @person_index - 2 : @person_index - 1
  end

  def joint_purchase?
    id.include?("_joint_purchase")
  end
end
