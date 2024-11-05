require "rails_helper"

RSpec.describe Form::Sales::Questions::Buyer2RelationshipToBuyer1, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page, subsection: instance_double(Form::Subsection, form: instance_double(Form, start_date: Time.zone.local(2023, 4, 1), start_year_2024_or_later?: false))) }

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("relat2")
  end

  it "has the correct type" do
    expect(question.type).to eq("radio")
  end

  it "is not marked as derived" do
    expect(question.derived?(nil)).to be false
  end

  it "has the correct answer_options" do
    expect(question.answer_options).to eq({
      "P" => { "value" => "Partner" },
      "C" => { "value" => "Child", "hint" => "Must be eligible for child benefit, aged under 16 or under 20 if still in full-time education." },
      "X" => { "value" => "Other" },
      "R" => { "value" => "Buyer prefers not to say" },
    })
  end

  it "has the correct check_answers_card_number" do
    expect(question.check_answers_card_number).to eq(2)
  end

  it "has the correct inferred_check_answers_value" do
    expect(question.inferred_check_answers_value).to eq([
      { "condition" => { "relat2" => "R" }, "value" => "Prefers not to say" },
    ])
  end
end
