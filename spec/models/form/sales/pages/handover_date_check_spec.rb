require "rails_helper"

RSpec.describe Form::Sales::Pages::HandoverDateCheck, type: :model do
  subject(:page) { described_class.new(page_id, page_definition, subsection) }

  let(:page_id) { "" }
  let(:page_definition) { nil }
  let(:subsection) { instance_double(Form::Subsection) }

  it "has correct subsection" do
    expect(page.subsection).to eq(subsection)
  end

  it "has correct questions" do
    expect(page.questions.map(&:id)).to eq(%w[hodate_check])
  end

  it "has the correct id" do
    expect(page.id).to eq("handover_date_check")
  end

  it "has the correct header" do
    expect(page.header).to be_nil
  end

  it "has the correct title_text" do
    expect(page.title_text).to eq({
      "translation" => "soft_validations.hodate.must_be_less_than_3_years_from_saledate",
      "arguments" => [],
    })
  end

  it "has the correct informative_text" do
    expect(page.informative_text).to eq({})
  end

  it "has correct depends_on" do
    expect(page.depends_on).to eq([
      { "hodate_3_years_or_more_saledate?" => true, "saledate_check" => nil },
      { "hodate_3_years_or_more_saledate?" => true, "saledate_check" => 1 },
    ])
  end

  it "is interruption screen page" do
    expect(page.interruption_screen?).to eq(true)
  end

  it "is has correct interruption_screen_question_ids" do
    expect(page.interruption_screen_question_ids).to eq(%w[hodate saledate])
  end
end
