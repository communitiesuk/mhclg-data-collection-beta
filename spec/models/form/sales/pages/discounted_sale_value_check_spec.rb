require "rails_helper"

RSpec.describe Form::Sales::Pages::DiscountedSaleValueCheck, type: :model do
  subject(:page) { described_class.new(page_id, page_definition, subsection, index) }

  let(:page_id) { "discounted_sale_value_check" }
  let(:page_definition) { nil }
  let(:index) { 1 }
  let(:form) { instance_double(Form, start_date: Time.zone.local(2024, 4, 1)) }
  let(:subsection) { instance_double(Form::Subsection, form:) }

  it "has correct subsection" do
    expect(page.subsection).to eq(subsection)
  end

  it "has correct questions" do
    expect(page.questions.map(&:id)).to eq(%w[discounted_sale_value_check])
  end

  it "has the correct id" do
    expect(page.id).to eq("discounted_sale_value_check")
  end

  it "has the correct title_text" do
    expect(page.title_text).to eq({
      "translation" => "forms.2024.sales.soft_validations.discounted_sale_value_check.title_text",
      "arguments" => [{ "arguments_for_key" => "value_with_discount", "i18n_template" => "value_with_discount", "key" => "field_formatted_as_currency" }],
    })
  end

  it "has the correct informative_text" do
    expect(page.informative_text).to eq({
      "translation" => "forms.2024.sales.soft_validations.discounted_sale_value_check.informative_text",
      "arguments" => [{ "arguments_for_key" => "mortgage_deposit_and_grant_total", "i18n_template" => "mortgage_deposit_and_grant_total", "key" => "field_formatted_as_currency" }],
    })
  end

  it "is interruption screen page" do
    expect(page.interruption_screen?).to eq(true)
  end

  it "has correct depends_on" do
    expect(page.depends_on).to eq([
      {
        "discounted_ownership_value_invalid?" => true,
      },
    ])
  end

  it "has correct interruption_screen_question_ids" do
    expect(page.interruption_screen_question_ids).to eq(%w[value deposit ownershipsch mortgage mortgageused discount grant type])
  end
end
