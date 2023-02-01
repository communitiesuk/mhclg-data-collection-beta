class Form::Lettings::Pages::Person4UnderRetirementValueCheck < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "person_4_under_retirement_value_check"
    @depends_on = [{ "person_4_retired_under_soft_min_age?" => true }]
    @title_text = { "translation" => "soft_validations.retirement.min.title", "arguments" => [{ "key" => "retirement_age_for_person_4", "label" => false, "i18n_template" => "age" }] }
    @informative_text = { "translation" => "soft_validations.retirement.min.hint_text", "arguments" => [{ "key" => "plural_gender_for_person_4", "label" => false, "i18n_template" => "gender" }, { "key" => "retirement_age_for_person_4", "label" => false, "i18n_template" => "age" }] }
  end

  def questions
    @questions ||= [Form::Lettings::Questions::RetirementValueCheck.new(nil, nil, self)]
  end
end
