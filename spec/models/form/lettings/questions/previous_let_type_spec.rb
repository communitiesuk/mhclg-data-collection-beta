require "rails_helper"

RSpec.describe Form::Lettings::Questions::PreviousLetType, type: :model do
  subject(:question) { described_class.new(nil, nil, page) }

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
    expect(question.page).to eq page
  end

  it "has the correct id" do
    expect(question.id).to eq "unitletas"
  end

  it "has the correct type" do
    expect(question.type).to eq "radio"
  end

  it "is not marked as derived" do
    expect(question.derived?(nil)).to be false
  end

  it "has the correct answer options" do
    expect(question.answer_options).to eq({
      "1" => { "value" => "Social rent basis" },
      "2" => { "value" => "Affordable rent basis" },
      "5" => { "value" => "A London Affordable Rent basis" },
      "6" => { "value" => "A Rent to Buy basis" },
      "7" => { "value" => "A London Living Rent basis" },
      "8" => { "value" => "Another Intermediate Rent basis" },
      "divider" => { "value" => true },
      "3" => { "value" => "Don’t know" },
    })
  end

  context "with collection year on or after 2024" do
    before do
      allow(form).to receive(:start_year_2024_or_later?).and_return(true)
    end

    it "has the correct answer options" do
      expect(question.answer_options).to eq({
        "1" => { "value" => "Social rent basis" },
        "2" => { "value" => "Affordable rent basis" },
        "5" => { "value" => "London Affordable Rent basis" },
        "6" => { "value" => "Rent to Buy basis" },
        "7" => { "value" => "London Living Rent basis" },
        "8" => { "value" => "Another Intermediate Rent basis" },
        "divider" => { "value" => true },
        "3" => { "value" => "Don’t know" },
      })
    end
  end

  context "with collection year on or after 2025" do
    before do
      allow(form).to receive(:start_year_2025_or_later?).and_return(true)
    end

    it "has the correct answer options" do
      expect(question.answer_options).to eq({
        "1" => { "value" => "Social rent basis" },
        "2" => { "value" => "Affordable rent basis" },
        "5" => { "value" => "London Affordable Rent basis" },
        "6" => { "value" => "Rent to Buy basis" },
        "7" => { "value" => "London Living Rent basis" },
        "8" => { "value" => "Another Intermediate Rent basis" },
        "9" => { "value" => "Specified accommodation - exempt accommodation, manged properties, refuges and local authority hostels" },
        "divider" => { "value" => true },
        "3" => { "value" => "Don’t know" },
      })
    end
  end
end
