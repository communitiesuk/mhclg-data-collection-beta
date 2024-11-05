require "rails_helper"

RSpec.describe Form::Lettings::Pages::RentType, type: :model do
  subject(:page) { described_class.new(page_id, page_definition, subsection) }

  let(:page_id) { nil }
  let(:page_definition) { nil }
  let(:subsection) { instance_double(Form::Subsection) }
  let(:form) { instance_double(Form, start_date: Time.zone.local(2024, 4, 1)) }

  before do
    allow(subsection).to receive(:form).and_return(form)
    allow(form).to receive(:start_year_2024_or_later?).and_return(true)
  end

  it "has correct subsection" do
    expect(page.subsection).to eq(subsection)
  end

  it "has correct questions" do
    expect(page.questions.map(&:id)).to eq(%w[rent_type irproduct_other])
  end

  it "has the correct id" do
    expect(page.id).to eq("rent_type")
  end

  it "has the correct description" do
    expect(page.description).to be_nil
  end
end
