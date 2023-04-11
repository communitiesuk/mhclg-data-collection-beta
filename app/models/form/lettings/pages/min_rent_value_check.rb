class Form::Lettings::Pages::MinRentValueCheck < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "min_rent_value_check"
    @depends_on = [{ "rent_in_soft_min_range?" => true }]
    @title_text = {
      "translation" => "soft_validations.rent.outside_range_title",
      "arguments" => [{
        "key" => "brent",
        "label" => true,
        "i18n_template" => "brent",
      }],
    }
    @informative_text = {
      "translation" => "soft_validations.rent.min_hint_text",
      "arguments" => [
        {
          "key" => "field_formatted_as_currency",
          "arguments_for_key" => "soft_min_for_period",
          "i18n_template" => "soft_min_for_period",
        },
      ],
    }
  end

  def questions
    @questions ||= [Form::Lettings::Questions::RentValueCheck.new(nil, nil, self)]
  end
end
