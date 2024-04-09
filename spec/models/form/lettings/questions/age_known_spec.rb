require "rails_helper"

RSpec.describe Form::Lettings::Questions::AgeKnown, type: :model do
  subject(:question) { described_class.new(nil, question_definition, page, person_index:) }

  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page, subsection: instance_double(Form::Subsection, form: instance_double(Form, start_date: Time.zone.local(2023, 4, 4)))) }
  let(:person_index) { 2 }

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
      "0" => { "value" => "Yes" },
      "1" => { "value" => "No" },
    })
  end

  it "has the correct hint" do
    expect(question.hint_text).to eq("")
  end

  it "has the correct check_answer_label" do
    expect(question.check_answer_label).to eq("")
  end

  context "with person 2" do
    it "has the correct id" do
      expect(question.id).to eq("age2_known")
    end

    it "has the correct header" do
      expect(question.header).to eq("Do you know person 2’s age?")
    end

    it "has correct conditional for" do
      expect(question.conditional_for).to eq({
        "age2" => [0],
      })
    end

    it "has the correct hidden_in_check_answers" do
      expect(question.hidden_in_check_answers).to eq(
        {
          "depends_on" => [
            {
              "age2_known" => 0,
            },
            {
              "age2_known" => 1,
            },
          ],
        },
      )
    end

    it "has the correct check_answers_card_number" do
      expect(question.check_answers_card_number).to eq(2)
    end
  end

  context "with person 3" do
    let(:person_index) { 3 }

    it "has the correct id" do
      expect(question.id).to eq("age3_known")
    end

    it "has the correct header" do
      expect(question.header).to eq("Do you know person 3’s age?")
    end

    it "has correct conditional for" do
      expect(question.conditional_for).to eq({
        "age3" => [0],
      })
    end

    it "has the correct hidden_in_check_answers" do
      expect(question.hidden_in_check_answers).to eq(
        {
          "depends_on" => [
            {
              "age3_known" => 0,
            },
            {
              "age3_known" => 1,
            },
          ],
        },
      )
    end

    it "has the correct check_answers_card_number" do
      expect(question.check_answers_card_number).to eq(3)
    end
  end
end
