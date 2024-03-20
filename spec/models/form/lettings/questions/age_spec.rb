require "rails_helper"

RSpec.describe Form::Lettings::Questions::Age, type: :model do
  subject(:question) { described_class.new(nil, question_definition, page, person_index:, person_type:) }

  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page, subsection: instance_double(Form::Subsection, form: instance_double(Form, start_date: Time.zone.local(2023, 4, 4), start_year_after_2024?: false))) }
  let(:person_index) { 2 }
  let(:person_type) { "non_child" }

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct header" do
    expect(question.header).to eq("Age")
  end

  it "has the correct type" do
    expect(question.type).to eq("numeric")
  end

  it "is not marked as derived" do
    expect(question.derived?).to be false
  end

  context "when child" do
    let(:person_type) { "child" }

    it "has the correct hint" do
      expect(question.hint_text).to eq("For a child under 1, enter 1")
    end
  end

  context "when not child" do
    it "has no hint" do
      expect(question.hint_text).to be nil
    end
  end

  it "has the correct min" do
    expect(question.min).to eq(1)
  end

  it "has the correct max" do
    expect(question.max).to eq(120)
  end

  it "has the correct width" do
    expect(question.width).to eq(2)
  end

  context "with person 2" do
    it "has the correct id" do
      expect(question.id).to eq("age2")
    end

    it "has the correct check_answer_label" do
      expect(question.check_answer_label).to eq("Person 2’s age")
    end

    it "has the correct inferred check answers value" do
      expect(question.inferred_check_answers_value).to eq([
        {
          "condition" => { "age2_known" => 1 },
          "value" => "Not known",
        },
      ])
    end

    it "has the correct check_answers_card_number" do
      expect(question.check_answers_card_number).to eq(2)
    end
  end

  context "with person 3" do
    let(:person_index) { 3 }

    it "has the correct id" do
      expect(question.id).to eq("age3")
    end

    it "has the correct check_answer_label" do
      expect(question.check_answer_label).to eq("Person 3’s age")
    end

    it "has the correct inferred check answers value" do
      expect(question.inferred_check_answers_value).to eq([
        {
          "condition" => { "age3_known" => 1 },
          "value" => "Not known",
        },
      ])
    end

    it "has the correct check_answers_card_number" do
      expect(question.check_answers_card_number).to eq(3)
    end
  end
end
