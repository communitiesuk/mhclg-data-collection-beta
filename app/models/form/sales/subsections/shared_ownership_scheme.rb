class Form::Sales::Subsections::SharedOwnershipScheme < ::Form::Subsection
  def initialize(id, hsh, section)
    super
    @id = "shared_ownership_scheme"
    @label = "Shared ownership scheme"
    @section = section
    @depends_on = [{ "ownershipsch" => 1, "setup_completed?" => true }]
  end

  def pages
    @pages ||= [
      Form::Sales::Pages::LivingBeforePurchase.new("living_before_purchase_shared_ownership", nil, self),
      Form::Sales::Pages::Staircase.new(nil, nil, self),
      Form::Sales::Pages::AboutStaircase.new(nil, nil, self),
      Form::Sales::Pages::Resale.new(nil, nil, self),
      Form::Sales::Pages::ExchangeDate.new(nil, nil, self),
      Form::Sales::Pages::LaNominations.new(nil, nil, self),
      Form::Sales::Pages::BuyerPrevious.new(nil, nil, self),
      Form::Sales::Pages::PreviousBedrooms.new(nil, nil, self),
      Form::Sales::Pages::AboutPrice.new(nil, nil, self),
      Form::Sales::Pages::AboutPriceSocialHousing.new(nil, nil, self),
      Form::Sales::Pages::AboutDeposit.new("about_deposit_shared_ownership", nil, self),
      Form::Sales::Pages::MonthlyRent.new(nil, nil, self),
      Form::Sales::Pages::LeaseholdCharges.new("leasehold_charges_shared_ownership", nil, self),
    ]
  end

  def displayed_in_tasklist?(log)
    log.ownershipsch == 1
  end
end
