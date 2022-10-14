require "rails_helper"

RSpec.describe Form::Sales::Pages::Person3Age, type: :model do
  subject(:page) { described_class.new(page_id, page_definition, subsection) }

  let(:page_id) { nil }
  let(:page_definition) { nil }
  let(:subsection) { instance_double(Form::Subsection) }

  it "has correct subsection" do
    expect(page.subsection).to eq(subsection)
  end

  it "has correct questions" do
    expect(page.questions.map(&:id)).to eq(%w[age5_known age5])
  end

  it "has the correct id" do
    expect(page.id).to eq("person_3_age")
  end

  it "has the correct header" do
    expect(page.header).to eq("")
  end

  it "has the correct description" do
    expect(page.description).to eq("")
  end

  it "has correct depends_on" do
    expect(page.depends_on).to eq(
      [{ "details_known_3" => 1, "hholdcount" => 3 }, { "details_known_3" => 1, "hholdcount" => 4 }],
    )
  end
end
