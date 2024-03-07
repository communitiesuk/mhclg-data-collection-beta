require "rails_helper"

RSpec.describe Form::Lettings::Questions::AddressSelection, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page) }
  let(:log) { create(:lettings_log, :in_progress, address_line1_input: "Address line 1", postcode_full_input: "AA1 1AA") }
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
    expect(question.id).to eq("address_selection")
  end

  it "has the correct header" do
    expect(question.header).to eq("Select the correct address")
  end

  it "has the correct check_answer_label" do
    expect(question.check_answer_label).to eq("Select the correct address")
  end

  it "has the correct question_number" do
    expect(question.question_number).to eq(nil)
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

  it "has the correct answer options" do
    stub_request(:get, /api.os.uk/)
      .to_return(status: 200, body: "", headers: {})

    expect(question.answer_options(log)).to eq({ "100" => { "value" => "The address is not listed, I want to enter the address manually" }, "0" => { "value" => "full address" }, "divider" => { "value" => true } })
  end

  it "has the correct displayed answer options" do
    stub_request(:get, /api.os.uk/)
      .to_return(status: 200, body: "", headers: {})

    expect(question.displayed_answer_options(log)).to eq({ "100" => { "value" => "The address is not listed, I want to enter the address manually" }, "0" => { "value" => "full address" }, "divider" => { "value" => true } })
  end

  it "has the correct inferred check answers value" do
    expect(question.inferred_check_answers_value).to be_nil
  end

  it "has the correct check_answers_card_number" do
    expect(question.check_answers_card_number).to be_nil
  end

  context "when the log has address options" do
    it "has the correct hidden_in_check_answers?" do
      stub_request(:get, /api.os.uk/)
        .to_return(status: 200, body: '{"results": {"0": "address_0", "1": "address_1", "2": "address_2"}}', headers: {})

      expect(question.hidden_in_check_answers?(log)).to eq(false)
    end
  end

  context "when the log does not have address options" do
    before do
      allow(address_client_instance).to receive(:result).and_return(nil)
    end

    it "has the correct hidden_in_check_answers?" do
      stub_request(:get, /api.os.uk/)
        .to_return(status: 200, body: "", headers: {})

      expect(question.hidden_in_check_answers?(log)).to eq(true)
    end
  end
end
