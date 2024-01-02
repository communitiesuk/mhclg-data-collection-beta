require "rails_helper"

RSpec.describe Form::Lettings::Questions::UprnConfirmation, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page) }

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("uprn_confirmed")
  end

  it "has the correct header" do
    expect(question.header).to eq("Is this the property address?")
  end

  it "has the correct check_answer_label" do
    expect(question.check_answer_label).to eq("Is this the right address?")
  end

  it "has the correct type" do
    expect(question.type).to eq("radio")
  end

  it "is not marked as derived" do
    expect(question.derived?).to be false
  end

  it "has the correct hint" do
    expect(question.hint_text).to be_nil
  end

  it "has the correct unanswered_error_message" do
    expect(question.unanswered_error_message).to eq("You must answer is this the right address?")
  end

  describe "notification_banner" do
    context "when address is not present" do
      it "returns nil" do
        log = create(:lettings_log)

        expect(question.notification_banner(log)).to be_nil
      end
    end

    context "when address is present" do
      it "returns formatted value" do
        log = create(:lettings_log, :setup_completed, address_line1: "1, Test Street", town_or_city: "Test Town", postcode_full: "AA1 1AA", uprn: "1", uprn_known: 1)

        expect(question.notification_banner(log)).to eq(
          {
            heading: "1, Test Street\nAA1 1AA\nTest Town",
            title: "UPRN: 1",
          },
        )
      end
    end
  end

  describe "has the correct hidden_in_check_answers" do
    context "when uprn_known != 1 && uprn_confirmed == nil" do
      let(:log) { create(:lettings_log, uprn_known: 0, uprn_confirmed: nil) }

      it "returns true" do
        expect(question.hidden_in_check_answers?(log)).to eq(true)
      end
    end

    context "when uprn_known == 1 && uprn_confirmed == nil" do
      let(:log) { create(:lettings_log, :completed, uprn_known: 1, uprn: 1, uprn_confirmed: nil) }

      it "returns false" do
        expect(question.hidden_in_check_answers?(log)).to eq(false)
      end
    end

    context "when uprn_known != 1 && uprn_confirmed == 1" do
      let(:log) { create(:lettings_log) }

      it "returns true" do
        log.uprn_known = 1
        log.uprn_confirmed = 1
        expect(question.hidden_in_check_answers?(log)).to eq(true)
      end
    end
  end
end
