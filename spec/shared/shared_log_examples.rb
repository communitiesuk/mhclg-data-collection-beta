require "rails_helper"

# rubocop:disable RSpec/AnyInstance
RSpec.shared_examples "shared log examples" do |log_type|
  describe "status" do
    let(:empty_log) { create(log_type) }
    let(:in_progress_log) { create(log_type, :in_progress) }
    let(:completed_log) { create(log_type, :completed) }

    it "is set to not started for an empty #{log_type} log" do
      expect(empty_log.not_started?).to be(true)
      expect(empty_log.in_progress?).to be(false)
      expect(empty_log.completed?).to be(false)
      expect(empty_log.deleted?).to be(false)
    end

    it "is set to in progress for a started #{log_type} log" do
      expect(in_progress_log.in_progress?).to be(true)
      expect(in_progress_log.not_started?).to be(false)
      expect(in_progress_log.completed?).to be(false)
      expect(in_progress_log.deleted?).to be(false)
    end

    it "is set to completed for a completed #{log_type} log" do
      expect(completed_log.in_progress?).to be(false)
      expect(completed_log.not_started?).to be(false)
      expect(completed_log.completed?).to be(true)
      expect(completed_log.deleted?).to be(false)
    end
  end

  describe "discard!" do
    around do |example|
      Timecop.freeze(Time.zone.local(2022, 1, 1)) do
        example.run
      end
      Timecop.return
    end

    let(:log) { create(log_type) }

    it "updates discarded at with current time" do
      expect { log.discard! }.to change { log.reload.discarded_at }.from(nil).to(Time.zone.now)
    end

    it "updates status to deleted" do
      expect { log.discard! }.to change { log.reload.status }.to("deleted")
    end
  end

  describe "#process_uprn_change!" do
    context "when UPRN set to a value" do
      let(:log) do
        log = build(
          log_type,
          uprn: "123456789",
          uprn_confirmed: 1,
          uprn_known: 1,
          county: "county",
          postcode_full: nil,
        )
        log.save!(validate: false)
        log
      end

      it "updates log fields" do
        log.uprn = "1111111"

        allow_any_instance_of(UprnClient).to receive(:call)
        allow_any_instance_of(UprnClient).to receive(:result).and_return({
          "UPRN" => "UPRN",
          "UDPRN" => "UDPRN",
          "ADDRESS" => "full address",
          "SUB_BUILDING_NAME" => "0",
          "BUILDING_NAME" => "building name",
          "THOROUGHFARE_NAME" => "thoroughfare",
          "POST_TOWN" => "posttown",
          "POSTCODE" => "postcode",
        })

        expect { log.process_uprn_change! }.to change(log, :address_line1).from(nil).to("0, Building Name, Thoroughfare")
        .and change(log, :town_or_city).from(nil).to("Posttown")
        .and change(log, :postcode_full).from(nil).to("POSTCODE")
        .and change(log, :county).from("county").to(nil)
      end
    end

    context "when UPRN nil" do
      let(:log) { create(log_type, uprn: nil) }

      it "does not update log" do
        expect { log.process_uprn_change! }.not_to change(log, :attributes)
      end
    end

    context "when service errors" do
      let(:log) { build(log_type, :in_progress, uprn_known: 1, uprn: "123456789", uprn_confirmed: 1) }
      let(:error_message) { "error" }

      it "adds error to log" do
        allow_any_instance_of(UprnClient).to receive(:call)
        allow_any_instance_of(UprnClient).to receive(:error).and_return(error_message)

        expect { log.process_uprn_change! }.to change { log.errors[:uprn] }.from([]).to([error_message])
                                                                           .and change { log.errors[:uprn_selection] }.from([]).to([error_message])
      end
    end
  end

  describe "#process_address_change!" do
    context "when address_line1_input and postcode_full_input set to a value" do
      let(:log) do
        log = build(
          log_type,
          uprn_selection: "UPRN",
          address_line1: "Address line 1",
          postcode_full: "AA1 1AA",
          county: "county",
        )
        log.save!(validate: false)
        log
      end

      it "updates log fields" do
        log.address_line1_input = "New address line 1"
        log.postcode_full_input = "BB2 2BB"

        allow_any_instance_of(AddressClient).to receive(:call)
        allow_any_instance_of(AddressClient).to receive(:result).and_return([{
          "UPRN" => "UPRN",
          "UDPRN" => "UDPRN",
          "ADDRESS" => "full address",
          "SUB_BUILDING_NAME" => "0",
          "BUILDING_NAME" => "building name",
          "THOROUGHFARE_NAME" => "thoroughfare",
          "POST_TOWN" => "posttown",
          "POSTCODE" => "postcode",
        }])

        allow_any_instance_of(UprnClient).to receive(:call)
        allow_any_instance_of(UprnClient).to receive(:result).and_return({
          "UPRN" => "UPRN",
          "UDPRN" => "UDPRN",
          "ADDRESS" => "full address",
          "SUB_BUILDING_NAME" => "0",
          "BUILDING_NAME" => "building name",
          "THOROUGHFARE_NAME" => "thoroughfare",
          "POST_TOWN" => "posttown",
          "POSTCODE" => "postcode",
        })

        expect { log.process_address_change! }.to change(log, :address_line1).from("Address line 1").to("0, Building Name, Thoroughfare")
                                              .and change(log, :town_or_city).from(nil).to("Posttown")
                                              .and change(log, :postcode_full).from("AA1 1AA").to("POSTCODE")
                                              .and change(log, :uprn_confirmed).from(nil).to(1)
                                              .and change(log, :uprn).from(nil).to("UPRN")
                                              .and change(log, :uprn_known).from(nil).to(1)
                                              .and change(log, :county).from("county").to(nil)
      end
    end

    context "when address inputs are nil" do
      let(:log) { create(log_type, uprn_selection: nil, address_line1_input: nil, postcode_full_input: nil) }

      it "does not update log" do
        expect { log.process_address_change! }.not_to change(log, :attributes)
      end
    end

    context "when service errors" do
      let(:log) { build(log_type, :in_progress, uprn_selection: "UPRN", address_line1_input: "123", postcode_full_input: "AA1 1AA") }
      let(:error_message) { "error" }

      it "adds error to log" do
        allow_any_instance_of(AddressClient).to receive(:call)
        allow_any_instance_of(AddressClient).to receive(:error).and_return(error_message)
        allow_any_instance_of(UprnClient).to receive(:call)
        allow_any_instance_of(UprnClient).to receive(:error).and_return(error_message)

        expect { log.process_address_change! }.to change { log.errors[:uprn_selection] }.from([]).to([error_message])
                                                    .and change { log.errors[:uprn_selection] }.from([]).to([error_message])
      end
    end
  end
end
# rubocop:enable RSpec/AnyInstance
