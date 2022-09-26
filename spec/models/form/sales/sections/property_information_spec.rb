require "rails_helper"

RSpec.describe Form::Sales::Sections::PropertyInformation, type: :model do
  subject(:setup) { described_class.new(section_id, section_definition, form) }

  let(:section_id) { nil }
  let(:section_definition) { nil }
  let(:form) { instance_double(Form) }

  it "has correct form" do
    expect(setup.form).to eq(form)
  end

  it "has correct subsections" do
    expect(setup.subsections.map(&:id)).to eq(%w[property_information])
  end

  it "has the correct id" do
    expect(setup.id).to eq("property_information")
  end

  it "has the correct label" do
    expect(setup.label).to eq("Property information")
  end

  it "has the correct description" do
    expect(setup.description).to eq("")
  end
end
