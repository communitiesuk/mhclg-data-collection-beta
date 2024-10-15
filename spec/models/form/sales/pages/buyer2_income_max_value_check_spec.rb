require "rails_helper"

RSpec.describe Form::Sales::Pages::Buyer2IncomeMaxValueCheck, type: :model do
  subject(:page) { described_class.new(page_id, page_definition, subsection, check_answers_card_number: 2) }

  let(:page_id) { "prefix_buyer_2_income_max_value_check" }
  let(:page_definition) { nil }
  let(:subsection) { instance_double(Form::Subsection) }

  it "has correct subsection" do
    expect(page.subsection).to eq(subsection)
  end

  it "has correct questions" do
    expect(page.questions.map(&:id)).to eq(%w[income2_value_check])
  end

  it "has the correct id" do
    expect(page.id).to eq("prefix_buyer_2_income_max_value_check")
  end

  it "has correct depends_on" do
    expect(page.depends_on).to eq([
      {
        "income2_over_soft_max?" => true,
      },
    ])
  end

  it "is interruption screen page" do
    expect(page.interruption_screen?).to eq(true)
  end
end
