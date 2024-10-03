require "rails_helper"

RSpec.describe Form::Sales::Questions::StaircaseOwned, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page, joint_purchase:) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page, subsection: instance_double(Form::Subsection, form: instance_double(Form, start_date: Time.zone.local(2023, 4, 1)))) }
  let(:joint_purchase) { false }

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("stairowned")
  end

  context "when a joint purchase" do
    let(:joint_purchase) { true }

    it "has the correct header" do
      expect(question.header).to eq("What percentage of the property do the buyers now own in total?")
    end

    it "has the correct check_answer_label" do
      expect(question.check_answer_label).to eq("Percentage the buyers now own in total.")
    end
  end

  context "when not a joint purchase" do
    it "has the correct header" do
      expect(question.header).to eq("What percentage of the property does the buyer now own in total?")
    end

    it "has the correct check_answer_label" do
      expect(question.check_answer_label).to eq("Percentage the buyer now owns in total.")
    end
  end

  it "has the correct type" do
    expect(question.type).to eq("numeric")
  end

  it "is not marked as derived" do
    expect(question.derived?(nil)).to be false
  end

  it "has the correct hint" do
    expect(question.hint_text).to be_nil
  end

  it "has the correct width" do
    expect(question.width).to eq(5)
  end

  it "has the correct inferred check answers value" do
    expect(question.inferred_check_answers_value).to eq(nil)
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
