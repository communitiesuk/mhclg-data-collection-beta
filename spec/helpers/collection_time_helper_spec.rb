require "rails_helper"

RSpec.describe CollectionTimeHelper do
  let(:current_user) { create(:user, :data_coordinator) }
  let(:user) { create(:user, :data_coordinator) }

  around do |example|
    Timecop.freeze(now) do
      example.run
    end
  end

  describe "Current collection start year" do
    context "when the date is after 1st of April" do
      let(:now) { Time.utc(2022, 8, 3) }

      it "returns the same year as the current start year" do
        expect(current_collection_start_year).to eq(2022)
      end

      it "returns the correct current start date" do
        expect(current_collection_start_date).to eq(Time.zone.local(2022, 4, 1))
      end
    end

    context "with the date before 1st of April" do
      let(:now) { Time.utc(2022, 2, 3) }

      it "returns the previous year as the current start year" do
        expect(current_collection_start_year).to eq(2021)
      end
    end
  end
end
