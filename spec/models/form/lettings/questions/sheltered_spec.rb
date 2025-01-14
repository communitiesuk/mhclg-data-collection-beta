require "rails_helper"

RSpec.describe Form::Lettings::Questions::Sheltered, type: :model do
  subject(:question) { described_class.new(nil, nil, page) }

  let(:page) { instance_double(Form::Page) }
  let(:subsection) { instance_double(Form::Subsection) }
  let(:form) { instance_double(Form, start_date: Time.zone.local(2023, 4, 1)) }

  before do
    allow(form).to receive(:start_year_2024_or_later?).and_return(false)
    allow(page).to receive(:subsection).and_return(subsection)
    allow(subsection).to receive(:form).and_return(form)
  end

  it "has correct page" do
    expect(question.page).to eq page
  end

  it "has the correct id" do
    expect(question.id).to eq "sheltered"
  end

  it "has the correct type" do
    expect(question.type).to eq "radio"
  end

  context "with 2024/25 form" do
    before do
      allow(form).to receive(:start_year_2024_or_later?).and_return(true)
      allow(form).to receive(:start_year_2025_or_later?).and_return(false)
    end

    it "has the correct answer_options" do
      expect(question.answer_options).to eq({
        "1" => { "value" => "Yes – specialist retirement housing" },
        "2" => { "value" => "Yes – extra care housing" },
        "5" => { "value" => "Yes – sheltered housing for adults aged under 55 years" },
        "6" => { "value" => "Yes – sheltered housing for adults aged 55 years and over who are not retired" },
        "3" => { "value" => "No" },
        "divider" => { "value" => true },
        "4" => { "value" => "Don’t know" },
      })
    end
  end

  context "with 2025/26 form" do
    before do
      allow(form).to receive(:start_year_2024_or_later?).and_return(true)
      allow(form).to receive(:start_year_2025_or_later?).and_return(true)
    end

    it "has the correct answer_options" do
      expect(question.answer_options).to eq({
        "1" => { "value" => "Yes – sheltered housing for tenants with low support needs" },
        "2" => { "value" => "Yes – extra care housing" },
        "7" => { "value" => "Yes - other" },
        "3" => { "value" => "No" },
        "divider" => { "value" => true },
        "4" => { "value" => "Don’t know" },
      })
    end
  end

  it "is not marked as derived" do
    expect(question.derived?(nil)).to be false
  end
end
