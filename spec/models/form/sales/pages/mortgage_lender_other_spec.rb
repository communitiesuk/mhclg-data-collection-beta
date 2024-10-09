require "rails_helper"

RSpec.describe Form::Sales::Pages::MortgageLenderOther, type: :model do
  subject(:page) { described_class.new(page_id, page_definition, subsection, ownershipsch: 1) }

  let(:page_id) { "mortgage_lender_other" }
  let(:page_definition) { nil }
  let(:subsection) { instance_double(Form::Subsection) }

  it "has correct subsection" do
    expect(page.subsection).to eq(subsection)
  end

  it "has correct questions" do
    expect(page.questions.map(&:id)).to eq(%w[mortgagelenderother])
  end

  it "has the correct id" do
    expect(page.id).to eq("mortgage_lender_other")
  end

  it "has the correct description" do
    expect(page.description).to eq("")
  end

  it "has correct depends_on" do
    expect(page.depends_on).to eq([{
      "mortgagelender" => 40,
    }])
  end
end
