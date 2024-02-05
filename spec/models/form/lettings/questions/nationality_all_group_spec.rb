require "rails_helper"

RSpec.describe Form::Lettings::Questions::NationalityAllGroup, type: :model do
  subject(:question) { described_class.new(nil, nil, page) }

  let(:page) { instance_double(Form::Page) }

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("nationality_all_group")
  end

  it "has the correct header" do
    expect(question.header).to eq("What is the nationality of the lead tenant?")
  end

  it "has the correct check_answer_label" do
    expect(question.check_answer_label).to eq("Lead tenant’s nationality")
  end

  it "has the correct type" do
    expect(question.type).to eq("radio")
  end

  it "has the correct hint_text" do
    expect(question.hint_text).to eq("The lead tenant is the person in the household who does the most paid work. If several people do the same paid work, the lead tenant is whoever is the oldest.")
  end

  it "has the correct answer_options" do
    expect(question.answer_options).to eq({
      "826" => { "value" => "United Kingdom" },
      "12" => { "value" => "Other" },
      "0" => { "value" => "Tenant prefers not to say" },
    })
  end
end
