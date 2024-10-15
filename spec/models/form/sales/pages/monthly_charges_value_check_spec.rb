require "rails_helper"

RSpec.describe Form::Sales::Pages::MonthlyChargesValueCheck, type: :model do
  subject(:page) { described_class.new(page_id, page_definition, subsection) }

  let(:page_id) { "monthly_charges_value_check" }
  let(:page_definition) { nil }
  let(:subsection) { instance_double(Form::Subsection) }

  it "has correct subsection" do
    expect(page.subsection).to eq(subsection)
  end

  it "has correct questions" do
    expect(page.questions.map(&:id)).to eq(%w[monthly_charges_value_check])
  end

  it "has the correct id" do
    expect(page.id).to eq("monthly_charges_value_check")
  end

  it "has correct depends_on" do
    expect(page.depends_on).to eq([
      {
        "monthly_charges_over_soft_max?" => true,
      },
    ])
  end

  it "is interruption screen page" do
    expect(page.interruption_screen?).to eq(true)
  end

  it "has correct title_text" do
    expect(page.title_text).to eq({
      "translation" => "soft_validations.monthly_charges_over_soft_max.title_text",
      "arguments" => [{ "arguments_for_key" => "mscharge", "i18n_template" => "mscharge", "key" => "field_formatted_as_currency" }],
    })
  end

  it "has correct informative_text" do
    expect(page.informative_text).to eq({ "arguments" => [], "translation" => "soft_validations.monthly_charges_over_soft_max.hint_text" })
  end

  it "has correct interruption_screen_question_ids" do
    expect(page.interruption_screen_question_ids).to eq(%w[type mscharge proptype])
  end
end
