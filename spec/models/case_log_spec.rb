require "rails_helper"
require_relative "../request_helper"

RSpec.describe Form, type: :model do
  let(:owning_organisation) { FactoryBot.create(:organisation) }
  let(:managing_organisation) { owning_organisation }
  before do
    RequestHelper.stub_http_requests
  end

  describe "#form" do
    let(:case_log) { FactoryBot.build(:case_log) }
    let(:case_log_2) { FactoryBot.build(:case_log, startdate: Time.zone.local(2022, 1, 1)) }
    let(:case_log_year_2) { FactoryBot.build(:case_log, startdate: Time.zone.local(2023, 5, 1)) }
    it "has returns the correct form based on the start date" do
      expect(case_log.form_name).to eq("2021_2022")
      expect(case_log_2.form_name).to eq("2021_2022")
      expect(case_log_year_2.form_name).to eq("2023_2024")
      expect(case_log.form).to be_a(Form)
    end
  end

  describe "#new" do
    it "validates age is a number" do
      expect {
        CaseLog.create!(
          age1: "random",
          owning_organisation: owning_organisation,
          managing_organisation: managing_organisation,
        )
      }.to raise_error(ActiveRecord::RecordInvalid)
      expect {
        CaseLog.create!(
          age3: "random",
          owning_organisation: owning_organisation,
          managing_organisation: managing_organisation,
        )
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "validates age is under 120" do
      expect {
        CaseLog.create!(
          age1: 121,
          owning_organisation: owning_organisation,
          managing_organisation: managing_organisation,
        )
      }.to raise_error(ActiveRecord::RecordInvalid)
      expect {
        CaseLog.create!(
          age3: 121,
          owning_organisation: owning_organisation,
          managing_organisation: managing_organisation,
        )
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "validates age is over 0" do
      expect {
        CaseLog.create!(
          age1: 0,
          owning_organisation: owning_organisation,
          managing_organisation: managing_organisation,
        )
      }.to raise_error(ActiveRecord::RecordInvalid)
      expect {
        CaseLog.create!(
          age3: 0,
          owning_organisation: owning_organisation,
          managing_organisation: managing_organisation,
        )
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    context "reasonable preference is yes" do
      it "validates that previously homeless should be selected" do
        expect {
          CaseLog.create!(
            homeless: "No",
            reasonpref: "Yes",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "reasonable preference is no" do
      it "validates no reason is needed" do
        expect {
          CaseLog.create!(
            reasonpref: "No",
            rp_homeless: "No",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.not_to raise_error
      end

      it "validates that no reason has been provided" do
        expect {
          CaseLog.create!(
            reasonpref: "No",
            rp_medwel: "Yes",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "reason for leaving last settled home validation" do
      it "Reason for leaving must be don’t know if reason for leaving settled home (Q9a) is don’t know." do
        expect {
          CaseLog.create!(reason: "Don’t know",
                          underoccupation_benefitcap: "Yes - benefit cap",
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
    context "other reason for leaving last settled home validation" do
      it "must be provided if main reason for leaving last settled home was given as other" do
        expect {
          CaseLog.create!(reason: "Other",
                          other_reason_for_leaving_last_settled_home: nil,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "must not be provided if the main reason for leaving settled home is not other" do
        expect {
          CaseLog.create!(reason: "Repossession",
                          other_reason_for_leaving_last_settled_home: "the other reason provided",
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "armed forces injured validation" do
      it "must not be answered if tenant was not a regular or reserve in armed forces" do
        expect {
          CaseLog.create!(armedforces: "No",
                          reservist: "Yes",
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "Validate pregnancy questions" do
      it "Cannot answer yes if no female tenants" do
        expect {
          CaseLog.create!(preg_occ: "Yes",
                          sex1: "Male",
                          age1: 20,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "Cannot answer yes if no female tenants within age range" do
        expect {
          CaseLog.create!(preg_occ: "Yes",
                          sex1: "Female",
                          age1: 51,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "Cannot answer prefer not to say if no valid tenants" do
        expect {
          CaseLog.create!(preg_occ: "Prefer not to say",
                          sex1: "Male",
                          age1: 20,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "Can answer yes if valid tenants" do
        expect {
          CaseLog.create!(preg_occ: "Yes",
                          sex1: "Female",
                          age1: 20,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.not_to raise_error
      end

      it "Can answer yes if valid second tenant" do
        expect {
          CaseLog.create!(preg_occ: "Yes",
                          sex1: "Male", age1: 99,
                          sex2: "Female",
                          age2: 20,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.not_to raise_error
      end
    end

    context "Property vacancy and let as validations" do
      it "cannot have a previously let as type, if it hasn't been let before" do
        expect {
          CaseLog.create!(
            first_time_property_let_as_social_housing: "No",
            unitletas: "Social rent basis",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.not_to raise_error
        expect {
          CaseLog.create!(
            first_time_property_let_as_social_housing: "Yes",
            unitletas: "Social rent basis",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)
        expect {
          CaseLog.create!(
            first_time_property_let_as_social_housing: "Yes",
            unitletas: "Affordable rent basis",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)
        expect {
          CaseLog.create!(
            first_time_property_let_as_social_housing: "Yes",
            unitletas: "Intermediate rent basis",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)
        expect {
          CaseLog.create!(
            first_time_property_let_as_social_housing: "Yes",
            unitletas: "Don’t know",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "must have a first let reason for vacancy if it's being let as social housing for the first time" do
        expect {
          CaseLog.create!(
            first_time_property_let_as_social_housing: "Yes",
            rsnvac: "First let of new-build property",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.not_to raise_error
        expect {
          CaseLog.create!(
            first_time_property_let_as_social_housing: "Yes",
            rsnvac: "First let of conversion, rehabilitation or acquired property",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.not_to raise_error
        expect {
          CaseLog.create!(
            first_time_property_let_as_social_housing: "Yes",
            rsnvac: "First let of leased property",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.not_to raise_error
        expect {
          CaseLog.create!(
            first_time_property_let_as_social_housing: "Yes",
            rsnvac: "Tenant moved to care home",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "Shared accomodation bedrooms validation" do
      it "you must have more than zero bedrooms" do
        expect {
          CaseLog.create!(unittype_gn: "Shared house",
                          beds: 0,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "you must answer less than 8 bedrooms" do
        expect {
          CaseLog.create!(unittype_gn: "Shared bungalow",
                          beds: 8,
                          other_hhmemb: 1,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "you must answer less than 8 bedrooms" do
        expect {
          CaseLog.create!(unittype_gn: "Shared bungalow",
                          beds: 4,
                          other_hhmemb: 0,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "A bedsit must only have one room" do
        expect {
          CaseLog.create!(unittype_gn: "Bedsit",
                          beds: 2,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "A bedsit must only have one room" do
        expect {
          CaseLog.create!(unittype_gn: "Bedsit",
                          beds: 0,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "outstanding rent or charges validation" do
      it "must be not be anwered if answered no to outstanding rent or charges" do
        expect {
          CaseLog.create!(hbrentshortfall: "No",
                          tshortfall: 99,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "tenant’s income is from Universal Credit, state pensions or benefits" do
      it "Cannot be All if person 1 works full time" do
        expect {
          CaseLog.create!(
            benefits: "All",
            ecstat1: "Full-time - 30 hours or more",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "Cannot be All if person 1 works part time" do
        expect {
          CaseLog.create!(
            benefits: "All",
            ecstat1: "Part-time - Less than 30 hours",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "Cannot be 1 All if any of persons 2-4 are person 1's partner and work part or full time" do
        expect {
          CaseLog.create!(
            benefits: "All",
            relat2: "Partner",
            ecstat2: "Part-time - Less than 30 hours",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "fixed term tenancy length" do
      it "Must not be completed if Type of main tenancy is not responded with either Secure or Assured shorthold " do
        expect {
          CaseLog.create!(tenancy: "Other",
                          tenancylength: 10,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "Must be completed and between 2 and 99 if type of tenancy is Assured shorthold" do
        expect {
          CaseLog.create!(tenancy: "Assured Shorthold",
                          tenancylength: 1,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect {
          CaseLog.create!(tenancy: "Assured Shorthold",
                          tenancylength: nil,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect {
          CaseLog.create!(tenancy: "Assured Shorthold",
                          tenancylength: 2,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.not_to raise_error
      end

      it "Must be empty or between 2 and 99 if type of tenancy is Secure" do
        expect {
          CaseLog.create!(tenancy: "Secure (including flexible)",
                          tenancylength: 1,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect {
          CaseLog.create!(tenancy: "Secure (including flexible)",
                          tenancylength: 100,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect {
          CaseLog.create!(tenancy: "Secure (including flexible)",
                          tenancylength: nil,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.not_to raise_error

        expect {
          CaseLog.create!(tenancy: "Secure (including flexible)",
                          tenancylength: 2,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.not_to raise_error
      end
    end

    context "armed forces active validation" do
      it "must not be answered if not ever served as a regular" do
        expect {
          CaseLog.create!(armedforces: "No",
                          leftreg: "Yes",
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      # Crossover over tests here as injured must be answered as well for no error
      it "must be answered if ever served in the forces as a regular" do
        expect do
          CaseLog.create!(armedforces: "A current or former regular in the UK Armed Forces (excluding National Service)",
                          leftreg: "Yes",
                          reservist: "Yes",
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        end
      end
    end

    context "household_member_validations" do
      it "validate that persons aged under 16 must have relationship Child" do
        expect {
          CaseLog.create!(
            age2: 14,
            relat2: "Partner",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "validate that persons aged over 70 must be retired" do
        expect {
          CaseLog.create!(
            age2: 71,
            ecstat2: "Full-time - 30 hours or more",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "validate that a male, retired persons must be over 65" do
        expect {
          CaseLog.create!(
            age2: 64,
            sex2: "Male",
            ecstat2: "Retired",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "validate that a female, retired persons must be over 60" do
        expect {
          CaseLog.create!(
            age2: 59,
            sex2: "Female",
            ecstat2: "Retired",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "validate that persons aged under 16 must be a child (economically speaking)" do
        expect {
          CaseLog.create!(
            age2: 15,
            ecstat2: "Full-time - 30 hours or more",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "validate that persons aged between 16 and 19 that are a child must be a full time student or economic status refused" do
        expect {
          CaseLog.create!(
            age2: 17,
            relat2: "Child - includes young adult and grown-up",
            ecstat2: "Full-time - 30 hours or more",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "validate that persons aged under 16 must be a child relationship" do
        expect {
          CaseLog.create!(
            age2: 15,
            relat2: "Partner",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "validate that no more than 1 partner relationship exists" do
        expect {
          CaseLog.create!(
            relat2: "Partner",
            relat3: "Partner",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "other tenancy type validation" do
      it "must be provided if tenancy type was given as other" do
        expect {
          CaseLog.create!(tenancy: "Other",
                          tenancyother: nil,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect {
          CaseLog.create!(tenancy: "Other",
                          tenancyother: "type",
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.not_to raise_error
      end

      it "must not be provided if tenancy type is not other" do
        expect {
          CaseLog.create!(tenancy: "Secure (including flexible)",
                          tenancyother: "the other reason provided",
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect {
          CaseLog.create!(tenancy: "Secure (including flexible)",
                          tenancyother: nil,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.not_to raise_error
      end
    end

    context "income ranges" do
      it "validates net income maximum" do
        expect {
          CaseLog.create!(
            ecstat1: "Full-time - 30 hours or more",
            earnings: 5000,
            incfreq: "Weekly",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "validates net income minimum" do
        expect {
          CaseLog.create!(
            ecstat1: "Full-time - 30 hours or more",
            earnings: 1,
            incfreq: "Weekly",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      context "given an income in upper soft validation range" do
        let(:case_log) do
          FactoryBot.create(:case_log,
                            ecstat1: "Full-time - 30 hours or more",
                            earnings: 750,
                            incfreq: "Weekly")
        end

        it "updates soft errors" do
          expect(case_log.has_no_unresolved_soft_errors?).to be false
          expect(case_log.soft_errors["override_net_income_validation"].message)
            .to match(I18n.t("soft_validations.net_income.in_soft_max_range.message"))
        end
      end

      context "given an income in lower soft validation range" do
        let(:case_log) do
          FactoryBot.create(:case_log,
                            ecstat1: "Full-time - 30 hours or more",
                            earnings: 120,
                            incfreq: "Weekly")
        end

        it "updates soft errors" do
          expect(case_log.has_no_unresolved_soft_errors?).to be false
          expect(case_log.soft_errors["override_net_income_validation"].message)
            .to match(I18n.t("soft_validations.net_income.in_soft_min_range.message"))
        end
      end
    end

    context "major repairs date" do
      it "cannot be later than the tenancy start date" do
        expect {
          CaseLog.create!(
            mrcdate: Date.new(2021, 10, 10),
            startdate: Date.new(2021, 10, 9),
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect {
          CaseLog.create!(
            mrcdate: Date.new(2021, 10, 9),
            startdate: Date.new(2021, 10, 10),
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.not_to raise_error
      end

      it "must not be completed if reason for vacancy is first let" do
        expect {
          CaseLog.create!(
            mrcdate: Date.new(2020, 10, 10),
            rsnvac: "First let of new-build property",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect {
          CaseLog.create!(
            mrcdate: Date.new(2020, 10, 10),
            rsnvac: "First let of conversion, rehabilitation or acquired property",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect {
          CaseLog.create!(
            mrcdate: Date.new(2020, 10, 10),
            rsnvac: "First let of leased property",
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "must have less than two years between the tenancy start date and major repairs date" do
        expect {
          CaseLog.create!(
            startdate: Date.new(2021, 10, 10),
            mrcdate: Date.new(2017, 10, 10),
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "void date" do
      it "must have less than 10 years between the tenancy start date and void" do
        expect {
          CaseLog.create!(
            startdate: Date.new(2021, 10, 10),
            property_void_date: Date.new(2009, 10, 10),
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect {
          CaseLog.create!(
            startdate: Date.new(2021, 10, 10),
            property_void_date: Date.new(2015, 10, 10),
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.not_to raise_error
      end

      it "must be before the tenancy start date" do
        expect {
          CaseLog.create!(
            startdate: Date.new(2021, 10, 10),
            property_void_date: Date.new(2021, 10, 11),
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect {
          CaseLog.create!(
            startdate: Date.new(2021, 10, 10),
            property_void_date: Date.new(2019, 10, 10),
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.not_to raise_error
      end

      it "must be before major repairs date if major repairs date provided" do
        expect {
          CaseLog.create!(
            startdate: Date.new(2021, 10, 10),
            mrcdate: Date.new(2019, 10, 10),
            property_void_date: Date.new(2019, 11, 11),
            owning_organisation: owning_organisation,
            managing_organisation: managing_organisation,
          )
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "Validate pregnancy questions" do
      it "Cannot answer yes if no female tenants" do
        expect {
          CaseLog.create!(preg_occ: "Yes",
                          sex1: "Male",
                          age1: 20,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "Cannot answer yes if no female tenants within age range" do
        expect {
          CaseLog.create!(preg_occ: "Yes",
                          sex1: "Female",
                          age1: 51,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "Cannot answer prefer not to say if no valid tenants" do
        expect {
          CaseLog.create!(preg_occ: "Prefer not to say",
                          sex1: "Male",
                          age1: 20,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "Can answer yes if valid tenants" do
        expect {
          CaseLog.create!(preg_occ: "Yes",
                          sex1: "Female",
                          age1: 20,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.not_to raise_error
      end

      it "Can answer yes if valid second tenant" do
        expect {
          CaseLog.create!(preg_occ: "Yes",
                          sex1: "Male", age1: 99,
                          sex2: "Female",
                          age2: 20,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.not_to raise_error
      end
    end

    context "Validate type of unit" do
      it "Cannot be bedsit if no of bedrooms is greater than 1" do
        expect {
          CaseLog.create!(unittype_gn: "Bedsit",
                          beds: 2,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect {
          CaseLog.create!(unittype_gn: "Bedsit",
                          beds: 1,
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.not_to raise_error
      end
    end

    context "Validate local authority" do
      it "Has to be london if rent type london affordable rent" do
        expect {
          CaseLog.create!(la: "Ashford",
                          rent_type: "London Affordable rent",
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect {
          CaseLog.create!(la: "Westminster",
                          rent_type: "London Affordable rent",
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.not_to raise_error
      end
    end

    context "For accessibility requirements" do
      it "validates that only one option can be selected" do
        expect {
          CaseLog.create!(housingneeds_a: "Yes",
                          housingneeds_b: "Yes",
                          rent_type: "London Affordable rent",
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "validates that only one option a, b, or c can be selected in conjunction with f" do
        expect {
          CaseLog.create!(housingneeds_a: "Yes",
                          housingneeds_f: "Yes",
                          rent_type: "London Affordable rent",
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to_not raise_error

        expect {
          CaseLog.create!(housingneeds_b: "Yes",
                          housingneeds_f: "Yes",
                          rent_type: "London Affordable rent",
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to_not raise_error

        expect {
          CaseLog.create!(housingneeds_c: "Yes",
                          housingneeds_f: "Yes",
                          rent_type: "London Affordable rent",
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to_not raise_error

        expect {
          CaseLog.create!(housingneeds_g: "Yes",
                          housingneeds_f: "Yes",
                          rent_type: "London Affordable rent",
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect {
          CaseLog.create!(housingneeds_a: "Yes",
                          housingneeds_b: "Yes",
                          housingneeds_f: "Yes",
                          rent_type: "London Affordable rent",
                          owning_organisation: owning_organisation,
                          managing_organisation: managing_organisation)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "status" do
    let!(:empty_case_log) { FactoryBot.create(:case_log) }
    let!(:in_progress_case_log) { FactoryBot.create(:case_log, :in_progress) }
    let!(:completed_case_log) { FactoryBot.create(:case_log, :completed) }

    it "is set to not started for an empty case log" do
      expect(empty_case_log.not_started?).to be(true)
      expect(empty_case_log.in_progress?).to be(false)
      expect(empty_case_log.completed?).to be(false)
    end

    it "is set to in progress for a started case log" do
      expect(in_progress_case_log.in_progress?).to be(true)
      expect(in_progress_case_log.not_started?).to be(false)
      expect(in_progress_case_log.completed?).to be(false)
    end

    it "is set to completed for a completed case log" do
      expect(completed_case_log.in_progress?).to be(false)
      expect(completed_case_log.not_started?).to be(false)
      expect(completed_case_log.completed?).to be(true)
    end
  end

  describe "weekly_net_income" do
    let(:net_income) { 5000 }
    let(:case_log) { FactoryBot.build(:case_log, earnings: net_income) }

    it "returns input income if frequency is already weekly" do
      case_log.incfreq = "Weekly"
      expect(case_log.weekly_net_income).to eq(net_income)
    end

    it "calculates the correct weekly income from monthly income" do
      case_log.incfreq = "Monthly"
      expect(case_log.weekly_net_income).to eq(1154)
    end

    it "calculates the correct weekly income from yearly income" do
      case_log.incfreq = "Yearly"
      expect(case_log.weekly_net_income).to eq(417)
    end
  end

  describe "derived variables" do
    require "date"
    let(:organisation) { FactoryBot.create(:organisation, "Org type": "PRP") }
    let!(:case_log) do
      CaseLog.create({
        managing_organisation: organisation,
        owning_organisation: organisation,
        property_postcode: "M1 1AE",
        previous_postcode: "M2 2AE",
        startdate: Time.gm(2021, 10, 10),
        mrcdate: Time.gm(2021, 5, 4),
        net_income_known: "Tenant prefers not to say",
        other_hhmemb: 6,
        rent_type: "London living rent",
        needstype: "General needs",
        hb: "Housing benefit",
        hbrentshortfall: "No",
      })
    end

    it "correctly derives and saves partial and full postcodes" do
      record_from_db = ActiveRecord::Base.connection.execute("select postcode, postcod2 from case_logs where id=#{case_log.id}").to_a[0]
      expect(record_from_db["postcode"]).to eq("M1")
      expect(record_from_db["postcod2"]).to eq("1AE")
    end

    it "correctly derives and saves partial and full previous postcodes" do
      record_from_db = ActiveRecord::Base.connection.execute("select ppostc1, ppostc2 from case_logs where id=#{case_log.id}").to_a[0]
      expect(record_from_db["ppostc1"]).to eq("M2")
      expect(record_from_db["ppostc2"]).to eq("2AE")
    end

    it "correctly derives and saves partial and full major repairs date" do
      record_from_db = ActiveRecord::Base.connection.execute("select mrcday, mrcmonth, mrcyear, mrcdate from case_logs where id=#{case_log.id}").to_a[0]
      expect(record_from_db["mrcdate"].day).to eq(4)
      expect(record_from_db["mrcdate"].month).to eq(5)
      expect(record_from_db["mrcdate"].year).to eq(2021)
      expect(record_from_db["mrcday"]).to eq(4)
      expect(record_from_db["mrcmonth"]).to eq(5)
      expect(record_from_db["mrcyear"]).to eq(2021)
    end

    it "correctly derives and saves incref" do
      record_from_db = ActiveRecord::Base.connection.execute("select incref from case_logs where id=#{case_log.id}").to_a[0]
      expect(record_from_db["incref"]).to eq(1)
    end

    it "correctly derives and saves hhmemb" do
      record_from_db = ActiveRecord::Base.connection.execute("select hhmemb from case_logs where id=#{case_log.id}").to_a[0]
      expect(record_from_db["hhmemb"]).to eq(7)
    end

    it "correctly derives and saves renttype" do
      record_from_db = ActiveRecord::Base.connection.execute("select renttype from case_logs where id=#{case_log.id}").to_a[0]
      expect(case_log.renttype).to eq("Intermediate Rent")
      expect(record_from_db["renttype"]).to eq(3)
    end

    it "correctly derives and saves lettype" do
      record_from_db = ActiveRecord::Base.connection.execute("select lettype from case_logs where id=#{case_log.id}").to_a[0]
      expect(case_log.lettype).to eq("Intermediate Rent General needs PRP")
      expect(record_from_db["lettype"]).to eq(9)
    end

    it "correctly derives and saves day, month, year from start date" do
      record_from_db = ActiveRecord::Base.connection.execute("select day, month, year, startdate from case_logs where id=#{case_log.id}").to_a[0]
      expect(record_from_db["startdate"].day).to eq(10)
      expect(record_from_db["startdate"].month).to eq(10)
      expect(record_from_db["startdate"].year).to eq(2021)
      expect(record_from_db["day"]).to eq(10)
      expect(record_from_db["month"]).to eq(10)
      expect(record_from_db["year"]).to eq(2021)
    end

    context "addresses" do
      before do
        stub_request(:get, /api.postcodes.io/)
          .to_return(status: 200, body: "{\"status\":200,\"result\":{\"admin_district\":\"Manchester\"}}", headers: {})
      end

      let!(:address_case_log) do
        CaseLog.create({
          managing_organisation: organisation,
          owning_organisation: organisation,
          postcode_known: "Yes",
          property_postcode: "M1 1AE",
        })
      end

      it "correctly infers la" do
        record_from_db = ActiveRecord::Base.connection.execute("select la from case_logs where id=#{address_case_log.id}").to_a[0]
        expect(address_case_log.la).to eq("Manchester")
        expect(record_from_db["la"]).to eq("E08000003")
      end

      it "errors if the property postcode is emptied" do
        expect { address_case_log.update!({ property_postcode: "" }) }
          .to raise_error(ActiveRecord::RecordInvalid, /#{I18n.t("validations.postcode")}/)
      end

      it "errors if the property postcode is not valid" do
        expect { address_case_log.update!({ property_postcode: "invalid_postcode" }) }
          .to raise_error(ActiveRecord::RecordInvalid, /#{I18n.t("validations.postcode")}/)
      end

      it "correctly resets all fields if property postcode not known" do
        address_case_log.update!({ postcode_known: "No" })

        record_from_db = ActiveRecord::Base.connection.execute("select la, property_postcode from case_logs where id=#{address_case_log.id}").to_a[0]
        expect(record_from_db["property_postcode"]).to eq(nil)
        expect(address_case_log.la).to eq(nil)
        expect(record_from_db["la"]).to eq(nil)
      end

      it "changes the LA if property postcode changes from not known to known and provided" do
        address_case_log.update!({ postcode_known: "No" })
        address_case_log.update!({ la: "Westminster" })

        record_from_db = ActiveRecord::Base.connection.execute("select la, property_postcode from case_logs where id=#{address_case_log.id}").to_a[0]
        expect(record_from_db["property_postcode"]).to eq(nil)
        expect(address_case_log.la).to eq("Westminster")
        expect(record_from_db["la"]).to eq("E09000033")

        address_case_log.update!({ postcode_known: "Yes", property_postcode: "M1 1AD" })

        record_from_db = ActiveRecord::Base.connection.execute("select la, property_postcode from case_logs where id=#{address_case_log.id}").to_a[0]
        expect(record_from_db["property_postcode"]).to eq("M1 1AD")
        expect(address_case_log.la).to eq("Manchester")
        expect(record_from_db["la"]).to eq("E08000003")
      end
    end

    context "net_income" do
      it "infers the income frequency" do
        case_log.update!(net_income_known: "Weekly")
        expect(case_log.reload.incfreq).to eq("Weekly")
        case_log.update!(net_income_known: "Monthly")
        expect(case_log.reload.incfreq).to eq("Monthly")
        case_log.update!(net_income_known: "Annually")
        expect(case_log.reload.incfreq).to eq("Yearly")
      end
    end

    context "rent and charges" do
      let!(:case_log) do
        CaseLog.create({
          managing_organisation: organisation,
          owning_organisation: organisation,
          brent: 5,
          scharge: 10,
          pscharge: 3,
          supcharg: 12,
        })
      end

      it "correctly sums rental charges" do
        record_from_db = ActiveRecord::Base.connection.execute("select tcharge from case_logs where id=#{case_log.id}").to_a[0]
        expect(record_from_db["tcharge"]).to eq(30)
      end
    end

    context "household members derived vars" do
      let!(:household_case_log) do
        CaseLog.create({
          managing_organisation: organisation,
          owning_organisation: organisation,
          other_hhmemb: 4,
          relat2: "Child - includes young adult and grown-up",
          relat3: "Child - includes young adult and grown-up",
          relat4: "Other",
          relat5: "Child - includes young adult and grown-up",
          relat7: "Other",
          relat8: "Other",
          age1: 22,
          age2: 14,
          age4: 60,
          age6: 88,
          age7: 16,
          age8: 42,
        })
      end

      it "correctly derives and saves totchild" do
        record_from_db = ActiveRecord::Base.connection.execute("select totchild from case_logs where id=#{household_case_log.id}").to_a[0]
        expect(record_from_db["totchild"]).to eq(3)
      end

      it "correctly derives and saves totelder" do
        record_from_db = ActiveRecord::Base.connection.execute("select totelder from case_logs where id=#{household_case_log.id}").to_a[0]
        expect(record_from_db["totelder"]).to eq(2)
      end

      it "correctly derives and saves totadult" do
        record_from_db = ActiveRecord::Base.connection.execute("select totadult from case_logs where id=#{household_case_log.id}").to_a[0]
        expect(record_from_db["totadult"]).to eq(3)
      end
    end

    it "correctly derives and saves has_benefits" do
      case_log.reload

      record_from_db = ActiveRecord::Base.connection.execute("select has_benefits from case_logs where id=#{case_log.id}").to_a[0]
      expect(record_from_db["has_benefits"]).to eq("Yes")
    end
  end

  describe "resetting invalidated fields" do
    context "when a question that has already been answered, no longer has met dependencies" do
      let(:case_log) { FactoryBot.create(:case_log, :in_progress, cbl: "Yes", preg_occ: "No") }

      it "clears the answer" do
        expect { case_log.update!(preg_occ: nil) }.to change { case_log.cbl }.from("Yes").to(nil)
      end
    end

    context "two pages with the same question key, only one's dependency is met" do
      let(:case_log) { FactoryBot.create(:case_log, :in_progress, cbl: "Yes", preg_occ: "No") }
      it "does not clear the answer" do
        expect(case_log.cbl).to eq("Yes")
      end
    end
  end
end
