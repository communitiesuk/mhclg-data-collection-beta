require "rails_helper"

RSpec.describe BulkUpload::Sales::Year2025::RowParser do
  subject(:parser) { described_class.new(attributes) }

  let(:now) { Time.zone.parse("01/05/2025") }

  let(:attributes) { { bulk_upload: } }
  let(:bulk_upload) { create(:bulk_upload, :sales, user:, year: 2025) }
  let(:user) { create(:user, organisation: owning_org) }
  let(:owning_org) { create(:organisation, :with_old_visible_id) }
  let(:managing_org) { create(:organisation, :with_old_visible_id) }

  let(:setup_section_params) do
    {
      bulk_upload:,
      field_1: now.day.to_s, # sale day
      field_2: now.month.to_s, # sale month
      field_3: now.strftime("%g"), # sale year
      field_4: owning_org.old_visible_id, # organisation
      field_5: managing_org.old_visible_id, # organisation
      field_6: user.email, # user
      field_7: "test id", # purchase id
      field_8: "1", # owhershipsch
      field_9: "2", # shared ownership sale type
      field_10: "1", # staircasing
      field_12: "2", # joint purchase
      field_14: "1", # noint
      field_15: "1", # privacy notice
    }
  end
  let(:valid_attributes) do
    {
      bulk_upload:,
      field_1: "12",
      field_2: "5",
      field_3: "25",
      field_4: owning_org.old_visible_id,
      field_5: managing_org.old_visible_id,
      field_7: "test id",
      field_8: "1",
      field_9: "2",
      field_10: "1",
      field_12: "1",
      field_13: "2",
      field_14: "1",
      field_15: "1",
      field_16: "1",
      field_17: "2",
      field_18: "1",
      field_19: "12",
      field_20: "Address line 1",
      field_24: "CR0",
      field_25: "4BB",
      field_26: "E09000008",
      field_27: "3",
      field_28: "32",
      field_29: "M",
      field_30: "12",
      field_31: "28",
      field_32: "1",
      field_33: "1",
      field_34: "R",
      field_35: "32",
      field_36: "F",
      field_37: "17",
      field_38: "28",
      field_39: "2",
      field_40: "1",
      field_41: "0",
      field_58: "1",
      field_59: "1",
      field_60: "A1",
      field_61: "1AA",
      field_62: "E09000008",
      field_63: "3",
      field_65: "3",
      field_67: "5",
      field_68: "3",
      field_69: "3",
      field_70: "30000",
      field_71: "1",
      field_72: "15000",
      field_73: "1",
      field_74: "4",
      field_75: "20000",
      field_76: "3",
      field_79: "5",
      field_80: "24",
      field_81: "3",
      field_82: "2022",
      field_83: "1",
      field_84: "1",
      field_85: "1",
      field_107: "250000",
      field_108: "25",
      field_109: "1",
      field_89: "5000",
      field_90: "20",
      field_96: "10",
      field_97: "40",
      field_98: "1",
      field_99: "2",
      field_94: "200",
      field_91: "20000",
      field_111: "800",
      field_100: "05",
      field_101: "04",
      field_102: "2020",
      field_103: "4",
      field_104: "06",
      field_105: "07",
      field_106: "2023",
      field_110: "900",
    }
  end

  around do |example|
    create(:organisation_relationship, parent_organisation: owning_org, child_organisation: managing_org)

    Timecop.freeze(Time.zone.local(2026, 2, 22)) do
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
        parser.field_4 = "1"
      end

      it "returns false" do
        expect(parser).not_to be_blank_row
      end
    end

    context "when the only populated fields are empty strings or whitespace" do
      before do
        parser.field_6 = " "
        parser.field_17 = ""
      end

      it "returns true" do
        expect(parser).to be_blank_row
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
    context "when field_59 is 1" do
      let(:attributes) do
        {
          bulk_upload:,
          field_59: 1,
        }
      end

      it "sets previous postcode known to yes" do
        expect(parser.log.ppcodenk).to eq(0)
      end
    end

    context "when field_59 is 2" do
      let(:attributes) do
        {
          bulk_upload:,
          field_59: 2,
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
          field_70: "R", # income 1
          field_72: "R", # income 2
          field_75: "R", # savings
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
          field_70: "30000", # income 1
          field_72: "0", # income 2
          field_75: "12420", # savings
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
          parser.valid?
          expect { parser.valid? }.not_to change(parser.errors, :count)
        end
      end

      context "when valid row" do
        let(:attributes) { valid_attributes }

        it "returns true" do
          expect(parser).to be_valid
        end

        it "instantiates a log with everything completed", aggregate_failures: true do
          parser.valid?

          questions = parser.send(:questions).reject do |q|
            parser.send(:log).optional_fields.include?(q.id) || q.completed?(parser.send(:log))
          end

          expect(questions.map(&:id).size).to eq(0)
          expect(questions.map(&:id)).to eql([])
        end
      end

      describe "#validate_nulls" do
        context "when non-setup questions are null" do
          let(:attributes) { setup_section_params.merge({ field_29: "" }) }

          it "fetches the question's check_answer_label if it exists" do
            parser.valid?
            expect(parser.errors[:field_29]).to eql([I18n.t("validations.not_answered", question: "buyer 1’s gender identity.")])
          end
        end

        context "when other null error is added" do
          let(:attributes) { setup_section_params.merge({ field_20: nil }) }

          it "only has one error added to the field" do
            parser.valid?
            expect(parser.errors[:field_20]).to eql([I18n.t("validations.sales.2025.bulk_upload.address.not_answered")])
          end
        end

        context "when an invalid value error has been added" do
          let(:attributes) { setup_section_params.merge({ field_10: "2", field_32: "100" }) }

          it "does not add an additional error" do
            parser.valid?
            expect(parser.errors[:field_32].length).to eq(1)
            expect(parser.errors[:field_32]).to include(match I18n.t("validations.sales.2025.bulk_upload.invalid_option", question: ""))
          end
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
        parser.valid?

        errors = parser.errors.select { |e| e.options[:category] == :setup }.map(&:attribute).sort

        expect(errors).to eql(%i[field_1 field_14 field_15 field_2 field_3 field_4 field_5 field_8])
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
        parser.valid?

        errors = parser.errors.select { |e| e.options[:category] == :setup }.map(&:attribute).sort

        expect(errors).to eql(%i[field_1 field_10 field_12 field_14 field_15 field_2 field_3 field_4 field_5 field_9])
      end
    end

    context "when setup section not complete it's shared ownership joint purchase" do
      let(:attributes) do
        {
          bulk_upload:,
          field_7: "test id",
          field_8: "1",
          field_9: "2",
          field_12: "1",
        }
      end

      it "has errors on correct setup fields" do
        parser.valid?

        errors = parser.errors.select { |e| e.options[:category] == :setup }.map(&:attribute).sort

        expect(errors).to eql(%i[field_1 field_10 field_13 field_14 field_15 field_2 field_3 field_4 field_5])
      end
    end

    context "when setup section not complete and type is discounted ownership" do
      let(:attributes) do
        {
          bulk_upload:,
          field_7: "test id",
          field_8: "2",
          field_11: nil,
        }
      end

      it "has errors on correct setup fields" do
        parser.valid?

        errors = parser.errors.select { |e| e.options[:category] == :setup }.map(&:attribute).sort

        expect(errors).to eql(%i[field_1 field_11 field_12 field_14 field_15 field_2 field_3 field_4 field_5])
      end
    end

    context "when setup section not complete and it's discounted ownership joint purchase" do
      let(:attributes) do
        {
          bulk_upload:,
          field_28: "2",
          field_43: "8",
          field_36: "1",
        }
      end

      it "has errors on correct setup fields" do
        parser.valid?

        errors = parser.errors.select { |e| e.options[:category] == :setup }.map(&:attribute).sort

        expect(errors).to eql(%i[field_1 field_14 field_15 field_2 field_3 field_4 field_5 field_8])
      end
    end

    describe "#field_4" do # owning org
      context "when no data given" do
        let(:attributes) { setup_section_params.merge(field_4: nil) }

        it "is not permitted as setup error" do
          parser.valid?
          expect(parser.errors.where(:field_4, category: :setup).map(&:message)).to eql([I18n.t("validations.sales.2025.bulk_upload.not_answered", question: "owning organisation.")])
        end

        it "blocks log creation" do
          parser.valid?
          expect(parser).to be_block_log_creation
        end
      end

      context "when cannot find owning org" do
        let(:attributes) { { bulk_upload:, field_4: "donotexist" } }

        it "is not permitted as a setup error" do
          parser.valid?
          expect(parser.errors.where(:field_4, category: :setup).map(&:message)).to eql([I18n.t("validations.sales.2025.bulk_upload.owning_organisation.not_found")])
        end

        it "blocks log creation" do
          parser.valid?
          expect(parser).to be_block_log_creation
        end
      end

      context "when not affiliated with owning org" do
        let(:unaffiliated_org) { create(:organisation, :with_old_visible_id) }

        let(:attributes) { { bulk_upload:, field_4: unaffiliated_org.old_visible_id } }

        it "is not permitted as setup error" do
          parser.valid?
          expect(parser.errors.where(:field_4, category: :setup).map(&:message)).to eql([I18n.t("validations.sales.2025.bulk_upload.owning_organisation.not_permitted.not_support")])
        end

        it "blocks log creation" do
          parser.valid?
          expect(parser).to be_block_log_creation
        end
      end

      context "when user's org has absorbed owning organisation with stock owners" do
        let(:merged_org) { create(:organisation, :with_old_visible_id, holds_own_stock: true) }
        let(:merged_org_stock_owner) { create(:organisation, :with_old_visible_id, holds_own_stock: true) }

        let(:attributes) { { bulk_upload:, field_4: merged_org_stock_owner.old_visible_id } }

        before do
          create(:organisation_relationship, parent_organisation: merged_org_stock_owner, child_organisation: merged_org)
          merged_org.update!(absorbing_organisation: user.organisation, merge_date: Time.zone.today)
          merged_org.reload
          user.organisation.reload
        end

        it "is permitted" do
          parser.valid?
          expect(parser.errors.where(:field_4)).not_to be_present
        end
      end

      context "when user's org has absorbed owning organisation" do
        let(:merged_org) { create(:organisation, :with_old_visible_id, holds_own_stock: true) }

        let(:attributes) { { bulk_upload:, field_4: merged_org.old_visible_id, field_6: user.email } }

        before do
          merged_org.update!(absorbing_organisation: user.organisation, merge_date: Time.zone.today)
          merged_org.reload
          user.organisation.reload
          user.reload
        end

        it "is permitted" do
          parser = described_class.new(attributes)

          parser.valid?
          expect(parser.errors.where(:field_4)).not_to be_present
          expect(parser.errors.where(:field_6)).not_to be_present
        end
      end

      context "when user's org has absorbed owning organisation before the startdate" do
        let(:merged_org) { create(:organisation, :with_old_visible_id, holds_own_stock: true) }

        let(:attributes) { setup_section_params.merge({ field_4: merged_org.old_visible_id, field_6: user.email }) }

        before do
          merged_org.update!(absorbing_organisation: user.organisation, merge_date: Time.zone.today - 3.years)
          merged_org.reload
          user.organisation.reload
          user.reload
        end

        it "is not permitted" do
          parser = described_class.new(attributes)

          parser.valid?
          expect(parser.errors[:field_4]).to include(/The owning organisation must be active on the sale completion date/)
          expect(parser.errors[:field_1]).to include(/Enter a date when the owning organisation was active/)
          expect(parser.errors[:field_2]).to include(/Enter a date when the owning organisation was active/)
          expect(parser.errors[:field_3]).to include(/Enter a date when the owning organisation was active/)
        end
      end

      context "when user is an unaffiliated non-support user and bulk upload organisation is affiliated with the owning organisation" do
        let(:affiliated_org) { create(:organisation, :with_old_visible_id) }
        let(:unaffiliated_user) { create(:user, organisation: create(:organisation)) }
        let(:attributes) { { bulk_upload:, field_4: affiliated_org.old_visible_id } }
        let(:organisation_id) { unaffiliated_user.organisation_id }

        before do
          create(:organisation_relationship, parent_organisation: owning_org, child_organisation: affiliated_org)
          bulk_upload.update!(organisation_id:, user: unaffiliated_user)
        end

        it "blocks log creation and adds an error to field_4" do
          parser = described_class.new(attributes)
          parser.valid?
          expect(parser).to be_block_log_creation
          expect(parser.errors[:field_4]).to include(I18n.t("validations.sales.2025.bulk_upload.owning_organisation.not_permitted.not_support"))
        end
      end

      context "when user is an unaffiliated support user and bulk upload organisation is affiliated with the owning organisation" do
        let(:affiliated_org) { create(:organisation, :with_old_visible_id) }
        let(:unaffiliated_support_user) { create(:user, :support, organisation: create(:organisation)) }
        let(:attributes) { { bulk_upload:, field_4: affiliated_org.old_visible_id } }
        let(:organisation_id) { affiliated_org.id }

        before do
          create(:organisation_relationship, parent_organisation: owning_org, child_organisation: affiliated_org)
          bulk_upload.update!(organisation_id:, user: unaffiliated_support_user)
        end

        it "does not block log creation and does not add an error to field_4" do
          parser = described_class.new(attributes)
          parser.valid?
          expect(parser.errors[:field_4]).not_to include(I18n.t("validations.sales.2025.bulk_upload.owning_organisation.not_permitted.not_support"))
        end
      end
    end

    describe "#field_6" do # username for assigned_to
      context "when blank" do
        let(:attributes) { setup_section_params.merge(bulk_upload:, field_6: nil) }

        it "is permitted" do
          parser.valid?
          expect(parser.errors[:field_6]).to be_blank
        end

        it "sets assigned to to bulk upload user" do
          parser.valid?
          expect(parser.log.assigned_to).to eq(bulk_upload.user)
        end

        it "sets created by to bulk upload user" do
          parser.valid?
          expect(parser.log.created_by).to eq(bulk_upload.user)
        end
      end

      context "when blank and bulk upload user is support" do
        let(:bulk_upload) { create(:bulk_upload, :sales, user: create(:user, :support), year: 2025) }

        let(:attributes) { setup_section_params.merge(bulk_upload:, field_6: nil) }

        it "is not permitted" do
          parser.valid?
          expect(parser.errors[:field_6]).to be_present
          expect(parser.errors[:field_6]).to include(I18n.t("validations.sales.2025.bulk_upload.not_answered", question: "what is the CORE username of the account this sales log should be assigned to?"))
        end

        it "blocks log creation" do
          parser.valid?
          expect(parser).to be_block_log_creation
        end
      end

      context "when user could not be found" do
        let(:attributes) { { bulk_upload:, field_6: "idonotexist@example.com" } }

        it "is not permitted" do
          parser.valid?
          expect(parser.errors[:field_6]).to be_present
        end
      end

      context "when an unaffiliated user" do
        let(:other_user) { create(:user) }

        let(:attributes) { { bulk_upload:, field_4: owning_org.old_visible_id, field_6: other_user.email } }

        it "is not permitted as a setup error" do
          parser.valid?
          expect(parser.errors.where(:field_6, category: :setup)).to be_present
        end

        it "blocks log creation" do
          parser.valid?
          expect(parser).to be_block_log_creation
        end
      end

      context "when a user part of owning org" do
        let(:other_user) { create(:user, organisation: owning_org) }

        let(:attributes) { { bulk_upload:, field_4: owning_org.old_visible_id, field_6: other_user.email } }

        it "is permitted" do
          parser.valid?
          expect(parser.errors[:field_6]).to be_blank
        end

        it "sets assigned to to the user" do
          parser.valid?
          expect(parser.log.assigned_to).to eq(other_user)
        end

        it "sets created by to bulk upload user" do
          parser.valid?
          expect(parser.log.created_by).to eq(bulk_upload.user)
        end
      end

      context "when email matches other than casing" do
        let(:other_user) { create(:user, organisation: owning_org) }

        let(:attributes) { { bulk_upload:, field_4: owning_org.old_visible_id, field_6: other_user.email.upcase! } }

        it "is permitted" do
          parser.valid?
          expect(parser.errors[:field_6]).to be_blank
        end
      end
    end

    describe "fields 1, 2, 3 => saledate" do
      context "when all of these fields are blank" do
        let(:attributes) { setup_section_params.merge({ field_1: nil, field_2: nil, field_3: nil }) }

        it "returns them as setup errors" do
          parser.valid?
          expect(parser.errors.where(:field_1, category: :setup)).to be_present
          expect(parser.errors.where(:field_2, category: :setup)).to be_present
          expect(parser.errors.where(:field_3, category: :setup)).to be_present
        end
      end

      context "when one of these fields is blank" do
        let(:attributes) { setup_section_params.merge({ field_1: "1", field_2: "1", field_3: nil }) }

        it "returns an error only on blank field as setup error" do
          parser.valid?
          expect(parser.errors[:field_1]).to be_blank
          expect(parser.errors[:field_2]).to be_blank
          expect(parser.errors.where(:field_3, category: :setup)).to be_present
        end
      end

      context "when field 3 is 4 digits instead of 2" do
        let(:attributes) { setup_section_params.merge({ bulk_upload:, field_3: "2025" }) }

        it "correctly sets the date" do
          parser.valid?
          expect(parser.errors.where(:field_3, category: :setup)).to be_empty
          expect(parser.log.saledate).to eq(Time.zone.local(2025, 5, 1))
        end
      end

      context "when field 2 is not 2 or 4 digits" do
        let(:attributes) { setup_section_params.merge({ bulk_upload:, field_3: "202" }) }

        it "returns a setup error" do
          parser.valid?
          expect(parser.errors.where(:field_3, category: :setup).map(&:message)).to include(I18n.t("validations.sales.2025.bulk_upload.saledate.year_not_two_or_four_digits"))
        end
      end

      context "when invalid date given" do
        let(:attributes) { setup_section_params.merge({ field_1: "a", field_2: "12", field_3: "2023" }) }

        it "does not raise an error" do
          expect { parser.valid? }.not_to raise_error
        end
      end

      context "when inside of collection year" do
        around do |example|
          Timecop.freeze(Date.new(2025, 10, 1)) do
            example.run
          end
        end

        let(:attributes) { setup_section_params.merge({ field_1: "1", field_2: "10", field_3: "25" }) }

        let(:bulk_upload) { create(:bulk_upload, :sales, user:, year: 2025) }

        it "does not return errors" do
          parser.valid?
          expect(parser.errors[:field_1]).not_to be_present
          expect(parser.errors[:field_2]).not_to be_present
          expect(parser.errors[:field_3]).not_to be_present
        end
      end

      context "when outside of collection year" do
        around do |example|
          Timecop.freeze(Date.new(2023, 4, 2)) do
            example.run
          end
        end

        let(:attributes) { setup_section_params.merge({ field_1: "1", field_2: "1", field_3: "22" }) }

        let(:bulk_upload) { create(:bulk_upload, :sales, user:, year: 2023) }

        it "returns setup errors" do
          parser.valid?
          expect(parser.errors.where(:field_1, category: :setup)).to be_present
          expect(parser.errors.where(:field_2, category: :setup)).to be_present
          expect(parser.errors.where(:field_3, category: :setup)).to be_present
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

        error_message = I18n.t("validations.sales.2025.bulk_upload.duplicate")

        [
          :field_4, # Owning org
          :field_1, # Sale completion date
          :field_2, # Sale completion date
          :field_3, # Sale completion date
          :field_24, # Postcode
          :field_25, # Postcode
          :field_28, # Buyer 1 age
          :field_29, # Buyer 1 gender
          :field_32, # Buyer 1 working situation
          :field_7, # Purchaser code
        ].each do |field|
          expect(parser.errors[field]).to include(error_message)
        end
      end
    end

    context "when a hidden log already exists in db" do
      before do
        parser.log.status = "pending"
        parser.log.save!
      end

      it "is a valid row" do
        expect(parser).to be_valid
      end

      it "does not add duplicate errors" do
        parser.valid?

        [
          :field_4, # Owning org
          :field_1, # Sale completion date
          :field_2, # Sale completion date
          :field_3, # Sale completion date
          :field_24, # Postcode
          :field_25, # Postcode
          :field_28, # Buyer 1 age
          :field_29, # Buyer 1 gender
          :field_32, # Buyer 1 working situation
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
          parser.valid?
          expect(parser.errors.where(:field_8, category: :setup)).to be_present
        end
      end
    end

    describe "#field_9" do # type for shared ownership sale
      context "when an invalid option" do
        let(:attributes) { setup_section_params.merge({ field_9: "100" }) }

        it "returns setup error" do
          parser.valid?
          expect(parser.errors.where(:field_9, category: :setup)).to be_present
        end
      end
    end

    describe "#field_11" do # type for discounted sale
      context "when an invalid option" do
        let(:attributes) { setup_section_params.merge({ field_11: "100" }) }

        it "returns setup error" do
          parser.valid?
          expect(parser.errors.where(:field_11, category: :setup)).to be_present
        end
      end
    end

    describe "#field_115" do # percentage discount
      context "when percentage discount over 70" do
        let(:attributes) { valid_attributes.merge({ field_8: "2", field_10: "2", field_11: "9", field_115: "71" }) }

        it "returns correct error" do
          parser.valid?
          expect(parser.errors.where(:field_115).map(&:message)).to include(I18n.t("validations.sales.2025.bulk_upload.numeric.within_range", field: "Percentage discount", min: "0%", max: "70%"))
        end
      end

      context "when percentage discount not over 70" do
        let(:attributes) { valid_attributes.merge({ field_8: "2", field_10: "2", field_115: "70" }) }

        it "does not return error" do
          parser.valid?
          expect(parser.errors.where(:field_115)).not_to be_present
        end
      end

      context "when percentage less than 0" do
        let(:attributes) { valid_attributes.merge({ field_8: "2", field_10: "2", field_115: "-1" }) }

        it "returns correct error" do
          parser.valid?
          expect(parser.errors.where(:field_115).map(&:message)).to include(I18n.t("validations.sales.2025.bulk_upload.numeric.within_range", field: "Percentage discount", min: "0%", max: "70%"))
        end
      end
    end

    describe "#field_12" do # joint purchase
      context "when an invalid option" do
        let(:attributes) { setup_section_params.merge({ field_12: "100" }) }

        it "returns a setup error" do
          parser.valid?
          expect(parser.errors.where(:field_12, category: :setup)).to be_present
        end
      end
    end

    describe "#field_13" do # more than 2 joint buyers?
      context "when invalid option and must be answered" do
        let(:attributes) { setup_section_params.merge({ field_12: "1", field_13: "100" }) }

        it "returns a setup error" do
          parser.valid?
          expect(parser.errors.where(:field_13, category: :setup)).to be_present
        end
      end
    end

    describe "UPRN and address fields" do
      context "when a valid UPRN is given" do
        let(:attributes) { setup_section_params.merge({ field_19: "12" }) }

        it "does not add errors" do
          parser.valid?
          %i[field_19 field_20 field_21 field_22 field_23 field_24 field_25].each do |field|
            expect(parser.errors[field]).to be_empty
          end
        end

        it "sets UPRN, UPRN known, and UPRN confirmed" do
          expect(parser.log.uprn).to eq("12")
          expect(parser.log.uprn_known).to eq(1)
          expect(parser.log.uprn_confirmed).to eq(1)
        end
      end

      context "when an invalid UPRN is given" do
        context "and address fields are not given" do
          let(:attributes) { setup_section_params.merge({ field_19: "1234567890123" }) }

          it "adds an appropriate error to the UPRN field" do
            parser.valid?
            expect(parser.errors[:field_19]).to eql(["UPRN must be 12 digits or less."])
          end

          it "adds errors to missing key address fields" do
            parser.valid?
            expect(parser.errors[:field_20]).to eql([I18n.t("validations.sales.2025.bulk_upload.not_answered", question: "address line 1.")])
            expect(parser.errors[:field_22]).to eql([I18n.t("validations.sales.2025.bulk_upload.not_answered", question: "town or city.")])
            expect(parser.errors[:field_24]).to eql([I18n.t("validations.sales.2025.bulk_upload.not_answered", question: "part 1 of postcode.")])
            expect(parser.errors[:field_25]).to eql([I18n.t("validations.sales.2025.bulk_upload.not_answered", question: "part 2 of postcode.")])
          end
        end

        context "and address fields are given" do
          let(:attributes) { setup_section_params.merge({ field_19: "1234567890123", field_20: "address line 1", field_22: "town or city", field_24: "AA1", field_25: "1AA" }) }

          it "adds an error to the UPRN field only" do
            parser.valid?
            expect(parser.errors[:field_19]).to eql(["UPRN must be 12 digits or less."])
            %i[field_20 field_22 field_24 field_25].each do |field|
              expect(parser.errors[field]).to be_empty
            end
          end

          it "does not do an address search" do
            parser.valid?
            expect(a_request(:any, /api\.os\.uk\/search\/places\/v1\/find/)).not_to have_been_made
          end
        end
      end

      context "when no UPRN is given" do
        context "and no address fields are given" do
          let(:attributes) { setup_section_params }

          it "adds appropriate errors to UPRN and key address fields" do
            parser.valid?
            expect(parser.errors[:field_19]).to eql([I18n.t("validations.sales.2025.bulk_upload.address.not_answered")])
            expect(parser.errors[:field_20]).to eql([I18n.t("validations.sales.2025.bulk_upload.address.not_answered")])
            expect(parser.errors[:field_22]).to eql([I18n.t("validations.sales.2025.bulk_upload.address.not_answered")])
            expect(parser.errors[:field_24]).to eql([I18n.t("validations.sales.2025.bulk_upload.address.not_answered")])
            expect(parser.errors[:field_25]).to eql([I18n.t("validations.sales.2025.bulk_upload.address.not_answered")])
          end
        end

        context "and some key address field is missing" do
          let(:attributes) { setup_section_params.merge({ field_22: "town or city", field_24: "AA1", field_25: "1AA" }) }

          it "adds errors to UPRN and the missing key address field" do
            parser.valid?
            expect(parser.errors[:field_19]).to eql([I18n.t("validations.sales.2025.bulk_upload.address.not_answered")])
            expect(parser.errors[:field_20]).to eql([I18n.t("validations.sales.2025.bulk_upload.address.not_answered")])
            expect(parser.errors[:field_22]).to be_empty
            expect(parser.errors[:field_24]).to be_empty
            expect(parser.errors[:field_25]).to be_empty
          end
        end

        context "and all key address fields are present" do
          let(:attributes) { setup_section_params.merge({ field_19: nil, field_20: "address line 1", field_22: "town or city", field_24: "AA1", field_25: "1AA" }) }

          context "and an address can be found with a high enough match rating" do
            before do
              stub_request(:get, /api\.os\.uk\/search\/places\/v1\/find/)
                .to_return(status: 200, body: { results: [{ DPA: { MATCH: 0.7, BUILDING_NAME: "", POST_TOWN: "", POSTCODE: "AA1 1AA", UPRN: "1" } }] }.to_json, headers: {})
            end

            it "does not add errors" do
              parser.valid?
              %i[field_19 field_20 field_21 field_22 field_23 field_24 field_25].each do |field|
                expect(parser.errors[field]).to be_empty
              end
            end
          end

          context "when no address can be found" do
            before do
              stub_request(:get, /api\.os\.uk\/search\/places\/v1\/find/)
                .to_return(status: 200, body: { results: [] }.to_json, headers: {})
            end

            it "adds address not found errors to address fields only" do
              parser.valid?
              expect(parser.errors[:field_19]).to be_empty
              %i[field_20 field_21 field_22 field_23 field_24 field_25].each do |field|
                expect(parser.errors[field]).to eql([I18n.t("validations.sales.2025.bulk_upload.address.not_found")])
              end
            end
          end

          context "when no address has a high enough match rating" do
            before do
              stub_request(:get, /api\.os\.uk\/search\/places\/v1\/find/)
                .to_return(status: 200, body: { results: [{ DPA: { MATCH: 0.6, BUILDING_NAME: "", POST_TOWN: "", POSTCODE: "AA1 1AA", UPRN: "1" } }] }.to_json, headers: {})
            end

            it "adds address not found errors to address fields only" do
              parser.valid?
              expect(parser.errors[:field_19]).to be_empty
              %i[field_20 field_21 field_22 field_23 field_24 field_25].each do |field|
                expect(parser.errors[field]).to eql([I18n.t("validations.sales.2025.bulk_upload.address.not_determined")])
              end
            end
          end
        end
      end
    end

    describe "#field_15" do # data protection
      let(:attributes) { setup_section_params.merge({ field_15: nil }) }

      before do
        parser.valid?
      end

      context "when not answered" do
        it "returns a setup error" do
          expect(parser.errors.where(:field_15, category: :setup)).to be_present
        end
      end

      context "when the privacy notice is not accepted" do
        it "cannot be nulled" do
          expect(parser.errors[:field_15]).to eq(["You must show or give the buyer access to the MHCLG privacy notice before you can submit this log."])
        end
      end
    end

    [
      %w[age1_known details_known_1 age1 field_28 field_34 field_36],
      %w[age2_known details_known_2 age2 field_35 field_34 field_36],
      %w[age3_known details_known_3 age3 field_43 field_42 field_44],
      %w[age4_known details_known_4 age4 field_47 field_46 field_48],
      %w[age5_known details_known_5 age5 field_51 field_50 field_52],
      %w[age6_known details_known_6 age6 field_55 field_54 field_56],
    ].each do |known, details_known, age, field, relationship, gender|
      describe "##{known} and ##{age}" do
        context "when #{field} is blank" do
          context "and person details are blank" do
            let(:attributes) { setup_section_params.merge({ field.to_s => nil, relationship.to_sym => nil, gender.to_sym => nil, field_15: "1", field_41: "5" }) }

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
            let(:attributes) { setup_section_params.merge({ field.to_sym => nil, relationship.to_sym => "C", gender.to_sym => "X", field_15: "1", field_41: "5" }) }

            it "does not set ##{age}" do
              parser.valid?
              expect(parser.errors[field.to_sym]).to include(/You must answer/)
            end
          end
        end

        context "when #{field} is R" do
          let(:attributes) { setup_section_params.merge({ field.to_s => "R", field_14: "1", field_41: "5", field_15: "1" }) }

          it "sets ##{known} 1" do
            expect(parser.log.public_send(known)).to be(1)
          end

          it "sets ##{age} to nil" do
            expect(parser.log.public_send(age)).to be_nil
          end
        end

        context "when #{field} is a number" do
          let(:attributes) { setup_section_params.merge({ field.to_s => "50", field_14: "1", field_41: "5", field_15: "1" }) }

          it "sets ##{known} to 0" do
            expect(parser.log.public_send(known)).to be(0)
          end

          it "sets ##{age} to given age" do
            expect(parser.log.public_send(age)).to be(50)
          end
        end

        context "when #{field} is a non-sensical value" do
          let(:attributes) { setup_section_params.merge({ field.to_s => "A", field_14: "1", field_41: "5", field_15: "1" }) }

          it "sets ##{known} to 0" do
            expect(parser.log.public_send(known)).to be(0)
          end

          it "sets ##{age} to nil" do
            expect(parser.log.public_send(age)).to be_nil
          end
        end
      end
    end

    describe "field_39" do # ecstat2
      context "when buyer 2 has no age but has ecstat as child" do
        let(:attributes) { valid_attributes.merge({ field_35: nil, field_39: "9" }) }

        it "a custom validation is applied" do
          parser.valid?

          expect(parser.errors[:field_39]).to include I18n.t("validations.sales.2025.bulk_upload.ecstat2.buyer_cannot_be_child")
        end
      end

      context "when buyer 2 is under 16" do
        let(:attributes) { valid_attributes.merge({ field_35: "9" }) }

        it "a custom validation is applied" do
          parser.valid?

          validation_message = "Buyer 2’s age must be between 16 and 110."
          expect(parser.errors[:field_35]).to include validation_message
        end
      end

      context "when buyer 2 is over 16 but has ecstat as child" do
        let(:attributes) { valid_attributes.merge({ field_35: "17", field_39: "9" }) }

        it "a custom validation is applied" do
          parser.valid?

          expect(parser.errors[:field_39]).to include I18n.t("validations.sales.2025.bulk_upload.ecstat2.buyer_cannot_be_over_16_and_child")
          expect(parser.errors[:field_35]).to include I18n.t("validations.sales.2025.bulk_upload.age2.buyer_cannot_be_over_16_and_child")
        end
      end

      context "when person 2 a child but not a buyer" do
        let(:attributes) { valid_attributes.merge({ field_12: 2, field_35: "10", field_39: "9" }) }

        it "does not add errors to their age and ecstat fields" do
          parser.valid?
          expect(parser.errors[:field_35]).to be_empty
          expect(parser.errors[:field_39]).to be_empty
        end
      end
    end

    describe "field_32" do # ecstat1
      context "when buyer 1 has no age but has ecstat as child" do
        let(:attributes) { valid_attributes.merge({ field_28: nil, field_32: "9" }) }

        it "a custom validation is applied" do
          parser.valid?

          expect(parser.errors[:field_32]).to include I18n.t("validations.sales.2025.bulk_upload.ecstat1.buyer_cannot_be_child")
        end
      end

      context "when buyer 1 is under 16" do
        let(:attributes) { valid_attributes.merge({ field_28: "9" }) }

        it "a custom validation is applied" do
          parser.valid?

          validation_message = "Buyer 1’s age must be between 16 and 110."
          expect(parser.errors[:field_28]).to include validation_message
        end
      end

      context "when buyer 1 is over 16 but has ecstat as child" do
        let(:attributes) { valid_attributes.merge({ field_28: "17", field_32: "9" }) }

        it "a custom validation is applied" do
          parser.valid?

          expect(parser.errors[:field_32]).to include I18n.t("validations.sales.2025.bulk_upload.ecstat1.buyer_cannot_be_over_16_and_child")
          expect(parser.errors[:field_28]).to include I18n.t("validations.sales.2025.bulk_upload.age1.buyer_cannot_be_over_16_and_child")
        end
      end
    end

    describe "#field_33" do # will buyer1 live in property?
      context "when not a possible value" do
        let(:attributes) { valid_attributes.merge({ field_10: "2", field_33: "3" }) }

        it "is not valid" do
          parser.valid?
          expect(parser.errors).to include(:field_33)
        end
      end
    end

    describe "#field_109" do # staircasing mortgageused
      context "when invalid value" do
        let(:attributes) { setup_section_params.merge(field_109: "4") }

        it "returns correct errors" do
          parser.valid?
          expect(parser.errors[:field_109]).to include(I18n.t("validations.sales.2025.bulk_upload.invalid_option", question: "was a mortgage used for this staircasing transaction?"))

          parser.log.blank_invalid_non_setup_fields!
          parser.log.save!
          expect(parser.log.mortgageused).to be_nil
        end
      end

      context "when value is 3 and stairowned is not 100" do
        let(:attributes) { setup_section_params.merge(field_109: "3", field_10: "1", field_96: "50", field_97: "99", field_120: nil) }

        it "returns correct errors" do
          parser.valid?
          expect(parser.errors[:field_109]).to include("The percentage owned has to be 100% if the mortgage used is 'Don’t know'")

          parser.log.blank_invalid_non_setup_fields!
          parser.log.save!
          expect(parser.log.mortgageused).to be_nil
        end
      end

      context "when value is 3 and stairowned is not answered" do
        let(:attributes) { setup_section_params.merge(field_109: "3", field_10: "1", field_96: "50", field_97: nil, field_120: nil) }

        it "does not add errors" do
          parser.valid?
          expect(parser.errors[:field_109]).to be_empty
        end
      end

      context "when value is 3 and stairowned is 100" do
        let(:attributes) { setup_section_params.merge(field_109: "3", field_10: "1", field_96: "50", field_97: "100", field_120: nil) }

        it "does not add errors and sets mortgage used to 3" do
          parser.valid?
          expect(parser.log.mortgageused).to eq(3)
          expect(parser.log.stairowned).to eq(100)
          expect(parser.log.deposit).to be_nil
          expect(parser.errors[:field_109]).to be_empty
          expect(parser.errors[:field_120]).to be_empty
        end
      end
    end

    describe "#field_88" do # shared ownership mortgageused
      context "when invalid value" do
        let(:attributes) { setup_section_params.merge(field_10: "2", field_88: "4") }

        it "returns correct errors" do
          parser.valid?
          expect(parser.errors[:field_88]).to include(I18n.t("validations.sales.2025.bulk_upload.invalid_option", question: "was a mortgage used for the purchase of this property? - Shared ownership."))

          parser.log.blank_invalid_non_setup_fields!
          parser.log.save!
          expect(parser.log.mortgageused).to be_nil
        end
      end

      context "when value is 3 and stairowned is not answered" do
        let(:attributes) { setup_section_params.merge(field_88: "3", field_10: "2", field_96: "50", field_97: nil, field_120: nil) }

        it "returns correct errors" do
          parser.valid?
          expect(parser.errors[:field_88]).to include(I18n.t("validations.invalid_option", question: "was a mortgage used for the purchase of this property?"))

          parser.log.blank_invalid_non_setup_fields!
          parser.log.save!
          expect(parser.log.mortgageused).to be_nil
        end
      end

      context "with non staircasing mortgage error" do
        let(:attributes) { setup_section_params.merge(field_9: "30", field_88: "1", field_89: "10000", field_91: "5000", field_86: "30000", field_87: "28", field_10: "2") }

        it "does not add a BU error on type (because it's a setup field and would block log creation)" do
          parser.valid?
          expect(parser.errors[:field_9]).to be_empty
        end

        it "includes errors on other related fields" do
          parser.valid?
          expect(parser.errors[:field_89]).to include("The mortgage (£10,000.00) and cash deposit (£5,000.00) added together is £15,000.00.</br></br>The full purchase price (£30,000.00) multiplied by the percentage equity stake purchased (28.0%) is £8,400.00.</br></br>These two amounts should be the same.")
          expect(parser.errors[:field_91]).to include("The mortgage (£10,000.00) and cash deposit (£5,000.00) added together is £15,000.00.</br></br>The full purchase price (£30,000.00) multiplied by the percentage equity stake purchased (28.0%) is £8,400.00.</br></br>These two amounts should be the same.")
          expect(parser.errors[:field_86]).to include("The mortgage (£10,000.00) and cash deposit (£5,000.00) added together is £15,000.00.</br></br>The full purchase price (£30,000.00) multiplied by the percentage equity stake purchased (28.0%) is £8,400.00.</br></br>These two amounts should be the same.")
          expect(parser.errors[:field_87]).to include("The mortgage (£10,000.00) and cash deposit (£5,000.00) added together is £15,000.00.</br></br>The full purchase price (£30,000.00) multiplied by the percentage equity stake purchased (28.0%) is £8,400.00.</br></br>These two amounts should be the same.")
        end

        it "does not add errors to other ownership type fields" do
          parser.valid?
          expect(parser.errors[:field_117]).to be_empty
          expect(parser.errors[:field_120]).to be_empty
          expect(parser.errors[:field_113]).to be_empty
          expect(parser.errors[:field_107]).to be_empty
          expect(parser.errors[:field_108]).to be_empty
          expect(parser.errors[:field_116]).to be_empty
          expect(parser.errors[:field_109]).to be_empty
        end
      end
    end

    describe "#field_116" do
      let(:attributes) { valid_attributes.merge({ field_8: "2", field_11: "9", field_116: "3" }) }

      it "does not allow 3 (don't know) as an option for discounted ownership" do
        parser.valid?
        expect(parser.errors[:field_116]).to include(I18n.t("validations.invalid_option", question: "was a mortgage used for the purchase of this property?"))

        parser.log.blank_invalid_non_setup_fields!
        parser.log.save!
        expect(parser.log.mortgageused).to be_nil
      end

      context "when validate_discounted_ownership_value is triggered" do
        let(:attributes) { setup_section_params.merge(field_113: 100, field_120: 100, field_8: 2, field_10: 2, field_11: 9, field_116: 2, field_115: 10) }

        it "only adds errors to the discounted ownership field" do
          parser.valid?
          expect(parser.errors[:field_88]).to be_empty
          expect(parser.errors[:field_117]).to include("The mortgage and cash deposit (£100.00) added together is £100.00.</br></br>The full purchase price (£100.00) subtracted by the sum of the full purchase price (£100.00) multiplied by the percentage discount (10.0%) is £90.00.</br></br>These two amounts should be the same.")
          expect(parser.errors[:field_126]).to be_empty
        end
      end
    end

    describe "soft validations" do
      context "when soft validation is triggered" do
        let(:attributes) { valid_attributes.merge({ field_10: 2, field_28: 22, field_32: 5 }) }

        it "adds an error to the relevant fields" do
          parser.valid?
          expect(parser.errors.where(:field_28, category: :soft_validation)).to be_present
          expect(parser.errors.where(:field_32, category: :soft_validation)).to be_present
        end

        it "populates with correct error message" do
          parser.valid?
          expect(parser.errors.where(:field_28, category: :soft_validation).first.message).to eql("You told us this person is aged 22 years and retired. The minimum expected retirement age in England is 66.")
          expect(parser.errors.where(:field_32, category: :soft_validation).first.message).to eql("You told us this person is aged 22 years and retired. The minimum expected retirement age in England is 66.")
        end
      end
    end

    describe "log_already_exists?" do
      let(:attributes) { { bulk_upload: } }

      before do
        build(:sales_log, owning_organisation: nil, saledate: nil, purchid: nil, age1: nil, sex1: nil, ecstat1: nil).save(validate: false)
      end

      it "does not add duplicate logs validation to the blank row" do
        expect(parser.log_already_exists?).to eq(false)
      end
    end
  end

  describe "#log" do
    describe "#noint" do
      context "when field is set to 1" do
        let(:attributes) { valid_attributes.merge({ field_14: 1 }) }

        it "is correctly set" do
          expect(parser.log.noint).to be(1)
        end
      end

      context "when field is set to 2" do
        let(:attributes) { valid_attributes.merge({ field_14: 2 }) }

        it "is correctly set" do
          expect(parser.log.noint).to be(2)
        end
      end
    end

    describe "#uprn" do
      let(:attributes) { setup_section_params.merge({ field_19: "12" }) }

      it "is correctly set" do
        expect(parser.log.uprn).to eql("12")
      end
    end

    describe "#uprn_known" do
      context "when uprn known" do
        let(:attributes) { setup_section_params.merge({ field_19: "12" }) }

        it "is correctly set" do
          expect(parser.log.uprn_known).to be(1)
        end
      end

      context "when uprn not known" do
        let(:attributes) { setup_section_params.merge({ field_19: nil }) }

        it "is correctly set" do
          expect(parser.log.uprn_known).to be(0)
        end
      end
    end

    describe "#address_line1" do
      let(:attributes) { setup_section_params.merge({ field_20: "some street" }) }

      it "is correctly set" do
        expect(parser.log.address_line1).to eql("some street")
      end
    end

    describe "#address_line2" do
      let(:attributes) { setup_section_params.merge({ field_21: "some other street" }) }

      it "is correctly set" do
        expect(parser.log.address_line2).to eql("some other street")
      end
    end

    describe "#town_or_city" do
      let(:attributes) { setup_section_params.merge({ field_22: "some town" }) }

      it "is correctly set" do
        expect(parser.log.town_or_city).to eql("some town")
      end
    end

    describe "#county" do
      let(:attributes) { setup_section_params.merge({ field_23: "some county" }) }

      it "is correctly set" do
        expect(parser.log.county).to eql("some county")
      end
    end

    describe "#ethnic_group" do
      context "when field_30 is 20" do
        let(:attributes) { setup_section_params.merge({ field_30: "20" }) }

        it "is correctly set" do
          expect(parser.log.ethnic_group).to be(0)
        end
      end
    end

    describe "#ethnic_group2" do
      let(:attributes) { setup_section_params.merge({ field_37: "1" }) }

      it "is correctly set" do
        expect(parser.log.ethnic_group2).to be(0)
      end

      context "when field_37 is 20" do
        let(:attributes) { setup_section_params.merge({ field_37: "20" }) }

        it "is correctly set" do
          expect(parser.log.ethnic_group2).to be(0)
        end
      end
    end

    describe "#ethnicbuy2" do
      let(:attributes) { setup_section_params.merge({ field_37: "1" }) }

      it "is correctly set" do
        expect(parser.log.ethnicbuy2).to be(1)
      end
    end

    describe "#nationality_all" do
      context "when field_31 is a 3 digit nationality code" do
        let(:attributes) { setup_section_params.merge({ field_31: "036" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all).to be(36)
          expect(parser.log.nationality_all_group).to be(12)
        end
      end

      context "when field_31 is a nationality code without the trailing 0s" do
        let(:attributes) { setup_section_params.merge({ field_31: "36" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all).to be(36)
          expect(parser.log.nationality_all_group).to be(12)
        end
      end

      context "when field_31 is a nationality code with trailing 0s" do
        let(:attributes) { setup_section_params.merge({ field_31: "0036" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all).to be(36)
          expect(parser.log.nationality_all_group).to be(12)
        end
      end

      context "when field_31 is 0" do
        let(:attributes) { setup_section_params.merge({ field_31: "0" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all).to be(0)
          expect(parser.log.nationality_all_group).to be(0)
        end
      end

      context "when field_31 is 000" do
        let(:attributes) { setup_section_params.merge({ field_31: "000" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all).to be(0)
          expect(parser.log.nationality_all_group).to be(0)
        end
      end

      context "when field_31 is 0000" do
        let(:attributes) { setup_section_params.merge({ field_31: "0000" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all).to be(0)
          expect(parser.log.nationality_all_group).to be(0)
        end
      end

      context "when field_31 is 826" do
        let(:attributes) { setup_section_params.merge({ field_31: "826" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all).to be(826)
          expect(parser.log.nationality_all_group).to be(826)
        end
      end

      context "when field_31 is 826 with trailing 0s" do
        let(:attributes) { setup_section_params.merge({ field_31: "0826" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all).to be(826)
          expect(parser.log.nationality_all_group).to be(826)
        end
      end

      context "when field_31 is not a valid option" do
        let(:attributes) { setup_section_params.merge({ field_31: "123123" }) }

        it "is correctly set" do
          parser.valid?
          expect(parser.log.nationality_all).to be(nil)
          expect(parser.log.nationality_all_group).to be(nil)
          expect(parser.errors["field_31"]).to include(I18n.t("validations.sales.2025.bulk_upload.nationality.invalid"))
        end
      end
    end

    describe "#nationality_all_buyer2" do
      context "when field_38 is a 3 digit nationality code" do
        let(:attributes) { setup_section_params.merge({ field_38: "036" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all_buyer2).to be(36)
          expect(parser.log.nationality_all_buyer2_group).to be(12)
        end
      end

      context "when field_38 is a nationality code without the trailing 0s" do
        let(:attributes) { setup_section_params.merge({ field_38: "36" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all_buyer2).to be(36)
          expect(parser.log.nationality_all_buyer2_group).to be(12)
        end
      end

      context "when field_38 is a nationality code with trailing 0s" do
        let(:attributes) { setup_section_params.merge({ field_38: "0036" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all_buyer2).to be(36)
          expect(parser.log.nationality_all_buyer2_group).to be(12)
        end
      end

      context "when field_38 is 0" do
        let(:attributes) { setup_section_params.merge({ field_38: "0" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all_buyer2).to be(0)
          expect(parser.log.nationality_all_buyer2_group).to be(0)
        end
      end

      context "when field_38 is 000" do
        let(:attributes) { setup_section_params.merge({ field_38: "000" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all_buyer2).to be(0)
          expect(parser.log.nationality_all_buyer2_group).to be(0)
        end
      end

      context "when field_38 is 0000" do
        let(:attributes) { setup_section_params.merge({ field_38: "0000" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all_buyer2).to be(0)
          expect(parser.log.nationality_all_buyer2_group).to be(0)
        end
      end

      context "when field_38 is 826" do
        let(:attributes) { setup_section_params.merge({ field_38: "826" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all_buyer2).to be(826)
          expect(parser.log.nationality_all_buyer2_group).to be(826)
        end
      end

      context "when field_38 is 826 with trailing 0s" do
        let(:attributes) { setup_section_params.merge({ field_38: "0826" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all_buyer2).to be(826)
          expect(parser.log.nationality_all_buyer2_group).to be(826)
        end
      end

      context "when field_38 is not a valid option" do
        let(:attributes) { setup_section_params.merge({ field_38: "123123" }) }

        it "is correctly set" do
          parser.valid?
          expect(parser.log.nationality_all_buyer2).to be(nil)
          expect(parser.log.nationality_all_buyer2_group).to be(nil)
          expect(parser.errors["field_38"]).to include(I18n.t("validations.sales.2025.bulk_upload.nationality.invalid"))
        end
      end
    end

    describe "#buy2living" do
      let(:attributes) { setup_section_params.merge({ field_63: "1" }) }

      it "is correctly set" do
        expect(parser.log.buy2living).to be(1)
      end
    end

    describe "#prevtenbuy2" do
      let(:attributes) { setup_section_params.merge({ field_64: "R" }) }

      it "is correctly set" do
        expect(parser.log.prevtenbuy2).to be(0)
      end
    end

    describe "#hhregres" do
      let(:attributes) { setup_section_params.merge({ field_65: "1" }) }

      it "is correctly set" do
        expect(parser.log.hhregres).to be(1)
      end
    end

    describe "#hhregresstill" do
      let(:attributes) { setup_section_params.merge({ field_66: "4" }) }

      it "is correctly set" do
        expect(parser.log.hhregresstill).to be(4)
      end
    end

    describe "#prevshared" do
      let(:attributes) { setup_section_params.merge({ field_77: "3" }) }

      it "is correctly set" do
        expect(parser.log.prevshared).to be(3)
      end
    end

    describe "#staircasesale" do
      let(:attributes) { setup_section_params.merge({ field_98: "1" }) }

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

      context "when shared ownership" do
        context "when prevten is a social housing type" do
          let(:attributes) { valid_attributes.merge({ field_8: "1", field_58: "1" }) }

          it "is set to yes" do
            expect(parser.log.soctenant).to be(1)
          end
        end

        context "when prevten is not a social housing type" do
          context "and prevtenbuy2 is a social housing type" do
            let(:attributes) { valid_attributes.merge({ field_8: "1", field_58: "3", field_64: "2" }) }

            it "is set to yes" do
              expect(parser.log.soctenant).to be(1)
            end
          end

          context "and prevtenbuy2 is not a social housing type" do
            let(:attributes) { valid_attributes.merge({ field_8: "1", field_58: "3", field_64: "4" }) }

            it "is set to no" do
              expect(parser.log.soctenant).to be(2)
            end
          end

          context "and prevtenbuy2 is blank" do
            let(:attributes) { valid_attributes.merge({ field_8: "1", field_58: "3", field_64: nil }) }

            it "is set to no" do
              expect(parser.log.soctenant).to be(2)
            end
          end
        end
      end
    end

    describe "with living before purchase years for shared ownership more than 0" do
      let(:attributes) { setup_section_params.merge({ field_8: "1", field_79: "1" }) }

      it "is sets living before purchase asked to yes and sets the correct living before purchase years" do
        expect(parser.log.proplen_asked).to be(0)
        expect(parser.log.proplen).to be(1)
      end
    end

    describe "with living before purchase years for discounted ownership more than 0" do
      let(:attributes) { setup_section_params.merge({ field_8: "2", field_112: "1" }) }

      it "is sets living before purchase asked to yes and sets the correct living before purchase years" do
        expect(parser.log.proplen_asked).to be(0)
        expect(parser.log.proplen).to be(1)
      end
    end

    describe "with living before purchase years for shared ownership set to 0" do
      let(:attributes) { setup_section_params.merge({ field_8: "1", field_79: "0" }) }

      it "is sets living before purchase asked to no" do
        expect(parser.log.proplen_asked).to be(1)
        expect(parser.log.proplen).to be_nil
      end
    end

    describe "with living before purchase 0 years for discounted ownership set to 0" do
      let(:attributes) { setup_section_params.merge({ field_8: "2", field_112: "0" }) }

      it "is sets living before purchase asked to no" do
        expect(parser.log.proplen_asked).to be(1)
        expect(parser.log.proplen).to be_nil
      end
    end

    context "when mscharge is given, but is set to 0 for shared ownership" do
      let(:attributes) { valid_attributes.merge(field_94: "0") }

      it "does not override variables correctly" do
        log = parser.log
        expect(log["has_mscharge"]).to eq(0) # no
        expect(log["mscharge"]).to be_nil
      end
    end

    context "when mscharge is given, but is set to 0 for discounted ownership" do
      let(:attributes) { valid_attributes.merge(field_8: "2", field_121: "0") }

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
        let(:attributes) { { bulk_upload:, field_5: "", field_3: "not blank" } }

        it "is not permitted as setup error" do
          parser.valid?
          setup_errors = parser.errors.select { |e| e.options[:category] == :setup }

          expect(setup_errors.find { |e| e.attribute == :field_5 }.message).to eql(I18n.t("validations.not_answered", question: "reported by."))
        end

        it "blocks log creation" do
          parser.valid?
          expect(parser).to be_block_log_creation
        end
      end

      context "when cannot find managing org" do
        let(:attributes) { { bulk_upload:, field_5: "donotexist" } }

        it "is not permitted as setup error" do
          parser.valid?
          setup_errors = parser.errors.select { |e| e.options[:category] == :setup }

          expect(setup_errors.find { |e| e.attribute == :field_5 }.message).to eql(I18n.t("validations.not_answered", question: "reported by."))
        end

        it "blocks log creation" do
          parser.valid?
          expect(parser).to be_block_log_creation
        end
      end

      context "when not affiliated with managing org" do
        let(:unaffiliated_org) { create(:organisation, :with_old_visible_id) }

        let(:attributes) { { bulk_upload:, field_4: owning_org.old_visible_id, field_5: unaffiliated_org.old_visible_id } }

        it "is not permitted as setup error" do
          parser.valid?
          setup_errors = parser.errors.select { |e| e.options[:category] == :setup }

          expect(setup_errors.find { |e| e.attribute == :field_5 }.message).to eql(I18n.t("validations.sales.2025.bulk_upload.assigned_to.managing_organisation_not_related"))
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

        expect(setup_errors.find { |e| e.attribute == :field_4 }.message).to eql(I18n.t("validations.sales.2025.bulk_upload.owning_organisation.not_stock_owner"))
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
