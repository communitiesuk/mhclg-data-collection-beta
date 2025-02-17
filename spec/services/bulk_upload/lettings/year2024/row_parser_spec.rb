require "rails_helper"

RSpec.describe BulkUpload::Lettings::Year2024::RowParser do
  subject(:parser) { described_class.new(attributes) }

  let(:now) { Time.zone.local(2024, 4, 5) }

  let(:attributes) { { bulk_upload: } }
  let(:bulk_upload) { create(:bulk_upload, :lettings, user:, needstype: nil, year: 2024) }
  let(:user) { create(:user, organisation: owning_org) }

  let(:owning_org) { create(:organisation, :with_old_visible_id) }
  let(:managing_org) { create(:organisation, :with_old_visible_id, rent_periods: [4, 1]) }
  let(:scheme) { create(:scheme, :with_old_visible_id, owning_organisation: owning_org) }
  let(:location) { create(:location, :with_old_visible_id, scheme:) }

  let(:setup_section_params) do
    {
      bulk_upload:,
      field_1: owning_org.old_visible_id,
      field_2: managing_org.old_visible_id,
      field_4: "1",
      field_7: "2",
      field_8: now.day.to_s,
      field_9: now.month.to_s,
      field_10: now.strftime("%g"),
      field_11: "1",
      field_15: "1",
    }
  end

  before do
    allow(FormHandler.instance).to receive(:lettings_in_crossover_period?).and_return(true)
    create(:organisation_relationship, parent_organisation: owning_org, child_organisation: managing_org)

    LaRentRange.create!(
      ranges_rent_id: "1",
      la: "E09000008",
      beds: 1,
      lettype: 7,
      soft_min: 12.41,
      soft_max: 118.85,
      hard_min: 9.87,
      hard_max: 200.99,
      start_year: 2024,
    )
  end

  around do |example|
    Timecop.freeze(Date.new(2024, 10, 1)) do
      FormHandler.instance.use_real_forms!
      example.run
    end
    Timecop.return
  end

  describe "#blank_row?" do
    context "when a new object" do
      it "returns true" do
        expect(parser).to be_blank_row
      end
    end

    context "when the only populated fields are whitespace" do
      before do
        parser.field_16 = " "
      end

      it "returns true" do
        expect(parser).to be_blank_row
      end
    end

    context "when any field is populated with something other than whitespace" do
      before do
        parser.field_1 = "1"
      end

      it "returns false" do
        expect(parser).not_to be_blank_row
      end
    end
  end

  describe "validations" do
    before do
      stub_request(:get, /api\.postcodes\.io/)
      .to_return(status: 200, body: "{\"status\":200,\"result\":{\"admin_district\":\"Manchester\", \"codes\":{\"admin_district\": \"E08000003\"}}}", headers: {})

      stub_request(:get, /api\.os\.uk\/search\/places\/v1\/find/)
        .to_return(status: 200, body: { results: [{ DPA: { MATCH: 0.9, BUILDING_NAME: "result address line 1", POST_TOWN: "result town or city", POSTCODE: "AA1 1AA", UPRN: "12345" } }] }.to_json, headers: {})

      stub_request(:get, /api\.os\.uk\/search\/places\/v1\/uprn/)
        .to_return(status: 200, body: '{"status":200,"results":[{"DPA":{
          "PO_BOX_NUMBER": "fake",
      "ORGANISATION_NAME": "org",
      "DEPARTMENT_NAME": "name",
      "SUB_BUILDING_NAME": "building",
      "BUILDING_NAME": "name",
      "BUILDING_NUMBER": "number",
      "DEPENDENT_THOROUGHFARE_NAME": "data",
      "THOROUGHFARE_NAME": "thing",
      "POST_TOWN": "London",
      "POSTCODE": "SE2 6RT"

         }}]}', headers: {})
    end

    describe "#valid?" do
      context "when the row is blank" do
        let(:attributes) { { bulk_upload: } }

        it "returns true" do
          expect(parser).to be_valid
        end
      end

      context "when calling the method multiple times" do
        let(:attributes) { { bulk_upload:, field_130: 2 } }

        it "does not add keep adding errors to the pile" do
          parser.valid?
          expect { parser.valid? }.not_to change(parser.errors, :count)
        end
      end

      describe "valid/invalid attributes" do
        let(:valid_attributes) do
          {
            bulk_upload:,
            field_13: "123",
            field_8: now.day.to_s,
            field_9: now.month.to_s,
            field_10: now.strftime("%g"),
            field_21: "EC1N",
            field_22: "2TD",
            field_1: owning_org.old_visible_id,
            field_2: managing_org.old_visible_id,
            field_11: "1",
            field_7: "2",
            field_26: "2",
            field_27: "1",
            field_28: "1",
            field_29: "1",
            field_36: "2",
            field_37: "1",
            field_38: "2",
            field_15: "1",

            field_42: "42",
            field_48: "41",
            field_52: "17",
            field_56: "18",
            field_60: "16",
            field_64: "14",
            field_68: "12",
            field_72: "20",

            field_43: "F",
            field_49: "M",
            field_53: "F",
            field_57: "M",
            field_61: "F",
            field_65: "M",
            field_69: "F",
            field_73: "M",

            field_44: "17",
            field_45: "826",

            field_47: "P",
            field_51: "C",
            field_55: "C",
            field_59: "R",
            field_63: "C",
            field_67: "C",
            field_71: "X",

            field_46: "1",
            field_50: "2",
            field_54: "7",
            field_58: "7",
            field_62: "8",
            field_66: "9",
            field_70: "0",
            field_74: "10",

            field_75: "1",
            field_76: "4",
            field_77: "1",

            field_78: "1",

            field_79: "1",
            field_80: "0",
            field_81: "0",
            field_82: "1",
            field_83: "0",

            field_85: "2",

            field_96: "11",
            field_97: "2",
            field_98: "31",
            field_100: "3",
            field_101: "11",

            field_102: "1",
            field_103: "EC1N",
            field_104: "2TD",

            field_106: "1",
            field_107: "1",
            field_108: "",
            field_109: "1",
            field_110: "",
            field_111: "",

            field_112: "1",
            field_113: "2",
            field_114: "2",
            field_115: "2",

            field_116: "2",

            field_117: "1",
            field_118: "2",
            field_119: "2300",
            field_120: "1",
            field_121: "4",

            field_123: "4",
            field_125: "1234.56",
            field_126: "43.32",
            field_127: "13.14",
            field_128: "101.11",
            field_129: "1",
            field_130: "34.56",

            field_24: "15",
            field_30: now.day.to_s,
            field_31: now.month.to_s,
            field_32: now.strftime("%g"),

            field_4: "1",

            field_16: "12",
          }
        end

        context "when valid row" do
          before do
            allow(FeatureToggle).to receive(:bulk_upload_duplicate_log_check_enabled?).and_return(true)
          end

          let(:attributes) { valid_attributes }

          it "returns true" do
            expect(parser).to be_valid
          end

          xit "instantiates a log with everything completed", aggregate_failures: true do
            parser.valid?

            questions = parser.send(:questions).reject do |q|
              parser.send(:log).optional_fields.include?(q.id) || q.completed?(parser.send(:log))
            end

            expect(questions.map(&:id).size).to eq(0)
            expect(questions.map(&:id)).to eql([])
          end

          context "when a general needs log already exists in the db" do
            before do
              parser.log.save!
              parser.instance_variable_set(:@valid, nil)
            end

            it "is not a valid row" do
              expect(parser).not_to be_valid
            end

            it "adds an error to all (and only) the fields used to determine duplicates" do
              parser.valid?

              error_message = I18n.t("validations.lettings.2024.bulk_upload.duplicate")

              [
                :field_1, # owning_organisation
                :field_8, # startdate
                :field_9, # startdate
                :field_10, # startdate
                :field_13, # tenancycode
                :field_21, # postcode_full
                :field_22, # postcode_full
                :field_23, # postcode_full
                :field_42, # age1
                :field_43, # sex1
                :field_46, # ecstat1
                :field_125, # brent
                :field_126, # scharge
                :field_127, # pscharge
                :field_128, # supcharg
              ].each do |field|
                expect(parser.errors[field]).to include(error_message)
              end

              expect(parser.errors[:field_6]).not_to include(error_message)
            end
          end

          context "when a general needs log already exists in the db but has a different tcharge" do
            let(:attributes) { valid_attributes.merge({ field_13: "tenant_code" }) }

            before do
              parser.log.save!
              saved_log = LettingsLog.find_by(tenancycode: "tenant_code")
              saved_log.update!(brent: saved_log.brent + 5)
              parser.instance_variable_set(:@valid, nil)
            end

            it "is a valid row (and not a duplicate)" do
              expect(parser).to be_valid
            end
          end

          context "when a supported housing log already exists in the db" do
            let(:attributes) { valid_attributes.merge({ field_4: "2", field_5: "S#{scheme.id}", field_6: location.old_visible_id, field_41: 3, field_122: 0 }) }

            before do
              parser.log.save!
              parser.instance_variable_set(:@valid, nil)
            end

            it "is not a valid row" do
              expect(parser).not_to be_valid
            end

            it "adds an error to all the fields used to determine duplicates" do
              parser.valid?

              error_message = I18n.t("validations.lettings.2024.bulk_upload.duplicate")

              [
                :field_1, # owning_organisation
                :field_8, # startdate
                :field_9, # startdate
                :field_10, # startdate
                :field_13, # tenancycode
                :field_6, # location
                :field_42, # age1
                :field_43, # sex1
                :field_46, # ecstat1
                :field_125, # brent
                :field_126, # scharge
                :field_127, # pscharge
                :field_128, # supcharg
              ].each do |field|
                expect(parser.errors[field]).to include(error_message)
              end

              expect(parser.errors[:field_21]).not_to include(error_message)
              expect(parser.errors[:field_22]).not_to include(error_message)
              expect(parser.errors[:field_23]).not_to include(error_message)
            end
          end

          context "with old core scheme and location ids" do
            context "when a supported housing log already exists in the db" do
              let(:attributes) { { bulk_upload:, field_4: "2", field_5: "123" } }

              before do
                parser.log.save!
                parser.instance_variable_set(:@valid, nil)
              end

              it "is not a valid row" do
                expect(parser).not_to be_valid
              end

              it "adds an error to all the fields used to determine duplicates" do
                parser.valid?

                error_message = I18n.t("validations.lettings.2024.bulk_upload.duplicate")

                [
                  :field_1, # owning_organisation
                  :field_8, # startdate
                  :field_9, # startdate
                  :field_10, # startdate
                  :field_13, # tenancycode
                  :field_6, # location
                  :field_42, # age1
                  :field_43, # sex1
                  :field_46, # ecstat1
                  :field_125, # brent
                  :field_126, # scharge
                  :field_127, # pscharge
                  :field_128, # supcharg
                ].each do |field|
                  expect(parser.errors[field]).to include(error_message)
                end

                expect(parser.errors[:field_21]).not_to include(error_message)
                expect(parser.errors[:field_22]).not_to include(error_message)
                expect(parser.errors[:field_23]).not_to include(error_message)
              end
            end

            context "when a supported housing log with chcharges already exists in the db" do
              let(:bulk_upload) { create(:bulk_upload, :lettings, user:, needstype: 2) }
              let(:attributes) do
                valid_attributes.merge({ field_5: "S#{scheme.id}",
                                         field_4: "2",
                                         field_11: "2",
                                         field_6: location.old_visible_id,
                                         field_1: owning_org.old_visible_id,
                                         field_122: 0,
                                         field_41: 4,
                                         field_124: "88" })
              end

              before do
                parser.log.save!
                parser.instance_variable_set(:@valid, nil)
              end

              it "is not a valid row" do
                expect(parser).not_to be_valid
              end

              it "adds an error to all the fields used to determine duplicates" do
                parser.valid?

                error_message = I18n.t("validations.lettings.2024.bulk_upload.duplicate")

                [
                  :field_1, # owning_organisation
                  :field_8, # startdate
                  :field_9, # startdate
                  :field_10, # startdate
                  :field_13, # tenancycode
                  :field_6, # location
                  :field_42, # age1
                  :field_43, # sex1
                  :field_46, # ecstat1
                  :field_124, # chcharge
                  :field_122, # household_charge
                ].each do |field|
                  expect(parser.errors[field]).to include(error_message)
                end

                expect(parser.errors[:field_21]).not_to include(error_message)
                expect(parser.errors[:field_22]).not_to include(error_message)
                expect(parser.errors[:field_23]).not_to include(error_message)
              end
            end

            context "when a supported housing log different chcharges already exists in the db" do
              let(:bulk_upload) { create(:bulk_upload, :lettings, user:, needstype: 2) }
              let(:attributes) do
                valid_attributes.merge({ field_5: "S#{scheme.id}",
                                         field_4: "2",
                                         field_11: "2",
                                         field_6: location.old_visible_id,
                                         field_1: owning_org.old_visible_id,
                                         field_122: 0,
                                         field_41: 4,
                                         field_124: "88" })
              end
              let(:attributes_too) do
                valid_attributes.merge({ field_5: "S#{scheme.id}",
                                         field_4: "2",
                                         field_11: "2",
                                         field_6: location.old_visible_id,
                                         field_1: owning_org.old_visible_id,
                                         field_122: 0,
                                         field_41: 4,
                                         field_124: "98" })
              end
              let(:parser_too) { described_class.new(attributes_too) }

              before do
                parser.log.save!
                parser.instance_variable_set(:@valid, nil)
              end

              it "is a valid row" do
                expect(parser_too).to be_valid
              end

              it "does not add an error to all the fields used to determine duplicates" do
                parser_too.valid?

                error_message = I18n.t("validations.lettings.2024.bulk_upload.duplicate")

                [
                  :field_1, # owning_organisation
                  :field_8, # startdate
                  :field_9, # startdate
                  :field_10, # startdate
                  :field_13, # tenancycode
                  :field_5, # location
                  :field_42, # age1
                  :field_43, # sex1
                  :field_46, # ecstat1
                ].each do |field|
                  expect(parser_too.errors[field]).not_to include(error_message)
                end
              end
            end
          end

          context "with new core scheme and location ids" do
            context "when a supported housing log already exists in the db" do
              let(:attributes) { { bulk_upload:, field_4: "2", field_5: "S123" } }

              before do
                parser.log.save!
                parser.instance_variable_set(:@valid, nil)
              end

              it "is not a valid row" do
                expect(parser).not_to be_valid
              end

              it "adds an error to all the fields used to determine duplicates" do
                parser.valid?

                error_message = I18n.t("validations.lettings.2024.bulk_upload.duplicate")

                [
                  :field_1, # owning_organisation
                  :field_8, # startdate
                  :field_9, # startdate
                  :field_10, # startdate
                  :field_13, # tenancycode
                  :field_6, # location
                  :field_42, # age1
                  :field_43, # sex1
                  :field_46, # ecstat1
                ].each do |field|
                  expect(parser.errors[field]).to include(error_message)
                end

                expect(parser.errors[:field_21]).not_to include(error_message)
                expect(parser.errors[:field_22]).not_to include(error_message)
                expect(parser.errors[:field_23]).not_to include(error_message)
              end
            end

            context "when a supported housing log with chcharges already exists in the db" do
              let(:bulk_upload) { create(:bulk_upload, :lettings, user:, needstype: 2) }
              let(:attributes) do
                valid_attributes.merge({ field_5: "S#{scheme.id}",
                                         field_4: "2",
                                         field_11: "2",
                                         field_6: location.id,
                                         field_1: owning_org.old_visible_id,
                                         field_122: 0,
                                         field_41: 4,
                                         field_124: "88" })
              end

              before do
                parser.log.save!
                parser.instance_variable_set(:@valid, nil)
              end

              it "is not a valid row" do
                expect(parser).not_to be_valid
              end

              it "adds an error to all the fields used to determine duplicates" do
                parser.valid?

                error_message = I18n.t("validations.lettings.2024.bulk_upload.duplicate")

                [
                  :field_1, # owning_organisation
                  :field_8, # startdate
                  :field_9, # startdate
                  :field_10, # startdate
                  :field_13, # tenancycode
                  :field_6, # location
                  :field_42, # age1
                  :field_43, # sex1
                  :field_46, # ecstat1
                  :field_124, # chcharge
                  :field_122, # household_charge
                ].each do |field|
                  expect(parser.errors[field]).to include(error_message)
                end

                expect(parser.errors[:field_21]).not_to include(error_message)
                expect(parser.errors[:field_22]).not_to include(error_message)
                expect(parser.errors[:field_23]).not_to include(error_message)
              end
            end

            context "when a supported housing log different chcharges already exists in the db" do
              let(:bulk_upload) { create(:bulk_upload, :lettings, user:, needstype: 2) }
              let(:attributes) do
                valid_attributes.merge({ field_5: "S#{scheme.id}",
                                         field_4: "2",
                                         field_11: "2",
                                         field_6: location.id,
                                         field_1: owning_org.old_visible_id,
                                         field_122: 0,
                                         field_41: 4,
                                         field_124: "88" })
              end
              let(:attributes_too) do
                valid_attributes.merge({ field_5: "S#{scheme.id}",
                                         field_4: "2",
                                         field_11: "2",
                                         field_6: location.id,
                                         field_1: owning_org.old_visible_id,
                                         field_122: 0,
                                         field_41: 4,
                                         field_124: "98" })
              end
              let(:parser_too) { described_class.new(attributes_too) }

              before do
                parser.log.save!
                parser.instance_variable_set(:@valid, nil)
              end

              it "is a valid row" do
                expect(parser_too).to be_valid
              end

              it "does not add an error to all the fields used to determine duplicates" do
                parser_too.valid?

                error_message = I18n.t("validations.lettings.2024.bulk_upload.duplicate")

                [
                  :field_1, # owning_organisation
                  :field_8, # startdate
                  :field_9, # startdate
                  :field_10, # startdate
                  :field_13, # tenancycode
                  :field_6, # location
                  :field_42, # age1
                  :field_43, # sex1
                  :field_46, # ecstat1
                  :field_125, # brent
                  :field_126, # scharge
                  :field_127, # pscharge
                  :field_128, # supcharg
                ].each do |field|
                  expect(parser_too.errors[field]).not_to include(error_message)
                end
              end
            end
          end

          context "when the rent range validation is triggered but the log has no scheme or location id" do
            let(:attributes) do
              setup_section_params.merge({ field_5: nil,
                                           field_6: nil,
                                           field_125: 300,
                                           field_123: 1,
                                           field_29: 1,
                                           field_4: 1,
                                           field_11: "2",
                                           field_23: "E09000008" })
            end

            it "is not a valid row" do
              expect(parser).not_to be_valid
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
                :field_1, # owning_organisation
                :field_8, # startdate
                :field_9, # startdate
                :field_10, # startdate
                :field_6, # location
                :field_21, # postcode_full
                :field_22, # postcode_full
                :field_23, # postcode_full
                :field_42, # age1
                :field_43, # sex1
                :field_46, # ecstat1
              ].each do |field|
                expect(parser.errors[field]).to be_blank
              end
            end
          end
        end

        context "when valid row with valid decimal (integer) field_11" do
          before do
            allow(FeatureToggle).to receive(:bulk_upload_duplicate_log_check_enabled?).and_return(true)
          end

          let(:attributes) { valid_attributes.merge(field_11: "1.00") }

          it "returns true" do
            expect(parser).to be_valid
          end
        end

        context "when valid row with invalid decimal (non-integer) field_11" do
          before do
            allow(FeatureToggle).to receive(:bulk_upload_duplicate_log_check_enabled?).and_return(true)
          end

          let(:attributes) { valid_attributes.merge(field_11: "1.56") }

          it "returns false" do
            expect(parser).not_to be_valid
          end
        end

        context "with a valid ethnic value" do
          context "when field_44 is 20" do
            let(:attributes) { valid_attributes.merge({ field_44: "20" }) }

            it "is correctly sets ethnic and ethnic group" do
              expect(parser.log.ethnic).to eq(20)
              expect(parser.log.ethnic_group).to eq(0)
            end
          end
        end

        context "when the privacy notice is not accepted" do
          let(:attributes) { valid_attributes.merge({ field_15: nil }) }

          it "cannot be nulled" do
            parser.valid?
            expect(parser.errors[:field_15]).to eq(["You must show or give the tenant access to the MHCLG privacy notice before you can submit this log."])
          end
        end

        context "when there is a :skip_bu_error error" do
          let(:managing_org) { create(:organisation, :with_old_visible_id, rent_periods: [4, 1]) }
          let(:attributes) { valid_attributes.merge({ field_123: 3, field_128: 80 }) }

          it "does not add that error" do
            parser.valid?

            expect(parser.log.errors.map(&:attribute).sort).to eql(%i[managing_organisation_id period])
            expect(parser.errors.map(&:attribute)).to eql(%i[field_123])
          end
        end
      end

      describe "#validate_nulls" do
        context "when non-setup questions are null" do
          let(:attributes) { setup_section_params.merge({ field_43: "" }) }

          it "fetches the question's check_answer_label if it exists" do
            parser.valid?
            expect(parser.errors[:field_43]).to eql([I18n.t("validations.lettings.2024.bulk_upload.not_answered", question: "lead tenant’s gender identity.")])
          end
        end

        context "when other null error is added" do
          let(:attributes) { setup_section_params.merge({ field_112: nil }) }

          it "only has one error added to the field" do
            parser.valid?
            expect(parser.errors[:field_112]).to eql([I18n.t("validations.lettings.2024.bulk_upload.not_answered", question: "was the letting made under the Choice-Based Lettings (CBL)?")])
          end
        end

        context "when an invalid value error has been added" do
          let(:attributes) { setup_section_params.merge({ field_116: "100" }) }

          it "does not add an additional error" do
            parser.valid?
            expect(parser.errors[:field_116].length).to eq(1)
            expect(parser.errors[:field_116]).to include(match I18n.t("validations.lettings.2024.bulk_upload.invalid_option", question: ""))
          end
        end
      end
    end

    context "when setup section not complete" do
      let(:attributes) { { bulk_upload:, field_13: "123" } }

      it "has errors on setup fields" do
        parser.valid?

        errors = parser.errors.select { |e| e.options[:category] == :setup }.map(&:attribute).sort

        expect(errors).to eql(%i[field_1 field_10 field_11 field_15 field_2 field_4 field_7 field_8 field_9])
      end
    end

    describe "#field_3" do # assigned_to
      context "when blank" do
        let(:attributes) { { bulk_upload:, field_3: "", field_4: 1 } }

        it "is permitted" do
          parser.valid?
          expect(parser.errors[:field_3]).to be_blank
        end

        it "sets assigned to to bulk upload user" do
          expect(parser.log.assigned_to).to eq(bulk_upload.user)
        end

        it "sets created by to bulk upload user" do
          expect(parser.log.created_by).to eq(bulk_upload.user)
        end
      end

      context "when blank and bulk upload user is support" do
        let(:bulk_upload) { create(:bulk_upload, :sales, user: create(:user, :support), year: 2024) }

        let(:attributes) { setup_section_params.merge(bulk_upload:, field_3: nil) }

        it "is not permitted" do
          parser.valid?
          expect(parser.errors[:field_3]).to be_present
          expect(parser.errors[:field_3]).to include(I18n.t("validations.lettings.2024.bulk_upload.not_answered", question: "what is the CORE username of the account this letting log should be assigned to?"))
        end

        it "blocks log creation" do
          parser.valid?
          expect(parser).to be_block_log_creation
        end
      end

      context "when user could not be found" do
        let(:attributes) { { bulk_upload:, field_3: "idonotexist@example.com" } }

        it "is not permitted" do
          parser.valid?
          expect(parser.errors[:field_3]).to be_present
        end
      end

      context "when an unaffiliated user" do
        let(:other_user) { create(:user) }

        let(:attributes) { { bulk_upload:, field_1: owning_org.old_visible_id, field_3: other_user.email, field_2: managing_org.old_visible_id } }

        it "is not permitted" do
          parser.valid?
          expect(parser.errors[:field_3]).to be_present
        end

        it "blocks log creation" do
          parser.valid?
          expect(parser).to be_block_log_creation
        end
      end

      context "when a user part of owning org" do
        let(:other_user) { create(:user, organisation: owning_org) }

        let(:attributes) { { bulk_upload:, field_1: owning_org.old_visible_id, field_3: other_user.email, field_2: managing_org.old_visible_id } }

        it "is permitted" do
          parser.valid?
          expect(parser.errors[:field_3]).to be_blank
        end

        it "sets assigned to to the user" do
          expect(parser.log.assigned_to).to eq(other_user)
        end

        it "sets created by to bulk upload user" do
          expect(parser.log.created_by).to eq(bulk_upload.user)
        end
      end

      context "when email matches other than casing" do
        let(:other_user) { create(:user, organisation: owning_org) }

        let(:attributes) { { bulk_upload:, field_1: owning_org.old_visible_id, field_3: other_user.email.upcase!, field_2: managing_org.old_visible_id } }

        it "is permitted" do
          parser.valid?
          expect(parser.errors[:field_3]).to be_blank
        end
      end

      context "when an user part of managing org" do
        let(:other_user) { create(:user, organisation: managing_org) }

        let(:attributes) { { bulk_upload:, field_1: owning_org.old_visible_id, field_3: other_user.email, field_2: managing_org.old_visible_id } }

        it "is permitted" do
          parser.valid?
          expect(parser.errors[:field_3]).to be_blank
        end
      end
    end

    describe "#field_5, field_6" do # scheme and location fields
      context "when nullable not permitted" do
        let(:attributes) { { bulk_upload:, field_4: "2", field_11: "2", field_5: nil, field_6: nil } }

        it "cannot be nulled" do
          parser.valid?
          expect(parser.errors[:field_5]).to eq([I18n.t("validations.lettings.2024.bulk_upload.not_answered", question: "scheme code.")])
          expect(parser.errors[:field_6]).to eq([I18n.t("validations.lettings.2024.bulk_upload.not_answered", question: "location code.")])
        end
      end

      context "when nullable permitted" do
        let(:attributes) { { bulk_upload:, field_4: "1", field_11: "1", field_5: nil, field_6: nil } }

        it "can be nulled" do
          parser.valid?
          expect(parser.errors[:field_5]).to be_blank
          expect(parser.errors[:field_6]).to be_blank
        end
      end

      context "when using New CORE ids" do
        let(:scheme) { create(:scheme, :with_old_visible_id, owning_organisation: owning_org) }
        let!(:location) { create(:location, :with_old_visible_id, scheme:) }

        before do
          parser.valid?
        end

        context "when matching scheme cannot be found" do
          let(:attributes) { { bulk_upload:, field_1: owning_org.old_visible_id, field_2: owning_org.old_visible_id, field_4: "2", field_11: "2", field_5: "S123", field_6: location.id } }

          it "returns a setup error" do
            expect(parser.errors.where(:field_5, category: :setup).map(&:message)).to eq([I18n.t("validations.lettings.2024.bulk_upload.scheme.must_relate_to_org")])
            expect(parser.errors[:field_6]).to be_blank
          end
        end

        context "when missing location" do
          let(:attributes) { { bulk_upload:, field_1: owning_org.old_visible_id, field_2: owning_org.old_visible_id, field_4: "2", field_11: "2", field_5: "S#{scheme.id}", field_6: nil } }

          it "returns a setup error" do
            expect(parser.errors[:field_5]).to be_blank
            expect(parser.errors.where(:field_6, category: :setup).map(&:message)).to eq([I18n.t("validations.lettings.2024.bulk_upload.not_answered", question: "location code.")])
            expect(parser.errors[:field_6].count).to eq(1)
          end
        end

        context "when matching location cannot be found" do
          let(:attributes) { { bulk_upload:, field_1: owning_org.old_visible_id, field_2: owning_org.old_visible_id, field_4: "2", field_11: "2", field_5: "S#{scheme.id}", field_6: "123" } }

          it "returns a setup error" do
            expect(parser.errors[:field_5]).to be_blank
            expect(parser.errors.where(:field_6, category: :setup).map(&:message)).to eq([I18n.t("validations.lettings.2024.bulk_upload.location.must_relate_to_org")])
          end
        end

        context "when matching location exists" do
          let(:attributes) { { bulk_upload:, field_1: owning_org.old_visible_id, field_2: owning_org.old_visible_id, field_4: "2", field_11: "2", field_5: "S#{scheme.id}", field_6: location.id } }

          it "does not return an error" do
            expect(parser.errors[:field_5]).to be_blank
            expect(parser.errors[:field_6]).to be_blank
          end
        end

        context "when scheme ID has leading spaces" do
          let(:attributes) { { bulk_upload:, field_1: owning_org.old_visible_id, field_2: owning_org.old_visible_id, field_4: "2", field_11: "1", field_5: " S#{scheme.id}", field_6: location.id } }

          it "does not return an error" do
            expect(parser.errors[:field_5]).to be_blank
            expect(parser.errors[:field_6]).to be_blank
          end
        end

        context "when location exists but not related" do
          let(:other_scheme) { create(:scheme, :with_old_visible_id) }
          let(:other_location) { create(:location, :with_old_visible_id, scheme: other_scheme) }
          let(:attributes) { { bulk_upload:, field_1: owning_org.old_visible_id, field_2: owning_org.old_visible_id, field_4: "2", field_11: "2", field_5: "S#{scheme.id}", field_6: other_location.id } }

          it "returns a setup error" do
            expect(parser.errors[:field_5]).to be_blank
            expect(parser.errors.where(:field_6, category: :setup).map(&:message)).to eq([I18n.t("validations.lettings.2024.bulk_upload.location.must_relate_to_org")])
          end
        end

        context "when scheme belongs to someone else" do
          let(:other_scheme) { create(:scheme, :with_old_visible_id) }
          let(:other_location) { create(:location, :with_old_visible_id, scheme: other_scheme) }
          let(:attributes) { { bulk_upload:, field_4: "2", field_11: "2", field_5: "S#{other_scheme.id}", field_6: other_location.id, field_1: owning_org.old_visible_id, field_2: owning_org.old_visible_id } }

          it "returns a setup error" do
            expect(parser.errors.where(:field_5, category: :setup).map(&:message)).to eq([I18n.t("validations.lettings.2024.bulk_upload.scheme.must_relate_to_org")])
            expect(parser.errors[:field_6]).to be_blank
          end
        end

        context "when scheme belongs to owning org" do
          let(:attributes) { { bulk_upload:, field_4: "2", field_11: "2", field_5: "S#{scheme.id}", field_6: location.id, field_1: owning_org.old_visible_id, field_2: owning_org.old_visible_id } }

          it "does not return an error" do
            expect(parser.errors[:field_5]).to be_blank
            expect(parser.errors[:field_6]).to be_blank
          end
        end

        context "when scheme belongs to managing org" do
          let(:managing_org_scheme) { create(:scheme, :with_old_visible_id, owning_organisation: managing_org) }
          let(:managing_org_location) { create(:location, :with_old_visible_id, scheme: managing_org_scheme) }
          let(:attributes) { { bulk_upload:, field_4: "2", field_11: "2", field_5: "S#{managing_org_scheme.id}", field_6: managing_org_location.id, field_2: managing_org.old_visible_id } }

          it "clears the scheme answer" do
            expect(parser.errors[:field_5]).to include("You must answer scheme name.")
            expect(parser.errors[:field_6]).to be_blank
          end
        end

        context "when matching location exists but is incomplete" do
          let(:incomplete_location) { create(:location, :with_old_visible_id, :incomplete, scheme:) }
          let(:attributes) { { bulk_upload:, field_1: owning_org.old_visible_id, field_2: owning_org.old_visible_id, field_4: "2", field_11: "2", field_5: "S#{scheme.id}", field_6: incomplete_location.id } }

          it "returns a setup error for scheme" do
            expect(parser.errors.where(:field_5).map(&:message)).to eq(["This location is incomplete. Select another location or update this one."])
            expect(parser.errors.where(:field_6).map(&:message)).to eq(["This location is incomplete. Select another location or update this one."])
          end
        end
      end
    end

    describe "#field_98" do # leaving reason
      context "when field_7 is 1 meaning it is a renewal" do
        context "when field_98 is 50" do
          let(:attributes) { { bulk_upload:, field_98: "50", field_7: "1" } }

          it "is permitted" do
            parser.valid?
            expect(parser.errors[:field_98]).to be_blank
          end
        end

        context "when field_98 is 51" do
          let(:attributes) { { bulk_upload:, field_98: "51", field_7: "1" } }

          it "is permitted" do
            parser.valid?
            expect(parser.errors[:field_98]).to be_blank
          end
        end

        context "when field_98 is 52" do
          let(:attributes) { { bulk_upload:, field_98: "52", field_7: "1" } }

          it "is permitted" do
            parser.valid?
            expect(parser.errors[:field_98]).to be_blank
          end
        end

        context "when field_98 is 53" do
          let(:attributes) { { bulk_upload:, field_98: "53", field_7: "1" } }

          it "is permitted" do
            parser.valid?
            expect(parser.errors[:field_98]).to be_blank
          end
        end

        context "when field_98 is not 50, 51, 52 or 53" do
          let(:attributes) { { bulk_upload:, field_98: "1", field_7: "1" } }

          it "is not permitted" do
            parser.valid?
            expect(parser.errors[:field_98]).to include(I18n.t("validations.lettings.2024.bulk_upload.reason.renewal_reason_needed"))
          end
        end
      end

      context "when no longer a valid option from previous year" do
        let(:attributes) { setup_section_params.merge({ field_98: "7" }) }

        it "returns an error" do
          parser.valid?
          expect(parser.errors[:field_98]).to include(I18n.t("validations.lettings.2024.bulk_upload.invalid_option", question: "what is the tenant’s main reason for the household leaving their last settled home?"))
        end
      end
    end

    describe "#field_79, #field_80, #field_81" do
      context "when one item selected" do
        let(:attributes) { { bulk_upload:, field_79: "1" } }

        it "is permitted" do
          parser.valid?
          expect(parser.errors[:field_79]).to be_blank
          expect(parser.errors[:field_80]).to be_blank
          expect(parser.errors[:field_81]).to be_blank
        end
      end

      context "when more than one item selected" do
        let(:attributes) { { bulk_upload:, field_79: "1", field_80: "1" } }

        it "is not permitted" do
          parser.valid?
          expect(parser.errors[:field_79]).to be_present
          expect(parser.errors[:field_80]).to be_present
        end
      end
    end

    describe "#field_83" do
      context "when 1 and another disability field selected" do
        let(:attributes) { { bulk_upload:, field_83: "1", field_82: "1" } }

        it "is not permitted" do
          parser.valid?
          expect(parser.errors[:field_83]).to be_present
        end
      end
    end

    describe "#field_84" do
      context "when 1 and another disability field selected" do
        let(:attributes) { { bulk_upload:, field_84: "1", field_82: "1" } }

        it "is not permitted" do
          parser.valid?
          expect(parser.errors[:field_84]).to be_present
        end
      end
    end

    describe "#field_83, #field_84" do
      context "when both 1" do
        let(:attributes) { { bulk_upload:, field_83: "1", field_84: "1" } }

        it "is not permitted" do
          parser.valid?
          expect(parser.errors[:field_83]).to be_present
          expect(parser.errors[:field_84]).to be_present
        end
      end
    end

    describe "#field_79 - #field_84" do
      context "when all blank" do
        let(:attributes) { setup_section_params.merge({ field_79: nil, field_80: nil, field_81: nil, field_82: nil, field_83: nil, field_84: nil }) }

        it "adds errors to correct fields" do
          parser.valid?
          expect(parser.errors[:field_79]).to be_present
          expect(parser.errors[:field_80]).to be_present
          expect(parser.errors[:field_81]).to be_present
          expect(parser.errors[:field_82]).to be_present
          expect(parser.errors[:field_83]).to be_present
        end
      end

      context "when one item selected and field_82 is blank" do
        let(:attributes) { setup_section_params.merge({ field_79: "1", field_82: nil }) }

        it "sets other disabled access needs as no" do
          parser.valid?
          expect(parser.errors[:field_79]).to be_blank
          expect(parser.errors[:field_82]).to be_blank
          expect(parser.log.housingneeds_other).to eq(0)
        end
      end
    end

    describe "#field_85, field_94 - 99" do
      context "when no illness but illnesses answered" do
        let(:attributes) { { bulk_upload:, field_85: "2", field_86: "1", field_87: "1", field_88: "1" } }

        it "errors added to correct fields" do
          parser.valid?
          expect(parser.errors[:field_86]).to be_present
          expect(parser.errors[:field_87]).to be_present
          expect(parser.errors[:field_88]).to be_present
          expect(parser.errors[:field_89]).not_to be_present
          expect(parser.errors[:field_90]).not_to be_present
          expect(parser.errors[:field_91]).not_to be_present
          expect(parser.errors[:field_92]).not_to be_present
          expect(parser.errors[:field_93]).not_to be_present
          expect(parser.errors[:field_94]).not_to be_present
          expect(parser.errors[:field_95]).not_to be_present
        end
      end

      context "when illness but no illnesses answered" do
        let(:attributes) { { bulk_upload:, field_85: "1", field_86: nil, field_87: nil, field_88: nil, field_89: nil, field_90: nil, field_91: nil, field_92: nil, field_93: nil, field_94: nil, field_95: nil } }

        it "errors added to correct fields" do
          parser.valid?
          expect(parser.errors[:field_86]).to be_present
          expect(parser.errors[:field_87]).to be_present
          expect(parser.errors[:field_88]).to be_present
          expect(parser.errors[:field_89]).to be_present
          expect(parser.errors[:field_90]).to be_present
          expect(parser.errors[:field_91]).to be_present
          expect(parser.errors[:field_92]).to be_present
          expect(parser.errors[:field_93]).to be_present
          expect(parser.errors[:field_94]).to be_present
          expect(parser.errors[:field_95]).to be_present
        end
      end
    end

    describe "#field_112 - 115 (lettings allocation methods)" do
      %i[field_112 field_113 field_114 field_115].each do |field|
        context "when only #{field} is not given" do
          let(:attributes) do
            override = {}
            override[field] = ""
            { bulk_upload:, field_112: "2", field_113: "1", field_114: "2", field_115: "1" }.merge(override)
          end

          it "adds an error to #{field}" do
            parser.valid?
            expect(parser.errors[field]).to be_present
          end
        end
      end
    end

    describe "#field_101, field_106 - 15" do
      context "when there is a reasonable preference but none is given" do
        let(:attributes) { { bulk_upload:, field_106: "1", field_107: nil, field_108: nil, field_109: nil, field_110: nil, field_111: nil } }

        it "is not permitted" do
          parser.valid?
          expect(parser.errors[:field_107]).to be_present
          expect(parser.errors[:field_108]).to be_present
          expect(parser.errors[:field_109]).to be_present
          expect(parser.errors[:field_110]).to be_present
          expect(parser.errors[:field_111]).to be_present
        end
      end

      context "when some reasonable preference options are seleceted" do
        let(:attributes) { setup_section_params.merge({ bulk_upload:, field_106: "1", field_107: "1", field_108: nil, field_109: "1", field_110: nil, field_111: nil }) }

        it "sets the rest of the options to 0" do
          parser.valid?
          expect(parser.log.rp_homeless).to eq(1)
          expect(parser.log.rp_insan_unsat).to eq(0)
          expect(parser.log.rp_medwel).to eq(1)
          expect(parser.log.rp_hardship).to eq(0)
          expect(parser.log.rp_dontknow).to eq(0)
        end
      end

      context "when some reasonable preference options are seleceted but reasonpref is No" do
        let(:attributes) { setup_section_params.merge({ bulk_upload:, field_106: "2", field_107: "1", field_108: nil, field_109: "1", field_110: nil, field_111: nil }) }

        it "sets the options to nil" do
          parser.valid?
          expect(parser.log.rp_homeless).to be_nil
          expect(parser.log.rp_insan_unsat).to be_nil
          expect(parser.log.rp_medwel).to be_nil
          expect(parser.log.rp_hardship).to be_nil
          expect(parser.log.rp_dontknow).to be_nil
        end
      end
    end

    describe "#field_116" do # referral
      context "when 3 ie PRP nominated by LA and owning org is LA" do
        let(:attributes) { { bulk_upload:, field_116: "3", field_1: owning_org.old_visible_id, field_2: owning_org.old_visible_id } }

        it "is not permitted" do
          parser.valid?
          expect(parser.errors[:field_116]).to be_present
        end
      end

      context "when 4 ie referred by LA and is general needs and owning org is LA" do
        let(:attributes) { { bulk_upload:, field_116: "4", field_1: owning_org.old_visible_id, field_2: owning_org.old_visible_id, field_4: "1" } }

        it "is not permitted" do
          parser.valid?
          expect(parser.errors[:field_116]).to be_present
        end
      end

      context "when 4 ie referred by LA and is general needs and owning org is PRP" do
        let(:owning_org) { create(:organisation, :prp, :with_old_visible_id) }

        let(:attributes) { { bulk_upload:, field_116: "4", field_1: owning_org.old_visible_id, field_2: owning_org.old_visible_id } }

        it "is permitted" do
          parser.valid?
          expect(parser.errors[:field_116]).to be_blank
        end
      end

      context "when 4 ie referred by LA and is not general needs" do
        let(:bulk_upload) { create(:bulk_upload, :lettings, user:) }
        let(:attributes) { { bulk_upload:, field_116: "4", field_4: "2" } }

        it "is permitted" do
          parser.valid?
          expect(parser.errors[:field_116]).to be_blank
        end
      end
    end

    describe "fields 7, 8, 9 => startdate" do
      context "when any one of these fields is blank" do
        let(:attributes) { { bulk_upload:, field_11: "1", field_8: nil, field_9: nil, field_10: nil } }

        it "returns an error" do
          parser.valid?
          expect(parser.errors[:field_8]).to be_present
          expect(parser.errors[:field_9]).to be_present
          expect(parser.errors[:field_10]).to be_present
        end
      end

      context "when field_10 is 4 digits instead of 2" do
        let(:attributes) { setup_section_params.merge({ bulk_upload:, field_10: "2024", field_9: "4", field_8: "5" }) }

        it "correctly sets the date" do
          parser.valid?
          expect(parser.errors[:field_10]).to be_empty
          expect(parser.log.startdate).to eq(Time.zone.local(2024, 4, 5))
        end
      end

      context "when field_10 is not 4 or 2 digits" do
        let(:attributes) { { bulk_upload:, field_10: "204" } }

        it "returns an error" do
          parser.valid?
          expect(parser.errors[:field_10]).to include(I18n.t("validations.lettings.2024.bulk_upload.startdate.year_not_two_or_four_digits"))
        end
      end

      context "when invalid date given" do
        let(:attributes) { { bulk_upload:, field_11: "1", field_8: "a", field_9: "12", field_10: "23" } }

        it "does not raise an error" do
          expect { parser.valid? }.not_to raise_error
        end
      end

      context "when inside of collection year" do
        let(:attributes) { { bulk_upload:, field_8: "1", field_9: "10", field_10: "23" } }

        let(:bulk_upload) { create(:bulk_upload, :lettings, user:, year: 2022) }

        it "does not return errors" do
          parser.valid?
          expect(parser.errors[:field_8]).not_to be_present
          expect(parser.errors[:field_9]).not_to be_present
          expect(parser.errors[:field_10]).not_to be_present
        end
      end

      context "when outside of collection year" do
        around do |example|
          Timecop.freeze(Date.new(2023, 4, 2)) do
            example.run
          end
        end

        let(:attributes) { { bulk_upload:, field_8: "1", field_9: "1", field_10: "23" } }

        let(:bulk_upload) { create(:bulk_upload, :lettings, user:, year: 2023) }

        it "returns setup errors" do
          parser.valid?
          expect(parser.errors.where(:field_8, category: :setup)).to be_present
          expect(parser.errors.where(:field_9, category: :setup)).to be_present
          expect(parser.errors.where(:field_10, category: :setup)).to be_present
        end
      end
    end

    describe "#field_1" do # owning org
      context "when blank" do
        let(:attributes) { { bulk_upload:, field_1: "", field_4: 1 } }

        it "is not permitted as setup error" do
          parser.valid?
          expect(parser.errors.where(:field_1, category: :setup).map(&:message)).to eql([I18n.t("validations.lettings.2024.bulk_upload.not_answered", question: "owning organisation.")])
        end

        it "blocks log creation" do
          parser.valid?
          expect(parser).to be_block_log_creation
        end
      end

      context "when cannot find owning org" do
        let(:attributes) { { bulk_upload:, field_1: "donotexist" } }

        it "is not permitted as setup error" do
          parser.valid?

          setup_errors = parser.errors.select { |e| e.options[:category] == :setup }

          expect(setup_errors.find { |e| e.attribute == :field_1 }.message).to eql(I18n.t("validations.lettings.2024.bulk_upload.owning_organisation.not_found"))
        end

        it "blocks log creation" do
          parser.valid?
          expect(parser).to be_block_log_creation
        end
      end

      context "when org is not stock owning" do
        let(:owning_org) { create(:organisation, :with_old_visible_id, :does_not_own_stock) }

        let(:attributes) { { bulk_upload:, field_1: owning_org.old_visible_id, field_2: owning_org.old_visible_id } }

        it "is not permitted as setup error" do
          parser.valid?

          setup_errors = parser.errors.select { |e| e.options[:category] == :setup }

          expect(setup_errors.find { |e| e.attribute == :field_1 }.message).to eql(I18n.t("validations.lettings.2024.bulk_upload.owning_organisation.not_stock_owner"))
        end

        it "blocks log creation" do
          parser.valid?
          expect(parser).to be_block_log_creation
        end
      end

      context "when not affiliated with owning org" do
        let(:unaffiliated_org) { create(:organisation, :with_old_visible_id) }

        let(:attributes) { { bulk_upload:, field_1: unaffiliated_org.old_visible_id } }

        it "is not permitted as setup error" do
          parser.valid?

          setup_errors = parser.errors.select { |e| e.options[:category] == :setup }

          expect(setup_errors.find { |e| e.attribute == :field_1 }.message).to eql(I18n.t("validations.lettings.2024.bulk_upload.owning_organisation.not_permitted.not_support"))
        end

        it "blocks log creation" do
          parser.valid?
          expect(parser).to be_block_log_creation
        end
      end

      context "when user's org has absorbed owning organisation" do
        let(:merged_org) { create(:organisation, :with_old_visible_id, holds_own_stock: true) }
        let(:merged_org_stock_owner) { create(:organisation, :with_old_visible_id, holds_own_stock: true) }

        let(:attributes) { { bulk_upload:, field_1: merged_org_stock_owner.old_visible_id, field_2: merged_org.old_visible_id, field_3: user.email } }

        before do
          create(:organisation_relationship, parent_organisation: merged_org_stock_owner, child_organisation: merged_org)
          merged_org.update!(absorbing_organisation: user.organisation, merge_date: Time.zone.today)
          merged_org.reload
          user.organisation.reload
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

        let(:attributes) { setup_section_params.merge({ field_1: merged_org.old_visible_id, field_2: merged_org.old_visible_id, field_3: user.email }) }

        before do
          merged_org.update!(absorbing_organisation: user.organisation, merge_date: Time.zone.today - 5.years)
          merged_org.reload
          user.organisation.reload
        end

        it "is not permitted" do
          parser = described_class.new(attributes)

          parser.valid?
          expect(parser.errors[:field_1]).to include(/The owning organisation must be active on the tenancy start date/)
          expect(parser.errors[:field_2]).to include(/The managing organisation must be active on the tenancy start date/)
          expect(parser.errors[:field_8]).to include(/Enter a date when the owning and managing organisation was active/)
          expect(parser.errors[:field_9]).to include(/Enter a date when the owning and managing organisation was active/)
          expect(parser.errors[:field_10]).to include(/Enter a date when the owning and managing organisation was active/)
        end
      end

      context "when user is an unaffiliated non-support user and bulk upload organisation is affiliated with the owning organisation" do
        let(:affiliated_org) { create(:organisation, :with_old_visible_id) }
        let(:unaffiliated_user) { create(:user, organisation: create(:organisation)) }
        let(:attributes) { { bulk_upload:, field_1: affiliated_org.old_visible_id } }
        let(:organisation_id) { unaffiliated_user.organisation_id }

        before do
          create(:organisation_relationship, parent_organisation: owning_org, child_organisation: affiliated_org)
          bulk_upload.update!(organisation_id:, user: unaffiliated_user)
        end

        it "blocks log creation and adds an error to field_1" do
          parser = described_class.new(attributes)
          parser.valid?
          expect(parser).to be_block_log_creation
          expect(parser.errors[:field_1]).to include(I18n.t("validations.lettings.2024.bulk_upload.owning_organisation.not_permitted.not_support"))
        end
      end

      context "when user is an unaffiliated support user and bulk upload organisation is affiliated with the owning organisation" do
        let(:affiliated_org) { create(:organisation, :with_old_visible_id) }
        let(:unaffiliated_support_user) { create(:user, :support, organisation: create(:organisation)) }
        let(:attributes) { { bulk_upload:, field_1: affiliated_org.old_visible_id } }
        let(:organisation_id) { affiliated_org.id }

        before do
          create(:organisation_relationship, parent_organisation: owning_org, child_organisation: affiliated_org)
          bulk_upload.update!(organisation_id:, user: unaffiliated_support_user)
        end

        it "does not block log creation and does not add an error to field_1" do
          parser = described_class.new(attributes)
          parser.valid?
          expect(parser.errors[:field_1]).not_to include(I18n.t("validations.lettings.2024.bulk_upload.owning_organisation.not_permitted"))
        end
      end
    end

    describe "#field_2" do # managing org
      context "when blank" do
        let(:attributes) { { bulk_upload:, field_2: "", field_4: 1 } }

        it "is not permitted as setup error" do
          parser.valid?

          setup_errors = parser.errors.select { |e| e.options[:category] == :setup }

          expect(setup_errors.find { |e| e.attribute == :field_2 }.message).to eql(I18n.t("validations.lettings.2024.bulk_upload.not_answered", question: "managing organisation."))
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

          expect(setup_errors.find { |e| e.attribute == :field_2 }.message).to eql(I18n.t("validations.lettings.2024.bulk_upload.managing_organisation.not_found"))
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

          expect(setup_errors.find { |e| e.attribute == :field_2 }.message).to eql(I18n.t("validations.lettings.2024.bulk_upload.managing_organisation.no_relationship"))
        end

        it "blocks log creation" do
          parser.valid?
          expect(parser).to be_block_log_creation
        end
      end
    end

    describe "#field_4" do # needs type
      context "when blank" do
        let(:attributes) { { bulk_upload:, field_4: nil, field_13: "123" } }

        it "is reported as a setup error" do
          parser.valid?
          expect(parser.errors.where(:field_4, category: :setup).map(&:message)).to eql([I18n.t("validations.lettings.2024.bulk_upload.not_answered", question: "needs type.")])
        end
      end
    end

    describe "#field_7" do # renewal
      context "when blank" do
        let(:attributes) { { bulk_upload:, field_1: owning_org.old_visible_id, field_2: owning_org.old_visible_id, field_7: "" } }

        it "has setup errors on the field" do
          parser.valid?
          expect(parser.errors.where(:field_7, category: :setup).map(&:message)).to eql([I18n.t("validations.lettings.2024.bulk_upload.not_answered", question: "property renewal.")])
        end
      end

      context "when none possible option selected" do
        let(:attributes) { setup_section_params.merge({ field_7: "101" }) }

        it "adds a setup error" do
          parser.valid?
          expect(parser.errors.where(:field_7, category: :setup).map(&:message)).to include(I18n.t("validations.lettings.2024.bulk_upload.invalid_option", question: "is this letting a renewal?"))
        end
      end
    end

    describe "UPRN and address fields" do
      context "with a general needs log" do
        context "when a valid UPRN is given" do
          context "and address fields are not given" do
            let(:attributes) { setup_section_params.merge({ field_4: 1, field_16: "123456789012" }) }

            it "does not add errors" do
              parser.valid?
              %i[field_16 field_17 field_18 field_19 field_20 field_21 field_22].each do |field|
                expect(parser.errors[field]).to be_empty
              end
            end
          end
        end

        context "when an invalid UPRN is given" do
          context "and address fields are not given" do
            let(:attributes) { setup_section_params.merge({ field_4: 1, field_16: "1234567890123" }) }

            it "adds an appropriate error to the UPRN field" do
              parser.valid?
              expect(parser.errors[:field_16]).to eql(["UPRN must be 12 digits or less."])
            end

            it "adds errors to missing key address fields" do
              parser.valid?
              expect(parser.errors[:field_17]).to eql([I18n.t("validations.lettings.2024.bulk_upload.not_answered", question: "address line 1.")])
              expect(parser.errors[:field_19]).to eql([I18n.t("validations.lettings.2024.bulk_upload.not_answered", question: "town or city.")])
              expect(parser.errors[:field_21]).to eql([I18n.t("validations.lettings.2024.bulk_upload.not_answered", question: "part 1 of postcode.")])
              expect(parser.errors[:field_22]).to eql([I18n.t("validations.lettings.2024.bulk_upload.not_answered", question: "part 2 of postcode.")])
            end
          end

          context "and address fields are given" do
            let(:attributes) { setup_section_params.merge({ field_4: 1, field_16: "1234567890123", field_17: "address line 1", field_19: "town or city", field_21: "AA1", field_22: "1AA" }) }

            it "adds an error to the UPRN field only" do
              parser.valid?
              expect(parser.errors[:field_16]).to eql(["UPRN must be 12 digits or less."])
              %i[field_17 field_19 field_21 field_22].each do |field|
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
            let(:attributes) { setup_section_params.merge({ field_4: 1 }) }

            it "adds appropriate errors to UPRN and key address fields" do
              parser.valid?
              expect(parser.errors[:field_16]).to eql([I18n.t("validations.lettings.2024.bulk_upload.address.not_answered")])
              expect(parser.errors[:field_17]).to eql([I18n.t("validations.lettings.2024.bulk_upload.address.not_answered")])
              expect(parser.errors[:field_19]).to eql([I18n.t("validations.lettings.2024.bulk_upload.address.not_answered")])
              expect(parser.errors[:field_21]).to eql([I18n.t("validations.lettings.2024.bulk_upload.address.not_answered")])
              expect(parser.errors[:field_22]).to eql([I18n.t("validations.lettings.2024.bulk_upload.address.not_answered")])
            end
          end

          context "and some key address field is missing" do
            let(:attributes) { setup_section_params.merge({ field_4: 1, field_19: "town or city", field_21: "AA1", field_22: "1AA" }) }

            it "adds errors to UPRN and the missing key address field" do
              parser.valid?
              expect(parser.errors[:field_16]).to eql([I18n.t("validations.lettings.2024.bulk_upload.address.not_answered")])
              expect(parser.errors[:field_17]).to eql([I18n.t("validations.lettings.2024.bulk_upload.address.not_answered")])
              expect(parser.errors[:field_19]).to be_empty
              expect(parser.errors[:field_21]).to be_empty
              expect(parser.errors[:field_22]).to be_empty
            end
          end

          context "and all key address fields are present" do
            let(:attributes) { setup_section_params.merge({ field_4: 1, field_16: nil, field_17: "address line 1", field_19: "town or city", field_21: "AA1", field_22: "1AA" }) }

            context "and an address can be found with a high enough match rating" do
              before do
                stub_request(:get, /api\.os\.uk\/search\/places\/v1\/find/)
                  .to_return(status: 200, body: { results: [{ DPA: { MATCH: 0.7, BUILDING_NAME: "", POST_TOWN: "", POSTCODE: "AA1 1AA", UPRN: "1" } }] }.to_json, headers: {})
              end

              it "does not add errors" do
                parser.valid?
                %i[field_16 field_17 field_18 field_19 field_20 field_21 field_22].each do |field|
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
                expect(parser.errors[:field_16]).to be_empty
                %i[field_17 field_18 field_19 field_20 field_21 field_22].each do |field|
                  expect(parser.errors[field]).to eql([I18n.t("validations.lettings.2024.bulk_upload.address.not_found")])
                end
              end
            end

            context "when a single address with not a high enough match rating is returned" do
              before do
                stub_request(:get, /api\.os\.uk\/search\/places\/v1\/find/)
                  .to_return(status: 200, body: { results: [{ DPA: { MATCH: 0.6, BUILDING_NAME: "", POST_TOWN: "", POSTCODE: "AA1 1AA", UPRN: "1" } }] }.to_json, headers: {})
              end

              it "adds address not found errors to address fields only" do
                parser.valid?
                expect(parser.errors[:field_16]).to be_empty
                %i[field_17 field_18 field_19 field_20 field_21 field_22].each do |field|
                  expect(parser.errors[field]).to eql([I18n.t("validations.lettings.2024.bulk_upload.address.not_determined.one")])
                end
              end
            end

            context "when no addresses have a high enough match rating" do
              before do
                stub_request(:get, /api\.os\.uk\/search\/places\/v1\/find/)
                  .to_return(status: 200, body: { results: [{ DPA: { MATCH: 0.6, BUILDING_NAME: "", POST_TOWN: "", POSTCODE: "AA1 1AA", UPRN: "1" } }, { DPA: { MATCH: 0.8, BUILDING_NAME: "", POST_TOWN: "", POSTCODE: "BB2 2BB", UPRN: "2" } }] }.to_json, headers: {})
              end

              it "adds address not found errors to address fields only" do
                parser.valid?
                expect(parser.errors[:field_16]).to be_empty
                %i[field_17 field_18 field_19 field_20 field_21 field_22].each do |field|
                  expect(parser.errors[field]).to eql([I18n.t("validations.lettings.2024.bulk_upload.address.not_determined.multiple")])
                end
              end
            end
          end
        end

        context "when it is a new build" do
          let(:attributes) { setup_section_params.merge({ 
            field_24: "15",
            field_17: "Address line 1",
            field_18: "Address line 2",
            field_19: "Town or city",
            field_20: "County",
            field_21: "DS1",
            field_22: "1AA",
            field_23: "E09000008",
            }) }

          it "sets manual address entry fields" do
            stub_request(:get, /api\.postcodes\.io/)
            .to_return(status: 200, body: "{\"status\":200,\"result\":{}", headers: {})
      
            parser.valid?
            expect(parser.log.select_best_address_match).to be_nil
            expect(parser.log.uprn_selection).to eq("uprn_not_listed")
            expect(parser.log.uprn_known).to be(0)
            expect(parser.log.uprn_confirmed).to be_nil
            expect(parser.log.address_line1).to eq("Address line 1")
            expect(parser.log.address_line2).to eq("Address line 2")
            expect(parser.log.town_or_city).to eq("Town or city")
            expect(parser.log.county).to eq("County")
            expect(parser.log.postcode_full).to eq("DS1 1AA")
            expect(parser.log.la).to eq("E09000008")
          end
        end
      end

      context "with a supported housing log" do
        context "when neither UPRN nor address fields are provided" do
          let(:attributes) { setup_section_params.merge({ field_4: 2, field_5: "S#{scheme.id}", field_6: location.old_visible_id, field_16: nil, field_17: nil, field_19: nil, field_21: nil, field_22: nil }) }

          it "does not add missing field errors" do
            parser.valid?
            %i[field_16 field_17 field_18 field_19 field_20 field_21 field_22].each do |field|
              expect(parser.errors[field]).to be_empty
            end
          end
        end
      end
    end

    describe "#field_25" do # unitletas
      context "when no longer a valid option from previous year" do
        let(:attributes) { setup_section_params.merge({ field_25: "4" }) }

        it "returns an error" do
          parser.valid?
          expect(parser.errors[:field_25]).to be_present
        end
      end
    end

    describe "#field_27" do
      context "when null" do
        let(:attributes) { setup_section_params.merge({ field_27: nil }) }

        it "returns an error" do
          parser.valid?
          expect(parser.errors[:field_27]).to be_present
        end

        it "populates with correct error message" do
          parser.valid?
          expect(parser.errors[:field_27]).to eql([I18n.t("validations.lettings.2024.bulk_upload.not_answered", question: "type of building.")])
        end
      end
    end

    describe "#field_48" do # age2
      context "when null but gender given" do
        let(:attributes) { setup_section_params.merge({ field_48: "", field_49: "F" }) }

        it "returns an error" do
          parser.valid?
          expect(parser.errors[:field_48]).to be_present
        end
      end
    end

    describe "#field_45" do
      context "when field_45 is a 3 digit nationality code" do
        let(:attributes) { setup_section_params.merge({ field_45: "036" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all).to be(36)
          expect(parser.log.nationality_all_group).to be(12)
        end
      end

      context "when field_45 is a nationality code without the trailing 0s" do
        let(:attributes) { setup_section_params.merge({ field_45: "36" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all).to be(36)
          expect(parser.log.nationality_all_group).to be(12)
        end
      end

      context "when field_45 is a nationality code with trailing 0s" do
        let(:attributes) { setup_section_params.merge({ field_45: "0036" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all).to be(36)
          expect(parser.log.nationality_all_group).to be(12)
        end
      end

      context "when field_45 is 0" do
        let(:attributes) { setup_section_params.merge({ field_45: "0" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all).to be(0)
          expect(parser.log.nationality_all_group).to be(0)
        end
      end

      context "when field_45 is 000" do
        let(:attributes) { setup_section_params.merge({ field_45: "000" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all).to be(0)
          expect(parser.log.nationality_all_group).to be(0)
        end
      end

      context "when field_45 is 0000" do
        let(:attributes) { setup_section_params.merge({ field_45: "0000" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all).to be(0)
          expect(parser.log.nationality_all_group).to be(0)
        end
      end

      context "when field_45 is 826" do
        let(:attributes) { setup_section_params.merge({ field_45: "826" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all).to be(826)
          expect(parser.log.nationality_all_group).to be(826)
        end
      end

      context "when field_45 is 826 with trailing 0s" do
        let(:attributes) { setup_section_params.merge({ field_45: "0826" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all).to be(826)
          expect(parser.log.nationality_all_group).to be(826)
        end
      end

      context "when field_45 is not a valid option" do
        let(:attributes) { setup_section_params.merge({ field_45: "123123" }) }

        it "is correctly set" do
          expect(parser.log.nationality_all).to be(nil)
          expect(parser.log.nationality_all_group).to be(nil)
        end

        it "adds an error to field_45" do
          parser.valid?
          expect(parser.errors["field_45"]).to include(I18n.t("validations.lettings.2024.bulk_upload.nationality.invalid"))
        end
      end
    end

    describe "soft validations" do
      context "when soft validation is triggered" do
        let(:attributes) { setup_section_params.merge({ field_42: 22, field_46: 5 }) }

        it "adds an error to the relevant fields" do
          parser.valid?
          expect(parser.errors.where(:field_42, category: :soft_validation)).to be_present
          expect(parser.errors.where(:field_46, category: :soft_validation)).to be_present
        end

        it "populates with correct error message" do
          parser.valid?
          expect(parser.errors.where(:field_42, category: :soft_validation).first.message).to eql("You told us this person is aged 22 years and retired. The minimum expected retirement age in England is 66.")
          expect(parser.errors.where(:field_46, category: :soft_validation).first.message).to eql("You told us this person is aged 22 years and retired. The minimum expected retirement age in England is 66.")
        end
      end

      context "when a soft validation is triggered that relates both to fields that are and are not routed to" do
        let(:attributes) { setup_section_params.merge({ field_78: "1", field_43: "M", field_49: "M", field_53: "M" }) }

        it "adds errors to fields that are routed to" do
          parser.valid?
          expect(parser.errors.where(:field_49, category: :soft_validation)).to be_present
          expect(parser.errors.where(:field_53, category: :soft_validation)).to be_present
        end

        it "does not add errors to fields that are not routed to" do
          parser.valid?
          expect(parser.errors.where(:field_57, category: :soft_validation)).not_to be_present
          expect(parser.errors.where(:field_61, category: :soft_validation)).not_to be_present
        end
      end

      context "when soft validation is triggered and not required" do
        let(:attributes) { setup_section_params.merge({ field_125: 120, field_126: 120, field_127: 120, field_128: 120, field_123: 1, field_29: 1, field_4: 1, field_11: "2", field_23: "E09000008" }) }

        it "adds an error to the relevant fields" do
          parser.valid?
          expect(parser.errors.where(:field_125, category: :soft_validation)).to be_present
        end

        it "populates with correct error message" do
          parser.valid?
          expect(parser.errors.where(:field_125, category: :soft_validation).count).to be(1)
          expect(parser.errors.where(:field_125, category: :soft_validation).first.message).to eql("You told us the rent is £120.00 every week. This is higher than we would expect.")
        end
      end

      context "when an invalid ecstat1 is given" do
        let(:attributes) { setup_section_params.merge({ field_46: 11, field_119: 123, field_118: 1 }) }

        it "does not run net income soft validations validation" do
          parser.valid?
          expect(parser.errors.where(:field_46).count).to be(1)
        end
      end
    end

    describe "log_already_exists?" do
      let(:attributes) { { bulk_upload: } }

      before do
        build(:lettings_log, owning_organisation: nil, startdate: nil, tenancycode: nil, location: nil, age1: nil, sex1: nil, ecstat1: nil, brent: nil, scharge: nil, pscharge: nil, supcharg: nil).save(validate: false)
      end

      it "does not add duplicate logs validation to the blank row" do
        expect(parser.log_already_exists?).to eq(false)
      end
    end
  end

  describe "#log" do
    describe "#assigned_to" do
      context "when blank" do
        let(:attributes) { setup_section_params }

        it "takes the user that is uploading" do
          expect(parser.log.assigned_to).to eql(bulk_upload.user)
        end
      end

      context "when email specified" do
        let(:other_user) { create(:user, organisation: owning_org) }

        let(:attributes) { setup_section_params.merge(field_3: other_user.email) }

        it "sets to user with specified email" do
          expect(parser.log.assigned_to).to eql(other_user)
        end
      end
    end

    describe "#uprn" do
      let(:attributes) { { bulk_upload:, field_4: 1, field_16: "12" } }

      it "sets to given value" do
        expect(parser.log.uprn).to eql("12")
      end
    end

    describe "#uprn_known" do
      context "when uprn specified" do
        let(:attributes) { { bulk_upload:, field_4: 1, field_16: "12" } }

        it "sets to 1" do
          expect(parser.log.uprn_known).to be(1)
          expect(parser.log.uprn_confirmed).to be(1)
        end
      end

      context "when uprn blank" do
        let(:attributes) { { bulk_upload:, field_4: 1, field_16: "" } }

        it "sets to 0" do
          expect(parser.log.uprn_known).to be(0)
        end
      end
    end

    describe "#address_line1" do
      let(:attributes) { { bulk_upload:, field_4: 1, field_17: "123 Sesame Street" } }

      it "sets to given value" do
        expect(parser.log.address_line1).to eql("123 Sesame Street")
      end
    end

    describe "#address_line2" do
      let(:attributes) { { bulk_upload:, field_4: 1, field_18: "Cookie Town" } }

      it "sets to given value" do
        expect(parser.log.address_line2).to eql("Cookie Town")
      end
    end

    describe "#town_or_city" do
      let(:attributes) { { bulk_upload:, field_4: 1, field_19: "London" } }

      it "sets to given value" do
        expect(parser.log.town_or_city).to eql("London")
      end
    end

    describe "#county" do
      let(:attributes) { { bulk_upload:, field_4: 1, field_20: "Greater London" } }

      it "sets to given value" do
        expect(parser.log.county).to eql("Greater London")
      end
    end

    describe "address related fields for supported housing logs" do
      context "when address data is provided for a supported housing log" do
        let(:attributes) { { bulk_upload:, field_4: 2, field_16: nil, field_17: "Flat 1", field_18: "Example Place", field_19: "London", field_20: "Greater London", field_21: "SW1A", field_22: "1AA" } }

        it "is not set on the log" do
          expect(parser.log.uprn).to be_nil
          expect(parser.log.uprn_known).to be_nil
          expect(parser.log.address_line1).to be_nil
          expect(parser.log.address_line1_as_entered).to be_nil
          expect(parser.log.address_line2).to be_nil
          expect(parser.log.address_line2_as_entered).to be_nil
          expect(parser.log.town_or_city).to be_nil
          expect(parser.log.town_or_city_as_entered).to be_nil
          expect(parser.log.county).to be_nil
          expect(parser.log.county_as_entered).to be_nil
          expect(parser.log.postcode_full).to be_nil
          expect(parser.log.postcode_full_as_entered).to be_nil
          expect(parser.log.la).to be_nil
          expect(parser.log.la_as_entered).to be_nil
          expect(parser.log.address_line1_input).to be_nil
          expect(parser.log.postcode_full_input).to be_nil
          expect(parser.log.select_best_address_match).to be_nil
        end
      end
    end

    [
      %w[age1_known details_known_1 age1 field_42 field_47 field_49],
      %w[age2_known details_known_2 age2 field_48 field_47 field_49],
      %w[age3_known details_known_3 age3 field_52 field_51 field_53],
      %w[age4_known details_known_4 age4 field_56 field_55 field_57],
      %w[age5_known details_known_5 age5 field_60 field_59 field_61],
      %w[age6_known details_known_6 age6 field_64 field_63 field_65],
      %w[age7_known details_known_7 age7 field_68 field_67 field_69],
      %w[age8_known details_known_8 age8 field_72 field_71 field_73],
    ].each do |known, details_known, age, field, relationship, gender|
      describe "##{known} and ##{age}" do
        context "when #{field} is blank" do
          context "and person details are not given" do
            let(:attributes) { { bulk_upload:, field.to_sym => nil, field_4: 1, relationship.to_sym => nil, gender.to_sym => nil } }

            it "does not set ##{known}" do
              unless known == "age1_known"
                expect(parser.log.public_send(known)).to be_nil
              end
            end

            it "sets ##{details_known} to no" do
              unless details_known == "details_known_1"
                expect(parser.log.public_send(details_known)).to eq(1)
              end
            end

            it "sets ##{age} to nil" do
              expect(parser.log.public_send(age)).to be_nil
            end
          end

          context "and person details are given" do
            let(:attributes) { { bulk_upload:, field.to_sym => nil, field_4: 1, relationship.to_sym => "C", gender.to_sym => "X" } }

            it "does not set ##{age}" do
              parser.valid?
              expect(parser.errors[field.to_sym]).to include(/must be a number or the letter R/)
            end
          end
        end

        context "when #{field} is R" do
          let(:attributes) { { bulk_upload:, field.to_s => "R" } }

          it "sets ##{known} 1" do
            expect(parser.log.public_send(known)).to be(1)
          end

          it "sets ##{age} to nil" do
            expect(parser.log.public_send(age)).to be_nil
          end
        end

        context "when #{field} is a number" do
          let(:attributes) { { bulk_upload:, field.to_s => "50" } }

          it "sets ##{known} to 0" do
            expect(parser.log.public_send(known)).to be(0)
          end

          it "sets ##{age} to given age" do
            expect(parser.log.public_send(age)).to be(50)
          end
        end
      end
    end

    describe "#location" do
      context "when lookup is via new core id" do
        let(:attributes) { { bulk_upload:, field_5: "S#{scheme.id}", field_6: location.id, field_1: "ORG#{owning_org.id}", field_2: "ORG#{owning_org.id}" } }

        it "assigns the correct location" do
          expect(parser.log.location).to eql(location)
        end
      end
    end

    describe "#scheme" do
      context "when lookup is via new core id" do
        let(:attributes) { { bulk_upload:, field_5: "S#{scheme.id}", field_1: "ORG#{owning_org.id}", field_2: "ORG#{owning_org.id}" } }

        it "assigns the correct scheme" do
          expect(parser.log.scheme).to eql(scheme)
        end
      end
    end

    describe "#owning_organisation" do
      context "when lookup is via id prefixed with ORG" do
        let(:attributes) { { bulk_upload:, field_1: "ORG#{owning_org.id}" } }

        it "assigns the correct org" do
          expect(parser.log.owning_organisation).to eql(owning_org)
        end
      end
    end

    describe "#managing_organisation" do
      context "when lookup is via id prefixed with ORG" do
        let(:attributes) { { bulk_upload:, field_2: "ORG#{managing_org.id}" } }

        it "assigns the correct org" do
          expect(parser.log.managing_organisation).to eql(managing_org)
        end
      end
    end

    describe "#beds" do
      context "when property is a bedsit" do
        let(:attributes) { setup_section_params.merge({ field_26: 2, field_29: 2 }) }

        it "sets value to 1 even if field_29 contradicts this" do
          expect(parser.log.beds).to be(1)
        end
      end

      context "when property is not a bedsit" do
        let(:attributes) { setup_section_params.merge({ field_26: 1, field_29: 2 }) }

        it "sets value to field_29" do
          expect(parser.log.beds).to be(2)
        end
      end
    end

    describe "#cbl" do
      context "when field_112 is yes ie 1" do
        let(:attributes) { { bulk_upload:, field_112: 1 } }

        it "sets value to 1" do
          expect(parser.log.cbl).to be(1)
        end
      end

      context "when field_112 is no ie 2" do
        let(:attributes) { { bulk_upload:, field_112: 2 } }

        it "sets value to 0" do
          expect(parser.log.cbl).to be(0)
        end
      end

      context "when field_112 is not a permitted value" do
        let(:attributes) { { bulk_upload:, field_112: 3 } }

        it "adds an error" do
          parser.valid?
          expect(parser.errors[:field_112]).to include(I18n.t("validations.lettings.2024.bulk_upload.invalid_option", question: "was the letting made under the Choice-Based Lettings (CBL)?"))
        end
      end
    end

    describe "#chr" do
      context "when field_114 is yes ie 1" do
        let(:attributes) { { bulk_upload:, field_114: 1 } }

        it "sets value to 1" do
          expect(parser.log.chr).to be(1)
        end
      end

      context "when field_114 is no ie 2" do
        let(:attributes) { { bulk_upload:, field_114: 2 } }

        it "sets value to 0" do
          expect(parser.log.chr).to be(0)
        end
      end

      context "when field_114 is not a permitted value" do
        let(:attributes) { { bulk_upload:, field_114: 3 } }

        it "adds an error" do
          parser.valid?
          expect(parser.errors[:field_114]).to include(I18n.t("validations.lettings.2024.bulk_upload.invalid_option", question: "was the letting made under the Common Housing Register (CHR)?"))
        end
      end
    end

    describe "#cap" do
      context "when field_113 is yes ie 1" do
        let(:attributes) { { bulk_upload:, field_113: 1 } }

        it "sets value to 1" do
          expect(parser.log.cap).to be(1)
        end
      end

      context "when field_113 is no ie 2" do
        let(:attributes) { { bulk_upload:, field_113: 2 } }

        it "sets value to 0" do
          expect(parser.log.cap).to be(0)
        end
      end

      context "when field_113 is not a permitted value" do
        let(:attributes) { { bulk_upload:, field_113: 3 } }

        it "adds an error" do
          parser.valid?
          expect(parser.errors[:field_113]).to include(I18n.t("validations.lettings.2024.bulk_upload.invalid_option", question: "was the letting made under the Common Allocation Policy (CAP)?"))
        end
      end
    end

    describe "#accessible_register" do
      context "when field_115 is yes ie 1" do
        let(:attributes) { { bulk_upload:, field_115: 1 } }

        it "sets value to 1" do
          expect(parser.log.accessible_register).to be(1)
        end
      end

      context "when field_115 is no ie 2" do
        let(:attributes) { { bulk_upload:, field_115: 2 } }

        it "sets value to 0" do
          expect(parser.log.accessible_register).to be(0)
        end
      end

      context "when field_115 is not a permitted value" do
        let(:attributes) { { bulk_upload:, field_115: 3 } }

        it "adds an error" do
          parser.valid?
          expect(parser.errors[:field_115]).to include(I18n.t("validations.lettings.2024.bulk_upload.invalid_option", question: "was the letting made under the Accessible Register?"))
        end
      end
    end

    describe "#letting_allocation_unknown" do
      context "when field_112, 113, 114, 115 are no ie 2" do
        let(:attributes) { { bulk_upload:, field_112: 2, field_113: 2, field_114: 2, field_115: 2 } }

        it "sets value to 1" do
          expect(parser.log.letting_allocation_unknown).to be(1)
        end
      end

      context "when any one of field_112, 113, 114, 115 is yes ie 1" do
        let(:attributes) { { bulk_upload:, field_115: 1 } }

        it "sets value to 0" do
          expect(parser.log.letting_allocation_unknown).to be(0)
        end
      end
    end

    describe "#renewal" do
      context "when field_7 is no ie 2" do
        let(:attributes) { { bulk_upload:, field_7: 2 } }

        it "sets value to 0" do
          expect(parser.log.renewal).to eq(0)
        end
      end
    end

    describe "#sexN fields" do
      let(:attributes) do
        {
          bulk_upload:,
          field_43: "F",
          field_49: "M",
          field_53: "X",
          field_57: "R",
          field_61: "F",
          field_65: "M",
          field_69: "X",
          field_73: "R",
        }
      end

      it "sets value from correct mapping" do
        expect(parser.log.sex1).to eql("F")
        expect(parser.log.sex2).to eql("M")
        expect(parser.log.sex3).to eql("X")
        expect(parser.log.sex4).to eql("R")
        expect(parser.log.sex5).to eql("F")
        expect(parser.log.sex6).to eql("M")
        expect(parser.log.sex7).to eql("X")
        expect(parser.log.sex8).to eql("R")
      end
    end

    describe "#ecstatN fields" do
      let(:attributes) do
        {
          bulk_upload:,
          field_46: "1",
          field_50: "2",
          field_54: "6",
          field_58: "7",
          field_62: "8",
          field_66: "9",
          field_70: "0",
          field_74: "10",
        }
      end

      it "sets value from correct mapping", aggregate_failures: true do
        expect(parser.log.ecstat1).to eq(1)
        expect(parser.log.ecstat2).to eq(2)
        expect(parser.log.ecstat3).to eq(6)
        expect(parser.log.ecstat4).to eq(7)
        expect(parser.log.ecstat5).to eq(8)
        expect(parser.log.ecstat6).to eq(9)
        expect(parser.log.ecstat7).to eq(0)
        expect(parser.log.ecstat8).to eq(10)
      end
    end

    describe "#relatN fields" do
      let(:attributes) do
        {
          bulk_upload:,
          field_47: "P",
          field_51: "C",
          field_55: "X",
          field_59: "R",
          field_63: "P",
          field_67: "C",
          field_71: "X",
        }
      end

      it "sets value from correct mapping", aggregate_failures: true do
        expect(parser.log.relat2).to eq("P")
        expect(parser.log.relat3).to eq("C")
        expect(parser.log.relat4).to eq("X")
        expect(parser.log.relat5).to eq("R")
        expect(parser.log.relat6).to eq("P")
        expect(parser.log.relat7).to eq("C")
        expect(parser.log.relat8).to eq("X")
      end
    end

    describe "#net_income_known" do
      context "when 1" do
        let(:attributes) { { bulk_upload:, field_117: "1" } }

        it "sets value from correct mapping" do
          expect(parser.log.net_income_known).to eq(0)
        end
      end

      context "when 2" do
        let(:attributes) { { bulk_upload:, field_117: "2" } }

        it "sets value from correct mapping" do
          expect(parser.log.net_income_known).to eq(1)
        end
      end

      context "when 3" do
        let(:attributes) { { bulk_upload:, field_117: "3" } }

        it "sets value from correct mapping" do
          expect(parser.log.net_income_known).to eq(2)
        end
      end
    end

    describe "#unitletas" do
      let(:attributes) { { bulk_upload:, field_25: "1" } }

      it "sets value from correct mapping" do
        expect(parser.log.unitletas).to eq(1)
      end
    end

    describe "#rsnvac" do
      let(:attributes) { { bulk_upload:, field_24: "5" } }

      it "sets value from correct mapping" do
        expect(parser.log.rsnvac).to eq(5)
      end
    end

    describe "#sheltered" do
      let(:attributes) { { bulk_upload:, field_41: "1" } }

      it "sets value from correct mapping" do
        expect(parser.log.sheltered).to eq(1)
      end
    end

    describe "illness fields" do
      mapping = [
        { attribute: :illness_type_1, field: :field_94 },
        { attribute: :illness_type_2, field: :field_88 },
        { attribute: :illness_type_3, field: :field_91 },
        { attribute: :illness_type_4, field: :field_86 },
        { attribute: :illness_type_5, field: :field_87 },
        { attribute: :illness_type_6, field: :field_89 },
        { attribute: :illness_type_7, field: :field_90 },
        { attribute: :illness_type_8, field: :field_93 },
        { attribute: :illness_type_9, field: :field_92 },
        { attribute: :illness_type_10, field: :field_95 },
      ]

      mapping.each do |hash|
        describe "##{hash[:attribute]}" do
          context "when yes" do
            let(:attributes) { { bulk_upload:, hash[:field] => "1" } }

            it "sets value from correct mapping" do
              expect(parser.log.public_send(hash[:attribute])).to eq(1)
            end
          end

          context "when no" do
            let(:attributes) { { bulk_upload:, hash[:field] => "", field_4: 1 } }

            it "sets value from correct mapping" do
              expect(parser.log.public_send(hash[:attribute])).to be_nil
            end
          end
        end
      end

      context "when some illness type values are seleceted" do
        let(:attributes) { setup_section_params.merge({ bulk_upload:, field_85: "1", field_94: "1", field_87: "1" }) }

        it "sets the rest of the values to 0" do
          parser.valid?
          expect(parser.log.illness_type_1).to eq(1)
          expect(parser.log.illness_type_2).to eq(0)
          expect(parser.log.illness_type_3).to eq(0)
          expect(parser.log.illness_type_4).to eq(0)
          expect(parser.log.illness_type_5).to eq(1)
          expect(parser.log.illness_type_6).to eq(0)
          expect(parser.log.illness_type_7).to eq(0)
          expect(parser.log.illness_type_8).to eq(0)
          expect(parser.log.illness_type_9).to eq(0)
          expect(parser.log.illness_type_10).to eq(0)
        end
      end

      context "when none of the illness type values are seleceted" do
        let(:attributes) { setup_section_params.merge({ bulk_upload:, field_85: "1" }) }

        it "sets the values to nil" do
          parser.valid?
          expect(parser.log.illness_type_1).to be_nil
          expect(parser.log.illness_type_2).to be_nil
          expect(parser.log.illness_type_3).to be_nil
          expect(parser.log.illness_type_4).to be_nil
          expect(parser.log.illness_type_5).to be_nil
          expect(parser.log.illness_type_6).to be_nil
          expect(parser.log.illness_type_7).to be_nil
          expect(parser.log.illness_type_8).to be_nil
          expect(parser.log.illness_type_9).to be_nil
          expect(parser.log.illness_type_10).to be_nil
        end
      end
    end

    describe "#irproduct_other" do
      let(:attributes) { { bulk_upload:, field_12: "some other product" } }

      it "sets value to given free text string" do
        expect(parser.log.irproduct_other).to eql("some other product")
      end
    end

    describe "#tenancyother" do
      let(:attributes) { { bulk_upload:, field_39: "some other tenancy" } }

      it "sets value to given free text string" do
        expect(parser.log.tenancyother).to eql("some other tenancy")
      end
    end

    describe "#tenancylength" do
      let(:attributes) { { bulk_upload:, field_40: "2" } }

      it "sets value to given free text string" do
        expect(parser.log.tenancylength).to eq(2)
      end
    end

    describe "#earnings" do
      let(:attributes) { { bulk_upload:, field_119: "104.50" } }

      it "rounds to the nearest whole pound" do
        expect(parser.log.earnings).to eq(105)
      end
    end

    describe "#reasonother" do
      context "when reason is 'other'" do
        let(:attributes) { { bulk_upload:, field_98: "20", field_99: "some other reason" } }

        it "is set to given free text string" do
          expect(parser.log.reasonother).to eql("some other reason")
        end
      end

      context "when reason is not 'other'" do
        let(:attributes) { { bulk_upload:, field_98: "50", field_99: "some other reason" } }

        it "is set to nil" do
          expect(parser.log.reasonother).to be_nil
        end
      end
    end

    describe "#ppcodenk" do
      let(:attributes) { { bulk_upload:, field_102: "2" } }

      it "sets correct value from mapping" do
        expect(parser.log.ppcodenk).to eq(1)
      end
    end

    describe "#household_charge" do
      context "when log is general needs" do
        let(:attributes) { { bulk_upload:, field_4: 1, field_122: "1" } }

        it "sets correct value from mapping" do
          expect(parser.log.household_charge).to eq(nil)
        end
      end

      context "when log is supported housing" do
        let(:attributes) { { bulk_upload:, field_4: 2, field_122: "1" } }

        it "sets correct value from mapping" do
          expect(parser.log.household_charge).to eq(1)
        end
      end
    end

    describe "#chcharge" do
      let(:attributes) { setup_section_params.merge({ field_124: "123.45", field_125: "123.45", field_126: "123.45", field_127: "123.45", field_128: "123.45" }) }

      it "sets value given" do
        expect(parser.log.chcharge).to eq(123.45)
      end

      it "sets is care home to yes" do
        expect(parser.log.is_carehome).to eq(1)
      end

      it "clears any other given charges" do
        parser.log.save!
        expect(parser.log.tcharge).to be_nil
        expect(parser.log.brent).to be_nil
        expect(parser.log.supcharg).to be_nil
        expect(parser.log.pscharge).to be_nil
        expect(parser.log.scharge).to be_nil
      end
    end

    describe "#supcharg" do
      let(:attributes) { setup_section_params.merge({ field_125: "330", field_126: "0", field_127: "0", field_128: "123.45" }) }

      it "sets value given" do
        expect(parser.log.supcharg).to eq(123.45)
      end

      context "when other charges are not given" do
        context "and it is carehome" do
          let(:attributes) { setup_section_params.merge({ field_128: "123.45", field_124: "123.45", field_125: nil, field_126: nil, field_127: nil }) }

          it "does not set charges values" do
            parser.log.save!
            expect(parser.log.tcharge).to be_nil
            expect(parser.log.brent).to be_nil
            expect(parser.log.supcharg).to be_nil
            expect(parser.log.pscharge).to be_nil
            expect(parser.log.scharge).to be_nil
          end

          it "does not add errors to missing charges" do
            parser.valid?
            expect(parser.errors[:field_125]).to be_empty
            expect(parser.errors[:field_126]).to be_empty
            expect(parser.errors[:field_127]).to be_empty
            expect(parser.errors[:field_128]).to be_empty
          end
        end

        context "and it is not carehome" do
          let(:attributes) { setup_section_params.merge({ field_128: "123.45", field_124: nil, field_125: nil, field_126: nil, field_127: nil }) }

          it "does not set charges values" do
            parser.log.save!
            expect(parser.log.tcharge).to be_nil
            expect(parser.log.brent).to be_nil
            expect(parser.log.supcharg).to be_nil
            expect(parser.log.pscharge).to be_nil
            expect(parser.log.scharge).to be_nil
          end

          it "adds an error to all missing charges" do
            parser.valid?
            expect(parser.errors[:field_125]).to eql([I18n.t("validations.lettings.2024.bulk_upload.charges.missing_charges", sentence_fragment: "basic rent")])
            expect(parser.errors[:field_126]).to eql([I18n.t("validations.lettings.2024.bulk_upload.charges.missing_charges", sentence_fragment: "service charge")])
            expect(parser.errors[:field_127]).to eql([I18n.t("validations.lettings.2024.bulk_upload.charges.missing_charges", sentence_fragment: "personal service charge")])
            expect(parser.errors[:field_128]).to eql([I18n.t("validations.lettings.2024.bulk_upload.charges.missing_charges", sentence_fragment: "basic rent"), I18n.t("validations.lettings.2024.bulk_upload.charges.missing_charges", sentence_fragment: "service charge"), I18n.t("validations.lettings.2024.bulk_upload.charges.missing_charges", sentence_fragment: "personal service charge")])
          end
        end
      end

      context "when supscharg is not given" do
        context "and it is not carehome" do
          let(:attributes) { setup_section_params.merge({ field_123: 1, field_124: nil, field_125: "350.45", field_126: "0", field_127: "0", field_128: nil }) }

          it "does not set charges values" do
            parser.log.save!
            expect(parser.log.period).not_to be_nil
            expect(parser.log.tcharge).to be_nil
            expect(parser.log.brent).to be_nil
            expect(parser.log.supcharg).to be_nil
            expect(parser.log.pscharge).to be_nil
            expect(parser.log.scharge).to be_nil
          end

          it "adds an error to all charges" do
            parser.valid?
            expect(parser.errors[:field_125]).to eql([I18n.t("validations.lettings.2024.bulk_upload.charges.missing_charges", sentence_fragment: "support charge")])
            expect(parser.errors[:field_126]).to eql([I18n.t("validations.lettings.2024.bulk_upload.charges.missing_charges", sentence_fragment: "support charge")])
            expect(parser.errors[:field_127]).to eql([I18n.t("validations.lettings.2024.bulk_upload.charges.missing_charges", sentence_fragment: "support charge")])
            expect(parser.errors[:field_128]).to eql([I18n.t("validations.lettings.2024.bulk_upload.charges.missing_charges", sentence_fragment: "support charge")])
          end
        end
      end
    end

    describe "#pscharge" do
      let(:attributes) { { bulk_upload:, field_125: "111.45", field_126: "0", field_127: "123.45", field_128: "0" } }

      it "sets value given" do
        expect(parser.log.pscharge).to eq(123.45)
      end
    end

    describe "#scharge" do
      let(:attributes) { { bulk_upload:, field_125: "111.45", field_126: "123.45", field_127: "0", field_128: "0" } }

      it "sets value given" do
        expect(parser.log.scharge).to eq(123.45)
      end
    end

    describe "#propcode" do
      let(:attributes) { { bulk_upload:, field_14: "abc123" } }

      it "sets value given" do
        expect(parser.log.propcode).to eq("abc123")
      end
    end

    describe "#mrcdate" do
      context "when valid" do
        let(:attributes) { { bulk_upload:, field_33: "13", field_34: "12", field_35: "22" } }

        it "sets value given" do
          expect(parser.log.mrcdate).to eq(Date.new(2022, 12, 13))
        end
      end

      context "when valid (4 digit year)" do
        let(:attributes) { { bulk_upload:, field_33: "13", field_34: "12", field_35: "2022" } }

        it "sets value given" do
          expect(parser.log.mrcdate).to eq(Date.new(2022, 12, 13))
        end
      end

      context "when invalid" do
        let(:attributes) { { bulk_upload:, field_33: "13", field_34: "13", field_35: "22" } }

        it "does not raise an error" do
          expect { parser.log.mrcdate }.not_to raise_error
        end
      end
    end

    describe "#majorrepairs" do
      context "when mrcdate given" do
        let(:attributes) { { bulk_upload:, field_33: "13", field_34: "12", field_35: "22" } }

        it "sets #majorrepairs to 1" do
          expect(parser.log.majorrepairs).to eq(1)
        end
      end

      context "when mrcdate not given" do
        let(:attributes) { { bulk_upload:, field_33: "", field_34: "", field_35: "", field_4: 1 } }

        it "sets #majorrepairs to 0" do
          expect(parser.log.majorrepairs).to eq(0)
        end
      end
    end

    describe "#voiddate" do
      context "when valid" do
        let(:attributes) { { bulk_upload:, field_30: "13", field_31: "12", field_32: "22" } }

        it "sets value given" do
          expect(parser.log.voiddate).to eq(Date.new(2022, 12, 13))
        end
      end

      context "when valid (4 digit year)" do
        let(:attributes) { { bulk_upload:, field_30: "13", field_31: "12", field_32: "2022" } }

        it "sets value given" do
          expect(parser.log.voiddate).to eq(Date.new(2022, 12, 13))
        end
      end

      context "when invalid" do
        let(:attributes) { { bulk_upload:, field_30: "13", field_31: "13", field_32: "22" } }

        it "does not raise an error" do
          expect { parser.log.voiddate }.not_to raise_error
        end
      end
    end

    describe "#startdate" do
      let(:attributes) { { bulk_upload:, field_8: now.day.to_s, field_9: now.month.to_s, field_10: now.strftime("%g") } }

      it "sets value given" do
        expect(parser.log.startdate).to eq(now)
      end
    end

    describe "#postcode_full" do
      let(:attributes) { { bulk_upload:, field_4: 1, field_21: " EC1N ", field_22: " 2TD " } }

      it "strips whitespace" do
        expect(parser.log.postcode_full).to eql("EC1N 2TD")
      end

      context "when a partial postcode is provided" do
        let(:attributes) { { bulk_upload:, field_4: 1, field_21: "EC1N", field_22: "" } }

        it "is set to the partial value" do
          expect(parser.log.postcode_full).to eql("EC1N")
        end
      end
    end

    describe "#la" do
      let(:attributes) { { bulk_upload:, field_4: 1, field_23: "E07000223" } }

      it "sets to given value" do
        expect(parser.log.la).to eql("E07000223")
      end
    end

    describe "#prevloc" do
      let(:attributes) { { bulk_upload:, field_105: "E07000223" } }

      it "sets to given value" do
        expect(parser.log.prevloc).to eql("E07000223")
      end
    end

    describe "#previous_la_known" do
      context "when known" do
        let(:attributes) { { bulk_upload:, field_105: "E07000223" } }

        it "sets to 1" do
          expect(parser.log.previous_la_known).to eq(1)
        end
      end

      context "when not known" do
        let(:attributes) { { bulk_upload:, field_105: "", field_4: 1 } }

        it "sets to 0" do
          expect(parser.log.previous_la_known).to eq(0)
        end
      end
    end

    describe "#first_time_property_let_as_social_housing" do
      context "when field_24 is 15, 16, or 17" do
        let(:attributes) { { bulk_upload:, field_24: %w[15 16 17].sample } }

        it "sets to 1" do
          expect(parser.log.first_time_property_let_as_social_housing).to eq(1)
        end
      end

      context "when field_24 is not 15, 16, or 17" do
        let(:attributes) { { bulk_upload:, field_24: "1" } }

        it "sets to 0" do
          expect(parser.log.first_time_property_let_as_social_housing).to eq(0)
        end
      end
    end

    describe "#housingneeds" do
      context "when no disabled needs" do
        let(:attributes) { { bulk_upload:, field_83: "1" } }

        it "sets to 2" do
          expect(parser.log.housingneeds).to eq(2)
        end
      end

      context "when dont know about disabled needs" do
        let(:attributes) { { bulk_upload:, field_84: "1" } }

        it "sets to 3" do
          expect(parser.log.housingneeds).to eq(3)
        end
      end

      context "when housingneeds are given" do
        let(:attributes) { { bulk_upload:, field_83: "0", field_81: "1", field_82: "1" } }

        it "sets correct housingneeds" do
          expect(parser.log.housingneeds).to eq(1)
          expect(parser.log.housingneeds_type).to eq(2)
          expect(parser.log.housingneeds_other).to eq(1)
        end
      end

      context "when housingneeds are given and field_82 is nil" do
        let(:attributes) { { bulk_upload:, field_83: nil, field_81: "1", field_82: "1" } }

        it "sets correct housingneeds" do
          expect(parser.log.housingneeds).to eq(1)
          expect(parser.log.housingneeds_type).to eq(2)
          expect(parser.log.housingneeds_other).to eq(1)
        end
      end

      context "when housingneeds are not given" do
        let(:attributes) { { bulk_upload:, field_79: nil, field_80: nil, field_81: nil, field_83: nil } }

        it "sets correct housingneeds" do
          expect(parser.log.housingneeds).to eq(1)
          expect(parser.log.housingneeds_type).to eq(3)
        end
      end

      context "when housingneeds a and b are selected" do
        let(:attributes) { { bulk_upload:, field_79: "1", field_80: "1" } }

        it "sets error on housingneeds a and b" do
          parser.valid?
          expect(parser.errors[:field_79]).to include(I18n.t("validations.lettings.2024.bulk_upload.housingneeds_type.only_one_option_permitted"))
          expect(parser.errors[:field_80]).to include(I18n.t("validations.lettings.2024.bulk_upload.housingneeds_type.only_one_option_permitted"))
          expect(parser.errors[:field_81]).to be_blank
        end
      end

      context "when housingneeds a and c are selected" do
        let(:attributes) { { bulk_upload:, field_79: "1", field_81: "1" } }

        it "sets error on housingneeds a and c" do
          parser.valid?
          expect(parser.errors[:field_79]).to include(I18n.t("validations.lettings.2024.bulk_upload.housingneeds_type.only_one_option_permitted"))
          expect(parser.errors[:field_81]).to include(I18n.t("validations.lettings.2024.bulk_upload.housingneeds_type.only_one_option_permitted"))
          expect(parser.errors[:field_80]).to be_blank
        end
      end

      context "when housingneeds b and c are selected" do
        let(:attributes) { { bulk_upload:, field_80: "1", field_81: "1" } }

        it "sets error on housingneeds b and c" do
          parser.valid?
          expect(parser.errors[:field_80]).to include(I18n.t("validations.lettings.2024.bulk_upload.housingneeds_type.only_one_option_permitted"))
          expect(parser.errors[:field_81]).to include(I18n.t("validations.lettings.2024.bulk_upload.housingneeds_type.only_one_option_permitted"))
          expect(parser.errors[:field_79]).to be_blank
        end
      end

      context "when housingneeds a and g are selected" do
        let(:attributes) { { bulk_upload:, field_79: "1", field_83: "1" } }

        it "sets error on housingneeds a and g" do
          parser.valid?
          expect(parser.errors[:field_83]).to include(I18n.t("validations.lettings.2024.bulk_upload.housingneeds.no_disabled_needs_conjunction"))
          expect(parser.errors[:field_79]).to include(I18n.t("validations.lettings.2024.bulk_upload.housingneeds.no_disabled_needs_conjunction"))
          expect(parser.errors[:field_80]).to be_blank
          expect(parser.errors[:field_81]).to be_blank
        end
      end

      context "when only housingneeds g is selected" do
        let(:attributes) { { bulk_upload:, field_79: "0", field_83: "1" } }

        it "does not add any housingneeds errors" do
          parser.valid?
          expect(parser.errors[:field_55]).to be_blank
          expect(parser.errors[:field_79]).to be_blank
          expect(parser.errors[:field_80]).to be_blank
          expect(parser.errors[:field_81]).to be_blank
        end
      end

      context "when housingneeds a and h are selected" do
        let(:attributes) { { bulk_upload:, field_79: "1", field_84: "1" } }

        it "sets error on housingneeds a and h" do
          parser.valid?
          expect(parser.errors[:field_84]).to include(I18n.t("validations.lettings.2024.bulk_upload.housingneeds.dont_know_disabled_needs_conjunction"))
          expect(parser.errors[:field_79]).to include(I18n.t("validations.lettings.2024.bulk_upload.housingneeds.dont_know_disabled_needs_conjunction"))
          expect(parser.errors[:field_80]).to be_blank
          expect(parser.errors[:field_81]).to be_blank
        end
      end

      context "when only housingneeds h is selected" do
        let(:attributes) { { bulk_upload:, field_79: "0", field_84: "1" } }

        it "does not add any housingneeds errors" do
          parser.valid?
          expect(parser.errors[:field_84]).to be_blank
          expect(parser.errors[:field_79]).to be_blank
          expect(parser.errors[:field_80]).to be_blank
          expect(parser.errors[:field_81]).to be_blank
        end
      end
    end

    describe "#housingneeds_type" do
      context "when field_79 is 1" do
        let(:attributes) { { bulk_upload:, field_79: "1" } }

        it "set to 0" do
          expect(parser.log.housingneeds_type).to eq(0)
        end
      end

      context "when field_80 is 1" do
        let(:attributes) { { bulk_upload:, field_80: "1" } }

        it "set to 1" do
          expect(parser.log.housingneeds_type).to eq(1)
        end
      end

      context "when field_81 is 1" do
        let(:attributes) { { bulk_upload:, field_81: "1" } }

        it "set to 2" do
          expect(parser.log.housingneeds_type).to eq(2)
        end
      end
    end

    describe "#housingneeds_other" do
      context "when field_54 is 1" do
        let(:attributes) { { bulk_upload:, field_82: "1" } }

        it "sets to 1" do
          expect(parser.log.housingneeds_other).to eq(1)
        end
      end
    end
  end

  describe "#startdate" do
    context "when year of 9 is passed to represent 2009" do
      let(:attributes) { { bulk_upload:, field_8: "1", field_9: "1", field_10: "9" } }

      it "uses the year 2009" do
        expect(parser.send(:startdate)).to eql(Date.new(2009, 1, 1))
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
