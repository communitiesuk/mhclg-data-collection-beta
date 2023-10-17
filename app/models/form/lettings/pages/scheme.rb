class Form::Lettings::Pages::Scheme < ::Form::Page
  def initialize(_id, hsh, subsection)
    super("scheme", hsh, subsection)
    @depends_on = [
      {
        "needstype" => 2,
      },
    ]
    @header = "Scheme"
    @next_unresolved_page_id = "location"
  end

  def questions
    @questions ||= [
      Form::Lettings::Questions::SchemeId.new(nil, nil, self),
    ]
  end
end
