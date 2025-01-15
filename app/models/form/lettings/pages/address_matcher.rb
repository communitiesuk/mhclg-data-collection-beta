class Form::Lettings::Pages::AddressMatcher < ::Form::Page
  def initialize(id, hsh, subsection)
    super
    @id = "address_matcher"
    @copy_key = "lettings.property_information.address_matcher"
    @depends_on = [
      { "is_supported_housing?" => false, "uprn_known" => nil },
      { "is_supported_housing?" => false, "uprn_known" => 0 },
      { "is_supported_housing?" => false, "uprn_confirmed" => 0 },
    ]
  end

  def questions
    @questions ||= [
      Form::Lettings::Questions::AddressLine1ForAddressMatcher.new(nil, nil, self),
      Form::Lettings::Questions::PostcodeForAddressMatcher.new(nil, nil, self),
    ]
  end

  def submit_text
    "Search"
  end

  def skip_href(log = nil)
    return unless log

    "/#{log.log_type.dasherize}s/#{log.id}/property-unit-type"
  end
end
