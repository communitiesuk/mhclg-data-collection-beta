class Form::Lettings::Pages::VoidDate < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "void_date"
    @depends_on = [{ "is_renewal?" => false, "vacancy_reason_not_renewal_or_first_let?" => true },
                   { "is_renewal?" => false, "has_first_let_vacancy_reason?" => true }]
  end

  def questions
    @questions ||= [Form::Lettings::Questions::Voiddate.new(nil, nil, self)]
  end
end
