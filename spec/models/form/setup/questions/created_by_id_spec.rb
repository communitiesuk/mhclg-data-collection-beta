require "rails_helper"

RSpec.describe Form::Setup::Questions::CreatedById, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page) }
  let(:subsection) { instance_double(Form::Subsection) }
  let(:form) { instance_double(Form) }
  let!(:user_1) { FactoryBot.create(:user, name: "first user") }
  let!(:user_2) { FactoryBot.create(:user, name: "second user") }
  let!(:user_3) { FactoryBot.create(:user, name: nil, email: "madeupmail@example.com") }
  let(:expected_answer_options) do
    {
      "" => "Select an option",
      user_1.id => user_1.name,
      user_2.id => user_2.name,
      user_3.id => user_3.email,
    }
  end

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("created_by_id")
  end

  it "has the correct header" do
    expect(question.header).to eq("Which user are you creating this log for?")
  end

  it "has the correct check_answer_label" do
    expect(question.check_answer_label).to eq("User")
  end

  it "has the correct type" do
    expect(question.type).to eq("select")
  end

  it "has the correct hint_text" do
    expect(question.hint_text).to eq("")
  end

  it "has the correct answer options" do
    expect(question.answer_options).to eq(expected_answer_options)
  end

  it "is marked as derived" do
    expect(question.derived?).to be true
  end

  context "when the current user is support" do
    let(:support_user) { FactoryBot.build(:user, :support) }

    it "is shown in check answers" do
      expect(question.hidden_in_check_answers?(nil, support_user)).to be false
    end
  end

  context "when the current user is not support" do
    let(:user) { FactoryBot.build(:user) }

    it "is not shown in check answers" do
      expect(question.hidden_in_check_answers?(nil, user)).to be true
    end
  end

  context "when the owning organisation is already set" do
    let(:case_log) { FactoryBot.create(:case_log, owning_organisation: user_2.organisation) }
    let(:expected_answer_options) do
      {
        "" => "Select an option",
        user_2.id => user_2.name,
      }
    end

    it "only displays users that belong to that organisation" do
      expect(question.displayed_answer_options(case_log)).to eq(expected_answer_options)
    end
  end
end
