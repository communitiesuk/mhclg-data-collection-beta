require "rails_helper"

RSpec.describe Form::Lettings::Subsections::PropertyInformation, type: :model do
  subject(:property_information) { described_class.new(nil, nil, section) }

  let(:section) { instance_double(Form::Lettings::Sections::TenancyAndProperty) }

  it "has correct section" do
    expect(property_information.section).to eq(section)
  end

  describe "pages" do
    let(:section) { instance_double(Form::Lettings::Sections::Household, form:) }
    let(:form) { instance_double(Form, start_date:) }

    before do
      allow(form).to receive(:start_year_2024_or_later?).and_return(true)
      allow(form).to receive(:start_year_2025_or_later?).and_return(false)
    end

    context "when 2023" do
      let(:start_date) { Time.utc(2023, 2, 8) }

      before do
        allow(form).to receive(:start_year_2024_or_later?).and_return(false)
        allow(form).to receive(:start_year_2025_or_later?).and_return(false)
      end

      it "has correct pages" do
        expect(property_information.pages.map(&:id)).to eq(
          %w[
            uprn
            uprn_confirmation
            address
            property_local_authority
            local_authority_rent_value_check
            first_time_property_let_as_social_housing
            property_let_type
            property_vacancy_reason_not_first_let
            property_vacancy_reason_first_let
            property_number_of_times_relet
            property_unit_type
            property_building_type
            property_wheelchair_accessible
            property_number_of_bedrooms
            beds_rent_value_check
            void_date
            void_date_value_check
            property_major_repairs
            property_major_repairs_value_check
          ],
        )
      end
    end

    context "when 2024" do
      let(:start_date) { Time.utc(2024, 2, 8) }

      before do
        allow(form).to receive(:start_year_2024_or_later?).and_return(true)
        allow(form).to receive(:start_year_2025_or_later?).and_return(false)
      end

      it "has correct pages" do
        expect(property_information.pages.map(&:id)).to eq(
          %w[
            address_search
            address
            property_local_authority
            local_authority_rent_value_check
            first_time_property_let_as_social_housing
            property_let_type
            property_vacancy_reason_not_first_let
            property_vacancy_reason_first_let
            property_unit_type
            property_building_type
            property_wheelchair_accessible
            property_number_of_bedrooms
            beds_rent_value_check
            void_date
            void_date_value_check
            property_major_repairs
            property_major_repairs_value_check
          ],
        )
      end
    end

    context "when 2025" do
      let(:start_date) { Time.utc(2025, 2, 8) }

      before do
        allow(form).to receive(:start_year_2024_or_later?).and_return(true)
        allow(form).to receive(:start_year_2025_or_later?).and_return(true)
      end

      it "has correct pages" do
        expect(property_information.pages.map(&:id)).to eq(
          %w[
            address_search
            address
            property_local_authority
            local_authority_rent_value_check
            first_time_property_let_as_social_housing
            property_let_type
            property_vacancy_reason_not_first_let
            property_vacancy_reason_first_let
            property_unit_type
            property_building_type
            property_wheelchair_accessible
            property_number_of_bedrooms
            beds_rent_value_check
            void_date
            void_date_value_check
            property_major_repairs
            property_major_repairs_value_check
            sheltered_accommodation
          ],
        )
      end
    end
  end

  it "has the correct id" do
    expect(property_information.id).to eq("property_information")
  end

  it "has the correct label" do
    expect(property_information.label).to eq("Property information")
  end

  it "has the correct depends_on" do
    expect(property_information.depends_on).to eq([{ "non_location_setup_questions_completed?" => true }])
  end
end
