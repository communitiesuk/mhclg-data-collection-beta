require "rails_helper"

RSpec.describe Form::Sales::Questions::UprnSelection, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page, skip_href: "skip_href") }
  let(:log) { build(:sales_log, :in_progress, address_line1_input: "Address line 1", postcode_full_input: "AA1 1AA") }
  let(:address_client_instance) { AddressClient.new(log.address_string) }

  before do
    allow(AddressClient).to receive(:new).and_return(address_client_instance)
    allow(address_client_instance).to receive(:call)
    allow(address_client_instance).to receive(:result).and_return([{
      "UPRN" => "UPRN",
      "UDPRN" => "UDPRN",
      "ADDRESS" => "full address",
      "SUB_BUILDING_NAME" => "0",
      "BUILDING_NAME" => "building name",
      "THOROUGHFARE_NAME" => "thoroughfare",
      "POST_TOWN" => "posttown",
      "POSTCODE" => "postcode",
    }])
  end

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("uprn_selection")
  end

  it "has the correct question_number" do
    expect(question.question_number).to eq(nil)
  end

  it "has the correct type" do
    expect(question.type).to eq("radio")
  end

  it "is not marked as derived" do
    expect(question.derived?(nil)).to be false
  end

  it "has the correct answer options" do
    stub_request(:get, /api\.os\.uk/)
      .to_return(status: 200, body: "", headers: {})

    expect(question.answer_options(log)).to eq({ "uprn_not_listed" => { "value" => "The address is not listed, I want to enter the address manually" }, "UPRN" => { "value" => "full address" }, "divider" => { "value" => true } })
  end

  it "has the correct displayed answer options" do
    stub_request(:get, /api\.os\.uk/)
      .to_return(status: 200, body: "", headers: {})

    expect(question.displayed_answer_options(log)).to eq({ "uprn_not_listed" => { "value" => "The address is not listed, I want to enter the address manually" }, "UPRN" => { "value" => "full address" }, "divider" => { "value" => true } })
  end

  it "has the correct inferred check answers value" do
    expect(question.inferred_check_answers_value).to be_nil
  end

  it "has the correct check_answers_card_number" do
    expect(question.check_answers_card_number).to be_nil
  end

  context "when the log has address options" do
    it "has the correct hidden_in_check_answers?" do
      stub_request(:get, /api\.os\.uk/)
        .to_return(status: 200, body: '{"results": {"0": "address_0", "1": "address_1", "2": "address_2"}}', headers: {})

      expect(question.hidden_in_check_answers?(log)).to eq(false)
    end
  end

  context "when the log does not have address options" do
    before do
      allow(address_client_instance).to receive(:result).and_return(nil)
    end

    it "has the correct hidden_in_check_answers?" do
      stub_request(:get, /api\.os\.uk/)
        .to_return(status: 200, body: "", headers: {})

      expect(question.hidden_in_check_answers?(log)).to eq(true)
    end
  end

  context "when the log has address line 1 input only" do
    before do
      allow(address_client_instance).to receive(:result).and_return(nil)
      log.address_line1_input = "Address line 1"
      log.postcode_full_input = nil
      log.save!(validate: false)
    end

    it "has the correct input_playback" do
      expect(question.input_playback(log)).to eq("0 addresses found for <strong>Address line 1</strong>. <a href=\"skip_href\">Search again</a>")
    end
  end

  context "when the log has postcode input only" do
    before do
      allow(address_client_instance).to receive(:result).and_return(nil)
      log.address_line1_input = nil
      log.postcode_full_input = "A1 1AA"
      log.save!(validate: false)
    end

    it "has the correct input_playback" do
      expect(question.input_playback(log)).to eq("0 addresses found for <strong>A1 1AA</strong>. <a href=\"skip_href\">Search again</a>")
    end
  end

  context "when the log has address line 1 and postcode inputs" do
    before do
      log.address_line1_input = "Address line 1"
      log.postcode_full_input = "A1 1AA"
      log.save!(validate: false)
    end

    it "has the correct input_playback" do
      expect(question.input_playback(log)).to eq("1 address found for <strong>Address line 1</strong> and <strong>A1 1AA</strong>. <a href=\"skip_href\">Search again</a>")
    end
  end
end
