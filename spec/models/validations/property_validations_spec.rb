require "rails_helper"

RSpec.describe Validations::PropertyValidations do
  subject(:property_validator) { property_validator_class.new }

  let(:property_validator_class) { Class.new { include Validations::PropertyValidations } }
  let(:record) { FactoryBot.create(:case_log) }

  describe "#validate_property_number_of_times_relet" do
    let(:expected_error) { I18n.t("validations.property.offered.relet_number") }

    it "does not add an error if the record offered is missing" do
      record.offered = nil
      property_validator.validate_property_number_of_times_relet(record)
      expect(record.errors).to be_empty
    end

    it "does not add an error if offered is valid (number between 0 and 20)" do
      record.offered = 0
      property_validator.validate_property_number_of_times_relet(record)
      expect(record.errors).to be_empty
      record.offered = 10
      property_validator.validate_property_number_of_times_relet(record)
      expect(record.errors).to be_empty
      record.offered = 20
      property_validator.validate_property_number_of_times_relet(record)
      expect(record.errors).to be_empty
    end

    it "does add an error when offered is invalid" do
      record.offered = "invalid"
      property_validator.validate_property_number_of_times_relet(record)
      expect(record.errors).not_to be_empty
      expect(record.errors["offered"]).to include(match(expected_error))
      record.offered = 21
      property_validator.validate_property_number_of_times_relet(record)
      expect(record.errors).not_to be_empty
      expect(record.errors["offered"]).to include(match(expected_error))
    end
  end

  describe "#validate_shared_housing_rooms" do
    context "when number of bedrooms has not been answered" do
      it "does not add an error" do
        record.beds = nil
        record.unittype_gn = "Bedsit"
        property_validator.validate_shared_housing_rooms(record)
        expect(record.errors).to be_empty
      end
    end

    context "when unit type is shared and number of bedrooms has not been answered" do
      it "does not add an error" do
        record.beds = nil
        record.unittype_gn = "Shared bungalow"
        property_validator.validate_shared_housing_rooms(record)
        expect(record.errors).to be_empty
      end
    end

    context "when unit type has not been answered" do
      it "does not add an error" do
        record.beds = 2
        record.unittype_gn = nil
        property_validator.validate_shared_housing_rooms(record)
        expect(record.errors).to be_empty
      end
    end

    context "when a bedsit has more than 1 bedroom" do
      let(:expected_error) { I18n.t("validations.property.unittype_gn.one_bedroom_bedsit") }

      it "adds an error" do
        record.beds = 2
        record.unittype_gn = "Bedsit"
        property_validator.validate_shared_housing_rooms(record)
        expect(record.errors["unittype_gn"]).to include(match(expected_error))
        expect(record.errors["beds"]).to include(I18n.t("validations.property.unittype_gn.one_bedroom_bedsit"))
      end
    end

    context "when a bedsit has less than 1 bedroom" do
      let(:expected_error) { I18n.t("validations.property.unittype_gn.one_bedroom_bedsit") }

      it "adds an error" do
        record.beds = 0
        record.unittype_gn = "Bedsit"
        property_validator.validate_shared_housing_rooms(record)
        expect(record.errors["unittype_gn"]).to include(match(expected_error))
        expect(record.errors["beds"]).to include(I18n.t("validations.property.unittype_gn.one_bedroom_bedsit"))
      end
    end

    context "when shared housing has more than 7 bedrooms" do
      let(:expected_error) { I18n.t("validations.property.unittype_gn.one_seven_bedroom_shared") }

      it "adds an error if the number of bedrooms is not between 1 and 7" do
        record.beds = 8
        record.unittype_gn = "Shared house"
        record.other_hhmemb = 2
        property_validator.validate_shared_housing_rooms(record)
        expect(record.errors["unittype_gn"]).to include(match(expected_error))
        expect(record.errors["beds"]).to include(I18n.t("validations.property.unittype_gn.one_seven_bedroom_shared"))
      end
    end

    context "when shared housing has less than 1 bedrooms" do
      let(:expected_error) { I18n.t("validations.property.unittype_gn.one_seven_bedroom_shared") }

      it "adds an error if the number of bedrooms is not between 1 and 7" do
        record.beds = 0
        record.unittype_gn = "Shared house"
        record.other_hhmemb = 2
        property_validator.validate_shared_housing_rooms(record)
        expect(record.errors["unittype_gn"]).to include(match(expected_error))
        expect(record.errors["beds"]).to include(I18n.t("validations.property.unittype_gn.one_seven_bedroom_shared"))
      end
    end

    context "when there are too many bedrooms for the number of household members and unit type" do
      let(:expected_error) { I18n.t("validations.property.unittype_gn.one_three_bedroom_single_tenant_shared") }

      it "adds an error" do
        record.beds = 4
        record.unittype_gn = "Shared house"
        record.other_hhmemb = 0
        property_validator.validate_shared_housing_rooms(record)
        expect(record.errors["unittype_gn"]).to include(match(expected_error))
        expect(record.errors["beds"]).to include(I18n.t("validations.property.unittype_gn.one_three_bedroom_single_tenant_shared"))
      end
    end

    context "when a negative number of bedrooms is entered" do
      it "adds an error" do
        record.beds = -4
        property_validator.validate_shared_housing_rooms(record)
        expect(record.errors["beds"]).to include(I18n.t("validations.property.beds.negative"))
      end
    end
  end

  describe "#validate_la" do
    context "when the rent type is London affordable" do
      let(:expected_error) { I18n.t("validations.property.la.london_rent") }

      it "validates that the local authority is in London" do
        record.la = "Ashford"
        record.rent_type = "London Affordable rent"
        property_validator.validate_la(record)
        expect(record.errors["la"]).to include(match(expected_error))
      end

      it "expects that the local authority is in London" do
        record.la = "Westminster"
        record.rent_type = "London Affordable rent"
        property_validator.validate_la(record)
        expect(record.errors["la"]).to be_empty
      end
    end
  end

  describe "#validate_unitletas" do
    context "when the property has not been let before" do
      it "validates that no previous let type is provided" do
        record.first_time_property_let_as_social_housing = "Yes"
        record.unitletas = "Social rent basis"
        property_validator.validate_unitletas(record)
        expect(record.errors["unitletas"])
          .to include(match I18n.t("validations.property.rsnvac.previous_let_social"))
        record.unitletas = "Affordable rent basis"
        property_validator.validate_unitletas(record)
        expect(record.errors["unitletas"])
          .to include(match I18n.t("validations.property.rsnvac.previous_let_social"))
        record.unitletas = "Intermediate rent basis"
        property_validator.validate_unitletas(record)
        expect(record.errors["unitletas"])
          .to include(match I18n.t("validations.property.rsnvac.previous_let_social"))
        record.unitletas = "Don’t know"
        property_validator.validate_unitletas(record)
        expect(record.errors["unitletas"])
          .to include(match I18n.t("validations.property.rsnvac.previous_let_social"))
      end
    end

    context "when the property has been let previously" do
      it "expects to have a previous let type" do
        record.first_time_property_let_as_social_housing = "No"
        record.unitletas = "Social rent basis"
        property_validator.validate_unitletas(record)
        expect(record.errors["unitletas"]).to be_empty
      end
    end
  end

  describe "validate_rsnvac" do
    context "when the property has not been let before" do
      it "validates that it has a first let reason for vacancy" do
        record.first_time_property_let_as_social_housing = "Yes"
        record.rsnvac = "Tenant moved to care home"
        property_validator.validate_rsnvac(record)
        expect(record.errors["rsnvac"])
          .to include(match I18n.t("validations.property.rsnvac.first_let_social"))
      end

      it "expects to have a first let reason for vacancy" do
        record.first_time_property_let_as_social_housing = "Yes"
        record.rsnvac = "First let of new-build property"
        property_validator.validate_rsnvac(record)
        expect(record.errors["rsnvac"]).to be_empty
        record.rsnvac = "First let of conversion, rehabilitation or acquired property"
        property_validator.validate_rsnvac(record)
        expect(record.errors["rsnvac"]).to be_empty
        record.rsnvac = "First let of leased property"
        property_validator.validate_rsnvac(record)
        expect(record.errors["rsnvac"]).to be_empty
      end
    end

    context "when the property has been let as social housing before" do
      it "validates that the reason for vacancy is not a first let as social housing reason" do
        record.first_time_property_let_as_social_housing = "No"
        record.rsnvac = "First let of new-build property"
        property_validator.validate_rsnvac(record)
        expect(record.errors["rsnvac"])
          .to include(match I18n.t("validations.property.rsnvac.first_let_not_social"))
        record.rsnvac = "First let of conversion, rehabilitation or acquired property"
        property_validator.validate_rsnvac(record)
        expect(record.errors["rsnvac"])
          .to include(match I18n.t("validations.property.rsnvac.first_let_not_social"))
        record.rsnvac = "First let of leased property"
        property_validator.validate_rsnvac(record)
        expect(record.errors["rsnvac"])
          .to include(match I18n.t("validations.property.rsnvac.first_let_not_social"))
      end

      it "expects the reason for vacancy to be a first let as social housing reason" do
        record.first_time_property_let_as_social_housing = "Yes"
        record.rsnvac = "First let of new-build property"
        property_validator.validate_rsnvac(record)
        expect(record.errors["rsnvac"]).to be_empty
        record.rsnvac = "First let of conversion, rehabilitation or acquired property"
        property_validator.validate_rsnvac(record)
        expect(record.errors["rsnvac"]).to be_empty
        record.rsnvac = "First let of leased property"
        property_validator.validate_rsnvac(record)
        expect(record.errors["rsnvac"]).to be_empty
      end
    end

    context "when the property has been let before" do
      let(:non_temporary_previous_tenancies) do
        [
          "Tied housing or rented with job",
          "Supported housing",
          "Sheltered accommodation",
          "Home Office Asylum Support",
          "Any other accommodation",
        ]
      end

      context "when the previous tenancy was not temporary" do
        let(:referral_sources) do
          [
            "Re-located through official housing mobility scheme",
            "Other social landlord",
            "Police, probation or prison",
            "Youth offending team",
            "Community mental health team",
            "Health service",
          ]
        end

        it "validates that the property is not being relet to tenant who occupied as temporary" do
          non_temporary_previous_tenancies.each do |rsn|
            record.rsnvac = "Re-let to tenant who occupied same property as temporary accommodation"
            record.prevten = rsn
            property_validator.validate_rsnvac(record)
            expect(record.errors["rsnvac"])
              .to include(match I18n.t("validations.property.rsnvac.non_temp_accommodation"))
          end
        end

        it "validates that the letting source is not a referral" do
          referral_sources.each do |src|
            record.rsnvac = "Re-let to tenant who occupied same property as temporary accommodation"
            record.referral = src
            property_validator.validate_rsnvac(record)
            expect(record.errors["rsnvac"])
              .to include(match I18n.t("validations.property.rsnvac.referral_invalid"))
          end
        end
      end

      context "when the previous tenancy was temporary" do
        it "expects that the property can be relet to a tenant who previously occupied it as temporary" do
          record.prevten = "Fixed-term local authority general needs tenancy"
          record.rsnvac = "Re-let to tenant who occupied same property as temporary accommodation"
          property_validator.validate_rsnvac(record)
          expect(record.errors["rsnvac"]).to be_empty
        end

        it "expects that the letting source can be a referral" do
          record.prevten = "Fixed-term local authority general needs tenancy"
          record.referral = "Re-located through official housing mobility scheme"
          property_validator.validate_rsnvac(record)
          expect(record.errors["rsnvac"]).to be_empty
        end
      end
    end
  end
end
