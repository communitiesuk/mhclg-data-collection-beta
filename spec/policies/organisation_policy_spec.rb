require "rails_helper"

RSpec.describe OrganisationPolicy do
  subject(:policy) { described_class }

  let(:organisation) { FactoryBot.create(:organisation) }
  let(:data_provider) { FactoryBot.create(:user, :data_provider) }
  let(:data_coordinator) { FactoryBot.create(:user, :data_coordinator) }
  let(:support) { FactoryBot.create(:user, :support) }

  permissions :deactivate? do
    it "does not permit data providers to deactivate an organisation" do
      organisation.active = true
      expect(policy).not_to permit(data_provider, organisation)
    end

    it "does not permit data coordinators to deactivate an organisation" do
      organisation.active = true
      expect(policy).not_to permit(data_coordinator, organisation)
    end

    it "permits support users to deactivate an active organisation" do
      organisation.active = true
      expect(policy).to permit(support, organisation)
    end

    it "does not permit support users to deactivate an inactive organisation" do
      organisation.active = false
      expect(policy).not_to permit(support, organisation)
    end

    it "does not permit support users to deactivate a merged organisation" do
      organisation.active = true
      organisation.merge_date = Time.zone.local(2023, 8, 2)
      expect(policy).not_to permit(support, organisation)
    end
  end

  permissions :reactivate? do
    it "does not permit data providers to reactivate an organisation" do
      organisation.active = false
      expect(policy).not_to permit(data_provider, organisation)
    end

    it "does not permit data coordinators to reactivate an organisation" do
      organisation.active = false
      expect(policy).not_to permit(data_coordinator, organisation)
    end

    it "permits support users to reactivate an inactive organisation" do
      organisation.active = false
      expect(policy).to permit(support, organisation)
    end

    it "does not permit support users to reactivate an active organisation" do
      organisation.active = true
      expect(policy).not_to permit(support, organisation)
    end

    it "does not permit support users to reactivate a merged organisation" do
      organisation.active = false
      organisation.merge_date = Time.zone.local(2023, 8, 2)
      expect(policy).not_to permit(support, organisation)
    end
  end
end
