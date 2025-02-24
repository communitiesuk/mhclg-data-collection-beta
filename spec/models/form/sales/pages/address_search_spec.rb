require "rails_helper"

RSpec.describe Form::Sales::Pages::AddressSearch, type: :model do
  subject(:page) { described_class.new(page_id, page_definition, subsection) }

  let(:page_id) { nil }
  let(:page_definition) { nil }
  let(:subsection) { instance_double(Form::Subsection, form: instance_double(Form, start_date:)) }
  let(:start_date) { Time.utc(2024, 4, 1) }

  it "has correct subsection" do
    expect(page.subsection).to eq(subsection)
  end

  it "has correct questions" do
    expect(page.questions.map(&:id)).to eq(%w[uprn])
  end

  it "has the correct id" do
    expect(page.id).to eq("address_search")
  end

  it "has the correct description" do
    expect(page.description).to be_nil
  end

  it "has correct depends_on" do
    expect(page.depends_on).to eq([{ "manual_address_entry_selected" => false }])
  end

  it "has the correct question number" do
    expect(page.question_number).to eq(15)
  end

  context "with 2025/26 form" do
    let(:start_date) { Time.utc(2025, 4, 1) }

    it "has the correct question number" do
      expect(page.question_number).to eq(13)
    end
  end
end
