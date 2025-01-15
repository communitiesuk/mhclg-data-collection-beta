require "rails_helper"

RSpec.describe CheckAnswersHelper do
  let(:lettings_log) { FactoryBot.build(:lettings_log) }
  let(:current_user) { FactoryBot.build(:user) }
  let(:subsection) { instance_double(Form::Subsection, form: lettings_log.form) }
  let(:questions) do
    [
      Form::Lettings::Questions::Hhmemb,
      Form::Lettings::Questions::Age1Known,
      Form::Lettings::Questions::Age1,
      Form::Lettings::Questions::GenderIdentity1,
    ].map { |q| q.new(nil, nil, instance_double(Form::Page, subsection:, routed_to?: true)) }
  end

  before do
    allow(subsection).to receive(:applicable_questions).and_return(questions)
  end

  describe "display_answered_questions_summary" do
    context "when a section hasn't been completed yet" do
      it "returns that you have unanswered questions" do
        expect(display_answered_questions_summary(subsection, lettings_log, current_user))
          .to match(/You have answered 0 of 4 questions./)
      end
    end

    context "when a section has been completed" do
      it "returns that you have answered all the questions" do
        lettings_log.sex1 = "F"
        lettings_log.hhmemb = 1
        lettings_log.age1_known = 1
        lettings_log.age1 = 18
        expect(display_answered_questions_summary(subsection, lettings_log, current_user))
          .to match(/You answered all the questions./)
        expect(display_answered_questions_summary(subsection, lettings_log, current_user))
          .not_to match(/href/)
      end
    end
  end

  describe "#get_answer_label" do
    context "when unanswered and bulk upload" do
      let(:question) { log.form.questions.sample }
      let(:bulk_upload) { create(:bulk_upload) }
      let(:log) { create(:sales_log, creation_method: "bulk upload", bulk_upload:) }

      it "is red" do
        expect(get_answer_label(question, log)).to include("red")
      end
    end
  end
end
