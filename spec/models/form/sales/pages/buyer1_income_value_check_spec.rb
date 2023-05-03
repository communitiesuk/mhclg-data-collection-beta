require "rails_helper"

RSpec.describe Form::Sales::Pages::Buyer1IncomeValueCheck, type: :model do
  subject(:page) { described_class.new(page_id, page_definition, subsection) }

  let(:page_id) { "prefix_buyer_1_income_value_check" }
  let(:page_definition) { nil }
  let(:subsection) { instance_double(Form::Subsection) }

  it "has correct subsection" do
    expect(page.subsection).to eq(subsection)
  end

  it "has correct questions" do
    expect(page.questions.map(&:id)).to eq(%w[income1_value_check])
  end

  it "has the correct id" do
    expect(page.id).to eq("prefix_buyer_1_income_value_check")
  end

  it "has the correct header" do
    expect(page.header).to be_nil
  end

  it "has correct depends_on" do
    expect(page.depends_on).to eq([
      {
        "income1_under_soft_min?" => true,
      },
    ])
  end

  it "is interruption screen page" do
    expect(page.interruption_screen?).to eq(true)
  end

  it "is has correct affected_question_ids" do
    expect(page.affected_question_ids).to eq(%w[ecstat1 income1])
  end
end
