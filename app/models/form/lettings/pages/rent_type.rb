class Form::Lettings::Pages::RentType < ::Form::Page
  def initialize(_id, hsh, subsection)
    super("rent_type", hsh, subsection)
    @derived = true
    @header = "Rent Type"
  end

  def questions
    @questions ||= [
      Form::Lettings::Questions::RentType.new(nil, nil, self),
      Form::Lettings::Questions::IrproductOther.new(nil, nil, self),
    ]
  end
end
