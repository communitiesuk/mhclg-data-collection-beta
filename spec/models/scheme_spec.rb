require "rails_helper"

RSpec.describe Scheme, type: :model do
  describe "#new" do
    let(:scheme) { FactoryBot.create(:scheme) }

    it "belongs to an organisation" do
      expect(scheme.organisation).to be_a(Organisation)
    end

    it "validates organisation_id presence" do
      expect { FactoryBot.create(:scheme, organisation: nil) }
        .to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Provider type #{I18n.t('validations.scheme.id_missing')}")
    end

    describe "scopes" do
      let!(:scheme_1) { FactoryBot.create(:scheme) }
      let!(:scheme_2) { FactoryBot.create(:scheme) }
      let!(:location) { FactoryBot.create(:location, scheme: scheme_1) }
      let!(:location_2) { FactoryBot.create(:location, scheme: scheme_2) }

      context "when searching by code" do
        it "returns case insensitive matching records" do
          expect(described_class.search_by_code(scheme_1.code.upcase).count).to eq(1)
          expect(described_class.search_by_code(scheme_1.code.downcase).count).to eq(1)
          expect(described_class.search_by_code(scheme_1.code.downcase).first.code).to eq(scheme_1.code)
          expect(described_class.search_by_code(scheme_2.code.upcase).count).to eq(1)
          expect(described_class.search_by_code(scheme_2.code.downcase).count).to eq(1)
          expect(described_class.search_by_code(scheme_2.code.downcase).first.code).to eq(scheme_2.code)
        end
      end

      context "when searching by scheme name" do
        it "returns case insensitive matching records" do
          expect(described_class.search_by_service_name(scheme_1.service_name.upcase).count).to eq(1)
          expect(described_class.search_by_service_name(scheme_1.service_name.downcase).count).to eq(1)
          expect(described_class.search_by_service_name(scheme_1.service_name.downcase).first.service_name).to eq(scheme_1.service_name)
          expect(described_class.search_by_service_name(scheme_2.service_name.upcase).count).to eq(1)
          expect(described_class.search_by_service_name(scheme_2.service_name.downcase).count).to eq(1)
          expect(described_class.search_by_service_name(scheme_2.service_name.downcase).first.service_name).to eq(scheme_2.service_name)
        end
      end

      context "when searching by postcode" do
        it "returns case insensitive matching records" do
          expect(described_class.search_by_postcode(location.postcode.upcase).count).to eq(1)
          expect(described_class.search_by_postcode(location.postcode.downcase).count).to eq(1)
          expect(described_class.search_by_postcode(location.postcode.downcase).first.locations.first.postcode).to eq(location.postcode)
          expect(described_class.search_by_postcode(location_2.postcode.upcase).count).to eq(1)
          expect(described_class.search_by_postcode(location_2.postcode.downcase).count).to eq(1)
          expect(described_class.search_by_postcode(location_2.postcode.downcase).first.locations.first.postcode).to eq(location_2.postcode)
        end
      end

      context "when searching by all searchable fields" do
        it "returns case insensitive matching records" do
          expect(described_class.search_by(scheme_1.code.upcase).count).to eq(1)
          expect(described_class.search_by(scheme_1.code.downcase).count).to eq(1)
          expect(described_class.search_by(scheme_1.code.downcase).first.code).to eq(scheme_1.code)
          expect(described_class.search_by_service_name(scheme_2.service_name.upcase).count).to eq(1)
          expect(described_class.search_by_service_name(scheme_2.service_name.downcase).count).to eq(1)
          expect(described_class.search_by_service_name(scheme_2.service_name.downcase).first.service_name).to eq(scheme_2.service_name)
        end
      end
    end
  end
end
