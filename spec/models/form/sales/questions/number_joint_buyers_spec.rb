require "rails_helper"

RSpec.describe Form::Sales::Questions::NumberJointBuyers, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page) }
  let(:subsection) { instance_double(Form::Subsection) }

  before do
    allow(page).to receive(:subsection).and_return(subsection)
    allow(subsection).to receive(:form).and_return(instance_double(Form, start_year_after_2024?: false, start_date: Time.zone.local(2023, 4, 1)))
  end

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("jointmore")
  end

  it "has the correct header" do
    expect(question.header).to eq("Are there more than 2 joint buyers of this property?")
  end

  it "has the correct check_answer_label" do
    expect(question.check_answer_label).to eq("More than 2 joint buyers")
  end

  it "has the correct type" do
    expect(question.type).to eq("radio")
  end

  it "is not marked as derived" do
    expect(question.derived?(nil)).to be false
  end

  it "has the correct hint_text" do
    expect(question.hint_text).to eq("You should still try to answer all questions even if the buyers weren’t interviewed in person")
  end

  it "has the correct answer_options" do
    expect(question.answer_options).to eq({
      "1" => { "value" => "Yes" },
      "2" => { "value" => "No" },
      "3" => { "value" => "Don’t know" },
    })
  end

  context "with 2024 form" do
    before do
      allow(subsection).to receive(:form).and_return(instance_double(Form, start_year_after_2024?: true, start_date: Time.zone.local(2024, 4, 1)))
    end

    it "has no hint_text" do
      expect(question.hint_text).to be_nil
    end
  end
end
