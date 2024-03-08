require "rails_helper"

RSpec.describe Form::Sales::Questions::PreviousLaKnown, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page, subsection: instance_double(Form::Subsection, form: instance_double(Form, start_date: Time.zone.local(2023, 4, 1)))) }

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("previous_la_known")
  end

  it "has the correct header" do
    expect(question.header).to eq("Do you know the local authority of buyer 1’s last settled accommodation?")
  end

  it "has the correct check_answer_label" do
    expect(question.check_answer_label).to eq("Local authority of buyer 1’s last settled accommodation")
  end

  it "has the correct type" do
    expect(question.type).to eq("radio")
  end

  it "is not marked as derived" do
    expect(question.derived?).to be false
  end

  it "has the correct answer_options" do
    expect(question.answer_options).to eq({
      "1" => { "value" => "Yes" },
      "0" => { "value" => "No" },
    })
  end

  it "has the correct hidden_in_check_answers" do
    expect(question.hidden_in_check_answers).to eq(
      {
        "depends_on" => [
          {
            "previous_la_known" => 0,
          },
          {
            "previous_la_known" => 1,
          },
        ],
      },
    )
  end

  it "has correct conditional_for" do
    expect(question.conditional_for).to eq({
      "prevloc" => [1],
    })
  end

  it "has the correct hint" do
    expect(question.hint_text).to eq("This is also known as the household’s 'last settled home'")
  end
end
