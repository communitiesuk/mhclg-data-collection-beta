require "rails_helper"
require_relative "helpers"

RSpec.describe "Form Navigation" do
  let(:now) { Time.zone.local(2022, 1, 1) }
  let(:user) { FactoryBot.create(:user) }
  let(:lettings_log) do
    FactoryBot.create(
      :lettings_log,
      :in_progress,
      owning_organisation: user.organisation,
      managing_organisation: user.organisation,
      assigned_to: user,
    )
  end
  let(:empty_lettings_log) do
    FactoryBot.create(
      :lettings_log,
      owning_organisation: user.organisation,
      managing_organisation: user.organisation,
      assigned_to: user,
    )
  end
  let(:id) { lettings_log.id }
  let(:question_answers) do
    {
      tenancycode: { type: "text", answer: "BZ737", path: "tenant-code-test" },
      age1: { type: "numeric", answer: 25, path: "person-1-age" },
      sex1: { type: "radio", answer: "Female", path: "person-1-gender" },
      ecstat1: { type: "radio", answer: 3, path: "person-1-working-situation" },
      hhmemb: { type: "numeric", answer: 1, path: "household-number-of-members" },
    }
  end
  let(:fake_2021_2022_form) { Form.new("spec/fixtures/forms/2021_2022.json") }

  around do |example|
    Timecop.travel(now) do
      Singleton.__init__(FormHandler)
      example.run
    end
    Timecop.return
    Singleton.__init__(FormHandler)
  end

  include Helpers

  before do
    allow(lettings_log.form).to receive(:new_logs_end_date).and_return(Time.zone.today + 1.day)
    allow(fake_2021_2022_form).to receive(:new_logs_end_date).and_return(Time.zone.today + 1.day)
    sign_in user
    allow(FormHandler.instance).to receive(:current_lettings_form).and_return(fake_2021_2022_form)
  end

  describe "Create a new lettings log" do
    it "redirects to the task list for the new log" do
      visit("/lettings-logs")
      click_button("Create a new lettings log")
      id = LettingsLog.order(created_at: :desc).first.id
      expect(page).to have_content("Log #{id}")
    end
  end

  describe "Viewing a log" do
    it "questions can be accessed by url" do
      visit("/lettings-logs/#{id}/person-1-age")
      expect(page).to have_field("lettings-log-age1-field")
    end

    it "a question page leads to the next unanswered question defined in the form definition" do
      pages = question_answers.map { |_key, val| val[:path] }
      pages[0..-2].each_with_index do |val, index|
        visit("/lettings-logs/#{empty_lettings_log.id}/#{val}")
        click_link("Skip for now")
        expect(page).to have_current_path("/lettings-logs/#{empty_lettings_log.id}/#{pages[index + 1]}")
      end
    end

    it "a question page has a Skip for now link that lets you move on to the next question without inputting anything" do
      visit("/lettings-logs/#{empty_lettings_log.id}/tenant-code-test")
      click_link(text: "Skip for now")
      expect(page).to have_current_path("/lettings-logs/#{empty_lettings_log.id}/person-1-age")
    end

    it "routes to check answers when skipping on the last page in the form" do
      visit("/lettings-logs/#{empty_lettings_log.id}/propcode")
      click_link(text: "Skip for now")
      expect(page).to have_current_path("/lettings-logs/#{empty_lettings_log.id}/household-characteristics/check-answers")
    end

    it "has correct breadcrumbs" do
      visit("/lettings-logs/#{id}/armed-forces")
      breadcrumbs = page.find_all(".govuk-breadcrumbs__link")
      expect(breadcrumbs.length).to eq 4
      expect(breadcrumbs[0].text).to eq "Home"
      expect(breadcrumbs[0][:href]).to eq root_path
      expect(breadcrumbs[1].text).to eq "Lettings logs"
      expect(breadcrumbs[1][:href]).to eq lettings_logs_path
      expect(breadcrumbs[2].text).to eq "Log #{lettings_log.id}"
      expect(breadcrumbs[2][:href]).to eq lettings_log_path(lettings_log)
      expect(breadcrumbs[3].text).to eq "Household needs"
      expect(breadcrumbs[3][:href]).to eq lettings_log_household_needs_check_answers_path(lettings_log)
    end
  end

  describe "Editing a log" do
    it "a question page has a link allowing you to cancel your input and return to the check answers page" do
      visit("lettings-logs/#{id}/tenant-code-test?referrer=check_answers")
      click_link(text: "Cancel")
      expect(page).to have_current_path("/lettings-logs/#{id}/household-characteristics/check-answers")
    end

    context "when clicking save and continue on a mandatory question with no input" do
      let(:id) { empty_lettings_log.id }

      it "shows a validation error on radio questions" do
        visit("/lettings-logs/#{id}/renewal")
        click_button("Save and continue")
        expect(page).to have_selector(".govuk-error-summary__title")
        expect(page).to have_selector("#lettings-log-renewal-error")
        expect(page).to have_title("Error")
      end

      it "shows a validation error on date questions" do
        visit("/lettings-logs/#{id}/tenancy-start-date")
        click_button("Save and continue")
        expect(page).to have_selector(".govuk-error-summary__title")
        expect(page).to have_selector("#lettings-log-startdate-error")
        expect(page).to have_title("Error")
      end

      context "when the page has a main and conditional question" do
        context "when the conditional question is required but not answered" do
          it "shows a validation error for the conditional question" do
            visit("/lettings-logs/#{id}/armed-forces")
            choose("lettings-log-armedforces-1-field", allow_label_click: true)
            click_button("Save and continue")
            expect(page).to have_selector(".govuk-error-summary__title")
            expect(page).to have_selector("#lettings-log-leftreg-error")
            expect(page).to have_title("Error")
          end
        end
      end
    end

    context "when clicking save and continue on an optional question with no input" do
      let(:id) { empty_lettings_log.id }

      it "does not show a validation error" do
        visit("/lettings-logs/#{id}/tenant-code")
        click_button("Save and continue")
        expect(page).not_to have_selector(".govuk-error-summary__title")
        expect(page).not_to have_title("Error")
        expect(page).to have_current_path("/lettings-logs/#{id}/property-reference")
      end
    end
  end

  describe "fixing duplicate logs" do
    let!(:lettings_log) { create(:lettings_log, :duplicate, assigned_to: user, duplicate_set_id: 1) }
    let!(:second_log) { create(:lettings_log, :duplicate, assigned_to: user, duplicate_set_id: 1) }

    it "shows a correct cancel link" do
      expect(lettings_log.duplicates.count).to eq(1)
      visit("lettings-logs/#{id}/tenant-code-test?first_remaining_duplicate_id=#{second_log.id}&original_log_id=#{id}&referrer=duplicate_logs")
      click_link(text: "Cancel")
      expect(page).to have_current_path("/lettings-logs/#{id}/duplicate-logs?original_log_id=#{id}")
      lettings_log.reload
      expect(lettings_log.duplicates.count).to eq(1)
    end

    it "shows a correct Save Changes buttons" do
      expect(lettings_log.duplicates.count).to eq(1)
      visit("lettings-logs/#{id}/tenant-code-test?first_remaining_duplicate_id=#{id}&original_log_id=#{id}&referrer=duplicate_logs")
      click_button(text: "Save changes")
      expect(page).to have_current_path("/lettings-logs/#{id}/duplicate-logs?original_log_id=#{id}&referrer=duplicate_logs")
      lettings_log.reload
      expect(lettings_log.duplicates.count).to eq(1)
    end

    it "shows back link to duplicate logs page instead of log breadcrumbs" do
      expect(lettings_log.duplicates.count).to eq(1)
      visit("lettings-logs/#{id}/tenant-code-test?first_remaining_duplicate_id=#{id}&original_log_id=#{id}&referrer=duplicate_logs")
      breadcrumbs = page.find_all(".govuk-breadcrumbs__link")
      expect(breadcrumbs.length).to eq 0
      click_link(text: "Back")
      expect(page).to have_current_path("/lettings-logs/#{id}/duplicate-logs?original_log_id=#{id}")
    end
  end
end
