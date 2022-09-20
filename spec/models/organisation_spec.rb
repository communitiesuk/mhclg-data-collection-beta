require "rails_helper"

RSpec.describe Organisation, type: :model do
  describe "#new" do
    let(:user) { FactoryBot.create(:user) }
    let!(:organisation) { user.organisation }
    let!(:scheme) { FactoryBot.create(:scheme, owning_organisation: organisation, managing_organisation: organisation) }

    it "has expected fields" do
      expect(organisation.attribute_names).to include("name", "phone", "provider_type")
    end

    it "has users" do
      expect(organisation.users.first).to eq(user)
    end

    it "has managed_schemes" do
      expect(organisation.managed_schemes.first).to eq(scheme)
    end

    it "has owned_schemes" do
      expect(organisation.owned_schemes.first).to eq(scheme)
    end

    it "validates provider_type presence" do
      expect { FactoryBot.create(:organisation, provider_type: nil) }
        .to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Provider type #{I18n.t('validations.organisation.provider_type_missing')}")
    end

    context "with parent/child association" do
      let(:child_organisation) { FactoryBot.create(:organisation, name: "DLUHC Child") }

      before do
        FactoryBot.create(:organisation_relationship, child_organisation:, parent_organisation: organisation)
      end

      it "has correct child" do
        expect(organisation.child_organisations.first).to eq(child_organisation)
      end

      it "has correct parent" do
        expect(child_organisation.parent_organisations.first).to eq(organisation)
      end
    end

    context "with data protection confirmations" do
      before do
        FactoryBot.create(:data_protection_confirmation, organisation:, confirmed: false, created_at: Time.utc(2018, 0o6, 0o5, 10, 36, 49))
        FactoryBot.create(:data_protection_confirmation, organisation:, created_at: Time.utc(2019, 0o6, 0o5, 10, 36, 49))
      end

      it "takes the most recently created" do
        expect(organisation.data_protection_confirmed?).to be true
      end
    end

    context "when the organisation only uses specific rent periods" do
      let(:rent_period_mappings) do
        { "2" => { "value" => "Weekly for 52 weeks" }, "3" => { "value" => "Every 2 weeks" } }
      end

      before do
        FactoryBot.create(:organisation_rent_period, organisation:, rent_period: 2)
        FactoryBot.create(:organisation_rent_period, organisation:, rent_period: 3)
        allow(RentPeriod).to receive(:rent_period_mappings).and_return(rent_period_mappings)
      end

      it "has rent periods associated" do
        expect(organisation.rent_periods).to eq([2, 3])
      end

      it "maps the rent periods to display values" do
        expect(organisation.rent_period_labels).to eq(["Weekly for 52 weeks", "Every 2 weeks"])
      end
    end

    context "when the organisation has not specified which rent periods it uses" do
      it "displays `all`" do
        expect(organisation.rent_period_labels).to eq(%w[All])
      end
    end

    context "with lettings logs" do
      let(:other_organisation) { FactoryBot.create(:organisation) }
      let!(:owned_lettings_log) do
        FactoryBot.create(
          :lettings_log,
          :completed,
          owning_organisation: organisation,
          managing_organisation: other_organisation,
          created_by: user,
        )
      end
      let!(:managed_lettings_log) do
        FactoryBot.create(
          :lettings_log,
          owning_organisation: other_organisation,
          managing_organisation: organisation,
        )
      end

      it "has owned lettings logs" do
        expect(organisation.owned_lettings_logs.first).to eq(owned_lettings_log)
      end

      it "has managed lettings logs" do
        expect(organisation.managed_lettings_logs.first).to eq(managed_lettings_log)
      end

      it "has lettings logs" do
        expect(organisation.lettings_logs.to_a).to match_array([owned_lettings_log, managed_lettings_log])
      end

      it "has lettings log status helper methods" do
        expect(organisation.completed_lettings_logs.to_a).to eq([owned_lettings_log])
        expect(organisation.not_completed_lettings_logs.to_a).to eq([managed_lettings_log])
      end
    end
  end

  describe "paper trail" do
    let(:organisation) { FactoryBot.create(:organisation) }

    it "creates a record of changes to a log" do
      expect { organisation.update!(name: "new test name") }.to change(organisation.versions, :count).by(1)
    end

    it "allows lettings logs to be restored to a previous version" do
      organisation.update!(name: "new test name")
      expect(organisation.paper_trail.previous_version.name).to eq("DLUHC")
    end
  end

  describe "scopes" do
    before do
      FactoryBot.create(:organisation, name: "Joe Bloggs")
      FactoryBot.create(:organisation, name: "Tom Smith")
    end

    context "when searching by name" do
      it "returns case insensitive matching records" do
        expect(described_class.search_by_name("Joe").count).to eq(1)
        expect(described_class.search_by_name("joe").count).to eq(1)
      end
    end

    context "when searching by all searchable field" do
      it "returns case insensitive matching records" do
        expect(described_class.search_by("Joe").count).to eq(1)
        expect(described_class.search_by("joe").count).to eq(1)
      end
    end
  end
end
