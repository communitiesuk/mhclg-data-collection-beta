require "rails_helper"

RSpec.describe Form::Lettings::Questions::Renewal, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page) }
  let(:subsection) { instance_double(Form::Subsection) }
  let(:form) { instance_double(Form, start_date: Time.zone.local(2023, 4, 1)) }

  before do
    allow(form).to receive(:start_year_after_2024?).and_return(false)
    allow(page).to receive(:subsection).and_return(subsection)
    allow(subsection).to receive(:form).and_return(form)
  end

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("renewal")
  end

  it "has the correct header" do
    expect(question.header).to eq("Is this letting a renewal?")
  end

  it "has the correct check_answer_label" do
    expect(question.check_answer_label).to eq("Property renewal")
  end

  it "has the correct type" do
    expect(question.type).to eq("radio")
  end

  it "has the correct hint_text" do
    expect(question.hint_text).to eq("A renewal is a letting to the same tenant in the same property. If the property was previously being used as temporary accommodation, then answer 'no'")
  end

  it "has the correct answer_options" do
    expect(question.answer_options).to eq({
      "1" => { "value" => "Yes" },
      "0" => { "value" => "No" },
    })
  end

  it "is not marked as derived" do
    expect(question.derived?(nil)).to be false
  end

  context "with collection year on or after 2024" do
    before do
      allow(form).to receive(:start_year_after_2024?).and_return(true)
    end

    it "has the correct header" do
      expect(question.header).to eq("Is this letting a renewal of social housing to the same tenant in the same property?")
    end

    it "has the correct hint_text" do
      expect(question.hint_text).to eq("If the property was previously being used as temporary accommodation, then answer 'no'")
    end
  end
end
