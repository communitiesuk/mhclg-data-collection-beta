require "rails_helper"

RSpec.describe CheckAnswersSummaryListCardComponent, type: :component do
  subject(:component) { described_class.new(questions:, log:, user:) }

  let(:rendered) { render_inline(component) }

  let(:user) { create(:user) }
  let(:log) { create(:lettings_log, :completed, sex1: "F", age2: 99, retirement_value_check: 1) }
  let(:subsection_id) { "household_characteristics" }
  let(:subsection) { log.form.get_subsection(subsection_id) }
  let(:questions) { subsection.applicable_questions(log) }

  it "renders a summary list card including question numbers for the answers to those questions" do
    expect(rendered).to have_content(questions.first.answer_label(log))
    expect(rendered).to match(/Q\d+ - Lead tenant’s age/)
  end

  it "applicable questions doesn't return questions that are hidden in check answers" do
    expect(component.applicable_questions.map(&:id).include?("retirement_value_check")).to eq(false)
  end

  it "has the correct answer label for a question" do
    sex1_question = questions.find { |q| q.id == "sex1" }
    expect(component.get_answer_label(sex1_question)).to eq("Female")
  end

  context "when log was created via a bulk upload and has an unanswered question" do
    let(:bulk_upload) { create(:bulk_upload) }
    let(:log) { create(:lettings_log, :in_progress, creation_method: "bulk upload", age2: 99, bulk_upload:) }

    it "displays red prompt link for required question" do
      expect(rendered).to have_link(log.form.get_question("age1_known", log).check_answer_prompt, href: "/lettings-logs/#{log.id}/lead-tenant-age?referrer=check_answers_new_answer", class: "app-red-link app-red-link---no-visited-state")
    end
  end

  context "when log was imported with a bulk upload creation method, without bulk upload id and has an unanswered question" do
    let(:log) { create(:lettings_log, :in_progress, creation_method: "bulk upload", age2: 99, bulk_upload_id: nil) }

    it "displays tweaked copy in red" do
      expect(rendered).not_to have_selector("span", class: "app-!-colour-red", text: "You still need to answer this question")
    end
  end

  context "when log was not created via a bulk upload and has an unanswered question" do
    let(:log) { create(:lettings_log, :in_progress) }

    it "displays normal copy with muted colour " do
      expect(rendered).to have_link(log.form.get_question("sex1", log).check_answer_prompt, href: "/lettings-logs/#{log.id}/lead-tenant-gender-identity?referrer=check_answers_new_answer", class: "govuk-link govuk-link--no-visited-state")
    end
  end

  context "when log was created via a bulk upload and has an unanswered optional question" do
    let(:subsection_id) { "setup" }
    let(:bulk_upload) { create(:bulk_upload) }
    let(:log) { create(:lettings_log, :completed, creation_method: "bulk upload", needstype: nil, tenancycode: nil, bulk_upload:) }

    it "displays red prompt link for required question" do
      expect(rendered).to have_no_link(log.form.get_question("needstype", log).check_answer_prompt, href: "/lettings-logs/#{log.id}/needs-type?referrer=check_answers_new_answer", class: "govuk-link govuk-link--no-visited-state")
      expect(rendered).to have_link(log.form.get_question("needstype", log).check_answer_prompt, href: "/lettings-logs/#{log.id}/needs-type?referrer=check_answers_new_answer", class: "app-red-link app-red-link---no-visited-state")
    end

    it "displays regular link for optional question" do
      expect(rendered).to have_link(log.form.get_question("tenancycode", log).check_answer_prompt, href: "/lettings-logs/#{log.id}/tenant-code?referrer=check_answers_new_answer", class: "govuk-link govuk-link--no-visited-state")
    end
  end

  context "when before 23/24 collection" do
    context "when given a set of questions" do
      let(:log) { create(:lettings_log, :completed, :ignore_validation_errors, age2: 99, startdate: Time.zone.local(2021, 5, 1), assigned_to: create(:user)) }

      it "renders a summary list card without question numbers for the answers to those questions" do
        expect(rendered).to have_content(questions.first.answer_label(log))
        expect(rendered).to have_content("Lead tenant’s age")
        expect(rendered).not_to include(" - Lead tenant’s age")
      end
    end
  end
end
