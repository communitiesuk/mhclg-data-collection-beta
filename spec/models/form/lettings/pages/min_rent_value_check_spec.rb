require "rails_helper"

RSpec.describe Form::Lettings::Pages::MinRentValueCheck, type: :model do
  subject(:page) { described_class.new(page_id, page_definition, subsection) }

  let(:page_id) { "min_rent_value_check" }
  let(:page_definition) { nil }
  let(:subsection) { instance_double(Form::Subsection, form: instance_double(Form, start_date: Time.zone.local(2024, 4, 1))) }

  it "has correct subsection" do
    expect(page.subsection).to eq(subsection)
  end

  it "has the correct description" do
    expect(page.description).to be nil
  end

  it "has correct questions" do
    expect(page.questions.map(&:id)).to eq(%w[rent_value_check])
  end

  it "has the correct id" do
    expect(page.id).to eq("min_rent_value_check")
  end

  it "has correct depends_on" do
    expect(page.depends_on).to eq(
      [{ "rent_in_soft_min_range?" => true }],
    )
  end

  it "has the correct title_text" do
    expect(page.title_text).to eq({
      "translation" => "soft_validations.rent.outside_range_title",
      "arguments" => [{ "i18n_template" => "brent", "key" => "brent", "label" => true }],
    })
  end

  it "has the correct interruption_screen_question_ids" do
    expect(page.interruption_screen_question_ids).to eq(%w[brent period startdate uprn postcode_full la beds rent_type needstype])
  end
end