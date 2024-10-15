require "rails_helper"

RSpec.describe Form::Lettings::Questions::PreviousTenureRenewal, type: :model do
  subject(:question) { described_class.new(nil, nil, page) }

  let(:page) { instance_double(Form::Page, subsection: instance_double(Form::Subsection, form: instance_double(Form, start_date: Time.zone.local(2023, 4, 1)))) }

  it "has the correct id" do
    expect(question.id).to eq("prevten")
  end

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct type" do
    expect(question.type).to eq("radio")
  end

  it "is not marked as derived" do
    expect(question.derived?(nil)).to be false
  end

  it "has the correct answer_options" do
    expect(question.answer_options).to eq({
      "34" => { "value" => "Specialist retirement housing" },
      "35" => { "value" => "Extra care housing" },
      "36" => { "value" => "Sheltered housing for adults aged under 55 years" },
      "6" => { "value" => "Other supported housing" },
    })
  end
end
