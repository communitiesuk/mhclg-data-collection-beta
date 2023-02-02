class Form::Lettings::Pages::Person2Known < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "person_2_known"
    @header = "You’ve given us the details for 1 person in the household"
    @depends_on = [{ "hhmemb" => 2 }, { "hhmemb" => 3 }, { "hhmemb" => 4 }, { "hhmemb" => 5 }, { "hhmemb" => 6 }, { "hhmemb" => 7 }, { "hhmemb" => 8 }]
    @description = ""
  end

  def questions
    @questions ||= [Form::Lettings::Questions::DetailsKnown2.new(nil, nil, self)]
  end
end
