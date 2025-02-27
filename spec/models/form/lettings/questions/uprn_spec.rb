require "rails_helper"

RSpec.describe Form::Lettings::Questions::Uprn, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page, subsection: instance_double(Form::Subsection, form: instance_double(Form, start_date: Time.zone.local(2023, 4, 1)))) }

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("uprn")
  end

  it "has the correct type" do
    expect(question.type).to eq("text")
  end

  it "is not marked as derived" do
    expect(question.derived?(nil)).to be false
  end

  it "has the correct question_number" do
    expect(question.question_number).to eq(11)
  end

  it "has the correct unanswered_error_message" do
    expect(question.unanswered_error_message).to eq(I18n.t("validations.lettings.property.uprn.invalid"))
  end

  describe "get_extra_check_answer_value" do
    context "when address is not present" do
      let(:log) { create(:lettings_log) }

      it "returns nil" do
        expect(question.get_extra_check_answer_value(log)).to be_nil
      end
    end

    context "when address is present" do
      let(:log) do
        create(
          :lettings_log,
          :in_progress,
          address_line1: "1, Test Street",
          town_or_city: "Test Town",
          county: "Test County",
          postcode_full: "AA1 1AA",
          la: "E09000003",
          uprn_known:,
          uprn:,
          manual_address_entry_selected:,
        )
      end

      context "when uprn known nil" do
        let(:uprn_known) { nil }
        let(:uprn) { nil }
        let(:manual_address_entry_selected) { true }

        it "returns formatted value" do
          expect(question.get_extra_check_answer_value(log)).to be_nil
        end
      end

      context "when uprn known" do
        let(:uprn_known) { 1 }
        let(:uprn) { 1 }
        let(:manual_address_entry_selected) { false }

        it "returns formatted value" do
          expect(question.get_extra_check_answer_value(log)).to eq(
            "\n\n1, Test Street\nTest Town\nAA1 1AA\nWestminster",
          )
        end
      end

      context "when uprn not known" do
        let(:uprn_known) { 0 }
        let(:uprn) { nil }
        let(:manual_address_entry_selected) { true }

        it "returns formatted value" do
          expect(question.get_extra_check_answer_value(log)).to be_nil
        end
      end
    end
  end

  it "has the correct inferred_check_answers_value" do
    expect(question.inferred_check_answers_value).to eq([{
      "condition" => {
        "uprn_known" => 0,
      },
      "value" => "Not known",
    }])
  end
end
