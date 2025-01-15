require "rails_helper"

RSpec.describe Form::Sales::Questions::UprnKnown, type: :model do
  include FormattingHelper

  subject(:question) { described_class.new(question_id, question_definition, page) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page, subsection: instance_double(Form::Subsection, form: instance_double(Form, start_date: Time.zone.local(2023, 4, 1)))) }

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("uprn_known")
  end

  it "has the correct type" do
    expect(question.type).to eq("radio")
  end

  it "is not marked as derived" do
    expect(question.derived?(nil)).to be false
  end

  it "has the correct answer_options" do
    expect(question.answer_options).to eq({
      "0" => { "value" => "No" },
      "1" => { "value" => "Yes" },
    })
  end

  it "has correct conditional for" do
    expect(question.conditional_for).to eq({ "uprn" => [1] })
  end

  it "has the correct unanswered_error_message" do
    expect(question.unanswered_error_message).to eq(I18n.t("validations.sales.property_information.uprn_known.invalid"))
  end

  it "has the correct hidden_in_check_answers" do
    expect(question.hidden_in_check_answers).to eq({
      "depends_on" => [
        { "uprn_known" => 0 },
        { "uprn_known" => 1 },
      ],
    })
  end

  it "has the correct inferred_check_answers_value" do
    expect(question.inferred_check_answers_value).to eq([
      {
        "condition" => { "uprn_known" => 0 },
        "value" => "Not known",
      },
    ])
  end
end
