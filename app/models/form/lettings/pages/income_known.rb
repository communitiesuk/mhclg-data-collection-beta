class Form::Lettings::Pages::IncomeKnown < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "income_known"
  end

  def questions
    @questions ||= [Form::Lettings::Questions::NetIncomeKnown.new(nil, nil, self)]
  end
end
