require "rails_helper"

RSpec.describe Form::Lettings::Pages::NoFemalesPregnantHouseholdPersonValueCheck, type: :model do
  subject(:page) { described_class.new(nil, page_definition, subsection, person_index:) }

  let(:page_definition) { nil }
  let(:subsection) { instance_double(Form::Subsection, form: instance_double(Form, start_date: Time.zone.local(2024, 4, 1))) }
  let(:person_index) { 2 }

  it "has correct subsection" do
    expect(page.subsection).to eq(subsection)
  end

  it "has the correct description" do
    expect(page.description).to be nil
  end

  it "has correct questions" do
    expect(page.questions.map(&:id)).to eq(%w[pregnancy_value_check])
  end

  context "with person 2" do
    it "has the correct id" do
      expect(page.id).to eq("no_females_pregnant_household_person_2_value_check")
    end

    it "has correct depends_on" do
      expect(page.depends_on).to eq(
        [
          {
            "details_known_2" => 0,
            "all_male_tenants_in_a_pregnant_household?" => true,
          },
        ],
      )
    end

    it "has the correct title_text" do
      expect(page.title_text).to eq({
        "translation" => "forms.2024.lettings.soft_validations.pregnancy_value_check.no_females_pregnant_household_value_check.title_text",
        "arguments" => [],
      })
    end

    it "has the correct informative_text" do
      expect(page.informative_text).to eq({
        "translation" => "forms.2024.lettings.soft_validations.pregnancy_value_check.no_females_pregnant_household_value_check.informative_text",
        "arguments" => [],
      })
    end
  end

  context "with person 3" do
    let(:person_index) { 3 }

    it "has the correct id" do
      expect(page.id).to eq("no_females_pregnant_household_person_3_value_check")
    end

    it "has correct depends_on" do
      expect(page.depends_on).to eq(
        [
          {
            "details_known_3" => 0,
            "all_male_tenants_in_a_pregnant_household?" => true,
          },
        ],
      )
    end

    it "has the correct title_text" do
      expect(page.title_text).to eq({
        "translation" => "forms.2024.lettings.soft_validations.pregnancy_value_check.no_females_pregnant_household_value_check.title_text",
        "arguments" => [],
      })
    end

    it "has the correct informative_text" do
      expect(page.informative_text).to eq({
        "translation" => "forms.2024.lettings.soft_validations.pregnancy_value_check.no_females_pregnant_household_value_check.informative_text",
        "arguments" => [],
      })
    end
  end
end
