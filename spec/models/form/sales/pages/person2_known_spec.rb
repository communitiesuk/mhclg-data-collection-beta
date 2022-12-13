require "rails_helper"

RSpec.describe Form::Sales::Pages::Person2Known, type: :model do
  subject(:page) { described_class.new(page_id, page_definition, subsection) }

  let(:page_id) { nil }
  let(:page_definition) { nil }
  let(:subsection) { instance_double(Form::Subsection) }

  it "has correct subsection" do
    expect(page.subsection).to eq(subsection)
  end

  it "has correct questions" do
    expect(page.questions.map(&:id)).to eq(%w[details_known_2])
  end

  it "has the correct id" do
    expect(page.id).to eq("person_2_known")
  end

  it "has the correct header" do
    expect(page.header).to eq("")
  end

  it "has the correct header_partial" do
    expect(page.header_partial).to eq("person_2_known_page")
  end

  it "has the correct description" do
    expect(page.description).to eq("")
  end

  it "has correct depends_on" do
    expect(page.depends_on).to eq(
      [
        { "hholdcount" => 2 },
        { "hholdcount" => 3 },
        { "hholdcount" => 4 },
      ],
    )
  end
end
