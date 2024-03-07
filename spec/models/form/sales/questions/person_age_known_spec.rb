require "rails_helper"

RSpec.describe Form::Sales::Questions::PersonAgeKnown, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page, person_index:) }

  let(:question_id) { "age3_known" }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page, subsection: instance_double(Form::Subsection, form: instance_double(Form, start_date: Time.zone.local(2023, 4, 1)))) }
  let(:person_index) { 2 }

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

  it "has the correct hint" do
    expect(question.hint_text).to be_nil
  end

  context "with person 2" do
    let(:question_id) { "age2_known" }
    let(:person_index) { 2 }

    it "has the correct id" do
      expect(question.id).to eq("age2_known")
    end

    it "has the correct header" do
      expect(question.header).to eq("Do you know person 2’s age?")
    end

    it "has the correct check_answer_label" do
      expect(question.check_answer_label).to eq("Person 2’s age known?")
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
    let(:question_id) { "age3_known" }
    let(:person_index) { 3 }

    it "has the correct id" do
      expect(question.id).to eq("age3_known")
    end

    it "has the correct header" do
      expect(question.header).to eq("Do you know person 3’s age?")
    end

    it "has the correct check_answer_label" do
      expect(question.check_answer_label).to eq("Person 3’s age known?")
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

  context "with person 4" do
    let(:question_id) { "age4_known" }
    let(:person_index) { 4 }

    it "has the correct id" do
      expect(question.id).to eq("age4_known")
    end

    it "has the correct header" do
      expect(question.header).to eq("Do you know person 4’s age?")
    end

    it "has the correct check_answer_label" do
      expect(question.check_answer_label).to eq("Person 4’s age known?")
    end

    it "has correct conditional for" do
      expect(question.conditional_for).to eq({
        "age4" => [0],
      })
    end

    it "has the correct hidden_in_check_answers" do
      expect(question.hidden_in_check_answers).to eq(
        {
          "depends_on" => [
            {
              "age4_known" => 0,
            },
            {
              "age4_known" => 1,
            },
          ],
        },
      )
    end

    it "has the correct check_answers_card_number" do
      expect(question.check_answers_card_number).to eq(4)
    end
  end

  context "with person 5" do
    let(:question_id) { "age5_known" }
    let(:person_index) { 5 }

    it "has the correct id" do
      expect(question.id).to eq("age5_known")
    end

    it "has the correct header" do
      expect(question.header).to eq("Do you know person 5’s age?")
    end

    it "has the correct check_answer_label" do
      expect(question.check_answer_label).to eq("Person 5’s age known?")
    end

    it "has correct conditional for" do
      expect(question.conditional_for).to eq({
        "age5" => [0],
      })
    end

    it "has the correct hidden_in_check_answers" do
      expect(question.hidden_in_check_answers).to eq(
        {
          "depends_on" => [
            {
              "age5_known" => 0,
            },
            {
              "age5_known" => 1,
            },
          ],
        },
      )
    end

    it "has the correct check_answers_card_number" do
      expect(question.check_answers_card_number).to eq(5)
    end
  end
end
