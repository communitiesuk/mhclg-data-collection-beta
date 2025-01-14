require "rails_helper"

RSpec.describe Form::Sales::Pages::BuyerLive, type: :model do
  include CollectionTimeHelper

  subject(:page) { described_class.new(page_id, page_definition, subsection) }

  let(:page_id) { nil }
  let(:page_definition) { nil }
  let(:subsection) { instance_double(Form::Subsection) }

  context "when start year is 2024" do
    let(:form) { instance_double(Form, start_date: Time.zone.local(2024, 4, 1)) }

    before do
      allow(form).to receive(:start_year_2024_or_later?).and_return(true)
      allow(form).to receive(:start_year_2025_or_later?).and_return(false)
      allow(subsection).to receive(:form).and_return(form)
    end

    it "has correct subsection" do
      expect(page.subsection).to eq(subsection)
    end

    it "has correct questions" do
      expect(page.questions.map(&:id)).to eq(%w[buylivein])
    end

    it "has the correct id" do
      expect(page.id).to eq("buyer_live")
    end

    it "has the correct description" do
      expect(page.description).to be_nil
    end

    it "has correct depends_on" do
      expect(page.depends_on).to eq([{
        "companybuy" => 2,
      }])
    end
  end

  context "when start year is 2025" do
    let(:form) { instance_double(Form, start_date: Time.zone.local(2025, 4, 1)) }

    before do
      allow(form).to receive(:start_year_2024_or_later?).and_return(true)
      allow(form).to receive(:start_year_2025_or_later?).and_return(true)
      allow(subsection).to receive(:form).and_return(form)
    end

    it "has correct depends_on" do
      expect(page.depends_on).to be_nil
    end
  end
end
