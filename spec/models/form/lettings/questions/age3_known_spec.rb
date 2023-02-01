require "rails_helper"

RSpec.describe Form::Lettings::Questions::Age3Known, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page) }

  let(:question_id) { "age3_known" }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page) }

  before do
    allow(page).to receive(:id).and_return("age3_known")
  end

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct type" do
    expect(question.type).to eq("radio")
  end

  it "is not marked as derived" do
    expect(question.derived?).to be false
  end

  it "has the correct answer_options" do
    expect(question.answer_options).to eq({
      "0" => { "value" => "Yes" },
      "1" => { "value" => "No" },
    })
  end

  it "has the correct hint" do
    expect(question.hint_text).to eq("")
  end

  it "has the correct id" do
    expect(question.id).to eq("age3_known")
  end

  it "has the correct header" do
    expect(question.header).to eq("Do you know person 3’s age?")
  end

  it "has the correct check_answer_label" do
    expect(question.check_answer_label).to eq("")
  end

  it "has correct conditional for" do
    expect(question.conditional_for).to eq({
      "age3" => [0],
    })
  end

  it "has the correct hidden_in_check_answers" do
    expect(question.hidden_in_check_answers).to eq(
      {
        "depends_on" => [
          {
            "age3_known" => 0,
          },
          {
            "age3_known" => 1,
          },
        ],
      },
    )
  end

  it "has the correct check_answers_card_number" do
    expect(question.check_answers_card_number).to eq(3)
  end
end
