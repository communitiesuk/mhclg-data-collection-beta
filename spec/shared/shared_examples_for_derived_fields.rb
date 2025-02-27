require "rails_helper"

RSpec.shared_examples "shared examples for derived fields" do |log_type|
  describe "sets ethnic based on the value of ethnic_refused" do
    it "is set to 17 when ethnic_group is 17" do
      log = FactoryBot.build(log_type, ethnic_group: 17, ethnic: nil)

      expect { log.set_derived_fields! }.to change(log, :ethnic).from(nil).to(17)
    end

    it "is is not modified otherwise" do
      log = FactoryBot.build(log_type, ethnic_group: nil, ethnic: nil)

      expect { log.set_derived_fields! }.not_to change(log, :ethnic)
    end
  end

  context "when uprn is not confirmed" do
    it "derives other uprn fields correctly" do
      log = FactoryBot.build(log_type, uprn_known: 1, uprn: 1, uprn_confirmed: 0)

      expect { log.set_derived_fields! }.to change(log, :uprn_known).from(1).to(0)
                                        .and change(log, :uprn).from("1").to(nil)
                                        .and change(log, :uprn_confirmed).from(0).to(nil)
    end

    it "does not affect older logs with uprn_confirmed == 0" do
      Timecop.freeze(Time.zone.local(2023, 4, 1)) do
        log = FactoryBot.build(log_type, uprn_known: 0, uprn: nil, uprn_confirmed: 0)
        allow(log.form).to receive(:start_year_2024_or_later?).and_return(false)
        expect { log.set_derived_fields! }.to not_change(log, :uprn_known)
                                          .and not_change(log, :uprn)
                                          .and not_change(log, :uprn_confirmed)
      end
      Timecop.return
    end
  end
end
