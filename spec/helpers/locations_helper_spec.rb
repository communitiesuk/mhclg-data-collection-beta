require "rails_helper"

RSpec.describe LocationsHelper do
  describe "mobility type selection" do
    expected_selection = [OpenStruct.new(id: "Wheelchair-user standard", name: "Wheelchair-user standard", description: "The majority of units are suitable for someone who uses a wheelchair and offer the full use of all rooms and facilities."),
                          OpenStruct.new(id: "Fitted with equipment and adaptations", name: "Fitted with equipment and adaptations", description: "For example, the majority of units have been fitted with stairlifts, ramps, level access showers or grab rails."),
                          OpenStruct.new(id: "None", name: "None", description: "The majority of units are not designed to wheelchair-user standards or fitted with any equipment and adaptations.")]
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

  describe "display_location_attributes" do
    let(:location) { FactoryBot.build(:location, created_at: Time.zone.local(2022, 3, 16), startdate: Time.zone.local(2022, 4, 1)) }

    it "returns correct display attributes" do
      attributes = [
        { name: "Postcode", value: location.postcode },
        { name: "Local authority", value: location.location_admin_district },
        { name: "Location name", value: location.name, edit: true },
        { name: "Total number of units at this location", value: location.units },
        { name: "Common type of unit", value: location.type_of_unit },
        { name: "Mobility type", value: location.mobility_type },
        { name: "Code", value: location.location_code },
        { name: "Availability", value: "Active from 1 April 2022" },
        { name: "Status", value: :active },
      ]

      expect(display_location_attributes(location)).to eq(attributes)
    end

    context "when viewing availability" do
      context "with are no deactivations" do
        it "displays created_at as availability date if startdate is not present" do
          location.update!(startdate: nil)
          availability_attribute = display_location_attributes(location).find { |x| x[:name] == "Availability" }[:value]

          expect(availability_attribute).to eq("Active from #{location.created_at.to_formatted_s(:govuk_date)}")
        end

        it "displays current collection start date as availability date if created_at is later than collection start date" do
          location.update!(startdate: nil, created_at: Time.zone.local(2022, 4, 16))
          availability_attribute = display_location_attributes(location).find { |x| x[:name] == "Availability" }[:value]

          expect(availability_attribute).to eq("Active from 1 April 2022")
        end
      end

      context "with previous deactivations" do
        context "and all reactivated deactivations" do
          before do
            location.location_deactivation_periods << FactoryBot.create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 8, 10), reactivation_date: Time.zone.local(2022, 9, 1))
            location.location_deactivation_periods << FactoryBot.create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 9, 15), reactivation_date: Time.zone.local(2022, 9, 28))
          end

          it "displays the timeline of availability" do
            availability_attribute = display_location_attributes(location).find { |x| x[:name] == "Availability" }[:value]

            expect(availability_attribute).to eq("Active from 1 April 2022 to 9 August 2022\nDeactivated on 10 August 2022\nActive from 1 September 2022 to 14 September 2022\nDeactivated on 15 September 2022\nActive from 28 September 2022")
          end
        end

        context "and non reactivated deactivation" do
          before do
            location.location_deactivation_periods << FactoryBot.create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 8, 10), reactivation_date: Time.zone.local(2022, 9, 1))
            location.location_deactivation_periods << FactoryBot.create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 9, 15), reactivation_date: nil)
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
            location.location_deactivation_periods << FactoryBot.create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 9, 24), reactivation_date: Time.zone.local(2022, 9, 28))
            location.location_deactivation_periods << FactoryBot.create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 6, 15), reactivation_date: Time.zone.local(2022, 6, 18))
          end

          it "displays the timeline of availability" do
            availability_attribute = display_location_attributes(location).find { |x| x[:name] == "Availability" }[:value]

            expect(availability_attribute).to eq("Active from 1 April 2022 to 14 June 2022\nDeactivated on 15 June 2022\nActive from 18 June 2022 to 23 September 2022\nDeactivated on 24 September 2022\nActive from 28 September 2022")
          end
        end

        context "and one non reactivated deactivation" do
          before do
            location.location_deactivation_periods << FactoryBot.create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 9, 24), reactivation_date: Time.zone.local(2022, 9, 28))
            location.location_deactivation_periods << FactoryBot.create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 6, 15), reactivation_date: nil)
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
            location.location_deactivation_periods << FactoryBot.create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 9, 24), reactivation_date: Time.zone.local(2022, 9, 28))
            location.location_deactivation_periods << FactoryBot.create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 10, 24), reactivation_date: Time.zone.local(2022, 10, 28))
            location.location_deactivation_periods << FactoryBot.create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 6, 15), reactivation_date: nil)
          end

          it "displays the timeline of availability" do
            availability_attribute = display_location_attributes(location).find { |x| x[:name] == "Availability" }[:value]

            expect(availability_attribute).to eq("Active from 1 April 2022 to 14 June 2022\nDeactivated on 15 June 2022\nActive from 28 September 2022 to 23 October 2022\nDeactivated on 24 October 2022\nActive from 28 October 2022")
          end
        end
      end
    end
  end
end
