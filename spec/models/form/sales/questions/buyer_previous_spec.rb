require "rails_helper"

RSpec.describe Form::Sales::Questions::BuyerPrevious, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page, joint_purchase:) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page) }
  let(:subsection) { instance_double(Form::Subsection) }
  let(:form) { instance_double(Form, start_date: Time.zone.local(2023, 4, 1)) }
  let(:joint_purchase) { true }

  before do
    allow(page).to receive(:subsection).and_return(subsection)
    allow(subsection).to receive(:form).and_return(form)
  end

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("soctenant")
  end

  context "when a joint purchase" do
    it "has the correct header" do
      expect(question.header).to eq("Were any of the buyers private registered providers, housing association or local authority tenants immediately before this sale?")
    end

    it "has the correct check_answer_label" do
      expect(question.check_answer_label).to eq("Any buyers were registered providers, housing association or local authority tenants immediately before this sale?")
    end
  end

  context "when not a joint purchase" do
    let(:joint_purchase) { false }

    it "has the correct header" do
      expect(question.header).to eq("Was the buyer a private registered provider, housing association or local authority tenant immediately before this sale?")
    end

    it "has the correct check_answer_label" do
      expect(question.check_answer_label).to eq("Buyer was a registered provider, housing association or local authority tenant immediately before this sale?")
    end
  end

  it "has the correct type" do
    expect(question.type).to eq("radio")
  end

  it "has the correct displayed_answer_options" do
    expect(question.displayed_answer_options(nil)).to eq({
      "1" => { "value" => "Yes" },
      "2" => { "value" => "No" },
    })
  end

  it "has the correct answer_options" do
    expect(question.answer_options).to eq({
      "1" => { "value" => "Yes" },
      "2" => { "value" => "No" },
      "0" => { "value" => "Don’t know" },
    })
  end

  it "has correct conditional for" do
    expect(question.conditional_for).to eq(nil)
  end

  it "has the correct hint" do
    expect(question.hint_text).to eq(nil)
  end

  context "when form year is before 2024" do
    before do
      allow(form).to receive(:start_year_after_2024?).and_return(false)
    end

    it "is not marked as derived" do
      expect(question.derived?).to be false
    end
  end

  context "when form year is >= 2024" do
    before do
      allow(form).to receive(:start_year_after_2024?).and_return(true)
    end

    it "is marked as derived" do
      expect(question.derived?).to be true
    end
  end
end
