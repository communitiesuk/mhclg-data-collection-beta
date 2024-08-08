require "rails_helper"

RSpec.describe Form::Lettings::Pages::Location, type: :model do
  subject(:page) { described_class.new(page_id, page_definition, subsection) }

  let(:page_id) { nil }
  let(:page_definition) { nil }
  let(:subsection) { instance_double(Form::Subsection) }
  let(:form) { instance_double(Form, start_date: Time.zone.local(2024, 4, 1)) }

  before do
    allow(form).to receive(:start_date).and_return(Time.zone.local(2022, 4, 1))
    allow(subsection).to receive(:form).and_return(form)
  end

  it "has correct subsection" do
    expect(page.subsection).to eq(subsection)
  end

  it "has correct questions" do
    expect(page.questions.map(&:id)).to eq(%w[location_id])
  end

  it "has the correct id" do
    expect(page.id).to eq("location")
  end

  it "has the correct header" do
    expect(page.header).to eq("Location")
  end

  it "has the correct description" do
    expect(page.description).to be_nil
  end

  it "has the correct depends_on" do
    expect(page.depends_on).to eq([
      {
        "needstype" => 2,
        "scheme_has_multiple_locations?" => true,
        "scheme_has_large_number_of_locations?" => false,
      },
    ])
  end
end

