require "rails_helper"

RSpec.describe Form::Lettings::Questions::RentType, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page) }
  let(:subsection) { instance_double(Form::Subsection) }
  let(:form) { instance_double(Form, start_date: Time.zone.local(2023, 4, 1)) }

  before do
    allow(page).to receive(:subsection).and_return(subsection)
    allow(subsection).to receive(:form).and_return(form)
    allow(form).to receive(:start_year_2025_or_later?).and_return(false)
  end

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("rent_type")
  end

  it "has the correct type" do
    expect(question.type).to eq("radio")
  end

  it "has the correct conditional_for" do
    expect(question.conditional_for).to eq({ "irproduct_other" => [5] })
  end

  it "is not marked as derived" do
    expect(question.derived?(nil)).to be false
  end

  context "when 2025" do
    before do
      allow(form).to receive(:start_year_2025_or_later?).and_return(true)
    end

    it "has the correct answer_options" do
      expect(question.answer_options).to eq({
        "1" => { "value" => "Affordable Rent" },
        "2" => { "value" => "London Affordable Rent" },
        "4" => { "value" => "London Living Rent" },
        "3" => { "value" => "Rent to Buy" },
        "0" => { "value" => "Social Rent" },
        "5" => { "value" => "Other intermediate rent product" },
        "6" => { "value" => "Specified accommodation - exempt accommodation, managed properties, refuges and local authority hostels" },
      })
    end

    it "has the correct guidance partial" do
      expect(question.top_guidance_partial).to eq("rent_type_definitions")
    end
  end

  context "when 2024" do
    before do
      allow(form).to receive(:start_year_2025_or_later?).and_return(false)
    end

    it "has the correct answer_options" do
      expect(question.answer_options).to eq({
        "0" => { "value" => "Social Rent" },
        "1" => { "value" => "Affordable Rent" },
        "2" => { "value" => "London Affordable Rent" },
        "3" => { "value" => "Rent to Buy" },
        "4" => { "value" => "London Living Rent" },
        "5" => { "value" => "Other intermediate rent product" },
      })
    end

    it "has the correct guidance partial" do
      expect(question.top_guidance_partial).to eq("rent_type_definitions")
    end
  end
end
