require "rails_helper"

RSpec.describe Form::Sales::Pages::StaircaseOwnedValueCheck, type: :model do
  subject(:page) { described_class.new(page_id, page_definition, subsection, joint_purchase:) }

  let(:page_id) { "an_id" }
  let(:page_definition) { nil }
  let(:subsection) { instance_double(Form::Subsection) }
  let(:joint_purchase) { false }

  it "has correct subsection" do
    expect(page.subsection).to eq(subsection)
  end

  it "has correct questions" do
    expect(page.questions.map(&:id)).to eq(%w[stairowned_value_check])
  end

  it "has the correct id" do
    expect(page.id).to eq("an_id")
  end

  it "has the correct header" do
    expect(page.header).to be_nil
  end

  it "has correct depends_on" do
    expect(page.depends_on).to eq([{
      "staircase_owned_out_of_soft_range?" => true,
      "joint_purchase?" => joint_purchase,
    }])
  end

  it "is interruption screen page" do
    expect(page.interruption_screen?).to eq(true)
  end

  it "has the correct informative_text" do
    expect(page.informative_text).to eq({
      "translation" => "soft_validations.staircase_owned.hint_text",
      "arguments" => [],
    })
  end

  it "has the correct interruption_screen_question_ids" do
    expect(page.interruption_screen_question_ids).to eq(%w[type stairowned])
  end

  context "when not a joint purchase" do
    it "has the correct title_text" do
      expect(page.title_text).to eq({
        "translation" => "soft_validations.staircase_owned.title_text.one",
        "arguments" => [
          {
            "key" => "stairowned",
            "label" => true,
            "i18n_template" => "stairowned",
          },
        ],
      })
    end
  end

  context "when a joint purchase" do
    let(:joint_purchase) { true }

    it "has the correct title_text" do
      expect(page.title_text).to eq({
        "translation" => "soft_validations.staircase_owned.title_text.two",
        "arguments" => [
          {
            "key" => "stairowned",
            "label" => true,
            "i18n_template" => "stairowned",
          },
        ],
      })
    end
  end
end
