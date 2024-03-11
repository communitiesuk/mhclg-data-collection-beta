require "rails_helper"

RSpec.describe BulkUpload::Sales::Year2024::RowParser do
  subject(:parser) { described_class.new(attributes) }

  let(:now) { Time.zone.parse("01/05/2024") }

  let(:attributes) { { bulk_upload: } }
  let(:bulk_upload) { create(:bulk_upload, :sales, user:, year: 2024) }
  let(:user) { create(:user, organisation: owning_org) }
  let(:owning_org) { create(:organisation, :with_old_visible_id) }
  let(:managing_org) { create(:organisation, :with_old_visible_id) }

  let(:setup_section_params) do
    {
      bulk_upload:,
      field_1: owning_org.old_visible_id, # organisation
      field_2: managing_org.old_visible_id, # organisation
      field_3: user.email, # user
      field_4: now.day.to_s, # sale day
      field_5: now.month.to_s, # sale month
      field_6: now.strftime("%g"), # sale year
      field_7: "test id", # purchase id
      field_8: "1", # owhershipsch
      field_9: "2", # shared ownership sale type
      field_14: "1", # will the buyers live in the property
      field_15: "2", # joint purchase
      field_17: "1", # noint
      field_18: "1", # privacy notice
    }
  end
  let(:valid_attributes) do
    {
      bulk_upload:,
      field_1: owning_org.old_visible_id,
      field_2: managing_org.old_visible_id,

      field_4: "12",
      field_5: "5",
      field_6: "24",
      field_7: "test id",
      field_8: "1",
      field_9: "2",
      field_14: "1",
      field_15: "1",
      field_16: "2",
      field_17: "1",
      field_18: "1",
      field_19: "2",
      field_20: "1",
      field_21: "1",
      field_22: "12",
      field_23: "Address line 1",
      field_27: "CR0",
      field_28: "4BB",
      field_29: "E09000008",
      field_30: "3",
      field_31: "32",
      field_32: "M",
      field_33: "12",
      field_34: "28",
      field_35: "1",
      field_36: "1",
      field_37: "R",
      field_38: "32",
      field_39: "F",
      field_40: "17",
      field_41: "28",
      field_42: "2",
      field_43: "1",
      field_44: "0",
      field_61: "1",
      field_62: "1",
      field_63: "A1",
      field_64: "1AA",
      field_65: "E09000008",
      field_68: "1",
      field_69: "1",
      field_70: "3",
      field_72: "3",
      field_74: "5",
      field_75: "3",
      field_76: "3",
      field_77: "30000",
      field_78: "1",
      field_79: "15000",
      field_80: "1",
      field_81: "4",
      field_82: "20000",
      field_83: "3",
      field_85: "5",
      field_86: "1",
      field_87: "10",
      field_88: "40",
      field_89: "1",
      field_91: "30",
      field_92: "3",
      field_93: "22",
      field_94: "24",
      field_95: "3",
      field_96: "22",
      field_97: "3",
      field_98: "1",
      field_99: "1",
      field_100: "1",
      field_101: "250000",
      field_102: "25",
      field_103: "1",
      field_104: "5000",
      field_105: "1",
      field_107: "20",
      field_108: "3",
      field_109: "20000",
      field_111: "800",
      field_112: "200",
    }
  end

  around do |example|
    create(:organisation_relationship, parent_organisation: owning_org, child_organisation: managing_org)

    Timecop.freeze(Time.zone.local(2025, 2, 22)) do
      Singleton.__init__(FormHandler)
      example.run
    end
  end

  describe "#blank_row?" do
    context "when a new object" do
      it "returns true" do
        expect(parser).to be_blank_row
      end
    end

    context "when any field is populated" do
      before do
        parser.field_1 = "1"
      end

      it "returns false" do
        expect(parser).not_to be_blank_row
      end
    end
  end

  describe "purchaser_code" do
    before do
      def purch_id_field
        described_class::QUESTIONS.key("What is the purchaser code?").to_s
      end
    end

    let(:attributes) do
      {
        bulk_upload:,
        purch_id_field => "some purchaser code",
      }
    end

    it "is linked to the correct field" do
      expect(parser.purchaser_code).to eq("some purchaser code")
    end
  end

  describe "previous postcode known" do
    context "when field_62 is 1" do
      let(:attributes) do
        {
          bulk_upload:,
          field_62: 1,
        }
      end

      it "sets previous postcode known to yes" do
        expect(parser.log.ppcodenk).to eq(0)
      end
    end

    context "when field_62 is 2" do
      let(:attributes) do
        {
          bulk_upload:,
          field_62: 2,
        }
      end

      it "sets previous postcode known to no" do
        expect(parser.log.ppcodenk).to eq(1)
      end
    end
  end

  describe "income and savings fields" do
    context "when set to R" do
      let(:attributes) do
        {
          bulk_upload:,
          field_77: "R", # income 1
          field_79: "R", # income 2
          field_82: "R", # savings
        }
      end

      it "sets the not known field as not known" do
        expect(parser.log.income1nk).to be(1)
        expect(parser.log.income2nk).to be(1)
        expect(parser.log.savingsnk).to be(1)
      end

      it "leaves the value field nil" do
        expect(parser.log.income1).to be_nil
        expect(parser.log.income2).to be_nil
        expect(parser.log.savings).to be_nil
      end
    end

    context "when set to a number" do
      let(:attributes) do
        {
          bulk_upload:,
          field_77: "30000", # income 1
          field_79: "0", # income 2
          field_82: "12420", # savings
        }
      end

      it "sets the not known field as known" do
        expect(parser.log.income1nk).to be(0)
        expect(parser.log.income2nk).to be(0)
        expect(parser.log.savingsnk).to be(0)
      end

      it "sets the values" do
        expect(parser.log.income1).to be(30_000)
        expect(parser.log.income2).to be(0)
        expect(parser.log.savings).to be(12_420)
      end
    end
  end

  describe "validations" do
    before do
      stub_request(:get, /api\.postcodes\.io/)
      .to_return(status: 200, body: "{\"status\":200,\"result\":{\"admin_district\":\"Manchester\", \"codes\":{\"admin_district\": \"E08000003\"}}}", headers: {})

      stub_request(:get, /api\.os\.uk/)
        .to_return(status: 200, body: { results: [{ DPA: { MATCH: 0.9, BUILDING_NAME: "result address line 1", POST_TOWN: "result town or city", POSTCODE: "AA1 1AA", UPRN: "12345" } }] }.to_json, headers: {})

      parser.valid?
    end

    describe "#valid?" do
      context "when the row is blank" do
        let(:attributes) { { bulk_upload: } }

        it "returns true" do
          expect(parser).to be_valid
        end
      end

      context "when calling the method multiple times" do
        let(:attributes) { { bulk_upload:, field_8: 2 } }

        it "does not add keep adding errors to the pile" do
          expect { parser.valid? }.not_to change(parser.errors, :count)
        end
      end

      context "when valid row" do
        let(:attributes) { valid_attributes }

        it "returns true" do
          expect(parser).to be_valid
        end

        it "instantiates a log with everything completed", aggregate_failures: true do
          questions = parser.send(:questions).reject do |q|
            parser.send(:log).optional_fields.include?(q.id) || q.completed?(parser.send(:log))
          end

          expect(questions.map(&:id).size).to eq(0)
          expect(questions.map(&:id)).to eql([])
        end
      end
    end

    context "when setup section not complete and type is not given" do
      let(:attributes) do
        {
          bulk_upload:,
          field_7: "test id",
        }
      end

      it "has errors on correct setup fields" do
        errors = parser.errors.select { |e| e.options[:category] == :setup }.map(&:attribute).sort

        expect(errors).to eql(%i[field_1 field_17 field_18 field_2 field_4 field_5 field_6 field_8])
      end
    end

    context "when setup section not complete and type is shared ownership" do
      let(:attributes) do
        {
          bulk_upload:,
          field_7: "test id",
          field_8: "1",
        }
      end

      it "has errors on correct setup fields" do
        errors = parser.errors.select { |e| e.options[:category] == :setup }.map(&:attribute).sort

        expect(errors).to eql(%i[field_1 field_15 field_17 field_18 field_2 field_4 field_5 field_6 field_9])
      end
    end

    context "when setup section not complete it's shared ownership joint purchase" do
      let(:attributes) do
        {
          bulk_upload:,
          field_7: "test id",
          field_8: "1",
          field_9: "2",
          field_15: "1",
        }
      end

      it "has errors on correct setup fields" do
        errors = parser.errors.select { |e| e.options[:category] == :setup }.map(&:attribute).sort

        expect(errors).to eql(%i[field_1 field_16 field_17 field_18 field_2 field_4 field_5 field_6])
      end
    end

    context "when setup section not complete and type is discounted ownership" do
      let(:attributes) do
        {
          bulk_upload:,
          field_7: "test id",
          field_8: "2",
          field_10: nil,
        }
      end

      it "has errors on correct setup fields" do
        errors = parser.errors.select { |e| e.options[:category] == :setup }.map(&:attribute).sort

        expect(errors).to eql(%i[field_1 field_10 field_15 field_17 field_18 field_2 field_4 field_5 field_6])
      end
    end

    context "when setup section not complete and it's discounted ownership joint purchase" do
      let(:attributes) do
        {
          bulk_upload:,
          field_31: "2",
          field_46: "8",
          field_39: "1",
        }
      end

      it "has errors on correct setup fields" do
        errors = parser.errors.select { |e| e.options[:category] == :setup }.map(&:attribute).sort

        expect(errors).to eql(%i[field_1 field_17 field_18 field_2 field_4 field_5 field_6 field_8])
      end
    end

    context "when setup section not complete and type is outright sale" do
      let(:attributes) do
        {
          bulk_upload:,
          field_7: "test id",
          field_8: "3",
        }
      end

      it "has errors on correct setup fields" do
        errors = parser.errors.select { |e| e.options[:category] == :setup }.map(&:attribute).sort

        expect(errors).to eql(%i[field_1 field_11 field_13 field_14 field_17 field_18 field_2 field_4 field_5 field_6])
      end
    end

    context "when setup section not complete outright sale buyer is not company" do
      let(:attributes) do
        {
          bulk_upload:,
          field_7: "test id",
          field_8: "3",
          field_11: "12",
          field_13: "2",
        }
      end

      it "has errors on correct setup fields" do
        errors = parser.errors.select { |e| e.options[:category] == :setup }.map(&:attribute).sort

        expect(errors).to eql(%i[field_1 field_12 field_14 field_15 field_17 field_18 field_2 field_4 field_5 field_6])
      end
    end

    describe "#field_1" do # owning org
      context "when no data given" do
        let(:attributes) { setup_section_params.merge(field_1: nil) }

        it "is not permitted as setup error" do
          expect(parser.errors.where(:field_1, category: :setup).map(&:message)).to eql(["You must answer owning organisation"])
        end

        it "blocks log creation" do
          expect(parser).to be_block_log_creation
        end
      end

      context "when cannot find owning org" do
        let(:attributes) { { bulk_upload:, field_1: "donotexist" } }

        it "is not permitted as a setup error" do
          expect(parser.errors.where(:field_1, category: :setup).map(&:message)).to eql(["You must answer owning organisation"])
        end

        it "blocks log creation" do
          expect(parser).to be_block_log_creation
        end
      end

      context "when not affiliated with owning org" do
        let(:unaffiliated_org) { create(:organisation, :with_old_visible_id) }

        let(:attributes) { { bulk_upload:, field_1: unaffiliated_org.old_visible_id } }

        it "is not permitted as setup error" do
          expect(parser.errors.where(:field_1, category: :setup).map(&:message)).to eql(["You do not have permission to add logs for this owning organisation"])
        end

        it "blocks log creation" do
          expect(parser).to be_block_log_creation
        end
      end

      context "when user's org has absorbed owning organisation with stock owners" do
        let(:merged_org) { create(:organisation, :with_old_visible_id, holds_own_stock: true) }
        let(:merged_org_stock_owner) { create(:organisation, :with_old_visible_id, holds_own_stock: true) }

        let(:attributes) { { bulk_upload:, field_1: merged_org_stock_owner.old_visible_id } }

        before do
          create(:organisation_relationship, parent_organisation: merged_org_stock_owner, child_organisation: merged_org)
          merged_org.update!(absorbing_organisation: user.organisation, merge_date: Time.zone.today)
          merged_org.reload
          user.organisation.reload
        end

        it "is permitted" do
          parser.valid?
          expect(parser.errors.where(:field_1)).not_to be_present
        end
      end

      context "when user's org has absorbed owning organisation" do
        let(:merged_org) { create(:organisation, :with_old_visible_id, holds_own_stock: true) }

        let(:attributes) { { bulk_upload:, field_1: merged_org.old_visible_id, field_3: user.email } }

        before do
          merged_org.update!(absorbing_organisation: user.organisation, merge_date: Time.zone.today)
          merged_org.reload
          user.organisation.reload
          user.reload
        end

        it "is permitted" do
          parser = described_class.new(attributes)

          parser.valid?
          expect(parser.errors.where(:field_1)).not_to be_present
          expect(parser.errors.where(:field_3)).not_to be_present
        end
      end

      context "when user's org has absorbed owning organisation before the startdate" do
        let(:merged_org) { create(:organisation, :with_old_visible_id, holds_own_stock: true) }

        let(:attributes) { setup_section_params.merge({ field_1: merged_org.old_visible_id, field_3: user.email }) }

        before do
          merged_org.update!(absorbing_organisation: user.organisation, merge_date: Time.zone.today - 3.years)
          merged_org.reload
          user.organisation.reload
          user.reload
        end

        it "is not permitted" do
          parser = described_class.new(attributes)

          parser.valid?
          expect(parser.errors[:field_1]).to include(/The owning organisation must be active on the sale completion date/)
          expect(parser.errors[:field_4]).to include(/Enter a date when the owning organisation was active/)
          expect(parser.errors[:field_5]).to include(/Enter a date when the owning organisation was active/)
          expect(parser.errors[:field_6]).to include(/Enter a date when the owning organisation was active/)
        end
      end
    end

    describe "#field_3" do # username for created_by
      context "when blank" do
        let(:attributes) { setup_section_params.merge(bulk_upload:, field_3: nil) }

        it "is permitted" do
          expect(parser.errors[:field_3]).to be_blank
        end
      end

      context "when user could not be found" do
        let(:attributes) { { bulk_upload:, field_3: "idonotexist@example.com" } }

        it "is not permitted" do
          expect(parser.errors[:field_3]).to be_present
        end
      end

      context "when an unaffiliated user" do
        let(:other_user) { create(:user) }

        let(:attributes) { { bulk_upload:, field_1: owning_org.old_visible_id, field_3: other_user.email } }

        it "is not permitted as a setup error" do
          expect(parser.errors.where(:field_3, category: :setup)).to be_present
        end

        it "blocks log creation" do
          expect(parser).to be_block_log_creation
        end
      end

      context "when an user part of owning org" do
        let(:other_user) { create(:user, organisation: owning_org) }

        let(:attributes) { { bulk_upload:, field_1: owning_org.old_visible_id, field_3: other_user.email } }

        it "is permitted" do
          expect(parser.errors[:field_3]).to be_blank
        end
      end

      context "when email matches other than casing" do
        let(:other_user) { create(:user, organisation: owning_org) }

        let(:attributes) { { bulk_upload:, field_1: owning_org.old_visible_id, field_3: other_user.email.upcase! } }

        it "is permitted" do
          expect(parser.errors[:field_3]).to be_blank
        end
      end
    end

    describe "fields 3, 4, 5 => saledate" do
      context "when all of these fields are blank" do
        let(:attributes) { setup_section_params.merge({ field_4: nil, field_5: nil, field_6: nil }) }

        it "returns them as setup errors" do
          expect(parser.errors.where(:field_4, category: :setup)).to be_present
          expect(parser.errors.where(:field_5, category: :setup)).to be_present
          expect(parser.errors.where(:field_6, category: :setup)).to be_present
        end
      end

      context "when one of these fields is blank" do
        let(:attributes) { setup_section_params.merge({ field_4: "1", field_5: "1", field_6: nil }) }

        it "returns an error only on blank field as setup error" do
          expect(parser.errors[:field_4]).to be_blank
          expect(parser.errors[:field_5]).to be_blank
          expect(parser.errors.where(:field_6, category: :setup)).to be_present
        end
      end

      context "when field 5 is 4 digits instead of 2" do
        let(:attributes) { setup_section_params.merge({ bulk_upload:, field_6: "2023" }) }

        it "returns a setup error" do
          expect(parser.errors.where(:field_6, category: :setup).map(&:message)).to include("Sale completion year must be 2 digits")
        end
      end

      context "when invalid date given" do
        let(:attributes) { setup_section_params.merge({ field_4: "a", field_5: "12", field_6: "2023" }) }

        it "does not raise an error" do
          expect { parser.valid? }.not_to raise_error
        end
      end

      context "when inside of collection year" do
        around do |example|
          Timecop.freeze(Date.new(2024, 10, 1)) do
            example.run
          end
        end

        let(:attributes) { setup_section_params.merge({ field_4: "1", field_5: "10", field_6: "24" }) }

        let(:bulk_upload) { create(:bulk_upload, :sales, user:, year: 2024) }

        it "does not return errors" do
          expect(parser.errors[:field_4]).not_to be_present
          expect(parser.errors[:field_5]).not_to be_present
          expect(parser.errors[:field_6]).not_to be_present
        end
      end

      context "when outside of collection year" do
        around do |example|
          Timecop.freeze(Date.new(2023, 4, 2)) do
            example.run
          end
        end

        let(:attributes) { setup_section_params.merge({ field_4: "1", field_5: "1", field_6: "22" }) }

        let(:bulk_upload) { create(:bulk_upload, :sales, user:, year: 2023) }

        it "returns setup errors" do
          expect(parser.errors.where(:field_4, category: :setup)).to be_present
          expect(parser.errors.where(:field_5, category: :setup)).to be_present
          expect(parser.errors.where(:field_6, category: :setup)).to be_present
        end
      end
    end

    context "when the log already exists in the db" do
      let(:attributes) { valid_attributes }

      before do
        parser.log.save!
        parser.instance_variable_set(:@valid, nil)
      end

      it "is not a valid row" do
        expect(parser).not_to be_valid
      end

      it "adds an error to all (and only) the fields used to determine duplicates" do
        parser.valid?

        error_message = "This is a duplicate log"

        [
          :field_1, # Owning org
          :field_4, # Sale completion date
          :field_5, # Sale completion date
          :field_6, # Sale completion date
          :field_27, # Postcode
          :field_28, # Postcode
          :field_31, # Buyer 1 age
          :field_32, # Buyer 1 gender
          :field_35, # Buyer 1 working situation
          :field_7, # Purchaser code
        ].each do |field|
          expect(parser.errors[field]).to include(error_message)
        end
      end
    end

    context "when a hidden log already exists in db" do
      before do
        parser.log.status = "pending"
        parser.log.skip_update_status = true
        parser.log.save!
      end

      it "is a valid row" do
        expect(parser).to be_valid
      end

      it "does not add duplicate errors" do
        parser.valid?

        [
          :field_1, # Owning org
          :field_4, # Sale completion date
          :field_5, # Sale completion date
          :field_6, # Sale completion date
          :field_27, # Postcode
          :field_28, # Postcode
          :field_31, # Buyer 1 age
          :field_32, # Buyer 1 gender
          :field_35, # Buyer 1 working situation
          :field_7, # Purchaser code
        ].each do |field|
          expect(parser.errors[field]).to be_blank
        end
      end
    end

    describe "#field_8" do # ownership scheme
      context "when an invalid option" do
        let(:attributes) { setup_section_params.merge({ field_8: "100" }) }

        it "returns setup error" do
          expect(parser.errors.where(:field_8, category: :setup)).to be_present
        end
      end
    end

    describe "#field_9" do # type for shared ownership sale
      context "when an invalid option" do
        let(:attributes) { setup_section_params.merge({ field_9: "100" }) }

        it "returns setup error" do
          expect(parser.errors.where(:field_9, category: :setup)).to be_present
        end
      end
    end

    describe "#field_10" do # type for discounted sale
      context "when an invalid option" do
        let(:attributes) { setup_section_params.merge({ field_10: "100" }) }

        it "returns setup error" do
          expect(parser.errors.where(:field_10, category: :setup)).to be_present
        end
      end
    end

    describe "#field_11" do # type for outright sale
      context "when an invalid option" do
        let(:attributes) { setup_section_params.merge({ field_11: "100" }) }

        it "returns setup error" do
          expect(parser.errors.where(:field_11, category: :setup)).to be_present
        end
      end
    end

    describe "#field_12" do # type of other outright sale
      context "when an invalid option" do
        let(:attributes) { setup_section_params.merge({ field_11: "12", field_12: nil }) }

        it "returns setup error" do
          expect(parser.errors.where(:field_12, category: :setup)).to be_present
        end
      end
    end

    describe "#field_13" do # buyer a company?
      context "when an invalid option" do
        let(:attributes) { setup_section_params.merge({ field_8: "3", field_13: "100" }) }

        it "returns setup error" do
          expect(parser.errors.where(:field_13).map(&:message)).to include("Enter a valid value for is the buyer a company?")
          expect(parser.errors.where(:field_13, category: :setup)).to be_present
        end
      end
    end

    describe "#field_14" do # will buyers live in the property?
      context "when an invalid option" do
        let(:attributes) { setup_section_params.merge({ field_8: "3", field_14: "100" }) }

        it "returns setup error" do
          expect(parser.errors.where(:field_14).map(&:message)).to eql(["Enter a valid value for will the buyers live in the property?"])
          expect(parser.errors.where(:field_14, category: :setup)).to be_present
        end
      end
    end

    describe "#field_15" do # joint purchase
      context "when an invalid option" do
        let(:attributes) { setup_section_params.merge({ field_15: "100" }) }

        it "returns a setup error" do
          expect(parser.errors.where(:field_15, category: :setup)).to be_present
        end
      end
    end

    describe "#field_16" do # more than 2 joint buyers?
      context "when invalid option and must be answered" do
        let(:attributes) { setup_section_params.merge({ field_15: "1", field_16: "100" }) }

        it "returns a setup error" do
          expect(parser.errors.where(:field_16, category: :setup)).to be_present
        end
      end
    end

    describe "#field_22" do # UPRN
      context "when UPRN known and lookup found" do
        let(:attributes) { setup_section_params.merge({ field_22: "12" }) }

        it "is valid" do
          expect(parser.errors[:field_22]).to be_blank
        end

        it "sets UPRN and UPRN known" do
          expect(parser.log.uprn).to eq("12")
          expect(parser.log.uprn_known).to eq(1)
          expect(parser.log.uprn_confirmed).to eq(1)
        end
      end

      context "when UPRN not known but address known" do
        let(:attributes) { setup_section_params.merge({ field_22: nil, field_23: "some street", field_25: "some town", field_27: "EC1N", field_28: "2TD" }) }

        it "is valid" do
          expect(parser.errors[:field_22]).to be_blank
        end
      end

      context "when neither UPRN or address known" do
        let(:attributes) { setup_section_params.merge({ field_22: nil, field_23: nil, field_25: nil, field_27: nil, field_28: nil }) }

        it "is not valid" do
          expect(parser.errors[:field_22]).to be_present
        end
      end

      context "when UPRN entered but no lookup found" do
        let(:attributes) { setup_section_params.merge({ field_22: "1234567890123" }) }

        it "is not valid" do
          expect(parser.errors[:field_22]).to be_present
        end
      end
    end

    [
      { field: :field_23, name: "address line 1" },
      { field: :field_25, name: "town or city" },
    ].each do |data|
      describe "##{data[:field]} (#{data[:name]})" do
        context "when UPRN present" do
          context "when UPRN valid" do
            let(:attributes) { setup_section_params.merge({ field_22: "12", data[:field] => nil }) }

            it "can be blank" do
              expect(parser.errors[data[:field]]).to be_blank
            end
          end

          context "when UPRN invalid" do
            let(:attributes) { setup_section_params.merge({ field_22: "1234567890123", data[:field] => nil }) }

            it "cannot be blank" do
              expect(parser.errors[data[:field]]).to be_present
            end
          end
        end

        context "when UPRN not present" do
          let(:attributes) { setup_section_params.merge({ field_22: nil, data[:field] => nil }) }

          it "cannot be blank" do
            expect(parser.errors[data[:field]]).to be_present
          end
        end
      end
    end

    describe "#field_18" do # data protection
      let(:attributes) { setup_section_params.merge({ field_18: nil }) }

      context "when not answered" do
        it "returns a setup error" do
          expect(parser.errors.where(:field_18, category: :setup)).to be_present
        end
      end
    end

    [
      %w[age1_known details_known_1 age1 field_31 field_37 field_39],
      %w[age2_known details_known_2 age2 field_38 field_37 field_39],
      %w[age3_known details_known_3 age3 field_46 field_45 field_47],
      %w[age4_known details_known_4 age4 field_50 field_49 field_51],
      %w[age5_known details_known_5 age5 field_54 field_53 field_55],
      %w[age6_known details_known_6 age6 field_58 field_57 field_59],
    ].each do |known, details_known, age, field, relationship, gender|
      describe "##{known} and ##{age}" do
        context "when #{field} is blank" do
          context "and person details are blank" do
            let(:attributes) { setup_section_params.merge({ field.to_s => nil, relationship.to_sym => nil, gender.to_sym => nil, field_18: "1", field_44: "5" }) }

            it "does not set ##{known}" do
              unless known == "age1_known"
                expect(parser.log.public_send(known)).to be_nil
              end
            end

            it "sets ##{details_known} to no" do
              unless details_known == "details_known_1"
                expect(parser.log.public_send(details_known)).to eq(2)
              end
            end

            it "sets ##{age} to nil" do
              expect(parser.log.public_send(age)).to be_nil
            end
          end

          context "and person details are given" do
            let(:attributes) { setup_section_params.merge({ field.to_sym => nil, relationship.to_sym => "C", gender.to_sym => "X", field_18: "1", field_44: "5" }) }

            it "does not set ##{age}" do
              parser.valid?
              expect(parser.errors[field.to_sym]).to include(/You must answer/)
            end
          end
        end

        context "when #{field} is R" do
          let(:attributes) { setup_section_params.merge({ field.to_s => "R", field_17: "1", field_44: "5", field_18: "1" }) }

          it "sets ##{known} 1" do
            expect(parser.log.public_send(known)).to be(1)
          end

          it "sets ##{age} to nil" do
            expect(parser.log.public_send(age)).to be_nil
          end
        end

        context "when #{field} is a number" do
          let(:attributes) { setup_section_params.merge({ field.to_s => "50", field_17: "1", field_44: "5", field_18: "1" }) }

          it "sets ##{known} to 0" do
            expect(parser.log.public_send(known)).to be(0)
          end

          it "sets ##{age} to given age" do
            expect(parser.log.public_send(age)).to be(50)
          end
        end

        context "when #{field} is a non-sensical value" do
          let(:attributes) { setup_section_params.merge({ field.to_s => "A", field_17: "1", field_44: "5", field_18: "1" }) }

          it "sets ##{known} to 0" do
            expect(parser.log.public_send(known)).to be(0)
          end

          it "sets ##{age} to nil" do
            expect(parser.log.public_send(age)).to be_nil
          end
        end
      end
    end

    describe "field_35" do # ecstat1
      context "when buyer 1 is marked as a child" do
        let(:attributes) { valid_attributes.merge({ field_35: "9" }) }

        it "a custom validation is applied" do
          validation_message = "Buyer 1 cannot be a child under 16"
          expect(parser.errors[:field_35]).to include validation_message
        end
      end
    end

    describe "#field_36" do # will buyer1 live in property?
      context "when not a possible value" do
        let(:attributes) { valid_attributes.merge({ field_36: "3" }) }

        it "is not valid" do
          expect(parser.errors).to include(:field_36)
        end
      end
    end

    describe "#field_66 - 69" do # buyers organisations
      let(:empty_organisation_params) { setup_section_params.merge(field_66: nil, field_67: nil, field_68: nil, field_69: nil) }

      context "when all empty" do
        let(:attributes) { empty_organisation_params }

        it "sets pregblank field" do
          expect(parser.log.pregblank).to be(1)
        end
      end

      %i[field_66 field_67 field_68 field_69].each do |field_number|
        context "when #{field_number} present" do
          let(:attributes) { empty_organisation_params.merge({ field_number => 1 }) }

          it "does not set pregblank field" do
            attributes[:field_number] = 1
            expect(parser.log.pregblank).to be(0)
          end
        end
      end
    end

    describe "#field_103" do # shared ownership mortgageused
      context "when invalid value" do
        let(:attributes) { setup_section_params.merge(field_103: "4") }

        it "returns correct errors" do
          expect(parser.errors[:field_103]).to include("Enter a valid value for Was a mortgage used for the purchase of this property? - Shared ownership")
        end
      end

      context "when value is 3 and stairowned is not 100" do
        let(:attributes) { setup_section_params.merge(field_103: "3", field_86: "1", field_87: "50", field_88: "99", field_109: nil) }

        it "returns correct errors" do
          expect(parser.errors[:field_103]).to include("Enter a valid value for Was a mortgage used for the purchase of this property? - Shared ownership")
        end
      end

      context "when value is 3 and stairowned is 100" do
        let(:attributes) { setup_section_params.merge(field_103: "3", field_86: "1", field_87: "50", field_88: "100", field_109: nil) }

        it "does not add errors and sets mortgage used to 3" do
          expect(parser.log.mortgageused).to be(3)
          expect(parser.log.stairowned).to be(100)
          expect(parser.log.deposit).to be(nil)
          expect(parser.errors[:field_103]).to be_empty
          expect(parser.errors[:field_109]).to be_empty
        end
      end
    end

    describe "soft validations" do
      context "when soft validation is triggered" do
        let(:attributes) { valid_attributes.merge({ field_31: 22, field_35: 5 }) }

        it "adds an error to the relevant fields" do
          expect(parser.errors.where(:field_31, category: :soft_validation)).to be_present
          expect(parser.errors.where(:field_35, category: :soft_validation)).to be_present
        end

        it "populates with correct error message" do
          expect(parser.errors.where(:field_31, category: :soft_validation).first.message).to eql("You told us this person is aged 22 years and retired.")
          expect(parser.errors.where(:field_31, category: :soft_validation).first.message).to eql("You told us this person is aged 22 years and retired.")
        end
      end
    end
  end

  describe "#log" do
    describe "#noint" do
      context "when field is set to 1" do
        let(:attributes) { valid_attributes.merge({ field_17: 1 }) }

        it "is correctly set" do
          expect(parser.log.noint).to be(1)
        end
      end

      context "when field is set to 2" do
        let(:attributes) { valid_attributes.merge({ field_17: 2 }) }

        it "is correctly set" do
          expect(parser.log.noint).to be(2)
        end
      end
    end

    describe "#uprn" do
      let(:attributes) { setup_section_params.merge({ field_22: "12" }) }

      it "is correctly set" do
        expect(parser.log.uprn).to eql("12")
      end
    end

    describe "#uprn_known" do
      context "when uprn known" do
        let(:attributes) { setup_section_params.merge({ field_22: "12" }) }

        it "is correctly set" do
          expect(parser.log.uprn_known).to be(1)
        end
      end

      context "when uprn not known" do
        let(:attributes) { setup_section_params.merge({ field_22: nil }) }

        it "is correctly set" do
          expect(parser.log.uprn_known).to be(0)
        end
      end
    end

    describe "#address_line1" do
      let(:attributes) { setup_section_params.merge({ field_23: "some street" }) }

      it "is correctly set" do
        expect(parser.log.address_line1).to eql("some street")
      end
    end

    describe "#address_line2" do
      let(:attributes) { setup_section_params.merge({ field_24: "some other street" }) }

      it "is correctly set" do
        expect(parser.log.address_line2).to eql("some other street")
      end
    end

    describe "#town_or_city" do
      let(:attributes) { setup_section_params.merge({ field_25: "some town" }) }

      it "is correctly set" do
        expect(parser.log.town_or_city).to eql("some town")
      end
    end

    describe "#county" do
      let(:attributes) { setup_section_params.merge({ field_26: "some county" }) }

      it "is correctly set" do
        expect(parser.log.county).to eql("some county")
      end
    end

    describe "#ethnic_group" do
      context "when field_33 is 20" do
        let(:attributes) { setup_section_params.merge({ field_33: "20" }) }

        it "is correctly set" do
          expect(parser.log.ethnic_group).to be(0)
        end
      end
    end

    describe "#ethnic_group2" do
      let(:attributes) { setup_section_params.merge({ field_40: "1" }) }

      it "is correctly set" do
        expect(parser.log.ethnic_group2).to be(0)
      end

      context "when field_40 is 20" do
        let(:attributes) { setup_section_params.merge({ field_40: "20" }) }

        it "is correctly set" do
          expect(parser.log.ethnic_group2).to be(0)
        end
      end
    end

    describe "#ethnicbuy2" do
      let(:attributes) { setup_section_params.merge({ field_40: "1" }) }

      it "is correctly set" do
        expect(parser.log.ethnicbuy2).to be(1)
      end
    end

    describe "#nationality_all" do
      context "when field_34 is a 3 digit nationality code" do
        let(:attributes) { setup_section_params.merge({ field_34: "036" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all).to be(36)
          expect(parser.log.nationality_all_group).to be(12)
        end
      end

      context "when field_34 is a nationality code without the trailing 0s" do
        let(:attributes) { setup_section_params.merge({ field_34: "36" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all).to be(36)
          expect(parser.log.nationality_all_group).to be(12)
        end
      end

      context "when field_34 is a nationality code with trailing 0s" do
        let(:attributes) { setup_section_params.merge({ field_34: "0036" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all).to be(36)
          expect(parser.log.nationality_all_group).to be(12)
        end
      end

      context "when field_34 is 0" do
        let(:attributes) { setup_section_params.merge({ field_34: "0" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all).to be(0)
          expect(parser.log.nationality_all_group).to be(0)
        end
      end

      context "when field_34 is 000" do
        let(:attributes) { setup_section_params.merge({ field_34: "000" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all).to be(0)
          expect(parser.log.nationality_all_group).to be(0)
        end
      end

      context "when field_34 is 0000" do
        let(:attributes) { setup_section_params.merge({ field_34: "0000" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all).to be(0)
          expect(parser.log.nationality_all_group).to be(0)
        end
      end

      context "when field_34 is 826" do
        let(:attributes) { setup_section_params.merge({ field_34: "826" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all).to be(826)
          expect(parser.log.nationality_all_group).to be(826)
        end
      end

      context "when field_34 is 826 with trailing 0s" do
        let(:attributes) { setup_section_params.merge({ field_34: "0826" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all).to be(826)
          expect(parser.log.nationality_all_group).to be(826)
        end
      end

      context "when field_34 is not a valid option" do
        let(:attributes) { setup_section_params.merge({ field_34: "123123" }) }

        it "is correctly set" do
          parser.valid?
          expect(parser.log.nationality_all).to be(nil)
          expect(parser.log.nationality_all_group).to be(nil)
          expect(parser.errors["field_34"]).to include("Select a valid nationality")
        end
      end
    end

    describe "#nationality_all_buyer2" do
      context "when field_41 is a 3 digit nationality code" do
        let(:attributes) { setup_section_params.merge({ field_41: "036" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all_buyer2).to be(36)
          expect(parser.log.nationality_all_buyer2_group).to be(12)
        end
      end

      context "when field_41 is a nationality code without the trailing 0s" do
        let(:attributes) { setup_section_params.merge({ field_41: "36" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all_buyer2).to be(36)
          expect(parser.log.nationality_all_buyer2_group).to be(12)
        end
      end

      context "when field_41 is a nationality code with trailing 0s" do
        let(:attributes) { setup_section_params.merge({ field_41: "0036" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all_buyer2).to be(36)
          expect(parser.log.nationality_all_buyer2_group).to be(12)
        end
      end

      context "when field_41 is 0" do
        let(:attributes) { setup_section_params.merge({ field_41: "0" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all_buyer2).to be(0)
          expect(parser.log.nationality_all_buyer2_group).to be(0)
        end
      end

      context "when field_41 is 000" do
        let(:attributes) { setup_section_params.merge({ field_41: "000" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all_buyer2).to be(0)
          expect(parser.log.nationality_all_buyer2_group).to be(0)
        end
      end

      context "when field_41 is 0000" do
        let(:attributes) { setup_section_params.merge({ field_41: "0000" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all_buyer2).to be(0)
          expect(parser.log.nationality_all_buyer2_group).to be(0)
        end
      end

      context "when field_41 is 826" do
        let(:attributes) { setup_section_params.merge({ field_41: "826" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all_buyer2).to be(826)
          expect(parser.log.nationality_all_buyer2_group).to be(826)
        end
      end

      context "when field_41 is 826 with trailing 0s" do
        let(:attributes) { setup_section_params.merge({ field_41: "0826" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all_buyer2).to be(826)
          expect(parser.log.nationality_all_buyer2_group).to be(826)
        end
      end

      context "when field_41 is not a valid option" do
        let(:attributes) { setup_section_params.merge({ field_41: "123123" }) }

        it "is correctly set" do
          parser.valid?
          expect(parser.log.nationality_all_buyer2).to be(nil)
          expect(parser.log.nationality_all_buyer2_group).to be(nil)
          expect(parser.errors["field_41"]).to include("Select a valid nationality")
        end
      end
    end

    describe "#buy2living" do
      let(:attributes) { setup_section_params.merge({ field_70: "1" }) }

      it "is correctly set" do
        expect(parser.log.buy2living).to be(1)
      end
    end

    describe "#prevtenbuy2" do
      let(:attributes) { setup_section_params.merge({ field_71: "R" }) }

      it "is correctly set" do
        expect(parser.log.prevtenbuy2).to be(0)
      end
    end

    describe "#hhregres" do
      let(:attributes) { setup_section_params.merge({ field_72: "1" }) }

      it "is correctly set" do
        expect(parser.log.hhregres).to be(1)
      end
    end

    describe "#hhregresstill" do
      let(:attributes) { setup_section_params.merge({ field_73: "4" }) }

      it "is correctly set" do
        expect(parser.log.hhregresstill).to be(4)
      end
    end

    describe "#prevshared" do
      let(:attributes) { setup_section_params.merge({ field_84: "3" }) }

      it "is correctly set" do
        expect(parser.log.prevshared).to be(3)
      end
    end

    describe "#staircasesale" do
      let(:attributes) { setup_section_params.merge({ field_89: "1" }) }

      it "is correctly set" do
        expect(parser.log.staircasesale).to be(1)
      end
    end

    describe "#soctenant" do
      context "when discounted ownership" do
        let(:attributes) { valid_attributes.merge({ field_8: "2" }) }

        it "is set to nil" do
          expect(parser.log.soctenant).to be_nil
        end
      end

      context "when outright sale" do
        let(:attributes) { valid_attributes.merge({ field_8: "3" }) }

        it "is set to nil" do
          expect(parser.log.soctenant).to be_nil
        end
      end

      context "when shared ownership" do
        context "when prevten is a social housing type" do
          let(:attributes) { valid_attributes.merge({ field_8: "1", field_61: "1" }) }

          it "is set to yes" do
            expect(parser.log.soctenant).to be(1)
          end
        end

        context "when prevten is not a social housing type" do
          context "and prevtenbuy2 is a social housing type" do
            let(:attributes) { valid_attributes.merge({ field_8: "1", field_61: "3", field_71: "2" }) }

            it "is set to yes" do
              expect(parser.log.soctenant).to be(1)
            end
          end

          context "and prevtenbuy2 is not a social housing type" do
            let(:attributes) { valid_attributes.merge({ field_8: "1", field_61: "3", field_71: "4" }) }

            it "is set to no" do
              expect(parser.log.soctenant).to be(2)
            end
          end

          context "and prevtenbuy2 is blank" do
            let(:attributes) { valid_attributes.merge({ field_8: "1", field_61: "3", field_71: nil }) }

            it "is set to no" do
              expect(parser.log.soctenant).to be(2)
            end
          end
        end
      end
    end

    describe "with living before purchase years for shared ownership more than 0" do
      let(:attributes) { setup_section_params.merge({ field_8: "1", field_85: "1" }) }

      it "is sets living before purchase asked to yes and sets the correct living before purchase years" do
        expect(parser.log.proplen_asked).to be(0)
        expect(parser.log.proplen).to be(1)
      end
    end

    describe "with living before purchase years for discounted ownership more than 0" do
      let(:attributes) { setup_section_params.merge({ field_8: "2", field_113: "1" }) }

      it "is sets living before purchase asked to yes and sets the correct living before purchase years" do
        expect(parser.log.proplen_asked).to be(0)
        expect(parser.log.proplen).to be(1)
      end
    end

    describe "with living before purchase years for shared ownership set to 0" do
      let(:attributes) { setup_section_params.merge({ field_8: "1", field_85: "0" }) }

      it "is sets living before purchase asked to no" do
        expect(parser.log.proplen_asked).to be(1)
        expect(parser.log.proplen).to be_nil
      end
    end

    describe "with living before purchase 0 years for discounted ownership set to 0" do
      let(:attributes) { setup_section_params.merge({ field_8: "2", field_113: "0" }) }

      it "is sets living before purchase asked to no" do
        expect(parser.log.proplen_asked).to be(1)
        expect(parser.log.proplen).to be_nil
      end
    end

    context "when mscharge is given, but is set to 0 for shared ownership" do
      let(:attributes) { valid_attributes.merge(field_112: "0") }

      it "does not override variables correctly" do
        log = parser.log
        expect(log["has_mscharge"]).to eq(0) # no
        expect(log["mscharge"]).to be_nil
      end
    end

    context "when mscharge is given, but is set to 0 for discounted ownership" do
      let(:attributes) { valid_attributes.merge(field_8: "2", field_124: "0") }

      it "does not override variables correctly" do
        log = parser.log
        expect(log["has_mscharge"]).to eq(0) # no
        expect(log["mscharge"]).to be_nil
      end
    end

    context "when mscharge is given, but is set to 0 for outright sale" do
      let(:attributes) { valid_attributes.merge(field_8: "3", field_131: "0") }

      it "does not override variables correctly" do
        log = parser.log
        expect(log["has_mscharge"]).to eq(0) # no
        expect(log["mscharge"]).to be_nil
      end
    end

    describe "shared ownership sale type" do
      context "when 32 is selected for shared ownership type" do
        let(:attributes) { valid_attributes.merge(field_9: "32") }

        it "sets the value correctly" do
          log = parser.log
          expect(log.type).to eq(32)
        end
      end
    end

    describe "#managing_organisation_id" do
      let(:attributes) { setup_section_params }

      context "when user is part of the owning organisation" do
        it "sets managing organisation to the correct organisation" do
          parser.valid?
          expect(parser.log.owning_organisation_id).to be(owning_org.id)
          expect(parser.log.managing_organisation_id).to be(managing_org.id)
        end
      end

      context "when blank" do
        let(:attributes) { { bulk_upload:, field_2: "" } }

        it "is not permitted as setup error" do
          parser.valid?
          setup_errors = parser.errors.select { |e| e.options[:category] == :setup }

          expect(setup_errors.find { |e| e.attribute == :field_2 }.message).to eql("You must answer reported by")
        end

        it "blocks log creation" do
          parser.valid?
          expect(parser).to be_block_log_creation
        end
      end

      context "when cannot find managing org" do
        let(:attributes) { { bulk_upload:, field_2: "donotexist" } }

        it "is not permitted as setup error" do
          parser.valid?
          setup_errors = parser.errors.select { |e| e.options[:category] == :setup }

          expect(setup_errors.find { |e| e.attribute == :field_2 }.message).to eql("You must answer reported by")
        end

        it "blocks log creation" do
          parser.valid?
          expect(parser).to be_block_log_creation
        end
      end

      context "when not affiliated with managing org" do
        let(:unaffiliated_org) { create(:organisation, :with_old_visible_id) }

        let(:attributes) { { bulk_upload:, field_1: owning_org.old_visible_id, field_2: unaffiliated_org.old_visible_id } }

        it "is not permitted as setup error" do
          parser.valid?
          setup_errors = parser.errors.select { |e| e.options[:category] == :setup }

          expect(setup_errors.find { |e| e.attribute == :field_2 }.message).to eql("This organisation does not have a relationship with the owning organisation")
        end

        it "blocks log creation" do
          parser.valid?
          expect(parser).to be_block_log_creation
        end
      end
    end
  end

  describe "#owning_organisation_id" do
    let(:attributes) { setup_section_params }

    context "when owning organisation does not own stock" do
      let(:owning_org) { create(:organisation, :with_old_visible_id, holds_own_stock: false) }
      let(:attributes) { setup_section_params }

      it "is not permitted as setup error" do
        parser.valid?
        setup_errors = parser.errors.select { |e| e.options[:category] == :setup }

        expect(setup_errors.find { |e| e.attribute == :field_1 }.message).to eql("The owning organisation code provided is for an organisation that does not own stock")
      end

      it "blocks log creation" do
        parser.valid?
        expect(parser).to be_block_log_creation
      end
    end
  end

  describe "#spreadsheet_duplicate_hash" do
    it "returns a hash" do
      expect(parser.spreadsheet_duplicate_hash).to be_a(Hash)
    end
  end

  describe "#add_duplicate_found_in_spreadsheet_errors" do
    it "adds errors" do
      expect { parser.add_duplicate_found_in_spreadsheet_errors }.to change(parser.errors, :size)
    end
  end
end
