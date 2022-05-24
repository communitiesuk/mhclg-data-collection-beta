class SubNavigationComponent < ViewComponent::Base
  attr_reader :items

  def initialize(items:)
    @items = items
    super
  end

  def highlighted_item?(item, _path)
    item[:current]
  end
end
