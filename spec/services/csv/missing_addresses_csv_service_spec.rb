require "rails_helper"

RSpec.describe Csv::MissingAddressesCsvService do
  let(:organisation) { create(:organisation, name: "Address test") }
  let(:user) { create(:user, organisation:, email: "testy@example.com") }
  let(:service) { described_class.new(organisation) }

  def replace_entity_ids(lettings_log, export_template)
    export_template.sub!(/\{id\}/, lettings_log.id.to_s)
  end

  describe "#create_missing_lettings_addresses_csv" do
    let!(:lettings_log) do
      create(:lettings_log,
             tenancycode: "tenancycode",
             propcode: "propcode",
             startdate: Time.zone.local(2023, 4, 5),
             created_by: user,
             owning_organisation: organisation,
             managing_organisation: organisation,
             address_line1: nil,
             town_or_city: nil,
             old_id: "old_id",
             old_form_id: "old_form_id",
             needstype: 1,
             uprn_known: 0)
    end

    context "when the organisation has logs with missing addresses" do
      it "returns a csv with relevant logs" do
        expected_content = replace_entity_ids(lettings_log, File.open("spec/fixtures/files/missing_lettings_logs_addresses.csv").read)
        csv = service.create_missing_lettings_addresses_csv
        expect(csv).to eq(expected_content)
      end
    end

    context "when the organisation only has supported housing logs with missing addresses" do
      before do
        lettings_log.update!(needstype: 2)
      end

      it "returns nil" do
        expect(service.create_missing_lettings_addresses_csv).to be_nil
      end
    end

    context "when the organisation only has logs with missing addresses from 2022" do
      before do
        lettings_log.update!(startdate: Time.zone.local(2022, 4, 5))
      end

      it "returns nil" do
        expect(service.create_missing_lettings_addresses_csv).to be_nil
      end
    end

    context "when the organisation has any address fields filled in" do
      before do
        lettings_log.update!(address_line1: "address_line1")
      end

      it "returns nil" do
        expect(service.create_missing_lettings_addresses_csv).to be_nil
      end
    end
  end

  describe "#create_missing_sales_addresses_csv" do
    let!(:sales_log) do
      create(:sales_log,
             purchid: "purchaser code",
             saledate: Time.zone.local(2023, 4, 5),
             created_by: user,
             owning_organisation: organisation,
             address_line1: nil,
             town_or_city: nil,
             old_id: "old_id",
             old_form_id: "old_form_id",
             uprn_known: 0)
    end

    context "when the organisation has logs with missing addresses" do
      it "returns a csv with relevant logs" do
        expected_content = replace_entity_ids(sales_log, File.open("spec/fixtures/files/missing_sales_logs_addresses.csv").read)
        csv = service.create_missing_sales_addresses_csv
        expect(csv).to eq(expected_content)
      end
    end

    context "when the organisation only has logs with missing addresses from 2022" do
      before do
        sales_log.update!(saledate: Time.zone.local(2022, 4, 5))
      end

      it "returns nil" do
        expect(service.create_missing_sales_addresses_csv).to be_nil
      end
    end

    context "when the organisation has any address fields filled in" do
      before do
        sales_log.update!(town_or_city: "town")
      end

      it "returns nil" do
        expect(service.create_missing_sales_addresses_csv).to be_nil
      end
    end
  end

  describe "#create_missing_lettings_town_or_city_csv" do
    let!(:lettings_log) do
      create(:lettings_log,
             tenancycode: "tenancycode",
             propcode: "propcode",
             startdate: Time.zone.local(2023, 4, 5),
             created_by: user,
             owning_organisation: organisation,
             managing_organisation: organisation,
             address_line1: "existing address",
             town_or_city: nil,
             old_id: "old_id",
             old_form_id: "old_form_id",
             needstype: 1,
             uprn_known: 0)
    end

    context "when the organisation has logs with missing town or city only" do
      it "returns a csv with relevant logs" do
        expected_content = replace_entity_ids(lettings_log, File.open("spec/fixtures/files/missing_lettings_logs_town_or_city.csv").read)
        csv = service.create_missing_lettings_town_or_city_csv
        expect(csv).to eq(expected_content)
      end
    end

    context "when the organisation only has supported housing logs with missing town or city only" do
      before do
        lettings_log.update!(needstype: 2)
      end

      it "returns nil" do
        expect(service.create_missing_lettings_town_or_city_csv).to be_nil
      end
    end

    context "when the organisation only has logs with missing town or city from 2022" do
      before do
        lettings_log.update!(startdate: Time.zone.local(2022, 4, 5))
      end

      it "returns nil" do
        expect(service.create_missing_lettings_town_or_city_csv).to be_nil
      end
    end

    context "when the organisation has any address field 1 not set" do
      before do
        lettings_log.update!(address_line1: nil)
      end

      it "returns nil" do
        expect(service.create_missing_lettings_town_or_city_csv).to be_nil
      end
    end
  end

  describe "#create_missing_sales_town_or_city_csv" do
    let!(:sales_log) do
      create(:sales_log,
             purchid: "purchaser code",
             saledate: Time.zone.local(2023, 4, 5),
             created_by: user,
             owning_organisation: organisation,
             address_line1: "existing address line 1",
             town_or_city: nil,
             old_id: "old_id",
             old_form_id: "old_form_id",
             uprn_known: 0)
    end

    context "when the organisation has logs with missing town_or_city only" do
      it "returns a csv with relevant logs" do
        expected_content = replace_entity_ids(sales_log, File.open("spec/fixtures/files/missing_sales_logs_town_or_city.csv").read)
        csv = service.create_missing_sales_town_or_city_csv
        expect(csv).to eq(expected_content)
      end
    end

    context "when the organisation only has logs with missing town_or_city only from 2022" do
      before do
        sales_log.update!(saledate: Time.zone.local(2022, 4, 5))
      end

      it "returns nil" do
        expect(service.create_missing_sales_town_or_city_csv).to be_nil
      end
    end

    context "when the organisation has any address fields not filled in" do
      before do
        sales_log.update!(address_line1: nil)
      end

      it "returns nil" do
        expect(service.create_missing_sales_town_or_city_csv).to be_nil
      end
    end
  end
end
