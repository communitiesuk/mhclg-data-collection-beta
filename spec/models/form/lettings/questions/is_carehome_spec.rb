require "rails_helper"

RSpec.describe Form::Lettings::Questions::IsCarehome, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page) }
  let(:subsection) { instance_double(Form::Subsection) }
  let(:form) { instance_double(Form) }

  before do
    allow(form).to receive(:start_year_after_2024?).and_return(false)
    allow(page).to receive(:subsection).and_return(subsection)
    allow(subsection).to receive(:form).and_return(form)
  end

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("is_carehome")
  end

  it "has the correct header" do
    expect(question.header).to eq("Is this accommodation a care home?")
  end

  it "has the correct check_answer_label" do
    expect(question.check_answer_label).to eq("Care home accommodation")
  end

  it "has the correct type" do
    expect(question.type).to eq("radio")
  end

  it "is not marked as derived" do
    expect(question.derived?).to be false
  end

  context "with 2023/24 form" do
    it "has the correct answer_options in the correct order" do
      expect(question.answer_options.map { |k, v| [k, v["value"]] }).to eq([
        %w[0 No],
        %w[1 Yes],
      ])
    end
  end

  context "with 2024/25 form" do
    before do
      allow(form).to receive(:start_year_after_2024?).and_return(true)
    end

    it "has the correct answer_options in the correct order" do
      expect(question.answer_options.map { |k, v| [k, v["value"]] }).to eq([
        %w[1 Yes],
        %w[0 No],
      ])
    end
  end

  it "has the correct check_answers_card_number" do
    expect(question.check_answers_card_number).to eq(0)
  end
end
