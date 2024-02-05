require "rails_helper"

RSpec.describe Form::Lettings::Questions::GenderIdentity1, type: :model do
  subject(:question) { described_class.new(nil, question_definition, page) }

  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page) }
  let(:subsection) { instance_double(Form::Subsection) }
  let(:form) { instance_double(Form) }

  before do
    allow(page).to receive(:subsection).and_return(subsection)
    allow(subsection).to receive(:form).and_return(form)
  end

  it "has the correct id" do
    expect(question.id).to eq("sex1")
  end

  it "has the correct header" do
    expect(question.header).to eq("Which of these best describes the lead tenant’s gender identity?")
  end

  it "has the correct check_answer_label" do
    expect(question.check_answer_label).to eq("Lead tenant’s gender identity")
  end

  it "has the correct check_answers_card_number" do
    expect(question.check_answers_card_number).to eq(1)
  end

  it "has the correct type" do
    expect(question.type).to eq("radio")
  end

  it "is not marked as derived" do
    expect(question.derived?).to be false
  end

  it "has the correct answer_options" do
    expect(question.answer_options).to eq({
      "F" => { "value" => "Female" },
      "M" => { "value" => "Male" },
      "X" => { "value" => "Non-binary" },
      "divider" => { "value" => true },
      "R" => { "value" => "Tenant prefers not to say" },
    })
  end

  context "with form year before 2024" do
    before do
      allow(form).to receive(:start_year_after_2024?).and_return(false)
    end

    it "has the correct hint" do
      expect(question.hint_text).to eq("The lead tenant is the person in the household who does the most paid work. If several people do the same paid work, the lead tenant is whoever is the oldest.")
    end
  end

  context "with form year >= 2024" do
    before do
      allow(form).to receive(:start_year_after_2024?).and_return(true)
    end

    it "has the correct hint" do
      expect(question.hint_text).to eq("This should be however they personally choose to identify from the options below. This may or may not be the same as their biological sex or the sex they were assigned at birth.")
    end
  end
end
