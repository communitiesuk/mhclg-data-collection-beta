require "rails_helper"

RSpec.describe Form::Lettings::Questions::Age1Known, type: :model do
  subject(:question) { described_class.new(nil, question_definition, page) }

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

  it "has the correct type" do
    expect(question.type).to eq("radio")
  end

  it "is not marked as derived" do
    expect(question.derived?).to be false
  end

  it "has the correct answer_options" do
    expect(question.answer_options).to eq({
      "0" => { "value" => "Yes" },
      "1" => { "value" => "No" },
    })
  end

  it "has the correct check_answer_label" do
    expect(question.check_answer_label).to eq("")
  end

  it "has the correct id" do
    expect(question.id).to eq("age1_known")
  end

  it "has the correct header" do
    expect(question.header).to eq("Do you know the lead tenant’s age?")
  end

  it "has correct conditional for" do
    expect(question.conditional_for).to eq({
      "age1" => [0],
    })
  end

  it "has the correct hidden_in_check_answers" do
    expect(question.hidden_in_check_answers).to eq(
      {
        "depends_on" => [
          {
            "age1_known" => 0,
          },
          {
            "age1_known" => 1,
          },
        ],
      },
    )
  end

  it "has the correct check_answers_card_number" do
    expect(question.check_answers_card_number).to eq(1)
  end

  context "with 2023/24 form" do
    it "has the correct hint" do
      expect(question.hint_text).to eq("The ’lead’ or ’main’ tenant is the person in the household who does the most paid work. If several people do the same paid work, the lead tenant is whoever is the oldest.")
    end
  end

  context "with 2024/25 form" do
    before do
      allow(form).to receive(:start_year_after_2024?).and_return(true)
    end

    it "has the correct hint" do
      expect(question.hint_text).to eq("The ’lead’ or ’main’ tenant is the person in the household who does the most paid work. If several people do the same amount of paid work, the lead tenant is whoever is the oldest.")
    end
  end
end
