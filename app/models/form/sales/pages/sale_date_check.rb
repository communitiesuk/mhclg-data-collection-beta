class Form::Sales::Pages::SaleDateCheck < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "completion_date_check"
    @depends_on = [{ "hodate_check" => nil, "hodate_3_years_or_more_saledate?" => true },
                   { "hodate_check" => 1, "hodate_3_years_or_more_saledate?" => true }]
    @informative_text = {}
    @title_text = {
      "translation" => "soft_validations.saledate.must_be_less_than_3_years_from_hodate",
      "arguments" => [],
    }
  end

  def questions
    @questions ||= [
      Form::Sales::Questions::SaleDateCheck.new(nil, nil, self),
    ]
  end
end
