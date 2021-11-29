require "rails_helper"

RSpec.describe User, type: :model do
  describe "#new" do
    let(:user) { FactoryBot.create(:user) }
    let(:other_organisation) { FactoryBot.create(:organisation) }
    let!(:owned_case_log) do
      FactoryBot.create(
        :case_log,
        :completed,
        owning_organisation: user.organisation,
        managing_organisation: other_organisation,
      )
    end
    let!(:managed_case_log) do
      FactoryBot.create(
        :case_log,
        owning_organisation: other_organisation,
        managing_organisation: user.organisation,
      )
    end

    it "belongs to an organisation" do
      expect(user.organisation).to be_a(Organisation)
    end

    it "has owned case logs through their organisation" do
      expect(user.owned_case_logs.first).to eq(owned_case_log)
    end

    it "has managed case logs through their organisation" do
      expect(user.managed_case_logs.first).to eq(managed_case_log)
    end

    it "has case logs through their organisation" do
      expect(user.case_logs.to_a).to eq([owned_case_log, managed_case_log])
    end

    it "has case log status helper methods" do
      expect(user.completed_case_logs.to_a).to eq([owned_case_log])
      expect(user.not_completed_case_logs.to_a).to eq([managed_case_log])
    end
  end
end
