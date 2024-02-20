require "rails_helper"

RSpec.describe Form::Sales::Questions::Equity, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page, subsection: instance_double(Form::Subsection, form: instance_double(Form, start_date: Time.zone.local(2023, 4, 1)))) }

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("equity")
  end

  it "has the correct header" do
    expect(question.header).to eq("What was the initial percentage equity stake purchased?")
  end

  it "has the correct check_answer_label" do
    expect(question.check_answer_label).to eq("Initial percentage equity stake")
  end

  it "has the correct type" do
    expect(question.type).to eq("numeric")
  end

  it "is not marked as derived" do
    expect(question.derived?).to be false
  end

  it "has the correct hint" do
    expect(question.hint_text).to eq("Enter the amount of initial equity held by the purchaser (for example, 25% or 50%)")
  end

  it "has correct width" do
    expect(question.width).to eq(5)
  end

  it "has correct suffix" do
    expect(question.suffix).to eq("%")
  end

  it "has correct min" do
    expect(question.min).to eq(0)
  end

  it "has correct max" do
    expect(question.max).to eq(100)
  end
end
