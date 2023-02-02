class Form::Lettings::Pages::Person3Known < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "person_3_known"
    @header = "You’ve given us the details for 2 people in the household"
    @depends_on = [{ "hhmemb" => 3 }, { "hhmemb" => 4 }, { "hhmemb" => 5 }, { "hhmemb" => 6 }, { "hhmemb" => 7 }, { "hhmemb" => 8 }]
    @description = ""
  end

  def questions
    @questions ||= [Form::Lettings::Questions::DetailsKnown3.new(nil, nil, self)]
  end
end
