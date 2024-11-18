class Form::Sales::Sections::SaleInformation < ::Form::Section
  def initialize(id, hsh, form)
    super
    @id = "sale_information"
    @label = "Sale information"
    @description = ""
    @subsections = [
      shared_ownership_scheme_subsection,
      Form::Sales::Subsections::DiscountedOwnershipScheme.new(nil, nil, self),
      Form::Sales::Subsections::OutrightSale.new(nil, nil, self),
    ] || []
  end

  def shared_ownership_scheme_subsection
    if form.start_year_2025_or_later?
      Form::Sales::Subsections::SharedOwnershipStaircasingTransaction.new(nil, nil, self)
    else
      Form::Sales::Subsections::SharedOwnershipScheme.new(nil, nil, self)
    end
  end
end
