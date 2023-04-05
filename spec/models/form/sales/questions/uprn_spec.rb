require "rails_helper"

RSpec.describe Form::Sales::Questions::Uprn, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page) }

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("uprn")
  end

  it "has the correct header" do
    expect(question.header).to eq("What is the property's UPRN")
  end

  it "has the correct check_answer_label" do
    expect(question.check_answer_label).to eq("UPRN")
  end

  it "has the correct type" do
    expect(question.type).to eq("text")
  end

  it "is not marked as derived" do
    expect(question.derived?).to be false
  end

  it "has the correct question_number" do
    expect(question.question_number).to eq(14)
  end

  it "has the correct hint" do
    expect(question.hint_text).to eq("The Unique Property Reference Number (UPRN) is a unique number system created by Ordnance Survey and used by housing providers and sectors UK-wide. For example 10010457355.")
  end

  it "has the correct unanswered_error_message" do
    expect(question.unanswered_error_message).to eq("UPRN must be 12 digits or less")
  end

  describe "get_extra_check_answer_value" do
    context "when address is not present" do
      let(:log) { create(:sales_log) }

      it "returns nil" do
        expect(question.get_extra_check_answer_value(log)).to be_nil
      end
    end

    context "when address is present" do
      let(:log) do
        create(
          :sales_log,
          address_line1: "1, Test Street",
          town_or_city: "Test Town",
          county: "Test County",
          postcode_full: "AA1 1AA",
          la: "E09000003",
        )
      end

      it "returns formatted value" do
        expect(question.get_extra_check_answer_value(log)).to eq(
          "\n\n1, Test Street\nTest Town\nTest County\nAA1 1AA\nWestminster",
        )
      end
    end
  end

  describe "has the correct hidden_in_check_answers" do
    context "when uprn_known == 1" do
      let(:log) { create(:sales_log) }

      it "returns false" do
        log.uprn_known = 1
        expect(question.hidden_in_check_answers?(log)).to eq(false)
      end
    end

    context "when uprn_known != 1" do
      let(:log) { create(:sales_log, uprn_known: 0) }

      it "returns false" do
        expect(question.hidden_in_check_answers?(log)).to eq(true)
      end
    end
  end
end
