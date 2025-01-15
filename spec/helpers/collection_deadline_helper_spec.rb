require "rails_helper"

RSpec.describe CollectionDeadlineHelper do
  let(:current_user) { create(:user, :data_coordinator) }
  let(:user) { create(:user, :data_coordinator) }

  describe "#quarter_for_date" do
    it "returns correct cutoff date for the first quarter of 2024/25" do
      quarter = quarter_for_date(date: Time.zone.local(2024, 4, 1))
      expect(quarter.cutoff_date).to eq(Time.zone.local(2024, 7, 12))
      expect(quarter.quarter_start_date).to eq(Time.zone.local(2024, 4, 1))
      expect(quarter.quarter_end_date).to eq(Time.zone.local(2024, 6, 30))
    end

    it "returns correct cutoff date for the second quarter of 2024/25" do
      quarter = quarter_for_date(date: Time.zone.local(2024, 9, 30))
      expect(quarter.cutoff_date).to eq(Time.zone.local(2024, 10, 11))
      expect(quarter.quarter_start_date).to eq(Time.zone.local(2024, 7, 1))
      expect(quarter.quarter_end_date).to eq(Time.zone.local(2024, 9, 30))
    end

    it "returns correct cutoff date for the third quarter of 2024/25" do
      quarter = quarter_for_date(date: Time.zone.local(2024, 10, 25))
      expect(quarter.cutoff_date).to eq(Time.zone.local(2025, 1, 10))
      expect(quarter.quarter_start_date).to eq(Time.zone.local(2024, 10, 1))
      expect(quarter.quarter_end_date).to eq(Time.zone.local(2024, 12, 31))
    end
  end
end
