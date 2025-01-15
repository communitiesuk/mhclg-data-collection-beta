require "rails_helper"
require "shared/shared_examples_for_derived_fields"

RSpec.describe LettingsLog, type: :model do
  let(:organisation) { build(:organisation, name: "derived fields org") }
  let(:user) { build(:user, organisation:) }
  let(:log) { build(:lettings_log, :startdate_today, assigned_to: user) }

  include_examples "shared examples for derived fields", :lettings_log

  it "correctly derives incref from net_income_known" do
    log.net_income_known = 0
    expect { log.set_derived_fields! }.to change(log, :incref).to 0

    log.net_income_known = 1
    expect { log.set_derived_fields! }.to change(log, :incref).to 2

    log.net_income_known = 2
    expect { log.set_derived_fields! }.to change(log, :incref).to 1
  end

  it "derives shortfall_known when tshortfall is set" do
    log.tshortfall = 10

    expect { log.set_derived_fields! }.to change(log, :tshortfall_known).to 0
  end

  describe "deriving has_benefits" do
    it "correctly derives when the household receives benefits" do
      benefits_codes = [1, 6, 8, 7]
      log.hb = benefits_codes.sample

      log.set_derived_fields!

      expect(log.has_benefits).to be 1
    end

    it "correctly derives when the household does not receive benefits" do
      no_benefits_codes = [9, 3, 10, 4]
      log.hb = no_benefits_codes.sample

      log.set_derived_fields!

      expect(log.has_benefits).to be 0
    end
  end

  describe "deriving vacant days" do
    it "correctly derives vacdays from startdate and mrcdate across DST boundaries" do
      log.startdate = Time.zone.local(2024, 4, 1)
      log.mrcdate = Time.zone.local(2024, 3, 30)

      log.set_derived_fields!

      expect(log.vacdays).to be 2
    end

    it "correctly derives vacdays from startdate and voiddate across DST boundaries" do
      log.startdate = Time.zone.local(2024, 4, 1)
      log.mrcdate = nil
      log.voiddate = Time.zone.local(2024, 3, 30)

      log.set_derived_fields!

      expect(log.vacdays).to be 2
    end

    it "correctly derives vacdays from startdate and mrcdate" do
      day_count = 8
      log.startdate = Time.zone.today
      log.mrcdate = Time.zone.today - day_count.days

      log.set_derived_fields!

      expect(log.vacdays).to be day_count
    end

    it "correctly derives vacdays from startdate and voiddate if mrcdate is nil" do
      day_count = 3
      log.startdate = Time.zone.today
      log.voiddate = Time.zone.today - day_count.days
      log.mrcdate = nil

      log.set_derived_fields!

      expect(log.vacdays).to be day_count
    end

    it "does not derive vacdays if voiddate and mrcdate are blank" do
      log.startdate = Time.zone.today
      log.voiddate = nil
      log.mrcdate = nil

      log.set_derived_fields!

      expect(log.vacdays).to be nil
    end

    it "does not derive vacdays if startdate is blank" do
      log.startdate = nil
      log.voiddate = Time.zone.today
      log.mrcdate = Time.zone.today

      log.set_derived_fields!

      expect(log.vacdays).to be nil
    end
  end

  describe "deriving household member fields" do
    before do
      log.assign_attributes(
        relat2: "X",
        relat3: "C",
        relat4: "X",
        relat5: "C",
        relat7: "C",
        relat8: "X",
        age1: 22,
        age2: 16,
        age4: 60,
        age6: 88,
        age7: 14,
        age8: 42,
      )

      log.set_derived_fields!
    end

    it "correctly derives totchild" do
      expect(log.totchild).to eq 3
    end

    it "correctly derives totelder" do
      expect(log.totelder).to eq 2
    end

    it "correctly derives totadult" do
      expect(log.totadult).to eq 3
    end

    it "correctly derives economic status for tenants under 16" do
      expect(log.ecstat7).to eq 9
    end
  end

  describe "deriving lettype" do
    context "when the owning organisation is a PRP" do
      before do
        log.owning_organisation.provider_type = "PRP"
      end

      [
        {
          context: "when the rent type is intermediate rent and supported housing",
          rent_type: 4,
          needstype: 2,
          expected_lettype: 10,
        },
        {
          context: "when the rent type is intermediate rent and general needs housing",
          rent_type: 4,
          needstype: 1,
          expected_lettype: 9,
        },
        {
          context: "when the rent type is affordable rent and supported housing",
          rent_type: 2,
          needstype: 2,
          expected_lettype: 6,
        },
        {
          context: "when the rent type is affordable rent and general needs housing",
          rent_type: 2,
          needstype: 1,
          expected_lettype: 5,
        },
        {
          context: "when the rent type is social rent and supported housing",
          rent_type: 0,
          needstype: 2,
          expected_lettype: 2,
        },
        {
          context: "when the rent type is social rent and general needs housing",
          rent_type: 0,
          needstype: 1,
          expected_lettype: 1,
        },
        {
          context: "when the rent type is Specified accommodation and supported housing",
          rent_type: 6,
          needstype: 2,
          expected_lettype: 14,
        },
        {
          context: "when the rent type is Specified accommodation and general needs housing",
          rent_type: 6,
          needstype: 1,
          expected_lettype: 13,
        },
      ].each do |test_case|
        context test_case[:context] do
          it "correctly derives lettype" do
            log.assign_attributes(
              rent_type: test_case[:rent_type],
              needstype: test_case[:needstype],
            )
            expect { log.set_derived_fields! }.to change(log, :lettype).to test_case[:expected_lettype]
          end
        end
      end
    end

    context "when the owning organisation is an LA" do
      before do
        log.owning_organisation.provider_type = "LA"
      end

      [
        {
          context: "when the rent type is intermediate rent and supported housing",
          rent_type: 4,
          needstype: 2,
          expected_lettype: 12,
        },
        {
          context: "when the rent type is intermediate rent and general needs housing",
          rent_type: 4,
          needstype: 1,
          expected_lettype: 11,
        },
        {
          context: "when the rent type is affordable rent and supported housing",
          rent_type: 2,
          needstype: 2,
          expected_lettype: 8,
        },
        {
          context: "when the rent type is affordable rent and general needs housing",
          rent_type: 2,
          needstype: 1,
          expected_lettype: 7,
        },
        {
          context: "when the rent type is social rent and supported housing",
          rent_type: 0,
          needstype: 2,
          expected_lettype: 4,
        },
        {
          context: "when the rent type is social rent and general needs housing",
          rent_type: 0,
          needstype: 1,
          expected_lettype: 3,
        },
      ].each do |test_case|
        context test_case[:context] do
          it "correctly derives lettype" do
            log.assign_attributes(
              rent_type: test_case[:rent_type],
              needstype: test_case[:needstype],
            )
            expect { log.set_derived_fields! }.to change(log, :lettype).to test_case[:expected_lettype]
          end
        end
      end
    end
  end

  describe "deriving newprop" do
    it "updates newprop correctly when this is the first time the property has been let" do
      first_time_let_codes = [15, 16, 17]
      log.rsnvac = first_time_let_codes.sample

      log.set_derived_fields!

      expect(log.newprop).to eq 1
    end

    it "updates newprop correctly when this is not the first time the property has been let" do
      not_first_time_let_codes = [14, 9, 13, 12, 8, 18, 20, 5, 19, 6, 10, 11, 21, 22]
      log.rsnvac = not_first_time_let_codes.sample

      log.set_derived_fields!

      expect(log.newprop).to eq 2
    end
  end

  describe "deriving charges based on rent period" do
    context "when rent is paid bi-weekly" do
      before do
        log.period = 2
      end

      [
        {
          test_title: "correctly derives weekly rent",
          fields_to_set: { brent: 100 },
          expected_values: { wrent: 50.0 },
        },
        {
          test_title: "correctly derives weekly service charge",
          fields_to_set: { scharge: 70 },
          expected_values: { wscharge: 35.0 },
        },
        {
          test_title: "correctly derives weekly personal service charge",
          fields_to_set: { pscharge: 60 },
          expected_values: { wpschrge: 30.0 },
        },
        {
          test_title: "correctly derives weekly support charge",
          fields_to_set: { supcharg: 80 },
          expected_values: { wsupchrg: 40.0 },
        },
        {
          test_title: "correctly derives weekly total shortfall",
          fields_to_set: { hbrentshortfall: 1, tshortfall: 100, hb: 6 },
          expected_values: { wtshortfall: 50.0 },
        },
        {
          test_title: "correctly clears weekly total shortfall if the tenant does not receive applicable benefits",
          fields_to_set: { hbrentshortfall: 1, tshortfall: 100, hb: 9 },
          expected_values: { wtshortfall: nil },
        },
        {
          test_title: "correctly derives floats and weekly total charge",
          fields_to_set: { supcharg: 60.12, pscharge: 50.13, scharge: 60.98, brent: 60.97 },
          expected_values: { wsupchrg: 30.06, wpschrge: 25.06, wscharge: 30.49, wrent: 30.49, wtcharge: 116.1 },
        },
        {
          test_title: "correctly derives weekly care home charge when the letting is supported housing",
          fields_to_set: { needstype: 2, chcharge: 57.86 },
          expected_values: { wchchrg: 28.93 },
        },
      ].each do |test_case|
        it test_case[:test_title] do
          log.assign_attributes(test_case[:fields_to_set])
          log.set_derived_fields!
          test_case[:expected_values].each do |field, expected_value|
            expect(log[field]).to eq expected_value
          end
        end
      end
    end

    context "when rent is paid every 4 weeks" do
      before do
        log.period = 3
      end

      [
        {
          test_title: "correctly derives weekly rent",
          fields_to_set: { brent: 120 },
          expected_values: { wrent: 30.0 },
        },
        {
          test_title: "correctly derives weekly service charge",
          fields_to_set: { scharge: 120 },
          expected_values: { wscharge: 30.0 },
        },
        {
          test_title: "correctly derives weekly personal service charge",
          fields_to_set: { pscharge: 120 },
          expected_values: { wpschrge: 30.0 },
        },
        {
          test_title: "correctly derives weekly support charge",
          fields_to_set: { supcharg: 120 },
          expected_values: { wsupchrg: 30.0 },
        },
        {
          test_title: "correctly derives weekly total shortfall",
          fields_to_set: { hbrentshortfall: 1, tshortfall: 120, hb: 6 },
          expected_values: { wtshortfall: 30.0 },
        },
        {
          test_title: "correctly clears weekly total shortfall if the tenant does not receive applicable benefits",
          fields_to_set: { hbrentshortfall: 1, tshortfall: 100, hb: 9 },
          expected_values: { wtshortfall: nil },
        },
        {
          test_title: "correctly derives floats and weekly total charge",
          fields_to_set: { supcharg: 100.12, pscharge: 100.13, scharge: 100.98, brent: 100.97 },
          expected_values: { wsupchrg: 25.03, wpschrge: 25.03, wscharge: 25.24, wrent: 25.24, wtcharge: 100.55 },
        },
        {
          test_title: "correctly derives weekly care home charge when the letting is supported housing",
          fields_to_set: { needstype: 2, chcharge: 57.86 },
          expected_values: { wchchrg: 14.46 },
        },
      ].each do |test_case|
        it test_case[:test_title] do
          log.assign_attributes(test_case[:fields_to_set])
          log.set_derived_fields!
          test_case[:expected_values].each do |field, expected_value|
            expect(log[field]).to eq expected_value
          end
        end
      end
    end

    context "when rent is paid every calendar month" do
      before do
        log.period = 4
      end

      [
        {
          test_title: "correctly derives weekly rent",
          fields_to_set: { brent: 130 },
          expected_values: { wrent: 30.0 },
        },
        {
          test_title: "correctly derives weekly service charge",
          fields_to_set: { scharge: 130 },
          expected_values: { wscharge: 30.0 },
        },
        {
          test_title: "correctly derives weekly personal service charge",
          fields_to_set: { pscharge: 130 },
          expected_values: { wpschrge: 30.0 },
        },
        {
          test_title: "correctly derives weekly support charge",
          fields_to_set: { supcharg: 130 },
          expected_values: { wsupchrg: 30.0 },
        },
        {
          test_title: "correctly derives weekly total shortfall",
          fields_to_set: { hbrentshortfall: 1, tshortfall: 130, hb: 6 },
          expected_values: { wtshortfall: 30.0 },
        },
        {
          test_title: "correctly clears weekly total shortfall if the tenant does not receive applicable benefits",
          fields_to_set: { hbrentshortfall: 1, tshortfall: 100, hb: 9 },
          expected_values: { wtshortfall: nil },
        },
        {
          test_title: "correctly derives floats and weekly total charge",
          fields_to_set: { supcharg: 100.12, pscharge: 100.13, scharge: 100.98, brent: 100.97 },
          expected_values: { wsupchrg: 23.10, wpschrge: 23.11, wscharge: 23.30, wrent: 23.30, wtcharge: 92.82 },
        },
        {
          test_title: "correctly derives weekly care home charge when the letting is supported housing",
          fields_to_set: { needstype: 2, chcharge: 57.86 },
          expected_values: { wchchrg: 13.35 },
        },
      ].each do |test_case|
        it test_case[:test_title] do
          log.assign_attributes(test_case[:fields_to_set])
          log.set_derived_fields!
          test_case[:expected_values].each do |field, expected_value|
            expect(log[field]).to eq expected_value
          end
        end
      end
    end

    context "when rent is paid weekly for 50 weeks" do
      before do
        log.period = 5
      end

      [
        {
          test_title: "correctly derives weekly rent",
          fields_to_set: { brent: 130 },
          expected_values: { wrent: 125.0 },
        },
        {
          test_title: "correctly derives weekly service charge",
          fields_to_set: { scharge: 130 },
          expected_values: { wscharge: 125.0 },
        },
        {
          test_title: "correctly derives weekly personal service charge",
          fields_to_set: { pscharge: 130 },
          expected_values: { wpschrge: 125.0 },
        },
        {
          test_title: "correctly derives weekly support charge",
          fields_to_set: { supcharg: 130 },
          expected_values: { wsupchrg: 125.0 },
        },
        {
          test_title: "correctly derives weekly total shortfall",
          fields_to_set: { hbrentshortfall: 1, tshortfall: 130, hb: 6 },
          expected_values: { wtshortfall: 125.0 },
        },
        {
          test_title: "correctly clears weekly total shortfall if the tenant does not receive applicable benefits",
          fields_to_set: { hbrentshortfall: 1, tshortfall: 100, hb: 9 },
          expected_values: { wtshortfall: nil },
        },
        {
          test_title: "correctly derives floats and weekly total charge",
          fields_to_set: { supcharg: 20.12, pscharge: 20.13, scharge: 20.98, brent: 100.97 },
          expected_values: { wsupchrg: 19.35, wpschrge: 19.36, wscharge: 20.17, wrent: 97.09, wtcharge: 155.96 },
        },
        {
          test_title: "correctly derives weekly care home charge when the letting is supported housing",
          fields_to_set: { needstype: 2, chcharge: 57.86 },
          expected_values: { wchchrg: 55.63 },
        },
      ].each do |test_case|
        it test_case[:test_title] do
          log.assign_attributes(test_case[:fields_to_set])
          log.set_derived_fields!
          test_case[:expected_values].each do |field, expected_value|
            expect(log[field]).to eq expected_value
          end
        end
      end
    end

    context "when rent is paid weekly for 49 weeks" do
      before do
        log.period = 6
      end

      [
        {
          test_title: "correctly derives weekly rent",
          fields_to_set: { brent: 130 },
          expected_values: { wrent: 122.5 },
        },
        {
          test_title: "correctly derives weekly service charge",
          fields_to_set: { scharge: 130 },
          expected_values: { wscharge: 122.5 },
        },
        {
          test_title: "correctly derives weekly personal service charge",
          fields_to_set: { pscharge: 130 },
          expected_values: { wpschrge: 122.5 },
        },
        {
          test_title: "correctly derives weekly support charge",
          fields_to_set: { supcharg: 130 },
          expected_values: { wsupchrg: 122.5 },
        },
        {
          test_title: "correctly derives weekly total shortfall",
          fields_to_set: { hbrentshortfall: 1, tshortfall: 130, hb: 6 },
          expected_values: { wtshortfall: 122.5 },
        },
        {
          test_title: "correctly clears weekly total shortfall if the tenant does not receive applicable benefits",
          fields_to_set: { hbrentshortfall: 1, tshortfall: 100, hb: 9 },
          expected_values: { wtshortfall: nil },
        },
        {
          test_title: "correctly derives floats and weekly total charge",
          fields_to_set: { supcharg: 30.12, pscharge: 30.13, scharge: 30.98, brent: 100.97 },
          expected_values: { wsupchrg: 28.38, wpschrge: 28.39, wscharge: 29.19, wrent: 95.14, wtcharge: 181.11 },
        },
        {
          test_title: "correctly derives weekly care home charge when the letting is supported housing",
          fields_to_set: { needstype: 2, chcharge: 57.86 },
          expected_values: { wchchrg: 54.52 },
        },
      ].each do |test_case|
        it test_case[:test_title] do
          log.assign_attributes(test_case[:fields_to_set])
          log.set_derived_fields!
          test_case[:expected_values].each do |field, expected_value|
            expect(log[field]).to eq expected_value
          end
        end
      end
    end

    context "when rent is paid weekly for 48 weeks" do
      before do
        log.period = 7
      end

      [
        {
          test_title: "correctly derives weekly rent",
          fields_to_set: { brent: 130 },
          expected_values: { wrent: 120 },
        },
        {
          test_title: "correctly derives weekly service charge",
          fields_to_set: { scharge: 130 },
          expected_values: { wscharge: 120 },
        },
        {
          test_title: "correctly derives weekly personal service charge",
          fields_to_set: { pscharge: 130 },
          expected_values: { wpschrge: 120 },
        },
        {
          test_title: "correctly derives weekly support charge",
          fields_to_set: { supcharg: 130 },
          expected_values: { wsupchrg: 120 },
        },
        {
          test_title: "correctly derives weekly total shortfall",
          fields_to_set: { hbrentshortfall: 1, tshortfall: 130, hb: 6 },
          expected_values: { wtshortfall: 120 },
        },
        {
          test_title: "correctly clears weekly total shortfall if the tenant does not receive applicable benefits",
          fields_to_set: { hbrentshortfall: 1, tshortfall: 100, hb: 9 },
          expected_values: { wtshortfall: nil },
        },
        {
          test_title: "correctly derives floats and weekly total charge",
          fields_to_set: { supcharg: 30.12, pscharge: 30.13, scharge: 30.98, brent: 100.97 },
          expected_values: { wsupchrg: 27.8, wpschrge: 27.81, wscharge: 28.6, wrent: 93.20, wtcharge: 177.42 },
        },
        {
          test_title: "correctly derives weekly care home charge when the letting is supported housing",
          fields_to_set: { needstype: 2, chcharge: 57.86 },
          expected_values: { wchchrg: 53.41 },
        },
      ].each do |test_case|
        it test_case[:test_title] do
          log.assign_attributes(test_case[:fields_to_set])
          log.set_derived_fields!
          test_case[:expected_values].each do |field, expected_value|
            expect(log[field]).to eq expected_value
          end
        end
      end
    end

    context "when rent is paid weekly for 47 weeks" do
      before do
        log.period = 8
      end

      [
        {
          test_title: "correctly derives weekly rent",
          fields_to_set: { brent: 130 },
          expected_values: { wrent: 117.5 },
        },
        {
          test_title: "correctly derives weekly service charge",
          fields_to_set: { scharge: 130 },
          expected_values: { wscharge: 117.5 },
        },
        {
          test_title: "correctly derives weekly personal service charge",
          fields_to_set: { pscharge: 130 },
          expected_values: { wpschrge: 117.5 },
        },
        {
          test_title: "correctly derives weekly support charge",
          fields_to_set: { supcharg: 130 },
          expected_values: { wsupchrg: 117.5 },
        },
        {
          test_title: "correctly derives weekly total shortfall",
          fields_to_set: { hbrentshortfall: 1, tshortfall: 130, hb: 6 },
          expected_values: { wtshortfall: 117.5 },
        },
        {
          test_title: "correctly clears weekly total shortfall if the tenant does not receive applicable benefits",
          fields_to_set: { hbrentshortfall: 1, tshortfall: 100, hb: 9 },
          expected_values: { wtshortfall: nil },
        },
        {
          test_title: "correctly derives floats and weekly total charge",
          fields_to_set: { supcharg: 30.12, pscharge: 30.13, scharge: 30.98, brent: 100.97 },
          expected_values: { wsupchrg: 27.22, wpschrge: 27.23, wscharge: 28, wrent: 91.26, wtcharge: 173.72 },
        },
        {
          test_title: "correctly derives weekly care home charge when the letting is supported housing",
          fields_to_set: { needstype: 2, chcharge: 57.86 },
          expected_values: { wchchrg: 52.3 },
        },
      ].each do |test_case|
        it test_case[:test_title] do
          log.assign_attributes(test_case[:fields_to_set])
          log.set_derived_fields!
          test_case[:expected_values].each do |field, expected_value|
            expect(log[field]).to eq expected_value
          end
        end
      end
    end

    context "when rent is paid weekly for 46 weeks" do
      before do
        log.period = 9
      end

      [
        {
          test_title: "correctly derives weekly rent",
          fields_to_set: { brent: 130 },
          expected_values: { wrent: 115 },
        },
        {
          test_title: "correctly derives weekly service charge",
          fields_to_set: { scharge: 130 },
          expected_values: { wscharge: 115 },
        },
        {
          test_title: "correctly derives weekly personal service charge",
          fields_to_set: { pscharge: 130 },
          expected_values: { wpschrge: 115 },
        },
        {
          test_title: "correctly derives weekly support charge",
          fields_to_set: { supcharg: 130 },
          expected_values: { wsupchrg: 115 },
        },
        {
          test_title: "correctly derives weekly total shortfall",
          fields_to_set: { hbrentshortfall: 1, tshortfall: 130, hb: 6 },
          expected_values: { wtshortfall: 115 },
        },
        {
          test_title: "correctly clears weekly total shortfall if the tenant does not receive applicable benefits",
          fields_to_set: { hbrentshortfall: 1, tshortfall: 100, hb: 9 },
          expected_values: { wtshortfall: nil },
        },
        {
          test_title: "correctly derives floats and weekly total charge",
          fields_to_set: { supcharg: 30.12, pscharge: 30.13, scharge: 30.98, brent: 100.97 },
          expected_values: { wsupchrg: 26.64, wpschrge: 26.65, wscharge: 27.41, wrent: 89.32, wtcharge: 170.02 },
        },
        {
          test_title: "correctly derives weekly care home charge when the letting is supported housing",
          fields_to_set: { needstype: 2, chcharge: 57.86 },
          expected_values: { wchchrg: 51.18 },
        },
      ].each do |test_case|
        it test_case[:test_title] do
          log.assign_attributes(test_case[:fields_to_set])
          log.set_derived_fields!
          test_case[:expected_values].each do |field, expected_value|
            expect(log[field]).to eq expected_value
          end
        end
      end
    end

    context "when rent is paid weekly for 52 weeks" do
      before do
        log.period = 1
      end

      [
        {
          test_title: "correctly derives weekly rent",
          fields_to_set: { brent: 130 },
          expected_values: { wrent: 130 },
        },
        {
          test_title: "correctly derives weekly service charge",
          fields_to_set: { scharge: 130 },
          expected_values: { wscharge: 130 },
        },
        {
          test_title: "correctly derives weekly personal service charge",
          fields_to_set: { pscharge: 130 },
          expected_values: { wpschrge: 130 },
        },
        {
          test_title: "correctly derives weekly support charge",
          fields_to_set: { supcharg: 130 },
          expected_values: { wsupchrg: 130 },
        },
        {
          test_title: "correctly derives weekly total shortfall",
          fields_to_set: { hbrentshortfall: 1, tshortfall: 130, hb: 6 },
          expected_values: { wtshortfall: 130 },
        },
        {
          test_title: "correctly clears weekly total shortfall if the tenant does not receive applicable benefits",
          fields_to_set: { hbrentshortfall: 1, tshortfall: 100, hb: 9 },
          expected_values: { wtshortfall: nil },
        },
        {
          test_title: "correctly derives floats and weekly total charge",
          fields_to_set: { supcharg: 30.12, pscharge: 25.13, scharge: 30.98, brent: 100.97 },
          expected_values: { wsupchrg: 30.12, wpschrge: 25.13, wscharge: 30.98, wrent: 100.97, wtcharge: 187.2 },
        },
        {
          test_title: "correctly derives weekly care home charge when the letting is supported housing",
          fields_to_set: { needstype: 2, chcharge: 57.86 },
          expected_values: { wchchrg: 57.86 },
        },
      ].each do |test_case|
        it test_case[:test_title] do
          log.assign_attributes(test_case[:fields_to_set])
          log.set_derived_fields!
          test_case[:expected_values].each do |field, expected_value|
            expect(log[field]).to eq expected_value
          end
        end
      end
    end

    context "when rent is paid weekly for 53 weeks" do
      before do
        log.period = 10
      end

      [
        {
          test_title: "correctly derives weekly rent",
          fields_to_set: { brent: 130 },
          expected_values: { wrent: 132.5 },
        },
        {
          test_title: "correctly derives weekly service charge",
          fields_to_set: { scharge: 130 },
          expected_values: { wscharge: 132.5 },
        },
        {
          test_title: "correctly derives weekly personal service charge",
          fields_to_set: { pscharge: 130 },
          expected_values: { wpschrge: 132.5 },
        },
        {
          test_title: "correctly derives weekly support charge",
          fields_to_set: { supcharg: 130 },
          expected_values: { wsupchrg: 132.5 },
        },
        {
          test_title: "correctly derives weekly total shortfall",
          fields_to_set: { hbrentshortfall: 1, tshortfall: 130, hb: 6 },
          expected_values: { wtshortfall: 132.5 },
        },
        {
          test_title: "correctly clears weekly total shortfall if the tenant does not receive applicable benefits",
          fields_to_set: { hbrentshortfall: 1, tshortfall: 100, hb: 9 },
          expected_values: { wtshortfall: nil },
        },
        {
          test_title: "correctly derives floats and weekly total charge",
          fields_to_set: { supcharg: 30.12, pscharge: 25.13, scharge: 30.98, brent: 100.97 },
          expected_values: { wsupchrg: 30.7, wpschrge: 25.61, wscharge: 31.58, wrent: 102.91, wtcharge: 190.8 },
        },
        {
          test_title: "correctly derives weekly care home charge when the letting is supported housing",
          fields_to_set: { needstype: 2, chcharge: 57.86 },
          expected_values: { wchchrg: 58.97 },
        },
      ].each do |test_case|
        it test_case[:test_title] do
          log.assign_attributes(test_case[:fields_to_set])
          log.set_derived_fields!
          test_case[:expected_values].each do |field, expected_value|
            expect(log[field]).to eq expected_value
          end
        end
      end
    end
  end

  describe "deriving charges" do
    describe "deriving the total charge" do
      it "sums all the charges" do
        brent = 5.77
        scharge = 10.01
        pscharge = 3
        supcharg = 12.2
        log.assign_attributes(brent:, scharge:, pscharge:, supcharg:)

        log.set_derived_fields!

        expect(log.tcharge).to eq(brent + scharge + pscharge + supcharg)
      end

      it "takes nil values to be zero" do
        brent = 5.77
        scharge = nil
        pscharge = nil
        supcharg = 12.2
        log.assign_attributes(brent:, scharge:, pscharge:, supcharg:)

        log.set_derived_fields!

        expect(log.tcharge).to eq(brent + supcharg)
      end
    end

    it "when any charge field is set all blank charge fields are set to 0, non-blank fields are left the same" do
      log.set_derived_fields!
      %i[brent scharge pscharge supcharg].each do |field|
        expect(log[field]).to be nil
      end

      brent_val = 111
      log.brent = brent_val
      log.set_derived_fields!
      %i[scharge pscharge supcharg].each do |field|
        expect(log[field]).to eq 0
      end

      log.scharge = 22
      log.set_derived_fields!
      expect(log.brent).to eq brent_val
    end
  end

  describe "deriving refused" do
    it "derives refused when any age field is refused or details field is unknown" do
      age_and_details_fields = %i[age1_known age2_known age3_known age4_known age5_known age6_known age7_known age8_known details_known_2 details_known_3 details_known_4 details_known_5 details_known_6 details_known_7 details_known_8]

      log[age_and_details_fields.sample] = 1
      log.set_derived_fields!

      expect(log.refused).to eq 1
    end

    it "derives refused when any sex or relationship field is refused" do
      age_fields = %i[sex1 sex2 sex3 sex4 sex5 sex6 sex7 sex8 relat2 relat3 relat4 relat5 relat6 relat7 relat8]

      log[age_fields.sample] = "R"
      log.set_derived_fields!

      expect(log.refused).to eq 1
    end

    it "derives refused when any economic status field is refused" do
      economic_status_fields = %i[ecstat1 ecstat2 ecstat3 ecstat4 ecstat5 ecstat6 ecstat7 ecstat8]

      log[economic_status_fields.sample] = 10
      log.set_derived_fields!

      expect(log.refused).to eq 1
    end
  end

  describe "deriving renttype from rent_type" do
    it "when rent_type is Social Rent derives renttype as Social Rent" do
      log.rent_type = 0
      expect { log.set_derived_fields! }.to change(log, :renttype).to 1
    end

    it "when rent_type is Affordable Rent derives renttype as Affordable Rent" do
      log.rent_type = 1
      expect { log.set_derived_fields! }.to change(log, :renttype).to 2
    end

    it "when rent_type is London Affordable Rent derives renttype as Affordable Rent" do
      log.rent_type = 2
      expect { log.set_derived_fields! }.to change(log, :renttype).to 2
    end

    it "when rent_type is Rent to Buy derives renttype as Intermediate Rent" do
      log.rent_type = 3
      expect { log.set_derived_fields! }.to change(log, :renttype).to 3
    end

    it "when rent_type is London Living Rent derives renttype as Intermediate Rent" do
      log.rent_type = 4
      expect { log.set_derived_fields! }.to change(log, :renttype).to 3
    end

    it "when rent_type is Other intermediate rent product derives renttype as Intermediate Rent" do
      log.rent_type = 5
      expect { log.set_derived_fields! }.to change(log, :renttype).to 3
    end

    it "when rent_type is Specified accommodation derives renttype as Specified accommodation" do
      log.rent_type = 6
      expect { log.set_derived_fields! }.to change(log, :renttype).to 4
    end
  end

  describe "variables dependent on whether a letting is a renewal" do
    let(:organisation) { create(:organisation) }
    let(:user) { create(:user, organisation:) }
    let(:startdate) { Time.zone.today }
    let(:persisted_renewal_lettings_log) { create(:lettings_log, :setup_completed, startdate:, renewal: 1, assigned_to: user) }

    it "derives waityear offered referral first_time_property_let_as_social_housing rsnvac when renewal" do
      log.renewal = 1
      expect { log.set_derived_fields! }
        .to change(log, :waityear).to(2)
        .and change(log, :offered).to(0)
        .and change(log, :referral).to(1)
        .and change(log, :first_time_property_let_as_social_housing).to(0)
        .and change(log, :rsnvac).to(14)
    end

    it "clears waityear offered referral first_time_property_let_as_social_housing rsnvac when not a renewal" do
      expect { persisted_renewal_lettings_log.update!(renewal: 0) }
        .to change(persisted_renewal_lettings_log, :waityear).from(2).to(nil)
        .and change(persisted_renewal_lettings_log, :offered).from(0).to(nil)
        .and change(persisted_renewal_lettings_log, :referral).from(1).to(nil)
        .and change(persisted_renewal_lettings_log, :first_time_property_let_as_social_housing).from(0).to(nil)
        .and change(persisted_renewal_lettings_log, :rsnvac).from(14).to(nil)
    end

    describe "deriving voiddate from startdate" do
      let(:startdate) { Time.zone.now.beginning_of_day }

      it "correctly derives voiddate if the letting is a renewal" do
        log.assign_attributes(renewal: 1, startdate:)

        expect { log.set_derived_fields! }.to change(log, :voiddate).to startdate
      end

      it "clears voiddate if the letting is no longer a renewal" do
        expect { persisted_renewal_lettings_log.update!(renewal: 0) }.to change(persisted_renewal_lettings_log, :voiddate).from(startdate).to nil
      end
    end

    it "derives values for local authority and previous location if postcode is set and log is a renewal" do
      expected_la = "E09000033"
      postcode = "SW1A 1AA"
      log.assign_attributes(postcode_known: 1, postcode_full: postcode, renewal: 1)

      expect { log.send :process_postcode_changes! }.to change(log, :la).to(expected_la)
      expect { log.set_derived_fields! }
        .to change(log, :ppostcode_full).to(postcode)
        .and change(log, :ppcodenk).to(0)
        .and change(log, :prevloc).to(expected_la)
    end

    it "clears values for previous location and related fields when log is a renewal and current values are cleared" do
      log.assign_attributes(postcode_known: 0, postcode_full: nil, la: nil, renewal: 1, previous_la_known: 1, prevloc: "E09000033", ppostcode_full: "SW1A 1AA", ppcodenk: 0)

      expect { log.set_derived_fields! }
        .to change(log, :previous_la_known).to(nil)
        .and change(log, :prevloc).to(nil)
        .and change(log, :ppcodenk).to(1)
        .and change(log, :ppostcode_full).to(nil)
    end

    context "when the log is general needs" do
      context "and the managing organisation is a private registered provider" do
        before do
          log.managing_organisation.provider_type = "PRP"
          log.renewal = 1
        end

        it "correctly derives prevten" do
          log.needstype = 1
          log.set_derived_fields!

          expect(log.prevten).to be 32
        end

        it "clears prevten if the log is marked as supported housing" do
          log.needstype = 2
          log.set_derived_fields!

          expect(log.prevten).to be nil
        end

        it "clears prevten if renewal is update to no" do
          log.renewal = 0
          log.set_derived_fields!

          expect(log.prevten).to be nil
        end
      end

      context "and the managing organisation is a local authority" do
        before do
          log.managing_organisation.provider_type = "LA"
          log.renewal = 1
        end

        it "correctly derives prevten if the log is general needs" do
          log.needstype = 1
          log.set_derived_fields!

          expect(log.prevten).to be 30
        end

        it "clears prevten if the log is marked as supported housing" do
          log.needstype = 2
          log.set_derived_fields!

          expect(log.prevten).to be nil
        end

        it "clears prevten if renewal is update to no" do
          log.renewal = 0
          log.set_derived_fields!

          expect(log.prevten).to be nil
        end
      end
    end

    context "and updating rent_type" do
      let(:irproduct_other) { nil }
      let(:persisted_renewal_lettings_log) { create(:lettings_log, :setup_completed, assigned_to: user, rent_type:, irproduct_other:, renewal: 1) }

      context "when rent_type is Social Rent" do
        let(:rent_type) { 0 }
        let(:expected_unitletas) { 1 }

        it "derives the most recent let type as Social Rent basis if it is a renewal" do
          log.assign_attributes(renewal: 1, rent_type:)

          expect { log.set_derived_fields! }.to change(log, :unitletas).to expected_unitletas
        end

        it "clears the most recent let type if it is not a renewal" do
          expect { persisted_renewal_lettings_log.update!(renewal: 0) }.to change(persisted_renewal_lettings_log, :unitletas).from(expected_unitletas).to nil
        end
      end

      context "when rent_type is Affordable Rent" do
        let(:rent_type) { 1 }
        let(:expected_unitletas) { 2 }

        it "derives the most recent let type as Affordable Rent basis if it is a renewal" do
          log.assign_attributes(renewal: 1, rent_type:)

          expect { log.set_derived_fields! }.to change(log, :unitletas).to expected_unitletas
        end

        it "clears the most recent let type if it is not a renewal" do
          expect { persisted_renewal_lettings_log.update!(renewal: 0) }.to change(persisted_renewal_lettings_log, :unitletas).from(expected_unitletas).to nil
        end
      end

      context "when rent_type is London Affordable Rent" do
        let(:rent_type) { 2 }
        let(:expected_unitletas) { 5 }

        it "derives the most recent let type as London Affordable Rent basis if it is a renewal" do
          log.assign_attributes(renewal: 1, rent_type:)

          expect { log.set_derived_fields! }.to change(log, :unitletas).to expected_unitletas
        end

        it "clears the most recent let type if it is not a renewal" do
          expect { persisted_renewal_lettings_log.update!(renewal: 0) }.to change(persisted_renewal_lettings_log, :unitletas).from(expected_unitletas).to nil
        end
      end

      context "when rent_type is Rent to Buy" do
        let(:rent_type) { 3 }
        let(:expected_unitletas) { 6 }

        it "derives the most recent let type as Rent to Buy basis if it is a renewal" do
          log.assign_attributes(renewal: 1, rent_type:)

          expect { log.set_derived_fields! }.to change(log, :unitletas).to expected_unitletas
        end

        it "clears the most recent let type if it is not a renewal" do
          expect { persisted_renewal_lettings_log.update!(renewal: 0) }.to change(persisted_renewal_lettings_log, :unitletas).from(expected_unitletas).to nil
        end
      end

      context "when rent_type is London Living Rent" do
        let(:rent_type) { 4 }
        let(:expected_unitletas) { 7 }

        it "derives the most recent let type as London Living Rent basis if it is a renewal" do
          log.assign_attributes(renewal: 1, rent_type:)

          expect { log.set_derived_fields! }.to change(log, :unitletas).to expected_unitletas
        end

        it "clears the most recent let type if it is not a renewal" do
          expect { persisted_renewal_lettings_log.update!(renewal: 0) }.to change(persisted_renewal_lettings_log, :unitletas).from(expected_unitletas).to nil
        end
      end

      context "when rent_type is Other intermediate rent product" do
        let(:rent_type) { 5 }
        let(:irproduct_other) { "Rent first" }
        let(:expected_unitletas) { 8 }

        it "derives the most recent let type as London Living Rent basis if it is a renewal" do
          log.assign_attributes(renewal: 1, rent_type:, irproduct_other:)

          expect { log.set_derived_fields! }.to change(log, :unitletas).to expected_unitletas
        end

        it "clears the most recent let type if it is not a renewal" do
          expect { persisted_renewal_lettings_log.update!(renewal: 0) }.to change(persisted_renewal_lettings_log, :unitletas).from(expected_unitletas).to nil
        end
      end

      context "when rent_type is Specified accommodation " do
        let(:rent_type) { 6 }
        let(:expected_unitletas) { 9 }

        before do
          Timecop.freeze(Time.zone.local(2025, 5, 5))
        end

        it "derives the most recent let type as London Living Rent basis if it is a renewal" do
          log.assign_attributes(renewal: 1, rent_type:)

          expect { log.set_derived_fields! }.to change(log, :unitletas).to expected_unitletas
        end

        it "clears the most recent let type if it is not a renewal" do
          expect { persisted_renewal_lettings_log.update!(renewal: 0) }.to change(persisted_renewal_lettings_log, :unitletas).from(expected_unitletas).to nil
        end
      end
    end
  end
end
