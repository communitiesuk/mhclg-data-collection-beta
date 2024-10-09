require "rails_helper"

RSpec.describe Form::Sales::Questions::LivingBeforePurchaseYears, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page, ownershipsch: 1) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:start_date) { Time.utc(2024, 2, 8) }
  let(:subsection) { instance_double(Form::Subsection, form: instance_double(Form, start_date:)) }
  let(:page) { instance_double(Form::Page, subsection:) }

  context "when 2022" do
    let(:start_date) { Time.utc(2022, 2, 8) }

    it "has correct page" do
      expect(question.page).to eq(page)
    end

    it "has the correct id" do
      expect(question.id).to eq("proplen")
    end

    it "has the correct type" do
      expect(question.type).to eq("numeric")
    end

    it "is not marked as derived" do
      expect(question.derived?(nil)).to be false
    end

    it "has correct width" do
      expect(question.width).to eq(5)
    end

    it "has correct step" do
      expect(question.step).to eq(1)
    end

    it "has correct min" do
      expect(question.min).to eq(0)
    end

    it "has correct max" do
      expect(question.max).to eq(80)
    end
  end

  context "when 2023" do
    let(:start_date) { Time.utc(2023, 2, 8) }

    it "has correct page" do
      expect(question.page).to eq(page)
    end

    it "has the correct id" do
      expect(question.id).to eq("proplen")
    end

    it "has the correct type" do
      expect(question.type).to eq("numeric")
    end

    it "is not marked as derived" do
      expect(question.derived?(nil)).to be false
    end

    it "has correct width" do
      expect(question.width).to eq(5)
    end

    it "has correct step" do
      expect(question.step).to eq(1)
    end

    it "has correct min" do
      expect(question.min).to eq(0)
    end

    it "has correct max" do
      expect(question.max).to eq(80)
    end
  end

  context "when 1 year" do
    let(:sales_log) { FactoryBot.build(:sales_log, proplen: 1) }

    it "has correct suffix" do
      expect(question.suffix_label(sales_log)).to eq(" year")
    end
  end

  context "when multiple years" do
    let(:sales_log) { FactoryBot.build(:sales_log, proplen: 5) }

    it "has correct suffix" do
      expect(question.suffix_label(sales_log)).to eq(" years")
    end
  end
end
