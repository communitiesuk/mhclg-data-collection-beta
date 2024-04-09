require "rails_helper"

RSpec.describe Form::Sales::Questions::Prevown, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page, joint_purchase:) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page, subsection: instance_double(Form::Subsection, form: instance_double(Form, start_date: Time.zone.local(2023, 4, 1)))) }
  let(:joint_purchase) { false }

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("prevown")
  end

  context "when sale is not a joint purchase" do
    it "has the correct header" do
      expect(question.header).to eq("Has the buyer previously owned a property?")
    end

    it "has the correct check_answer_label" do
      expect(question.check_answer_label).to eq("Buyer previously owned a property")
    end
  end

  context "when sale is a joint purchase" do
    let(:joint_purchase) { true }

    it "has the correct header" do
      expect(question.header).to eq("Have any of the buyers previously owned a property?")
    end

    it "has the correct check_answer_label" do
      expect(question.check_answer_label).to eq("Buyers previously owned a property")
    end
  end

  it "has the correct type" do
    expect(question.type).to eq("radio")
  end

  it "is not marked as derived" do
    expect(question.derived?(nil)).to be false
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
end
