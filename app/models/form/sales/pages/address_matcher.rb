class Form::Sales::Pages::AddressMatcher < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "address_matcher"
    @copy_key = "sales.property_information.address_matcher"
    @depends_on = [
      { "uprn_known" => nil, "address_export_and_display?" => true },
      { "uprn_known" => 0, "address_export_and_display?" => true },
      { "uprn_confirmed" => 0, "address_export_and_display?" => true },
    ]
  end

  def questions
    @questions ||= [
      Form::Sales::Questions::AddressLine1ForAddressMatcher.new(nil, nil, self),
      Form::Sales::Questions::PostcodeForAddressMatcher.new(nil, nil, self),
    ]
  end

  def submit_text
    "Search"
  end

  def skip_href(log = nil)
    return unless log

    "/#{log.log_type.dasherize}s/#{log.id}/property-number-of-bedrooms"
  end

  def routed_to?(log, _current_user)
    false if form.start_year_2024_or_later?
  end
end
