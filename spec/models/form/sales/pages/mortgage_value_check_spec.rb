require "rails_helper"

RSpec.describe Form::Sales::Pages::MortgageValueCheck, type: :model do
  subject(:page) { described_class.new(page_id, page_definition, subsection, index) }

  let(:page_id) { "buyer_1_income_mortgage_value_check" }
  let(:page_definition) { nil }
  let(:index) { 1 }
  let(:form) { instance_double(Form, start_date: Time.zone.local(2024, 4, 1)) }
  let(:subsection) { instance_double(Form::Subsection, form:) }

  it "has correct subsection" do
    expect(page.subsection).to eq(subsection)
  end

  it "has correct questions" do
    expect(page.questions.map(&:id)).to eq(%w[mortgage_value_check])
  end

  it "has the correct id" do
    expect(page.id).to eq("buyer_1_income_mortgage_value_check")
  end

  it "is interruption screen page" do
    expect(page.interruption_screen?).to eq(true)
  end

  it "has correct depends_on" do
    expect(page.depends_on).to eq([
      {
        "mortgage_over_soft_max?" => true,
      },
    ])
  end

  it "has correct interruption_screen_question_ids" do
    expect(page.interruption_screen_question_ids).to eq(%w[mortgage inc1mort inc2mort jointpur income1 income2 inc1mort inc2mort])
  end

  context "when checking buyer 2" do
    let(:index) { 2 }

    it "has correct depends_on" do
      expect(page.depends_on).to eq([
        {
          "mortgage_over_soft_max?" => true,
          "joint_purchase?" => true,
        },
      ])
    end
  end
end
