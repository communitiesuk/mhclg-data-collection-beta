class Form::Sales::Subsections::Setup < ::Form::Subsection
  def initialize(id, hsh, section)
    super
    @id = "setup"
    @label = "Set up this sales log"
  end

  def pages
    @pages ||= [
      Form::Sales::Pages::OwningOrganisation.new(nil, nil, self),
      Form::Sales::Pages::ManagingOrganisation.new(nil, nil, self),
      Form::Sales::Pages::CreatedBy.new(nil, nil, self),
      Form::Sales::Pages::SaleDate.new(nil, nil, self),
      Form::Sales::Pages::PurchaserCode.new(nil, nil, self),
      Form::Sales::Pages::OwnershipScheme.new(nil, nil, self),
      Form::Sales::Pages::SharedOwnershipType.new(nil, nil, self),
      Form::Sales::Pages::DiscountedOwnershipType.new(nil, nil, self),
      Form::Sales::Pages::OutrightOwnershipType.new(nil, nil, self),
      Form::Sales::Pages::BuyerCompany.new(nil, nil, self),
      Form::Sales::Pages::BuyerLive.new(nil, nil, self),
      Form::Sales::Pages::JointPurchase.new(nil, nil, self),
      Form::Sales::Pages::NumberJointBuyers.new(nil, nil, self),
    ]
  end
end
