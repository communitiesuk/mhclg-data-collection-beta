require "rails_helper"

RSpec.describe Form::Sales::Questions::DepositAmount, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page, ownershipsch: 1, optional: false) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page, subsection: instance_double(Form::Subsection, form: instance_double(Form, start_date: Time.zone.local(2023, 4, 1)))) }

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("deposit")
  end

  it "has the correct header" do
    expect(question.header).to eq("How much cash deposit was paid on the property?")
  end

  it "has the correct check_answer_label" do
    expect(question.check_answer_label).to eq("Cash deposit")
  end

  it "has the correct type" do
    expect(question.type).to eq("numeric")
  end

  it "is marked as derived" do
    expect(question.derived?).to be true
  end

  it "has the correct hint" do
    expect(question.hint_text).to eq("Enter the total cash sum paid by the buyer towards the property that was not funded by the mortgage. This excludes any grant or loan")
  end

  it "has correct width" do
    expect(question.width).to eq(5)
  end

  it "has correct prefix" do
    expect(question.prefix).to eq("£")
  end

  it "has correct min" do
    expect(question.min).to eq(0)
  end

  it "has correct max" do
    expect(question.max).to eq(999_999)
  end

  context "when optional iis true" do
    subject(:question) { described_class.new(question_id, question_definition, page, ownershipsch: 1, optional: true) }

    it "has a correct hint_text" do
      expect(question.hint_text).to eq("Enter the total cash sum paid by the buyer towards the property that was not funded by the mortgage. This excludes any grant or loan. As this is a fully staircased sale this question is optional. If you do not have the information available click save and continue")
    end
  end
end
