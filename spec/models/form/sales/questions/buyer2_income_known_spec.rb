require "rails_helper"

RSpec.describe Form::Sales::Questions::Buyer2IncomeKnown, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page, subsection: instance_double(Form::Subsection, form: instance_double(Form, start_date: Time.zone.local(2023, 4, 1)))) }

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("income2nk")
  end

  it "has the correct header" do
    expect(question.header).to eq("Do you know buyer 2’s annual income?")
  end

  it "has the correct check_answer_label" do
    expect(question.check_answer_label).to eq("Buyer 2’s gross annual income known?")
  end

  it "has the correct type" do
    expect(question.type).to eq("radio")
  end

  it "is not marked as derived" do
    expect(question.derived?(nil)).to be false
  end

  it "has the correct answer_options" do
    expect(question.answer_options).to eq({
      "0" => { "value" => "Yes" },
      "1" => { "value" => "No" },
    })
  end

  it "has correct conditional for" do
    expect(question.conditional_for).to eq({
      "income2" => [0],
    })
  end

  it "has the correct check_answers_card_number" do
    expect(question.check_answers_card_number).to eq(2)
  end
end
