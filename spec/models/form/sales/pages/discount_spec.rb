require "rails_helper"

RSpec.describe Form::Sales::Pages::Discount, type: :model do
  subject(:page) { described_class.new(page_id, page_definition, subsection) }

  let(:page_id) { nil }
  let(:page_definition) { nil }
  let(:subsection) { instance_double(Form::Subsection) }

  before do
    allow(subsection).to receive(:form).and_return(instance_double(Form, start_year_2024_or_later?: false, start_date: Time.zone.local(2023, 4, 1)))
  end

  it "has correct subsection" do
    expect(page.subsection).to eq(subsection)
  end

  it "has correct questions" do
    expect(page.questions.map(&:id)).to eq(%w[discount])
  end

  it "has the correct id" do
    expect(page.id).to eq("discount")
  end

  it "has the correct description" do
    expect(page.description).to be_nil
  end

  it "has correct depends_on" do
    expect(page.depends_on).to eq([{
      "right_to_buy?" => true,
    }])
  end
end
