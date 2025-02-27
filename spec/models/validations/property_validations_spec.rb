require "rails_helper"

RSpec.describe Validations::PropertyValidations do
  subject(:property_validator) { property_validator_class.new }

  let(:property_validator_class) { Class.new { include Validations::PropertyValidations } }
  let(:log) { build(:lettings_log) }

  describe "#validate_shared_housing_rooms" do
    context "when number of bedrooms has not been answered" do
      it "does not add an error" do
        log.beds = nil
        log.unittype_gn = 2
        property_validator.validate_shared_housing_rooms(log)
        expect(log.errors).to be_empty
      end
    end

    context "when unit type is shared and number of bedrooms has not been answered" do
      it "does not add an error" do
        log.beds = nil
        log.unittype_gn = 10
        property_validator.validate_shared_housing_rooms(log)
        expect(log.errors).to be_empty
      end
    end

    context "when unit type has not been answered" do
      it "does not add an error" do
        log.beds = 2
        log.unittype_gn = nil
        property_validator.validate_shared_housing_rooms(log)
        expect(log.errors).to be_empty
      end
    end

    context "when a bedsit has more than 1 bedroom" do
      before do
        log.beds = 2
        log.unittype_gn = 2
      end

      context "and the log is for 24/25 or later" do
        it "does not add an error" do
          property_validator.validate_shared_housing_rooms(log)

          expect(log.errors).to be_empty
        end
      end
    end

    context "when shared housing has more than 7 bedrooms" do
      let(:expected_error) { I18n.t("validations.lettings.property.unittype_gn.one_seven_bedroom_shared") }

      it "adds an error if the number of bedrooms is not between 1 and 7" do
        log.beds = 8
        log.unittype_gn = 9
        log.hhmemb = 3
        property_validator.validate_shared_housing_rooms(log)
        expect(log.errors["unittype_gn"]).to include(match(expected_error))
        expect(log.errors["beds"]).to include(I18n.t("validations.lettings.property.unittype_gn.one_seven_bedroom_shared"))
      end
    end

    context "when shared housing has less than 1 bedrooms" do
      let(:expected_error) { I18n.t("validations.lettings.property.unittype_gn.one_seven_bedroom_shared") }

      it "adds an error if the number of bedrooms is not between 1 and 7" do
        log.beds = 0
        log.unittype_gn = 9
        log.hhmemb = 3
        property_validator.validate_shared_housing_rooms(log)
        expect(log.errors["unittype_gn"]).to include(match(expected_error))
        expect(log.errors["beds"]).to include(I18n.t("validations.lettings.property.unittype_gn.one_seven_bedroom_shared"))
      end
    end

    context "when there are too many bedrooms for the number of household members and unit type" do
      let(:expected_error) { I18n.t("validations.lettings.property.unittype_gn.one_three_bedroom_single_tenant_shared") }

      it "adds an error" do
        log.beds = 4
        log.unittype_gn = 9
        log.hhmemb = 1
        property_validator.validate_shared_housing_rooms(log)
        expect(log.errors["unittype_gn"]).to include(match(expected_error))
        expect(log.errors["beds"]).to include(I18n.t("validations.lettings.property.unittype_gn.one_three_bedroom_single_tenant_shared"))
      end
    end
  end

  describe "validate_rsnvac" do
    context "when the property has not been let before" do
      it "expects to have a first let reason for vacancy" do
        log.first_time_property_let_as_social_housing = 1
        log.rsnvac = 15
        property_validator.validate_rsnvac(log)
        expect(log.errors["rsnvac"]).to be_empty
        log.rsnvac = 16
        property_validator.validate_rsnvac(log)
        expect(log.errors["rsnvac"]).to be_empty
        log.rsnvac = 17
        property_validator.validate_rsnvac(log)
        expect(log.errors["rsnvac"]).to be_empty
      end
    end

    context "when the property has been let as social housing before" do
      it "expects the reason for vacancy to be a first let as social housing reason" do
        log.first_time_property_let_as_social_housing = 1
        log.rsnvac = 15
        property_validator.validate_rsnvac(log)
        expect(log.errors["rsnvac"]).to be_empty
        log.rsnvac = 16
        property_validator.validate_rsnvac(log)
        expect(log.errors["rsnvac"]).to be_empty
        log.rsnvac = 17
        property_validator.validate_rsnvac(log)
        expect(log.errors["rsnvac"]).to be_empty
      end

      context "when the letting is not a renewal" do
        it "validates that the reason for vacancy is not renewal" do
          log.first_time_property_let_as_social_housing = 0
          log.renewal = 0
          log.rsnvac = 14
          property_validator.validate_rsnvac(log)
          expect(log.errors["rsnvac"])
                .to include(match I18n.t("validations.lettings.property.rsnvac.not_a_renewal"))
        end
      end
    end

    context "when the property has been let before" do
      let(:non_temporary_previous_tenancies) { [4, 5, 16, 21, 22] }

      context "when the previous tenancy was not temporary" do
        let(:referral_sources) { described_class::REFERRAL_INVALID_TMP }

        it "validates that the property is not being relet to tenant who occupied as temporary" do
          non_temporary_previous_tenancies.each do |prevten|
            log.rsnvac = 9
            log.prevten = prevten
            property_validator.validate_rsnvac(log)
            expect(log.errors["rsnvac"])
              .to include(match I18n.t("validations.lettings.property.rsnvac.non_temp_accommodation"))
          end
        end

        it "validates that the letting source is not a referral" do
          referral_sources.each do |src|
            log.rsnvac = 9
            log.referral = src
            property_validator.validate_rsnvac(log)
            expect(log.errors["rsnvac"])
              .to include(match I18n.t("validations.lettings.property.rsnvac.referral_invalid"))
          end
        end
      end

      context "when the previous tenancy was temporary" do
        it "expects that the property can be relet to a tenant who previously occupied it as temporary" do
          log.prevten = 0
          log.rsnvac = 2
          property_validator.validate_rsnvac(log)
          expect(log.errors["rsnvac"]).to be_empty
        end

        it "expects that the letting source can be a referral" do
          log.prevten = 0
          log.referral_type = 101
          log.referral = 2
          property_validator.validate_rsnvac(log)
          expect(log.errors["rsnvac"]).to be_empty
        end
      end
    end
  end

  describe "#validate_uprn" do
    context "when within length limit but alphanumeric" do
      let(:log) { build(:sales_log, uprn: "123abc") }

      it "adds an error" do
        property_validator.validate_uprn(log)
        expect(log.errors.added?(:uprn, "UPRN must be 12 digits or less.")).to be true
      end
    end

    context "when over the length limit" do
      let(:log) { build(:sales_log, uprn: "1234567890123") }

      it "adds an error" do
        property_validator.validate_uprn(log)
        expect(log.errors.added?(:uprn, "UPRN must be 12 digits or less.")).to be true
      end
    end

    context "when within the limit and only numeric" do
      let(:log) { build(:sales_log, uprn: "123456789012") }

      it "does not add an error" do
        property_validator.validate_uprn(log)
        expect(log.errors).not_to be_present
      end
    end
  end

  describe "#validate_la_in_england" do
    context "with a log on or after 2025" do
      before do
        allow(log.form).to receive(:start_year_2025_or_later?).and_return true
      end

      context "and the local authority is not in England for general needs log" do
        let(:log) { build(:lettings_log, la: "S12000019", needstype: 1) }

        it "adds an error" do
          property_validator.validate_la_in_england(log)
          expect(log.errors["la"]).to include(I18n.t("validations.lettings.property.la.not_in_england"))
          expect(log.errors["postcode_full"]).to include(I18n.t("validations.lettings.property.postcode_full.not_in_england"))
          expect(log.errors["uprn"]).to include(I18n.t("validations.lettings.property.uprn.not_in_england"))
          expect(log.errors["uprn_confirmation"]).to include(I18n.t("validations.lettings.property.uprn_confirmation.not_in_england"))
          expect(log.errors["uprn_selection"]).to include(I18n.t("validations.lettings.property.uprn_selection.not_in_england"))
          expect(log.errors["startdate"]).to include(I18n.t("validations.lettings.property.startdate.postcode_not_in_england"))
          expect(log.errors["scheme_id"]).to be_empty
          expect(log.errors["location_id"]).to be_empty
        end
      end

      context "and the local authority is not in England for supported housing log" do
        let(:location) { create(:location, location_code: "S12000019") }
        let(:log) { build(:lettings_log, la: "S12000019", needstype: 2, location:) }

        it "adds an error" do
          property_validator.validate_la_in_england(log)
          expect(log.errors["scheme_id"]).to include(I18n.t("validations.lettings.property.scheme_id.not_in_england"))
          expect(log.errors["location_id"]).to include(I18n.t("validations.lettings.property.location_id.not_in_england"))
          expect(log.errors["startdate"]).to include(I18n.t("validations.lettings.property.startdate.location_not_in_england"))
          expect(log.errors["la"]).to be_empty
          expect(log.errors["postcode_full"]).to be_empty
          expect(log.errors["uprn"]).to be_empty
          expect(log.errors["uprn_confirmation"]).to be_empty
          expect(log.errors["uprn_selection"]).to be_empty
        end
      end

      context "and the local authority is in England" do
        let(:log) { build(:lettings_log, la: "E06000002") }

        it "does not add an error" do
          property_validator.validate_la_in_england(log)
          expect(log.errors["la"]).to be_empty
          expect(log.errors["postcode_full"]).to be_empty
          expect(log.errors["uprn"]).to be_empty
          expect(log.errors["uprn_confirmation"]).to be_empty
          expect(log.errors["uprn_selection"]).to be_empty
          expect(log.errors["startdate"]).to be_empty
        end
      end
    end

    context "with a log before 2025" do
      before do
        allow(log.form).to receive(:start_year_2025_or_later?).and_return false
      end

      context "and the local authority is not in England" do
        let(:log) { build(:lettings_log, la: "S12000019") }

        it "does not add an error" do
          property_validator.validate_la_in_england(log)
          expect(log.errors["la"]).to be_empty
          expect(log.errors["postcode_full"]).to be_empty
          expect(log.errors["uprn"]).to be_empty
          expect(log.errors["uprn_confirmation"]).to be_empty
          expect(log.errors["uprn_selection"]).to be_empty
        end
      end
    end
  end
end
