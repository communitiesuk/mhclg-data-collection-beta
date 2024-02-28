require "rails_helper"

RSpec.describe Form::Sales::Pages::LivingBeforePurchase, type: :model do
  subject(:page) { described_class.new(page_id, page_definition, subsection, ownershipsch: 1, joint_purchase: false) }

  let(:page_id) { nil }
  let(:page_definition) { nil }
  let(:subsection) { instance_double(Form::Subsection) }

  it "has correct subsection" do
    expect(page.subsection).to eq(subsection)
  end

  describe "questions" do
    let(:subsection) { instance_double(Form::Subsection, form: instance_double(Form, start_date:)) }

    context "when 2022" do
      let(:start_date) { Time.utc(2022, 2, 8) }

      it "has correct questions" do
        expect(page.questions.map(&:id)).to eq(%w[proplen])
      end
    end

    context "when 2023" do
      let(:start_date) { Time.utc(2023, 2, 8) }

      it "has correct questions" do
        expect(page.questions.map(&:id)).to eq(%w[proplen_asked proplen])
      end
    end
  end

  it "has the correct id" do
    expect(page.id).to eq(nil)
  end

  it "has the correct header" do
    expect(page.header).to be_nil
  end

  it "has the correct description" do
    expect(page.description).to be_nil
  end

  it "has correct depends_on" do
    expect(page.depends_on).to eq([{ "not_joint_purchase?" => true }])
  end

  context "with joint purchase" do
    subject(:page) { described_class.new(page_id, page_definition, subsection, ownershipsch: 1, joint_purchase: true) }

    it "has correct depends_on" do
      expect(page.depends_on).to eq([{ "joint_purchase?" => true }])
    end
  end
end
