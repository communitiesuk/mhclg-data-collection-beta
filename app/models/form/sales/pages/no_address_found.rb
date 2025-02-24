class Form::Sales::Pages::NoAddressFound < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "no_address_found"
    @type = "interruption_screen"
    @copy_key = "sales.soft_validations.address_search_value_check"
    @title_text = {
      "translation" => "forms.#{form.start_date.year}.#{@copy_key}.title_text",
      "arguments" => [],
    }
    @informative_text = {
      "translation" => "forms.#{form.start_date.year}.#{@copy_key}.informative_text",
      "arguments" => [],
    }
    @depends_on = [
      { "uprn_known" => nil, "address_options_present?" => false },
      { "uprn_known" => 0, "address_options_present?" => false },
      { "uprn_confirmed" => 0, "address_options_present?" => false },
    ]
  end

  def questions
    @questions ||= [
      Form::Sales::Questions::NoAddressFound.new(nil, nil, self),
    ]
  end

  def interruption_screen_question_ids
    %w[address_line1_input]
  end
end
