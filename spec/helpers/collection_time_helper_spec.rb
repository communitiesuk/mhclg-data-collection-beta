require "rails_helper"

RSpec.describe CollectionTimeHelper do
  let(:current_user) { create(:user, :data_coordinator) }
  let(:user) { create(:user, :data_coordinator) }

  describe "Current collection start year" do
    before do
      allow(Time).to receive(:now).and_return(now)
    end

    context "when the date is after 1st of April" do
      let(:now) { Time.utc(2022, 8, 3) }

      it "returns the same year as the current start year" do
        expect(current_collection_start_year).to eq(2022)
      end

      it "returns the correct current start date" do
        expect(current_collection_start_date).to eq(Time.zone.local(2022, 4, 1))
      end

      it "returns the correct current end date" do
        expect(current_collection_end_date).to eq(Time.zone.local(2023, 3, 31).end_of_day)
      end
    end

    context "with the date before 1st of April" do
      let(:now) { Time.utc(2022, 2, 3) }

      it "returns the previous year as the current start year" do
        expect(current_collection_start_year).to eq(2021)
      end

      it "returns the correct current start date" do
        expect(current_collection_start_date).to eq(Time.zone.local(2021, 4, 1))
      end

      it "returns the correct current end date" do
        expect(current_collection_end_date).to eq(Time.zone.local(2022, 3, 31).end_of_day)
      end
    end
  end

  describe "Any collection year" do
    context "when the date is after 1st of April" do
      let(:now) { Time.utc(2022, 8, 3) }

      it "returns the same year as the current start year" do
        expect(collection_start_year_for_date(now)).to eq(2022)
      end

      it "returns the correct current start date" do
        expect(collection_start_date(now)).to eq(Time.zone.local(2022, 4, 1))
      end

      it "returns the correct current end date" do
        expect(collection_end_date(now)).to eq(Time.zone.local(2023, 3, 31).end_of_day)
      end
    end

    context "with the date before 1st of April" do
      let(:now) { Time.utc(2022, 2, 3) }

      it "returns the previous year as the current start year" do
        expect(collection_start_year_for_date(now)).to eq(2021)
      end

      it "returns the correct current start date" do
        expect(collection_start_date(now)).to eq(Time.zone.local(2021, 4, 1))
      end

      it "returns the correct current end date" do
        expect(collection_end_date(now)).to eq(Time.zone.local(2022, 3, 31).end_of_day)
      end
    end
  end

  describe "#date_mid_collection_year_formatted" do
    subject(:result) { date_mid_collection_year_formatted(input) }

    context "when called with nil" do
      let(:input) { nil }

      it "returns the 13th of September in the current collection year" do
        year = current_collection_start_year
        expect(result).to eq("13 9 #{year}")
      end
    end

    context "when called with a date after the first of April" do
      calendar_year = 2030
      let(:input) { Date.new(calendar_year, 7, 7) }

      it "returns the 13th of September from that year" do
        expect(result).to eq("13 9 #{calendar_year}")
      end
    end

    context "when called with a date before April" do
      calendar_year = 2040
      let(:input) { Date.new(calendar_year, 2, 7) }

      it "returns the 13th of September from the previous year" do
        expect(result).to eq("13 9 #{calendar_year - 1}")
      end
    end
  end
end
