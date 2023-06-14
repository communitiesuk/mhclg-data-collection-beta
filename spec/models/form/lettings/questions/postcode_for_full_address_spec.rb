require "rails_helper"

RSpec.describe Form::Lettings::Questions::PostcodeForFullAddress, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page) }

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("postcode_full")
  end

  it "has the correct header" do
    expect(question.header).to eq("Postcode")
  end

  it "has the correct check_answer_label" do
    expect(question.check_answer_label).to eq("Q12 - Postcode")
  end

  it "has the correct type" do
    expect(question.type).to eq("text")
  end

  it "is not marked as derived" do
    expect(question.derived?).to be false
  end

  it "has the correct hint" do
    expect(question.hint_text).to be_nil
  end

  it "has the correct width" do
    expect(question.width).to eq(5)
  end

  it "has the correct inferred_answers" do
    expect(question.inferred_answers).to eq({
      "la" => {
        "is_la_inferred" => true,
      },
    })
  end

  it "has the correct inferred_check_answers_value" do
    expect(question.inferred_check_answers_value).to eq([{
      "condition" => {
        "pcodenk" => 1,
      },
      "value" => "Not known",
    }])
  end

  it "has the correct hidden_in_check_answers" do
    expect(question.hidden_in_check_answers?).to eq(true)
  end
end
