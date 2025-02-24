require "rails_helper"

RSpec.describe BulkUpload::Sales::LogCreator do
  subject(:service) { described_class.new(bulk_upload:, path: "") }

  let(:owning_org) { create(:organisation, old_visible_id: 123) }
  let(:user) { create(:user, organisation: owning_org) }
  let(:log) { build(:sales_log, :completed, assigned_to: user, owning_organisation: owning_org, managing_organisation: owning_org) }

  [2023, 2024, 2025].each do |year|
    context "when #{year}" do
      let(:bulk_upload) { create(:bulk_upload, :sales, user:, year:) }
      let(:year_csv_parser) { instance_double("BulkUpload::Sales::Year#{year}::CsvParser".constantize) }
      let(:year_row_parser) { instance_double("BulkUpload::Sales::Year#{year}::RowParser".constantize) }

      before do
        allow("BulkUpload::Sales::Year#{year}::CsvParser".constantize).to receive(:new).and_return(year_csv_parser)
        allow(year_csv_parser).to receive(:row_parsers).and_return([year_row_parser])
        allow(year_row_parser).to receive(:log).and_return(log)
        allow(year_row_parser).to receive(:bulk_upload=).and_return(true)
        allow(year_row_parser).to receive(:valid?).and_return(true)
        allow(year_row_parser).to receive(:blank_row?).and_return(false)
      end

      it "creates a parser for the correct year" do
        # This would fail without parser stubs, so the parser must be for the expected year
        expect { service.call }.to change(SalesLog, :count)
      end
    end
  end

  # Apart from picking the correct year's parser, everything else is year-independent
  context "when 2024" do
    let(:bulk_upload) { create(:bulk_upload, :sales, user:, year: 2024) }
    let(:csv_parser) { instance_double(BulkUpload::Sales::Year2024::CsvParser) }
    let(:row_parser) { instance_double(BulkUpload::Sales::Year2024::RowParser) }

    before do
      allow(BulkUpload::Sales::Year2024::CsvParser).to receive(:new).and_return(csv_parser)
      allow(csv_parser).to receive(:row_parsers).and_return([row_parser])
      allow(row_parser).to receive(:log).and_return(log)
      allow(row_parser).to receive(:bulk_upload=).and_return(true)
      allow(row_parser).to receive(:valid?).and_return(true)
      allow(row_parser).to receive(:blank_row?).and_return(false)
    end

    describe "#call" do
      context "when a valid csv with new log" do
        it "creates a new log" do
          expect { service.call }.to change(SalesLog, :count)
        end

        it "create a log with pending status" do
          service.call
          expect(SalesLog.last.status).to eql("pending")
        end

        it "associates log with bulk upload" do
          service.call

          log = SalesLog.last
          expect(log.bulk_upload).to eql(bulk_upload)
          expect(bulk_upload.sales_logs).to include(log)
        end

        it "sets the creation method" do
          service.call

          expect(SalesLog.last.creation_method_bulk_upload?).to be true
        end
      end

      context "when a valid csv with several blank rows" do
        before do
          allow(row_parser).to receive(:blank_row?).and_return(true)
        end

        it "ignores them and does not create the logs" do
          expect { service.call }.not_to change(SalesLog, :count)
        end
      end

      context "when a valid csv with row with one invalid non setup field" do
        let(:log) do
          build(
            :sales_log,
            :completed,
            age1: 5,
            owning_organisation: owning_org,
            assigned_to: user,
            managing_organisation: owning_org,
          )
        end

        it "creates the log" do
          expect { service.call }.to change(SalesLog, :count).by(1)
        end

        it "blanks invalid field" do
          service.call

          record = SalesLog.last
          expect(record.age1).to be_blank
        end
      end

      context "when a valid csv with row with compound errors on non setup field" do
        let(:log) do
          build(
            :sales_log,
            :completed,
            owning_organisation: owning_org,
            assigned_to: user,
            managing_organisation: owning_org,
            ownershipsch: 2,
            value: 200_000,
            deposit: 10_000,
            mortgageused: 1,
            mortgage: 100_000,
            grant: 10_000,
          )
        end

        it "creates the log" do
          expect { service.call }.to change(SalesLog, :count).by(1)
        end

        it "blanks invalid field" do
          service.call

          record = SalesLog.last
          expect(record.value).to be_blank
          expect(record.deposit).to be_blank
          expect(record.mortgage).to be_blank
          expect(record.grant).to be_blank
        end
      end

      context "when pre-creating logs" do
        it "creates a new log" do
          expect { service.call }.to change(SalesLog, :count)
        end

        it "creates a log with correct states" do
          service.call

          last_log = SalesLog.last

          expect(last_log.status).to eql("pending")
          expect(last_log.status_cache).to eql("completed")
        end
      end

      context "when valid csv with existing log" do
        xit "what should happen?"
      end

      context "with a valid csv and soft validations" do
        let(:log) do
          build(
            :sales_log,
            :completed,
            age1: 30,
            age1_known: 0,
            ecstat1: 5,
            owning_organisation: owning_org,
            assigned_to: user,
            managing_organisation: owning_org,
          )
        end

        it "creates a new log" do
          expect { service.call }.to change(SalesLog, :count)
        end

        it "creates a log with pending status" do
          service.call
          expect(SalesLog.last.status).to eql("pending")
        end

        it "does not set unanswered soft validations" do
          service.call

          log = SalesLog.last
          expect(log.age1).to be(30)
          expect(log.ecstat1).to be(5)
          expect(log.retirement_value_check).to be(nil)
        end
      end
    end
  end
end
