require "rails_helper"

RSpec.describe Form::Sales::Pages::OutrightOwnershipType, type: :model do
  subject(:page) { described_class.new(page_id, page_definition, subsection) }

  let(:page_id) { nil }
  let(:page_definition) { nil }
  let(:subsection) { instance_double(Form::Subsection, form: instance_double(Form, start_date:)) }
  let(:start_date) { Time.zone.today }

  it "has correct subsection" do
    expect(page.subsection).to eq(subsection)
  end

  it "has correct questions" do
    expect(page.questions.map(&:id)).to eq(%w[type othtype])
  end

  it "has the correct id" do
    expect(page.id).to eq("outright_ownership_type")
  end

  it "has the correct description" do
    expect(page.description).to be_nil
  end

  it "has correct depends_on" do
    expect(page.depends_on).to eq([{
      "ownershipsch" => 3,
    }])
  end

  describe "headers" do
    context "when the form year is 2023" do
      let(:start_date) { Time.utc(2023, 2, 8) }

      it "has the correct header" do
        expect(page.header).to eq("Outright ownership type")
      end
    end

    context "when the form is before the year 2023" do
      let(:start_date) { Time.utc(2022, 2, 8) }

      it "does not have a page header" do
        expect(page.header).to eq(nil)
      end
    end
  end
end
