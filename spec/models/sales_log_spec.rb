require "rails_helper"
require "shared/shared_examples_for_derived_fields"
require "shared/shared_log_examples"

# rubocop:disable RSpec/MessageChain
RSpec.describe SalesLog, type: :model do
  let(:owning_organisation) { create(:organisation) }
  let(:created_by_user) { create(:user) }

  include_examples "shared examples for derived fields", :sales_log
  include_examples "shared log examples", :sales_log

  it "inherits from log" do
    expect(described_class).to be < Log
    expect(described_class).to be < ApplicationRecord
  end

  it "is a not a lettings log" do
    sales_log = build(:sales_log, created_by: created_by_user)
    expect(sales_log.lettings?).to be false
  end

  it "is a sales log" do
    sales_log = build(:sales_log, created_by: created_by_user)
    expect(sales_log.sales?).to be true
  end

  describe "#new" do
    context "when creating a record" do
      let(:sales_log) { described_class.create }

      it "attaches the correct custom validator" do
        expect(sales_log._validators.values.flatten.map(&:class))
          .to include(SalesLogValidator)
      end
    end
  end

  describe "#update" do
    let(:sales_log) { create(:sales_log, created_by: created_by_user) }
    let(:validator) { sales_log._validators[nil].first }

    after do
      sales_log.update(age1: 25)
    end

    it "validates other household member details" do
      expect(validator).to receive(:validate_household_number_of_other_members)
    end

    it "calls the form to clear any invalid answers" do
      expect(sales_log.form).to receive(:reset_not_routed_questions_and_invalid_answers)
    end
  end

  describe "resetting invalid answers" do
    let(:sales_log) { create(:sales_log, ownershipsch: 2, type: 8) }

    it "resets attributes that have become invalid when the sales log is updated" do
      expect { sales_log.update!(ownershipsch: 1) }.to change(sales_log, :type).from(8).to(nil)
    end
  end

  describe "#optional_fields" do
    context "when saledate is before 2023" do
      let(:sales_log) { build(:sales_log, saledate: Time.zone.parse("2022-07-01")) }

      it "returns optional fields" do
        expect(sales_log.optional_fields).to eq(%w[
          purchid
          othtype
          proplen
          mortlen
          frombeds
        ])
      end
    end

    context "when saledate is after 2023" do
      let(:sales_log) { build(:sales_log, saledate: Time.zone.parse("2023-07-01")) }

      it "returns optional fields" do
        expect(sales_log.optional_fields).to eq(%w[
          purchid
          othtype
          address_line2
          county
          postcode_full
        ])
      end
    end
  end

  describe "#form" do
    let(:sales_log) { build(:sales_log, created_by: created_by_user) }
    let(:sales_log_2) { build(:sales_log, saledate: Time.zone.local(2022, 5, 1), created_by: created_by_user) }

    before do
      Timecop.freeze(Time.zone.local(2023, 1, 10))
      Singleton.__init__(FormHandler)
    end

    after do
      Timecop.return
    end

    it "has returns the correct form based on the start date" do
      expect(sales_log.form_name).to be_nil
      expect(sales_log.form).to be_a(Form)
      expect(sales_log_2.form_name).to eq("current_sales")
      expect(sales_log_2.form).to be_a(Form)
    end
  end

  describe "status" do
    let(:completed_sales_log) { create(:sales_log, :completed) }

    context "when proplen is not given" do
      before do
        Timecop.freeze(Time.zone.local(2023, 5, 1))
      end

      after do
        Timecop.unfreeze
      end

      it "is set to completed for a log with a saledate before 23/24" do
        completed_sales_log.update!(proplen: nil, proplen_asked: 0, saledate: Time.zone.local(2022, 5, 1))
        expect(completed_sales_log.in_progress?).to be(false)
        expect(completed_sales_log.not_started?).to be(false)
        expect(completed_sales_log.completed?).to be(true)
        expect(completed_sales_log.deleted?).to be(false)
      end

      it "is set to in_progress for a log with a saledate after 23/24" do
        completed_sales_log.update!(proplen: nil, proplen_asked: 0, saledate: Time.zone.local(2023, 5, 1))
        expect(completed_sales_log.in_progress?).to be(true)
        expect(completed_sales_log.not_started?).to be(false)
        expect(completed_sales_log.completed?).to be(false)
        expect(completed_sales_log.deleted?).to be(false)
      end
    end
  end

  context "when filtering by organisation" do
    let(:organisation_1) { create(:organisation) }
    let(:organisation_2) { create(:organisation) }
    let(:organisation_3) { create(:organisation) }

    before do
      create(:sales_log, :in_progress, owning_organisation: organisation_1)
      create(:sales_log, :completed, owning_organisation: organisation_1)
      create(:sales_log, :completed, owning_organisation: organisation_2)
    end

    it "filters by given organisation" do
      expect(described_class.filter_by_organisation([organisation_1]).count).to eq(2)
      expect(described_class.filter_by_organisation([organisation_1, organisation_2]).count).to eq(3)
      expect(described_class.filter_by_organisation([organisation_3]).count).to eq(0)
    end
  end

  context "when filtering by year or nil" do
    before do
      Timecop.freeze(Time.utc(2021, 5, 3))
      create(:sales_log, :in_progress, saledate: nil)
      create(:sales_log, :in_progress, saledate: Time.zone.local(2021, 4, 1))
      sales_log_3 = create(:sales_log, :in_progress)
      sales_log_3.saledate = Time.zone.local(2022, 5, 1)
      sales_log_3.save!(validate: false)
    end

    after do
      Timecop.unfreeze
    end

    it "allows filtering on a single year or nil" do
      expect(described_class.filter_by_years_or_nil(%w[2021]).count).to eq(2)
    end

    it "allows filtering by multiple years or nil using OR" do
      expect(described_class.filter_by_years_or_nil(%w[2021 2022]).count).to eq(3)
    end

    it "can filter by year(s) AND status" do
      expect(described_class.filter_by_years_or_nil(%w[2021 2022]).filter_by_status("in_progress").count).to eq(3)
    end
  end

  context "when filtering duplicate logs" do
    let(:organisation) { create(:organisation) }
    let(:log) { create(:sales_log, :duplicate, owning_organisation: organisation) }
    let!(:duplicate_log) { create(:sales_log, :duplicate, owning_organisation: organisation) }

    it "returns all duplicate logs for given log" do
      expect(described_class.duplicate_logs(log).count).to eq(1)
    end

    it "returns duplicate log" do
      expect(described_class.duplicate_logs(log)).to include(duplicate_log)
    end

    it "does not return the given log" do
      expect(described_class.duplicate_logs(log)).not_to include(log)
    end

    context "when there is a deleted duplicate log" do
      let!(:deleted_duplicate_log) { create(:sales_log, :duplicate, discarded_at: Time.zone.now, owning_organisation: organisation) }

      it "does not return the deleted log as a duplicate" do
        expect(described_class.duplicate_logs(log)).not_to include(deleted_duplicate_log)
      end
    end

    context "when there is a log with a different sale date" do
      let!(:different_sale_date_log) { create(:sales_log, :duplicate, saledate: Time.zone.tomorrow, owning_organisation: organisation) }

      it "does not return a log with a different sale date as a duplicate" do
        expect(described_class.duplicate_logs(log)).not_to include(different_sale_date_log)
      end
    end

    context "when there is a log with a different age1" do
      let!(:different_age1) { create(:sales_log, :duplicate, age1: 50, owning_organisation: organisation) }

      it "does not return a log with a different age1 as a duplicate" do
        expect(described_class.duplicate_logs(log)).not_to include(different_age1)
      end
    end

    context "when there is a log with a different sex1" do
      let!(:different_sex1) { create(:sales_log, :duplicate, sex1: "M", owning_organisation: organisation) }

      it "does not return a log with a different sex1 as a duplicate" do
        expect(described_class.duplicate_logs(log)).not_to include(different_sex1)
      end
    end

    context "when there is a log with a different ecstat1" do
      let!(:different_ecstat1) { create(:sales_log, :duplicate, ecstat1: 0, owning_organisation: organisation) }

      it "does not return a log with a different ecstat1 as a duplicate" do
        expect(described_class.duplicate_logs(log)).not_to include(different_ecstat1)
      end
    end

    context "when there is a log with a different purchid" do
      let!(:different_purchid) { create(:sales_log, :duplicate, purchid: "different", owning_organisation: organisation) }

      it "does not return a log with a different purchid as a duplicate" do
        expect(described_class.duplicate_logs(log)).not_to include(different_purchid)
      end
    end

    context "when there is a log with a different postcode_full" do
      let!(:different_postcode_full) { create(:sales_log, :duplicate, postcode_full: "B1 1AA", owning_organisation: organisation) }

      it "does not return a log with a different postcode_full as a duplicate" do
        expect(described_class.duplicate_logs(log)).not_to include(different_postcode_full)
      end
    end

    context "when there is a log with nil values for duplicate check fields" do
      let!(:duplicate_check_fields_not_given) { create(:sales_log, :duplicate, age1: nil, sex1: nil, ecstat1: nil, pcodenk: 1, postcode_full: nil, owning_organisation: organisation) }

      it "does not return a log with nil values as a duplicate" do
        log.update!(age1: nil, sex1: nil, ecstat1: nil, pcodenk: 1, postcode_full: nil)
        expect(described_class.duplicate_logs(log)).not_to include(duplicate_check_fields_not_given)
      end
    end

    context "when there is a log with nil values for purchid" do
      let!(:purchid_not_given) { create(:sales_log, :duplicate, purchid: nil, owning_organisation: organisation) }

      it "returns the log as a duplicate if purchid is nil" do
        log.update!(purchid: nil)
        expect(described_class.duplicate_logs(log)).to include(purchid_not_given)
      end
    end

    context "when there is a log age not known" do
      let!(:age1_not_known) { create(:sales_log, :duplicate, age1_known: 1, age1: nil, owning_organisation: organisation) }

      it "returns the log as a duplicate if age is not known" do
        log.update!(age1_known: 1, age1: nil)
        expect(described_class.duplicate_logs(log)).to include(age1_not_known)
      end
    end

    context "when there is a log age pefers not to say" do
      let!(:age1_prefers_not_to_say) { create(:sales_log, :duplicate, age1_known: 2, age1: nil, owning_organisation: organisation) }

      it "returns the log as a duplicate if age is prefers not to say" do
        log.update!(age1_known: 2, age1: nil)
        expect(described_class.duplicate_logs(log)).to include(age1_prefers_not_to_say)
      end
    end

    context "when there is a log age pefers not to say and not known" do
      let!(:age1_prefers_not_to_say) { create(:sales_log, :duplicate, age1_known: 2, age1: nil, owning_organisation: organisation) }

      it "does not return the log as a duplicate if age is prefers not to say" do
        log.update!(age1_known: 1, age1: nil)
        expect(described_class.duplicate_logs(log)).not_to include(age1_prefers_not_to_say)
      end
    end
  end

  context "when getting list of duplicate logs" do
    let(:organisation) { create(:organisation) }
    let!(:log) { create(:sales_log, :duplicate, owning_organisation: organisation) }
    let!(:duplicate_log) { create(:sales_log, :duplicate, owning_organisation: organisation) }
    let(:duplicate_sets) { described_class.duplicate_sets }

    it "returns a list of duplicates in the same organisation" do
      expect(duplicate_sets.count).to eq(1)
      expect(duplicate_sets.first).to contain_exactly(log.id, duplicate_log.id)
    end

    context "when there is a deleted duplicate log" do
      before do
        create(:sales_log, :duplicate, discarded_at: Time.zone.now, status: 4)
      end

      it "does not return the deleted log as a duplicate" do
        expect(duplicate_sets.count).to eq(1)
        expect(duplicate_sets.first).to contain_exactly(log.id, duplicate_log.id)
      end
    end

    context "when there is a log with a different sale date" do
      before do
        create(:sales_log, :duplicate, saledate: Time.zone.tomorrow)
      end

      it "does not return a log with a different sale date as a duplicate" do
        expect(duplicate_sets.count).to eq(1)
        expect(duplicate_sets.first).to contain_exactly(log.id, duplicate_log.id)
      end
    end

    context "when there is a log with a different age1" do
      before do
        create(:sales_log, :duplicate, age1: 50)
      end

      it "does not return a log with a different age1 as a duplicate" do
        expect(duplicate_sets.count).to eq(1)
        expect(duplicate_sets.first).to contain_exactly(log.id, duplicate_log.id)
      end
    end

    context "when there is a log with a different sex1" do
      before do
        create(:sales_log, :duplicate, sex1: "X")
      end

      it "does not return a log with a different sex1 as a duplicate" do
        expect(duplicate_sets.count).to eq(1)
        expect(duplicate_sets.first).to contain_exactly(log.id, duplicate_log.id)
      end
    end

    context "when there is a log with a different ecstat1" do
      before do
        create(:sales_log, :duplicate, ecstat1: 9)
      end

      it "does not return a log with a different ecstat1 as a duplicate" do
        expect(duplicate_sets.count).to eq(1)
        expect(duplicate_sets.first).to contain_exactly(log.id, duplicate_log.id)
      end
    end

    context "when there is a log with a different purchid" do
      before do
        create(:sales_log, :duplicate, purchid: "different")
      end

      it "does not return a log with a different purchid as a duplicate" do
        expect(duplicate_sets.count).to eq(1)
        expect(duplicate_sets.first).to contain_exactly(log.id, duplicate_log.id)
      end
    end

    context "when there is a log with a different postcode_full" do
      before do
        create(:sales_log, :duplicate, postcode_full: "B1 1AA")
      end

      it "does not return a log with a different postcode_full as a duplicate" do
        expect(duplicate_sets.count).to eq(1)
        expect(duplicate_sets.first).to contain_exactly(log.id, duplicate_log.id)
      end
    end

    context "when there is a log with nil values for duplicate check fields" do
      before do
        create(:sales_log, :duplicate, age1: nil, sex1: nil, ecstat1: nil, pcodenk: 1, postcode_full: nil)
      end

      it "does not return a log with nil values as a duplicate" do
        log.update!(age1: nil, sex1: nil, ecstat1: nil, pcodenk: 1, postcode_full: nil)
        expect(duplicate_sets).to be_empty
      end
    end

    context "when there is a log with nil values for purchid" do
      let!(:purchid_not_given) { create(:sales_log, :duplicate, purchid: nil, owning_organisation: organisation) }

      it "returns the log as a duplicate if tenancy code is nil" do
        log.update!(purchid: nil)
        expect(duplicate_sets.count).to eq(1)
        expect(duplicate_sets.first).to contain_exactly(log.id, purchid_not_given.id)
      end
    end

    context "when there is a log with age1 not known" do
      let!(:age1_not_known) { create(:sales_log, :duplicate, age1_known: 1, age1: nil, owning_organisation: organisation) }

      it "returns the log as a duplicate if age1 is not known" do
        log.update!(age1_known: 1, age1: nil)
        expect(duplicate_sets.count).to eq(1)
        expect(duplicate_sets.first).to contain_exactly(age1_not_known.id, log.id)
      end
    end

    context "when there is a log with age1 prefers not to say" do
      let!(:age1_prefers_not_to_say) { create(:sales_log, :duplicate, age1_known: 2, age1: nil, owning_organisation: organisation) }

      it "returns the log as a duplicate if age1 is prefers not to say" do
        log.update!(age1_known: 2, age1: nil)
        expect(duplicate_sets.count).to eq(1)
        expect(duplicate_sets.first).to contain_exactly(age1_prefers_not_to_say.id, log.id)
      end
    end

    context "when there is a log with age1 not known and prefers not to say" do
      before do
        create(:sales_log, :duplicate, age1_known: 2, age1: nil)
      end

      it "doe not return the log as a duplicate" do
        log.update!(age1_known: 1, age1: nil)
        expect(duplicate_sets).to be_empty
      end
    end

    context "when user is given" do
      let(:user) { create(:user) }

      before do
        create_list(:sales_log, 2, :duplicate, purchid: "other duplicates")
        log.update!(created_by: user, owning_organisation: user.organisation)
      end

      it "does not return logs not associated with the given user" do
        duplicate_log.update!(owning_organisation: user.organisation)
        duplicate_sets = described_class.duplicate_sets(user.id)
        expect(duplicate_sets.count).to eq(1)
        expect(duplicate_sets.first).to contain_exactly(log.id, duplicate_log.id)
      end
    end
  end

  describe "derived variables" do
    let(:sales_log) { create(:sales_log, :completed) }

    around do |example|
      Timecop.freeze(Time.zone.local(2022, 7, 4)) do
        example.run
      end
      Timecop.return
    end

    it "correctly derives and saves exday, exmonth and exyear" do
      sales_log.update!(exdate: Time.gm(2022, 5, 4), saledate: Time.gm(2022, 7, 4), ownershipsch: 1, type: 18, staircase: 2, resale: 2, proplen: 0)
      record_from_db = described_class.find(sales_log.id)
      expect(record_from_db["exday"]).to eq(4)
      expect(record_from_db["exmonth"]).to eq(5)
      expect(record_from_db["exyear"]).to eq(2022)
    end

    it "correctly derives and saves deposit for outright sales when no mortgage is used" do
      sales_log.update!(value: 123_400, deposit: nil, mortgageused: 2, ownershipsch: 3, type: 10, companybuy: 1, jointpur: 1, jointmore: 1)
      record_from_db = described_class.find(sales_log.id)
      expect(record_from_db["deposit"]).to eq(123_400)
    end

    it "does not derive deposit if the sale isn't outright" do
      sales_log.update!(value: 123_400, deposit: nil, mortgageused: 2, ownershipsch: 2)
      record_from_db = described_class.find(sales_log.id)
      expect(record_from_db["deposit"]).to eq(nil)
    end

    it "does not derive deposit if the mortgage is used" do
      sales_log.update!(value: 123_400, deposit: nil, mortgageused: 1, ownershipsch: 3, type: 10, companybuy: 1, jointpur: 1, jointmore: 1)
      record_from_db = described_class.find(sales_log.id)
      expect(record_from_db["deposit"]).to eq(nil)
    end

    it "correctly derives and saves pcode1 and pcode1 and pcode2" do
      sales_log.update!(postcode_full: "W6 0SP")
      record_from_db = described_class.find(sales_log.id)
      expect(record_from_db["pcode1"]).to eq("W6")
      expect(record_from_db["pcode2"]).to eq("0SP")
    end

    it "derives a mortgage value of 0 when mortgage is not used" do
      # to avoid log failing validations when mortgage value is removed:
      new_grant_value = sales_log.grant + sales_log.mortgage
      sales_log.update!(mortgageused: 2, grant: new_grant_value)
      record_from_db = described_class.find(sales_log.id)
      expect(record_from_db["mortgage"]).to eq(0.0)
    end

    it "clears mortgage value if mortgage used is changed from no to yes" do
      # to avoid log failing validations when mortgage value is removed:
      new_grant_value = sales_log.grant + sales_log.mortgage
      sales_log.update!(mortgageused: 2, grant: new_grant_value)
      sales_log.update!(mortgageused: 1)
      record_from_db = described_class.find(sales_log.id)
      expect(record_from_db["mortgage"]).to eq(nil)
    end

    context "when outright sale and buyers will live in the property" do
      let(:sales_log) { create(:sales_log, :outright_sale_setup_complete, buylivein: 1, jointpur:) }

      context "and the sale is not a joint purchase" do
        let(:jointpur) { 2 }

        it "derives that buyer 1 will live in the property" do
          expect(sales_log.buy1livein).to be 1
        end

        it "does not derive a value for whether buyer 2 will live in the property" do
          expect(sales_log.buy2livein).to be nil
        end

        it "clears that buyer 1 will live in the property if joint purchase is updated" do
          sales_log.update!(jointpur: 1)
          expect(sales_log.buy1livein).to be nil
        end
      end

      context "and the sale is a joint purchase" do
        let(:jointpur) { 1 }

        it "does not derive values for whether buyer 1 or buyer 2 will live in the property" do
          expect(sales_log.buy1livein).to be nil
          expect(sales_log.buy2livein).to be nil
        end
      end
    end

    context "when outright sale and buyers will not live in the property" do
      let(:sales_log) { create(:sales_log, :outright_sale_setup_complete, buylivein: 2, jointpur:) }

      context "and the sale is not a joint purchase" do
        let(:jointpur) { 2 }

        it "derives that buyer 1 will not live in the property" do
          expect(sales_log.buy1livein).to be 2
        end

        it "does not derive a value for whether buyer 2 will live in the property" do
          expect(sales_log.buy2livein).to be nil
        end
      end

      context "and the sale is a joint purchase" do
        let(:jointpur) { 1 }

        it "derives that neither buyer 1 nor buyer 2 will live in the property" do
          expect(sales_log.buy1livein).to be 2
          expect(sales_log.buy2livein).to be 2
        end
      end
    end

    context "when deriving nationality variables" do
      it "correctly derives nationality_all/nationality_all_buyer2 when it's UK" do
        expect { sales_log.update!(nationality_all_group: 826) }.to change(sales_log, :nationality_all).to 826
        expect { sales_log.update!(nationality_all_buyer2_group: 826) }.to change(sales_log, :nationality_all_buyer2).to 826
      end

      it "correctly derives nationality_all/nationality_all_buyer2 when buyer prefers not to say" do
        expect { sales_log.update!(nationality_all_group: 0) }.to change(sales_log, :nationality_all).to 0
        expect { sales_log.update!(nationality_all_buyer2_group: 0) }.to change(sales_log, :nationality_all_buyer2).to 0
      end

      it "does not derive nationality_all/nationality_all_buyer2 when it is other or not given" do
        expect { sales_log.update!(nationality_all_group: 12) }.not_to change(sales_log, :nationality_all)
        expect { sales_log.update!(nationality_all_buyer2_group: 12) }.not_to change(sales_log, :nationality_all_buyer2)
        expect { sales_log.update!(nationality_all_group: nil) }.not_to change(sales_log, :nationality_all)
        expect { sales_log.update!(nationality_all_buyer2_group: nil) }.not_to change(sales_log, :nationality_all_buyer2)
      end
    end
  end

  context "when saving addresses" do
    before do
      stub_request(:get, /api.postcodes.io/)
        .to_return(status: 200, body: "{\"status\":200,\"result\":{\"admin_district\":\"Manchester\",\"codes\":{\"admin_district\": \"E08000003\"}}}", headers: {})
    end

    def check_postcode_fields(postcode_field)
      record_from_db = described_class.find(address_sales_log.id)
      expect(address_sales_log[postcode_field]).to eq("M1 1AE")
      expect(record_from_db[postcode_field]).to eq("M1 1AE")
    end

    let!(:address_sales_log) do
      create(
        :sales_log,
        :completed,
        owning_organisation:,
        created_by: created_by_user,
        pcodenk: 0,
        postcode_full: "M1 1AE",
      )
    end

    def check_property_postcode_fields
      check_postcode_fields("postcode_full")
    end

    it "correctly formats previous postcode" do
      address_sales_log.update!(postcode_full: "M1 1AE")
      check_property_postcode_fields

      address_sales_log.update!(postcode_full: "m1 1ae")
      check_property_postcode_fields

      address_sales_log.update!(postcode_full: "m11Ae")
      check_property_postcode_fields

      address_sales_log.update!(postcode_full: "m11ae")
      check_property_postcode_fields
    end

    it "correctly infers la" do
      record_from_db = described_class.find(address_sales_log.id)
      expect(address_sales_log.la).to eq("E08000003")
      expect(record_from_db["la"]).to eq("E08000003")
    end

    context "with 22/23 logs" do
      let(:address_sales_log_22_23) do
        described_class.create({
          owning_organisation:,
          created_by: created_by_user,
          ppcodenk: 1,
          postcode_full: "CA10 1AA",
          saledate: Time.zone.local(2022, 5, 2),
        })
      end

      before do
        WebMock.stub_request(:get, /api.postcodes.io\/postcodes\/CA101AA/)
               .to_return(status: 200, body: '{"status":200,"result":{"admin_district":"Cumberland","codes":{"admin_district":"E06000064"}}}', headers: {})

        Timecop.freeze(2023, 5, 1)
        Singleton.__init__(FormHandler)
      end

      after do
        Timecop.unfreeze
      end

      it "correctly sets la as nil" do
        record_from_db = described_class.find(address_sales_log_22_23.id)
        expect(address_sales_log_22_23.la).to eq(nil)
        expect(record_from_db["la"]).to eq(nil)
      end
    end

    context "with 23/24 logs" do
      let(:address_sales_log_23_24) do
        described_class.create({
          owning_organisation:,
          created_by: created_by_user,
          ppcodenk: 1,
          postcode_full: "CA10 1AA",
          saledate: Time.zone.local(2023, 5, 2),
        })
      end

      before do
        WebMock.stub_request(:get, /api.postcodes.io\/postcodes\/CA101AA/)
        .to_return(status: 200, body: '{"status":200,"result":{"admin_district":"Eden","codes":{"admin_district":"E07000030"}}}', headers: {})

        Timecop.freeze(2023, 5, 2)
        Singleton.__init__(FormHandler)
      end

      after do
        Timecop.unfreeze
      end

      it "correctly infers new la" do
        record_from_db = described_class.find(address_sales_log_23_24.id)
        expect(address_sales_log_23_24.la).to eq("E06000064")
        expect(record_from_db["la"]).to eq("E06000064")
      end

      it "does not set previous postcode for discounted sale" do
        address_sales_log_23_24.update!(ownershipsch: 2, ppostcode_full: nil)
        record_from_db = described_class.find(address_sales_log_23_24.id)
        expect(address_sales_log_23_24.ppostcode_full).to eq(nil)
        expect(record_from_db["ppostcode_full"]).to eq(nil)
      end
    end

    context "with 24/25 logs" do
      let(:address_sales_log_24_25) do
        described_class.create({
          owning_organisation:,
          created_by: created_by_user,
          ppcodenk: 1,
          postcode_full: "CA10 1AA",
          saledate: Time.zone.local(2024, 5, 2),
        })
      end

      before do
        WebMock.stub_request(:get, /api.postcodes.io\/postcodes\/CA101AA/)
        .to_return(status: 200, body: '{"status":200,"result":{"admin_district":"Eden","codes":{"admin_district":"E07000030"}}}', headers: {})

        Timecop.freeze(2024, 5, 2)
        Singleton.__init__(FormHandler)
      end

      after do
        Timecop.unfreeze
      end

      it "sets previous postcode for discounted sale" do
        address_sales_log_24_25.update!(ownershipsch: 2, ppostcode_full: nil)
        record_from_db = described_class.find(address_sales_log_24_25.id)
        expect(address_sales_log_24_25.ppostcode_full).to eq("CA10 1AA")
        expect(record_from_db["ppostcode_full"]).to eq("CA10 1AA")
      end

      it "does not set previous postcode for non discounted sale" do
        address_sales_log_24_25.update!(ownershipsch: 1, ppostcode_full: nil)
        record_from_db = described_class.find(address_sales_log_24_25.id)
        expect(address_sales_log_24_25.ppostcode_full).to eq(nil)
        expect(record_from_db["ppostcode_full"]).to eq(nil)
      end
    end

    it "errors if the property postcode is emptied" do
      expect { address_sales_log.update!({ postcode_full: "" }) }
        .to raise_error(ActiveRecord::RecordInvalid, /#{I18n.t("validations.postcode")}/)
    end

    it "errors if the property postcode is not valid" do
      expect { address_sales_log.update!({ postcode_full: "invalid_postcode" }) }
        .to raise_error(ActiveRecord::RecordInvalid, /#{I18n.t("validations.postcode")}/)
    end

    context "when the local authority lookup times out" do
      before do
        allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)
      end

      it "logs a warning" do
        expect(Rails.logger).to receive(:warn).with("Postcodes.io lookup timed out")
        address_sales_log.update!({ pcodenk: 1, postcode_full: "M1 1AD" })
      end
    end

    it "correctly resets all fields if property postcode not known" do
      address_sales_log.update!({ pcodenk: 1 })

      record_from_db = described_class.find(address_sales_log.id)
      expect(record_from_db["postcode_full"]).to eq(nil)
      expect(address_sales_log.la).to eq(nil)
      expect(record_from_db["la"]).to eq(nil)
    end

    it "changes the LA if property postcode changes from not known to known and provided" do
      address_sales_log.update!({ pcodenk: 1 })
      address_sales_log.update!({ la: "E09000033" })

      record_from_db = described_class.find(address_sales_log.id)
      expect(record_from_db["postcode_full"]).to eq(nil)
      expect(address_sales_log.la).to eq("E09000033")
      expect(record_from_db["la"]).to eq("E09000033")

      address_sales_log.update!({ pcodenk: 0, postcode_full: "M1 1AD" })

      record_from_db = described_class.find(address_sales_log.id)
      expect(record_from_db["postcode_full"]).to eq("M1 1AD")
      expect(address_sales_log.la).to eq("E08000003")
      expect(record_from_db["la"]).to eq("E08000003")
    end
  end

  context "when deriving household variables" do
    let!(:sales_log) do
      create(
        :sales_log,
        :completed,
        jointpur: 1,
        hholdcount: 4,
        details_known_3: 1,
        details_known_4: 1,
        details_known_5: 1,
        details_known_6: 1,
        relat2: "C",
        relat3: "C",
        relat4: "X",
        relat5: "X",
        relat6: "P",
        income2: 0,
        ecstat2: 9,
        ecstat3: 7,
        age1: 47,
        age2: 14,
        age3: 17,
        age4: 88,
        age5: 19,
        age6: 46,
      )
    end

    it "correctly derives and saves hhmemb" do
      record_from_db = described_class.find(sales_log.id)
      expect(record_from_db["hhmemb"]).to eq(6)
    end

    it "correctly derives and saves hhmemb if it's a joint purchase" do
      sales_log.update!(jointpur: 2, jointmore: 2)
      record_from_db = described_class.find(sales_log.id)
      expect(record_from_db["hhmemb"]).to eq(5)
    end

    it "correctly derives and saves totchild" do
      record_from_db = described_class.find(sales_log.id)
      expect(record_from_db["totchild"]).to eq(2)
    end

    it "correctly derives and saves totadult" do
      record_from_db = described_class.find(sales_log.id)
      expect(record_from_db["totadult"]).to eq(4)
    end

    it "correctly derives and saves hhtype" do
      record_from_db = described_class.find(sales_log.id)
      expect(record_from_db["hhtype"]).to eq(9)
    end
  end

  context "when saving previous address" do
    def check_previous_postcode_fields(postcode_field)
      record_from_db = described_class.find(address_sales_log.id)
      expect(address_sales_log[postcode_field]).to eq("M1 1AE")
      expect(record_from_db[postcode_field]).to eq("M1 1AE")
    end

    before do
      stub_request(:get, /api.postcodes.io/)
        .to_return(status: 200, body: "{\"status\":200,\"result\":{\"admin_district\":\"Manchester\", \"codes\":{\"admin_district\": \"E08000003\"}}}", headers: {})
    end

    let!(:address_sales_log) do
      described_class.create({
        owning_organisation:,
        created_by: created_by_user,
        ppcodenk: 1,
        ppostcode_full: "M1 1AE",
      })
    end

    def previous_postcode_fields
      check_previous_postcode_fields("ppostcode_full")
    end

    it "correctly formats previous postcode" do
      address_sales_log.update!(ppostcode_full: "M1 1AE")
      previous_postcode_fields

      address_sales_log.update!(ppostcode_full: "m1 1ae")
      previous_postcode_fields

      address_sales_log.update!(ppostcode_full: "m11Ae")
      previous_postcode_fields

      address_sales_log.update!(ppostcode_full: "m11ae")
      previous_postcode_fields
    end

    it "correctly infers prevloc" do
      record_from_db = described_class.find(address_sales_log.id)
      expect(address_sales_log.prevloc).to eq("E08000003")
      expect(record_from_db["prevloc"]).to eq("E08000003")
    end

    it "errors if the previous postcode is emptied" do
      expect { address_sales_log.update!({ ppostcode_full: "" }) }
        .to raise_error(ActiveRecord::RecordInvalid, /#{I18n.t("validations.postcode")}/)
    end

    it "errors if the previous postcode is not valid" do
      expect { address_sales_log.update!({ ppostcode_full: "invalid_postcode" }) }
        .to raise_error(ActiveRecord::RecordInvalid, /#{I18n.t("validations.postcode")}/)
    end

    it "correctly resets all fields if previous postcode not known" do
      address_sales_log.update!({ ppcodenk: 1 })

      record_from_db = described_class.find(address_sales_log.id)
      expect(record_from_db["ppostcode_full"]).to eq(nil)
      expect(address_sales_log.prevloc).to eq(nil)
      expect(record_from_db["prevloc"]).to eq(nil)
    end
  end

  describe "expected_shared_ownership_deposit_value" do
    let!(:completed_sales_log) { create(:sales_log, :completed, ownershipsch: 1, type: 2, value: 1000, equity: 50) }

    it "is set to completed for a completed sales log" do
      expect(completed_sales_log.expected_shared_ownership_deposit_value).to eq(500)
    end
  end

  describe "#field_formatted_as_currency" do
    let(:completed_sales_log) { create(:sales_log, :completed) }

    it "returns small numbers correctly formatted as currency" do
      completed_sales_log.update!(savings: 20)

      expect(completed_sales_log.field_formatted_as_currency("savings")).to eq("£20.00")
    end

    it "returns quite large numbers correctly formatted as currency" do
      completed_sales_log.update!(savings: 40_000)

      expect(completed_sales_log.field_formatted_as_currency("savings")).to eq("£40,000.00")
    end

    it "returns very large numbers correctly formatted as currency" do
      completed_sales_log.update!(savings: 400_000_000)

      expect(completed_sales_log.field_formatted_as_currency("savings")).to eq("£400,000,000.00")
    end
  end

  describe "#beds_for_la_sale_range" do
    context "when beds nil" do
      let(:sales_log) { build(:sales_log, beds: nil) }

      it "returns nil" do
        expect(sales_log.beds_for_la_sale_range).to be_nil
      end
    end

    context "when beds <= 4" do
      let(:sales_log) { build(:sales_log, beds: 4) }

      it "returns number of beds" do
        expect(sales_log.beds_for_la_sale_range).to eq(4)
      end
    end

    context "when beds > 4" do
      let(:sales_log) { build(:sales_log, beds: 40) }

      it "returns max number of beds" do
        expect(sales_log.beds_for_la_sale_range).to eq(4)
      end
    end
  end

  describe "#collection_period_open?" do
    let(:log) { build(:sales_log, saledate:) }

    context "when saledate is nil" do
      let(:saledate) { nil }

      it "returns false" do
        expect(log.collection_period_open?).to eq(true)
      end
    end

    context "when older_than_previous_collection_year" do
      let(:previous_collection_start_date) { Time.zone.local(2050, 4, 1) }
      let(:saledate) { previous_collection_start_date - 1.day }

      before do
        allow(log).to receive(:previous_collection_start_date).and_return(previous_collection_start_date)
      end

      it "returns true" do
        expect(log.collection_period_open?).to eq(false)
      end
    end

    context "when form end date is in the future" do
      let(:saledate) { nil }

      before do
        allow(log).to receive_message_chain(:form, :new_logs_end_date).and_return(Time.zone.now + 1.day)
      end

      it "returns true" do
        expect(log.collection_period_open?).to eq(true)
      end
    end

    context "when form end date is in the past" do
      let(:saledate) { Time.zone.local(2020, 4, 1) }

      before do
        allow(log).to receive_message_chain(:form, :new_logs_end_date).and_return(Time.zone.now - 1.day)
      end

      it "returns false" do
        expect(log.collection_period_open?).to eq(false)
      end
    end
  end
end
# rubocop:enable RSpec/MessageChain
