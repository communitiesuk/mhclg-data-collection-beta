require "rails_helper"

RSpec.describe Form::Lettings::Questions::ReferralGeneralNeeds, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page) }
  let(:subsection) { instance_double(Form::Subsection) }
  let(:form) { instance_double(Form, start_date: Time.zone.local(2023, 4, 1)) }

  before do
    allow(form).to receive(:start_year_2024_or_later?).and_return(false)
    allow(page).to receive(:subsection).and_return(subsection)
    allow(subsection).to receive(:form).and_return(form)
  end

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("referral")
  end

  it "has the correct type" do
    expect(question.type).to eq("radio")
  end

  it "has the correct check_answers_card_number" do
    expect(question.check_answers_card_number).to eq(0)
  end

  it "is not marked as derived" do
    expect(question).not_to be_derived(nil)
  end

  context "with 2023/24 form" do
    it "has the correct answer_options" do
      expect(question.answer_options).to eq({
        "1" => { "value" => "Internal transfer", "hint" => "Where the tenant has moved to another social property owned by the same landlord." },
        "2" => { "value" => "Tenant applied directly (no referral or nomination)" },
        "3" => { "value" => "Nominated by a local housing authority" },
        "4" => { "value" => "Referred by local authority housing department" },
        "8" => { "value" => "Re-located through official housing mobility scheme" },
        "10" => { "value" => "Other social landlord" },
        "9" => { "value" => "Community learning disability team" },
        "14" => { "value" => "Community mental health team" },
        "15" => { "value" => "Health service" },
        "12" => { "value" => "Police, probation or prison" },
        "7" => { "value" => "Voluntary agency" },
        "13" => { "value" => "Youth offending team" },
        "17" => { "value" => "Children’s Social Care" },
        "16" => { "value" => "Other" },
      })
    end

    it "has the correct question number" do
      expect(question.question_number).to eq(85)
    end
  end

  context "with 2024/25 form" do
    let(:form) { instance_double(Form, start_date: Time.zone.local(2024, 4, 1)) }

    before do
      allow(form).to receive(:start_year_2024_or_later?).and_return(true)
    end

    it "has the correct answer_options" do
      expect(question.answer_options).to eq({
        "1" => { "value" => "Internal transfer", "hint" => "Where the tenant has moved to another social property owned by the same landlord." },
        "2" => { "value" => "Tenant applied directly (no referral or nomination)" },
        "3" => { "value" => "Nominated by a local housing authority" },
        "8" => { "value" => "Re-located through official housing mobility scheme" },
        "10" => { "value" => "Other social landlord" },
        "9" => { "value" => "Community learning disability team" },
        "14" => { "value" => "Community mental health team" },
        "15" => { "value" => "Health service" },
        "18" => { "value" => "Police, probation, prison or youth offending team – tenant had custodial sentence" },
        "19" => { "value" => "Police, probation, prison or youth offending team – no custodial sentence" },
        "7" => { "value" => "Voluntary agency" },
        "17" => { "value" => "Children’s Social Care" },
        "16" => { "value" => "Other" },
      })
    end

    it "has the correct question number" do
      expect(question.question_number).to eq(84)
    end
  end
end
