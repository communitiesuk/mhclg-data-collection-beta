require "rails_helper"

RSpec.describe Form::Sales::Questions::Person1Age, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page) }

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("age3")
  end

  it "has the correct header" do
    expect(question.header).to eq("Age")
  end

  it "has the correct check_answer_label" do
    expect(question.check_answer_label).to eq("Person 1’s age")
  end

  it "has the correct type" do
    expect(question.type).to eq("numeric")
  end

  it "is not marked as derived" do
    expect(question.derived?).to be false
  end

  it "has the correct hint" do
    expect(question.hint_text).to be_nil
  end

  it "has the correct width" do
    expect(question.width).to eq(3)
  end

  it "has the correct inferred check answers value" do
    expect(question.inferred_check_answers_value).to eq({
      "condition" => {"age3_known" => 1},
      "value" => "Not known"
    })
  end

  it "has the correct check_answers_card_number" do
    expect(question.check_answers_card_number).to eq(3)
  end
end
