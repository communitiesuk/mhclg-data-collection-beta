class Form::Lettings::Pages::PropertyVacancyReasonFirstLet < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "property_vacancy_reason_first_let"
    @depends_on = [{ "first_time_property_let_as_social_housing" => 1, "is_renewal?" => false }]
  end

  def questions
    @questions ||= [Form::Lettings::Questions::RsnvacFirstLet.new(nil, nil, self)]
  end
end
