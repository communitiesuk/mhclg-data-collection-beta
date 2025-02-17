class Form::Lettings::Pages::AddressSearch < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "address_search"
    @copy_key = "sales.property_information.address_search"
    @depends_on = [{ "is_supported_housing?" => false, "manual_address_entry_selected" => false }]
    @question_number = QUESTION_NUMBER_FROM_YEAR[form.start_date.year] || QUESTION_NUMBER_FROM_YEAR[QUESTION_NUMBER_FROM_YEAR.keys.max]
  end

  def questions
    @questions ||= [
      Form::Lettings::Questions::AddressSearch.new(nil, nil, self),
    ]
  end

  def skip_href(log = nil)
    return unless log

    "/#{log.log_type.dasherize}s/#{log.id}/first-time-property-let-as-social-housing"
  end

  QUESTION_NUMBER_FROM_YEAR = { 2024 => 12, 2025 => 12 }.freeze
end
