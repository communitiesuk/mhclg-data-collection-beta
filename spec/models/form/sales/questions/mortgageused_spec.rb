require "rails_helper"

RSpec.describe Form::Sales::Questions::Mortgageused, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page, ownershipsch: 1) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page) }
  let(:log) { create(:sales_log) }

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("mortgageused")
  end

  it "has the correct header" do
    expect(question.header).to eq("Was a mortgage used for the purchase of this property?")
  end

  it "has the correct check_answer_label" do
    expect(question.check_answer_label).to eq("Mortgage used")
  end

  it "has the correct type" do
    expect(question.type).to eq("radio")
  end

  it "is not marked as derived" do
    expect(question.derived?).to be false
  end

  it "has the correct answer_options" do
    expect(question.answer_options).to eq({
      "1" => { "value" => "Yes" },
      "2" => { "value" => "No" },
      "3" => { "value" => "Don’t know" },
    })
  end

  it "has correct conditional for" do
    expect(question.conditional_for).to eq(nil)
  end

  it "has the correct hint" do
    expect(question.hint_text).to be_nil
  end

  context "when staircase owned percentage is 100%" do
    let(:log) { build(:sales_log, stairowned: 100) }

    it "shows the don't know option" do
      expect(question.displayed_answer_options(log)).to eq({
        "1" => { "value" => "Yes" },
        "2" => { "value" => "No" },
        "3" => { "value" => "Don’t know" },
      })
    end
  end

  context "when an outright sale" do
    subject(:question) { described_class.new(question_id, question_definition, page, ownershipsch: 3) }

    it "shows the don't know option" do
      expect(question.displayed_answer_options(log)).to eq({
        "1" => { "value" => "Yes" },
        "2" => { "value" => "No" },
        "3" => { "value" => "Don’t know" },
      })
    end
  end

  context "when staircase owned percentage is less than 100%" do
    let(:log) { build(:sales_log, stairowned: 99) }

    it "shows the don't know option" do
      expect(question.displayed_answer_options(log)).to eq({
        "1" => { "value" => "Yes" },
        "2" => { "value" => "No" },
      })
    end
  end
end
