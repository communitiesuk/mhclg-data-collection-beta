require "rails_helper"

RSpec.describe Validations::SoftValidations do
  let(:record) { FactoryBot.create(:case_log) }

  describe "rent min max validations" do
    before do
      LaRentRange.create!(
        ranges_rent_id: "1",
        la: "E07000223",
        beds: 1,
        lettype: 1,
        soft_min: 12.41,
        soft_max: 89.54,
        hard_min: 9.87,
        hard_max: 100.99,
        start_year: 2021,
      )

      record.la = "E07000223"
      record.lettype = 1
      record.beds = 1
      record.period = 1
      record.startdate = Time.zone.local(2021, 10, 10)
    end

    context "when validating soft min" do
      before do
        record.brent = 11
      end

      it "returns out of soft min range if no startdate is given" do
        record.startdate = nil
        expect(record)
          .not_to be_rent_in_soft_min_range
      end

      it "returns out of soft min range if no brent is given" do
        record.brent = nil
        expect(record)
          .not_to be_rent_in_soft_min_range
      end

      it "returns true if weekly rent is in soft min range" do
        expect(record)
          .to be_rent_in_soft_min_range
      end
    end

    context "when validating soft max" do
      before do
        record.brent = 90
      end

      it "returns out of soft max range if no startdate is given" do
        record.startdate = nil
        expect(record)
          .not_to be_rent_in_soft_max_range
      end

      it "returns out of soft max range if no brent is given" do
        record.brent = nil
        expect(record)
          .not_to be_rent_in_soft_max_range
      end

      it "returns true if weekly rent is in soft max range" do
        expect(record)
          .to be_rent_in_soft_max_range
      end
    end
  end

  describe "retirement soft validations" do
    context "when the tenant is retired but under the expected retirement age" do
      context "when the tenant is female" do
        it "shows the interruption screen" do
          record.update!(age1: 43, sex1: "F", ecstat1: 5)
          expect(record.person_1_retired_under_soft_min_age?).to be true
        end
      end

      context "when the tenant is male" do
        it "shows the interruption screen" do
          record.update!(age1: 43, sex1: "M", ecstat1: 5)
          expect(record.person_1_retired_under_soft_min_age?).to be true
        end
      end

      context "when the tenant is non-binary" do
        it "shows the interruption screen" do
          record.update!(age1: 43, sex1: "X", ecstat1: 5)
          expect(record.person_1_retired_under_soft_min_age?).to be true
        end
      end
    end

    context "when the tenant is not retired but over the expected retirement age" do
      context "when the tenant is female" do
        it "shows the interruption screen" do
          record.update!(age1: 85, sex1: "F", ecstat1: 3)
          expect(record.person_1_not_retired_over_soft_max_age?).to be true
        end
      end

      context "when the tenant is male" do
        it "shows the interruption screen" do
          record.update!(age1: 85, sex1: "M", ecstat1: 3)
          expect(record.person_1_not_retired_over_soft_max_age?).to be true
        end
      end

      context "when the tenant is non-binary" do
        it "shows the interruption screen" do
          record.update!(age1: 85, sex1: "X", ecstat1: 3)
          expect(record.person_1_not_retired_over_soft_max_age?).to be true
        end
      end
    end

    context "when the tenant prefers not to say what their economic status is but is under the expected retirement age" do
      context "when the tenant is female" do
        it "does not show the interruption screen" do
          record.update!(age1: 43, sex1: "F", ecstat1: 10)
          expect(record.person_1_retired_under_soft_min_age?).to be false
        end
      end

      context "when the tenant is male" do
        it "does not show the interruption screen" do
          record.update!(age1: 43, sex1: "M", ecstat1: 10)
          expect(record.person_1_retired_under_soft_min_age?).to be false
        end
      end

      context "when the tenant is non-binary" do
        it "does not show the interruption screen" do
          record.update!(age1: 43, sex1: "X", ecstat1: 10)
          expect(record.person_1_retired_under_soft_min_age?).to be false
        end
      end
    end

    context "when the tenant prefers not to say what their economic status is but is over the expected retirement age" do
      context "when the tenant is female" do
        it "does not show the interruption screen" do
          record.update!(age1: 85, sex1: "F", ecstat1: 10)
          expect(record.person_1_not_retired_over_soft_max_age?).to be false
        end
      end

      context "when the tenant is male" do
        it "does not show the interruption screen" do
          record.update!(age1: 85, sex1: "M", ecstat1: 10)
          expect(record.person_1_not_retired_over_soft_max_age?).to be false
        end
      end

      context "when the tenant is non-binary" do
        it "does not show the interruption screen" do
          record.update!(age1: 85, sex1: "X", ecstat1: 10)
          expect(record.person_1_not_retired_over_soft_max_age?).to be false
        end
      end
    end
  end
end
