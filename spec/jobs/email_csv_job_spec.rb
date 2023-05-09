require "rails_helper"

describe EmailCsvJob do
  include Helpers

  test_url = :test_url

  let(:job) { described_class.new }
  let(:user) { FactoryBot.create(:user) }
  let(:organisation) { user.organisation }
  let(:other_organisation) { FactoryBot.create(:organisation) }
  let(:fake_2021_2022_form) { Form.new("spec/fixtures/forms/2021_2022.json") }

  before do
    allow(FormHandler.instance).to receive(:current_lettings_form).and_return(fake_2021_2022_form)
  end

  context "when a log exists" do
    let!(:lettings_log) do
      FactoryBot.create(
        :lettings_log,
        created_by: user,
        ecstat1: 1,
      )
    end

    let(:storage_service) { instance_double(Storage::S3Service) }
    let(:mailer) { instance_double(CsvDownloadMailer) }
    let(:sales_log_csv_service) { instance_double(Csv::SalesLogCsvService) }

    before do
      FactoryBot.create(:lettings_log,
                        :completed,
                        created_by: user,
                        startdate: Time.zone.local(2022, 5, 1),
                        voiddate: Time.zone.local(2022, 5, 1),
                        mrcdate: Time.zone.local(2022, 5, 1))

      allow(Storage::S3Service).to receive(:new).and_return(storage_service)
      allow(storage_service).to receive(:write_file)
      allow(storage_service).to receive(:get_presigned_url).and_return(test_url)

      allow(Csv::SalesLogCsvService).to receive(:new).and_return(sales_log_csv_service)
      allow(sales_log_csv_service).to receive(:prepare_csv).and_return("")

      allow(CsvDownloadMailer).to receive(:new).and_return(mailer)
      allow(mailer).to receive(:send_csv_download_mail)
    end

    context "when exporting lettings logs" do
      it "uses an appropriate filename in S3" do
        expect(storage_service).to receive(:write_file).with(/lettings-logs-.*\.csv/, anything)
        job.perform(user)
      end

      it "includes the organisation name in the filename when one is provided" do
        expect(storage_service).to receive(:write_file).with(/lettings-logs-#{organisation.name}-.*\.csv/, anything)
        job.perform(user, nil, {}, nil, organisation)
      end
    end

    context "when exporting sales logs" do
      it "uses an appropriate filename in S3" do
        expect(storage_service).to receive(:write_file).with(/sales-logs-.*\.csv/, anything)
        job.perform(user, nil, {}, nil, nil, nil, "sales")
      end

      it "includes the organisation name in the filename when one is provided" do
        expect(storage_service).to receive(:write_file).with(/sales-logs-#{organisation.name}-.*\.csv/, anything)
        job.perform(user, nil, {}, nil, organisation, nil, "sales")
      end

      it "creates a SalesLogCsvService with the correct export type" do
        expect(Csv::SalesLogCsvService).to receive(:new).with(export_type: "labels")
        codes_only = false
        job.perform(user, nil, {}, nil, nil, codes_only, "sales")
        expect(Csv::SalesLogCsvService).to receive(:new).with(export_type: "codes")
        codes_only = true
        job.perform(user, nil, {}, nil, nil, codes_only, "sales")
      end
    end

    it "sends an E-mail with the presigned URL and duration" do
      expect(mailer).to receive(:send_csv_download_mail).with(user, test_url, instance_of(Integer))
      job.perform(user)
    end

    context "when writing to S3" do
      before do
        FactoryBot.create_list(:lettings_log, 4, owning_organisation: other_organisation)
        FactoryBot.create(:lettings_log, owning_organisation: other_organisation, status: "pending", skip_update_status: true)
      end

      def expect_csv
        expect(storage_service).to receive(:write_file) do |_filename, data|
          # Ignore byte order marker
          csv = CSV.parse(data[1..])
          yield(csv)
        end
      end

      it "writes CSV data with headers" do
        expect_csv do |csv|
          expect(csv.first.first).to eq("id")
          expect(csv.second.first).to eq(lettings_log.id.to_s)
        end

        job.perform(user)
      end

      context "when there is no organisation provided" do
        it "only writes logs from the user's organisation" do
          expect_csv do |csv|
            # Headings + 2 rows
            expect(csv.count).to eq(3)
          end

          job.perform(user)
        end
      end

      context "when the user is support and an organisation is provided" do
        let(:user) { FactoryBot.create(:user, :support) }

        it "only writes logs from that organisation" do
          expect_csv do |csv|
            # other organisation => Headings + 4 rows
            expect(csv.count).to eq(5)
          end

          job.perform(user, nil, {}, nil, other_organisation)
        end
      end

      it "writes answer labels rather than values" do
        expect_csv do |csv|
          expect(csv.second[19]).to eq("Full-time – 30 hours or more")
        end

        job.perform(user)
      end

      it "writes filtered logs" do
        expect_csv do |csv|
          expect(csv.count).to eq(2)
        end

        job.perform(user, nil, { status: "completed" })
      end

      it "writes searched logs" do
        expect_csv do |csv|
          expect(csv.count).to eq(LettingsLog.search_by(lettings_log.id.to_s).count + 1)
        end

        job.perform(user, lettings_log.id.to_s)
      end

      context "when both filter and search applied" do
        let(:postcode) { "XX1 1TG" }

        before do
          FactoryBot.create(:lettings_log, :in_progress, postcode_full: postcode, owning_organisation: organisation, created_by: user)
          FactoryBot.create(:lettings_log, :completed, postcode_full: postcode, owning_organisation: organisation, created_by: user)
        end

        it "downloads logs matching both csv and filter logs" do
          expect_csv do |csv|
            expect(csv.count).to eq(2)
          end

          job.perform(user, postcode, { status: "completed" })
        end
      end

      context "when there are more than 20 logs" do
        before do
          FactoryBot.create_list(:lettings_log, 26, owning_organisation: organisation)
        end

        it "does not paginate, it downloads all the user's logs" do
          expect_csv do |csv|
            # Heading + 2 + 26
            expect(csv.count).to eq(29)
          end

          job.perform(user)
        end
      end
    end
  end
end
