require "rails_helper"

RSpec.describe Form::Lettings::Pages::ShelteredAccommodation, type: :model do
  subject(:page) { described_class.new(nil, nil, subsection) }

  let(:subsection) { instance_double(Form::Subsection, form: instance_double(Form, start_date: Time.zone.local(2024, 4, 1))) }

  it "has correct subsection" do
    expect(page.subsection).to eq(subsection)
  end

  it "has correct questions" do
    expect(page.questions.map(&:id)).to eq(%w[sheltered])
  end

  it "has the correct id" do
    expect(page.id).to eq("sheltered_accommodation")
  end

  it "has the correct description" do
    expect(page.description).to be_nil
  end

  it "has the correct depends_on" do
    expect(page.depends_on).to eq([{ "is_supported_housing?" => true }])
  end
end
