require "rails_helper"

RSpec.describe Form::Sales::Pages::DiscountedSaleValueCheck, type: :model do
  subject(:page) { described_class.new(page_id, page_definition, subsection, index) }

  let(:page_id) { "discounted_sale_value_check" }
  let(:page_definition) { nil }
  let(:index) { 1 }
  let(:subsection) { instance_double(Form::Subsection) }

  it "has correct subsection" do
    expect(page.subsection).to eq(subsection)
  end

  it "has correct questions" do
    expect(page.questions.map(&:id)).to eq(%w[discounted_sale_value_check])
  end

  it "has the correct id" do
    expect(page.id).to eq("discounted_sale_value_check")
  end

  it "has the correct header" do
    expect(page.header).to be_nil
  end

  it "is interruption screen page" do
    expect(page.interruption_screen?).to eq(true)
  end

  it "has correct depends_on" do
    expect(page.depends_on).to eq([
      {
        "discounted_ownership_value_invalid?" => true,
      },
    ])
  end
end
