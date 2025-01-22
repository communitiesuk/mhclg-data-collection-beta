require "rails_helper"

RSpec.describe Form::Sales::Questions::OwnershipScheme, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page) }
  let(:subsection) { instance_double(Form::Subsection) }
  let(:form) { instance_double(Form, start_date: Time.zone.local(2023, 4, 1)) }

  before do
    allow(form).to receive(:start_year_2024_or_later?).and_return(false)
    allow(form).to receive(:start_year_2025_or_later?).and_return(false)
    allow(page).to receive(:subsection).and_return(subsection)
    allow(subsection).to receive(:form).and_return(form)
  end

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("ownershipsch")
  end

  it "has the correct type" do
    expect(question.type).to eq("radio")
  end

  it "is not marked as derived" do
    expect(question.derived?(nil)).to be false
  end

  it "has the correct answer_options" do
    expect(question.answer_options).to eq({
      "1" => { "value" => "Yes - a shared ownership scheme" },
      "2" => { "value" => "Yes - a discounted ownership scheme" },
      "3" => { "value" => "No - this is an outright or other sale" },
    })
  end

  context "with collection year in 2024" do
    before do
      allow(form).to receive(:start_year_2024_or_later?).and_return(true)
    end

    it "has the correct answer_options" do
      expect(question.answer_options).to eq({
        "1" => { "value" => "Yes - a shared ownership scheme", "hint" => "When the purchaser buys an initial share of up to 75% of the property value and pays rent to the Private Registered Provider (PRP) on the remaining portion, or a subsequent staircasing transaction" },
        "2" => { "value" => "Yes - a discounted ownership scheme" },
        "3" => { "value" => "No - this is an outright or other sale" },
      })
    end
  end

  context "with collection year on or after 2025" do
    before do
      allow(form).to receive(:start_year_2024_or_later?).and_return(true)
      allow(form).to receive(:start_year_2025_or_later?).and_return(true)
    end

    it "has the correct answer_options" do
      expect(question.answer_options).to eq({
        "1" => { "value" => "Shared Ownership", "hint" => "When the purchaser buys an initial share of up to 75% of the property value and pays rent to the Private Registered Provider (PRP) on the remaining portion, or a subsequent staircasing transaction" },
        "2" => { "value" => "Discounted Ownership" },
      })
    end
  end
end
