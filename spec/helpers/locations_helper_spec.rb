require "rails_helper"

RSpec.describe LocationsHelper do
  include CollectionTimeHelper

  describe "mobility type selection" do
    expected_selection = [OpenStruct.new(id: "Wheelchair-user standard", name: "Wheelchair-user standard", description: "Suitable for someone who uses a wheelchair and offers the full use of all rooms and facilities."),
                          OpenStruct.new(id: "Fitted with equipment and adaptations", name: "Fitted with equipment and adaptations", description: "Fitted with stairlifts, ramps, level access showers or grab rails."),
                          OpenStruct.new(id: "None", name: "None", description: "Not designed to wheelchair-user standards or fitted with any equipment or adaptations.")]
    it "returns correct selection to display" do
      expect(mobility_type_selection).to eq(expected_selection)
    end
  end

  describe "another location selection" do
    it "returns correct selection to display" do
      expected_selection = [OpenStruct.new(id: "Yes", name: "Yes"), OpenStruct.new(id: "No", name: "No")]
      expect(another_location_selection).to eq(expected_selection)
    end
  end

  describe "type of units selection" do
    it "returns correct selection to display" do
      expected_selection = [OpenStruct.new(id: "Bungalow", name: "Bungalow"),
                            OpenStruct.new(id: "Self-contained flat or bedsit", name: "Self-contained flat or bedsit"),
                            OpenStruct.new(id: "Self-contained flat or bedsit with common facilities", name: "Self-contained flat or bedsit with common facilities"),
                            OpenStruct.new(id: "Self-contained house", name: "Self-contained house"),
                            OpenStruct.new(id: "Shared flat", name: "Shared flat"),
                            OpenStruct.new(id: "Shared house or hostel", name: "Shared house or hostel")]
      expect(type_of_units_selection).to eq(expected_selection)
    end
  end

  describe "selection options" do
    it "returns empty array for nil" do
      expect(selection_options(nil)).to eq([])
    end

    it "returns empty array for empty string" do
      expect(selection_options("")).to eq([])
    end

    it "returns empty array for empty object" do
      expect(selection_options({})).to eq([])
    end

    it "can map a resource with values" do
      expect(selection_options(%w[example])).to eq([OpenStruct.new(id: "example", name: "Example")])
    end
  end

  describe "Active periods" do
    let(:location) { FactoryBot.create(:location, startdate: nil) }
    let(:today) { Time.zone.local(2023, 10, 10) }
    let(:one_year_ago) { today - 1.year }
    let(:over_a_year_ago) { one_year_ago - 5.months }
    let(:beginning_of_collection) { Time.zone.local(2022, 4, 1) }

    before do
      allow(Time).to receive(:now).and_return(today)
      allow(FormHandler.instance).to receive(:lettings_in_crossover_period?).and_return(true)
    end

    it "returns one active period without to date" do
      expect(location_active_periods(location).count).to eq(1)
      expect(location_active_periods(location).first).to have_attributes(from: beginning_of_collection, to: nil)
    end

    it "ignores reactivations that were deactivated on the same day" do
      FactoryBot.create(:location_deactivation_period, deactivation_date: over_a_year_ago, reactivation_date: over_a_year_ago + 1.month, location:)
      FactoryBot.create(:location_deactivation_period, deactivation_date: over_a_year_ago + 1.month, location:)
      location.reload

      expect(location_active_periods(location).count).to eq(1)
      expect(location_active_periods(location).first).to have_attributes(from: beginning_of_collection, to: over_a_year_ago)
    end

    it "returns sequential non reactivated active periods" do
      FactoryBot.create(:location_deactivation_period, deactivation_date: over_a_year_ago, reactivation_date: over_a_year_ago + 1.month, location:)
      FactoryBot.create(:location_deactivation_period, deactivation_date: over_a_year_ago + 2.months, location:)
      location.reload

      expect(location_active_periods(location).count).to eq(2)
      expect(location_active_periods(location).first).to have_attributes(from: beginning_of_collection, to: over_a_year_ago)
      expect(location_active_periods(location).second).to have_attributes(from: over_a_year_ago + 1.month, to: over_a_year_ago + 2.months)
    end

    it "returns sequential reactivated active periods" do
      FactoryBot.create(:location_deactivation_period, deactivation_date: over_a_year_ago, reactivation_date: over_a_year_ago + 1.month, location:)
      FactoryBot.create(:location_deactivation_period, deactivation_date: over_a_year_ago + 2.months, reactivation_date: over_a_year_ago + 3.months, location:)
      location.reload
      expect(location_active_periods(location).count).to eq(3)
      expect(location_active_periods(location).first).to have_attributes(from: beginning_of_collection, to: over_a_year_ago)
      expect(location_active_periods(location).second).to have_attributes(from: over_a_year_ago + 1.month, to: over_a_year_ago + 2.months)
      expect(location_active_periods(location).third).to have_attributes(from: over_a_year_ago + 3.months, to: nil)
    end

    it "returns non sequential non reactivated active periods" do
      FactoryBot.create(:location_deactivation_period, deactivation_date: over_a_year_ago + 2.months, reactivation_date: over_a_year_ago + 3.months, location:)
      FactoryBot.create(:location_deactivation_period, deactivation_date: over_a_year_ago, reactivation_date: nil, location:)
      location.reload

      expect(location_active_periods(location).count).to eq(2)
      expect(location_active_periods(location).first).to have_attributes(from: beginning_of_collection, to: over_a_year_ago)
      expect(location_active_periods(location).second).to have_attributes(from: over_a_year_ago + 3.months, to: nil)
    end

    it "returns non sequential reactivated active periods" do
      FactoryBot.create(:location_deactivation_period, deactivation_date: over_a_year_ago + 2.months, reactivation_date: over_a_year_ago + 3.months, location:)
      FactoryBot.create(:location_deactivation_period, deactivation_date: over_a_year_ago, reactivation_date: over_a_year_ago + 1.month, location:)
      location.reload
      expect(location_active_periods(location).count).to eq(3)
      expect(location_active_periods(location).first).to have_attributes(from: beginning_of_collection, to: over_a_year_ago)
      expect(location_active_periods(location).second).to have_attributes(from: over_a_year_ago + 1.month, to: over_a_year_ago + 2.months)
      expect(location_active_periods(location).third).to have_attributes(from: over_a_year_ago + 3.months, to: nil)
    end

    it "returns correct active periods when reactivation happends during a deactivated period" do
      FactoryBot.create(:location_deactivation_period, deactivation_date: over_a_year_ago, reactivation_date: one_year_ago, location:)
      FactoryBot.create(:location_deactivation_period, deactivation_date: beginning_of_collection + 2.days, reactivation_date: over_a_year_ago + 1.month, location:)
      location.reload

      expect(location_active_periods(location).count).to eq(2)
      expect(location_active_periods(location).first).to have_attributes(from: beginning_of_collection, to: beginning_of_collection + 2.days)
      expect(location_active_periods(location).second).to have_attributes(from: one_year_ago, to: nil)
    end

    it "returns correct active periods when a full deactivation period happens during another deactivation period" do
      FactoryBot.create(:location_deactivation_period, deactivation_date: over_a_year_ago, reactivation_date: over_a_year_ago + 1.month, location:)
      FactoryBot.create(:location_deactivation_period, deactivation_date: over_a_year_ago - 1.month, reactivation_date: over_a_year_ago + 3.months, location:)
      location.reload

      expect(location_active_periods(location).count).to eq(2)
      expect(location_active_periods(location).first).to have_attributes(from: beginning_of_collection, to: over_a_year_ago - 1.month)
      expect(location_active_periods(location).second).to have_attributes(from: over_a_year_ago + 3.months, to: nil)
    end
  end

  describe "display_location_attributes" do
    let(:location) { FactoryBot.build(:location, created_at: Time.zone.local(2022, 3, 16), startdate: Time.zone.local(2022, 4, 1)) }

    it "returns correct display attributes" do
      attributes = [
        { attribute: "postcode", name: "Postcode", value: location.postcode },
        { attribute: "name", name: "Location name", value: location.name },
        { attribute: "status", name: "Status", value: :active },
        { attribute: "local_authority", name: "Local authority", value: location.location_admin_district },
        { attribute: "units", name: "Number of units", value: location.units },
        { attribute: "type_of_unit", name: "Most common unit", value: location.type_of_unit },
        { attribute: "mobility_standards", name: "Mobility standards", value: location.mobility_type },
        { attribute: "id", name: "Location code", value: location.id },
        { attribute: "availability", name: "Availability", value: "Active from 1 April 2022" },
      ]

      expect(display_location_attributes(location)).to eq(attributes)
    end

    context "when location has different local authorities for different years" do
      before do
        LocalAuthorityLink.create!(local_authority_id: LocalAuthority.find_by(code: "E07000030").id, linked_local_authority_id: LocalAuthority.find_by(code: "E06000063").id)
        location.update!(location_code: "E07000030")
      end

      it "returns correct display attributes" do
        attributes = [
          { attribute: "postcode", name: "Postcode", value: location.postcode },
          { attribute: "name", name: "Location name", value: location.name },
          { attribute: "status", name: "Status", value: :active },
          { attribute: "local_authority", name: "Local authority", value: "Eden (until 31 March 2023)\nCumberland (1 April 2023 - present)" },
          { attribute: "units", name: "Number of units", value: location.units },
          { attribute: "type_of_unit", name: "Most common unit", value: location.type_of_unit },
          { attribute: "mobility_standards", name: "Mobility standards", value: location.mobility_type },
          { attribute: "id", name: "Location code", value: location.id },
          { attribute: "availability", name: "Availability", value: "Active from 1 April 2022" },
        ]

        expect(display_location_attributes(location)).to eq(attributes)
      end
    end

    context "when location has no local authority" do
      before do
        LocalAuthorityLink.create!(local_authority_id: LocalAuthority.find_by(code: "E07000030").id, linked_local_authority_id: LocalAuthority.find_by(code: "E06000063").id)
        location.update!(location_code: nil, confirmed: false)
      end

      it "returns correct display attributes" do
        attributes = [
          { attribute: "postcode", name: "Postcode", value: location.postcode },
          { attribute: "name", name: "Location name", value: location.name },
          { attribute: "status", name: "Status", value: :incomplete },
          { attribute: "local_authority", name: "Local authority", value: "" },
          { attribute: "units", name: "Number of units", value: location.units },
          { attribute: "type_of_unit", name: "Most common unit", value: location.type_of_unit },
          { attribute: "mobility_standards", name: "Mobility standards", value: location.mobility_type },
          { attribute: "id", name: "Location code", value: location.id },
          { attribute: "availability", name: "Availability", value: "Active from 1 April 2022" },
        ]

        expect(display_location_attributes(location)).to eq(attributes)
      end
    end

    context "when viewing availability" do
      context "with no deactivations" do
        before do
          allow(Time).to receive(:now).and_call_original
        end

        it "displays current collection start date as availability date if created_at is later than collection start date and not in a crossover period" do
          allow(FormHandler.instance).to receive(:in_crossover_period?).with(anything).and_return(false)

          location.update!(startdate: nil, created_at: current_collection_start_date + 6.months)
          availability_attribute = display_location_attributes(location).find { |x| x[:name] == "Availability" }[:value]

          expect(availability_attribute).to eq("Active from 1 April #{current_collection_start_date.year}")
        end

        it "displays previous collection start date as availability date if created_at is later than collection start date and in crossover" do
          allow(FormHandler.instance).to receive(:in_crossover_period?).with(anything).and_return(true)

          location.update!(startdate: nil, created_at: current_collection_start_date + 1.week)
          availability_attribute = display_location_attributes(location).find { |x| x[:name] == "Availability" }[:value]

          expect(availability_attribute).to eq("Active from 1 April #{previous_collection_start_date.year}")
        end

        context "when location was merged" do
          it "displays merge date as availability date" do
            location.update!(startdate: Time.zone.local(2022, 4, 16))
            availability_attribute = display_location_attributes(location).find { |x| x[:name] == "Availability" }[:value]

            expect(availability_attribute).to eq("Active from 16 April 2022")
          end
        end
      end

      context "with previous deactivations" do
        context "and all reactivated deactivations" do
          before do
            allow(Time).to receive(:now).and_return(Time.zone.local(2023, 11, 10))
            FactoryBot.create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 8, 10), reactivation_date: Time.zone.local(2022, 9, 1), location:)
            FactoryBot.create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 9, 15), reactivation_date: Time.zone.local(2022, 9, 28), location:)
            location.reload
          end

          it "displays the timeline of availability" do
            availability_attribute = display_location_attributes(location).find { |x| x[:name] == "Availability" }[:value]

            expect(availability_attribute).to eq("Active from 1 April 2022 to 9 August 2022\nDeactivated on 10 August 2022\nActive from 1 September 2022 to 14 September 2022\nDeactivated on 15 September 2022\nActive from 28 September 2022")
          end
        end

        context "and non reactivated deactivation" do
          before do
            allow(Time).to receive(:now).and_return(Time.zone.local(2023, 11, 10))
            FactoryBot.create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 8, 10), reactivation_date: Time.zone.local(2022, 9, 1), location:)
            FactoryBot.create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 9, 15), reactivation_date: nil, location:)
            location.reload
          end

          it "displays the timeline of availability" do
            availability_attribute = display_location_attributes(location).find { |x| x[:name] == "Availability" }[:value]

            expect(availability_attribute).to eq("Active from 1 April 2022 to 9 August 2022\nDeactivated on 10 August 2022\nActive from 1 September 2022 to 14 September 2022\nDeactivated on 15 September 2022")
          end
        end
      end

      context "with out of order deactivations" do
        context "and all reactivated deactivations" do
          before do
            allow(Time).to receive(:now).and_return(Time.zone.local(2023, 11, 10))
            FactoryBot.create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 9, 24), reactivation_date: Time.zone.local(2022, 9, 28), location:)
            FactoryBot.create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 6, 15), reactivation_date: Time.zone.local(2022, 6, 18), location:)
            location.reload
          end

          it "displays the timeline of availability" do
            availability_attribute = display_location_attributes(location).find { |x| x[:name] == "Availability" }[:value]

            expect(availability_attribute).to eq("Active from 1 April 2022 to 14 June 2022\nDeactivated on 15 June 2022\nActive from 18 June 2022 to 23 September 2022\nDeactivated on 24 September 2022\nActive from 28 September 2022")
          end
        end

        context "and one non reactivated deactivation" do
          before do
            allow(Time).to receive(:now).and_return(Time.zone.local(2023, 11, 10))
            FactoryBot.create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 9, 24), reactivation_date: Time.zone.local(2022, 9, 28), location:)
            FactoryBot.create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 6, 15), reactivation_date: nil, location:)
            location.reload
          end

          it "displays the timeline of availability" do
            availability_attribute = display_location_attributes(location).find { |x| x[:name] == "Availability" }[:value]

            expect(availability_attribute).to eq("Active from 1 April 2022 to 14 June 2022\nDeactivated on 15 June 2022\nActive from 28 September 2022")
          end
        end
      end

      context "with multiple out of order deactivations" do
        context "and one non reactivated deactivation" do
          before do
            allow(Time).to receive(:now).and_return(Time.zone.local(2023, 11, 10))
            FactoryBot.create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 9, 24), reactivation_date: Time.zone.local(2022, 9, 28), location:)
            FactoryBot.create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 10, 24), reactivation_date: Time.zone.local(2022, 10, 28), location:)
            FactoryBot.create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 6, 15), reactivation_date: nil, location:)
            location.reload
          end

          it "displays the timeline of availability" do
            availability_attribute = display_location_attributes(location).find { |x| x[:name] == "Availability" }[:value]

            expect(availability_attribute).to eq("Active from 1 April 2022 to 14 June 2022\nDeactivated on 15 June 2022\nActive from 28 September 2022 to 23 October 2022\nDeactivated on 24 October 2022\nActive from 28 October 2022")
          end
        end
      end

      context "with intersecting deactivations" do
        before do
          allow(Time).to receive(:now).and_return(Time.zone.local(2023, 11, 10))
          FactoryBot.create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 10, 10), reactivation_date: Time.zone.local(2022, 12, 1), location:)
          FactoryBot.create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 11, 11), reactivation_date: Time.zone.local(2022, 12, 11), location:)
          location.reload
        end

        it "displays the timeline of availability" do
          availability_attribute = display_location_attributes(location).find { |x| x[:name] == "Availability" }[:value]

          expect(availability_attribute).to eq("Active from 1 April 2022 to 9 October 2022\nDeactivated on 10 October 2022\nActive from 11 December 2022")
        end
      end
    end
  end

  describe "edit_location_text" do
    let(:parent_organisation) { FactoryBot.create(:organisation, name: "Parent") }
    let(:child_organisation) { FactoryBot.create(:organisation, name: "Child") }
    let(:scheme) { FactoryBot.create(:scheme, owning_organisation: parent_organisation) }
    let(:data_coordinator) { FactoryBot.create(:user, :data_coordinator, organisation: child_organisation) }
    let(:data_provider) { FactoryBot.create(:user, :data_provider, organisation: child_organisation) }
    let(:location) { FactoryBot.build(:location, scheme:) }

    before do
      create(:organisation_relationship, child_organisation:, parent_organisation:)
    end

    context "with data coordinator user" do
      it "returns correct edit location text for a parent organisation location" do
        expect(edit_location_text(scheme, data_coordinator)).to include("This location belongs to your stock owner Parent.")
      end

      it "returns nil when viewing your organisation location" do
        data_coordinator.update!(organisation: parent_organisation)
        expect(edit_location_text(scheme, data_coordinator)).to be_nil
      end
    end

    context "with data provider user" do
      it "returns correct edit location text for a parent organisation location" do
        expect(edit_location_text(scheme, data_provider)).to include("If you think this location should be updated, ask a data coordinator to make the changes. Find your data coordinators on the ")
      end

      it "returns correct edit location text for your organisation location" do
        data_provider.update!(organisation: parent_organisation)
        expect(edit_location_text(scheme, data_provider)).to include("If you think this location should be updated, ask a data coordinator to make the changes. Find your data coordinators on the ")
      end
    end
  end

  describe "formatted_local_authority_timeline" do
    before do
      LocalAuthorityLink.create!(local_authority_id: LocalAuthority.find_by(code: "E07000030").id, linked_local_authority_id: LocalAuthority.find_by(code: "E06000063").id)
      LocalAuthorityLink.create!(local_authority_id: LocalAuthority.find_by(code: "E08000016").id, linked_local_authority_id: LocalAuthority.find_by(code: "E08000038").id)
    end

    context "when the location LA's have changed" do
      let(:location) { FactoryBot.create(:location, location_code: "E07000030") }

      it "displays a timeline of LAs" do
        expect(formatted_local_authority_timeline(location)).to eq("Eden (until 31 March 2023)\nCumberland (1 April 2023 - present)")
      end
    end

    context "when the LA name hasn't changed but Ecode has changed" do
      let(:location) { FactoryBot.create(:location, location_code: "E08000016") }

      it "only displays the location name once" do
        expect(formatted_local_authority_timeline(location)).to eq("Barnsley")
      end
    end
  end
end
