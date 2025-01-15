require "rails_helper"
require_relative "helpers"

RSpec.describe "Lettings Log Check Answers Page" do
  around do |example|
    Timecop.freeze(Time.zone.local(2021, 5, 1)) do
      Singleton.__init__(FormHandler)
      example.run
    end
    Timecop.return
    Singleton.__init__(FormHandler)
  end

  include Helpers
  let(:user) { FactoryBot.create(:user) }
  let(:subsection) { "household-characteristics" }
  let(:conditional_subsection) { "conditional-question" }
  let(:scheme) { FactoryBot.create(:scheme, owning_organisation: user.organisation) }
  let(:location) { FactoryBot.create(:location, scheme:, mobility_type: "N", startdate: Time.zone.local(2021, 4, 1)) }

  let(:lettings_log) do
    FactoryBot.create(
      :lettings_log,
      :in_progress,
      assigned_to: user,
      needstype: 2,
      scheme:,
      location:,
    )
  end
  let(:empty_lettings_log) do
    FactoryBot.create(
      :lettings_log,
      previous_la_known: 1,
      prevloc: "E09000033",
      is_previous_la_inferred: false,
      assigned_to: user,
    )
  end
  let(:completed_lettings_log) do
    FactoryBot.create(
      :lettings_log,
      :completed,
      owning_organisation: user.organisation,
      managing_organisation: user.organisation,
      assigned_to: user,
      startdate: Time.zone.local(2021, 5, 1),
    )
  end
  let(:id) { lettings_log.id }
  let(:fake_2021_2022_form) { Form.new("spec/fixtures/forms/2021_2022.json") }

  before do
    allow(lettings_log.form).to receive(:new_logs_end_date).and_return(Time.zone.today + 1.day)
    allow(fake_2021_2022_form).to receive(:new_logs_end_date).and_return(Time.zone.today + 1.day)
    sign_in user
    allow(FormHandler.instance).to receive(:current_lettings_form).and_return(fake_2021_2022_form)
  end

  context "when the user needs to check their answers for a subsection" do
    let(:last_question_for_subsection) { "propcode" }

    it "can be visited by URL" do
      visit("/lettings-logs/#{id}/#{subsection}/check-answers")
      expect(page).to have_content("#{subsection.tr('-', ' ').humanize} Check your answers")
    end

    it "redirects to the check answers page when answering the last question and clicking save and continue" do
      fill_in_number_question(id, "propcode", 0, last_question_for_subsection)
      expect(page).to have_current_path("/lettings-logs/#{id}/#{subsection}/check-answers")
    end

    it "has question headings based on the subsection" do
      visit("/lettings-logs/#{id}/#{subsection}/check-answers")
      question_labels = ["Tenant code", "Lead tenant’s age", "Number of Household Members"]
      question_labels.each do |label|
        expect(page).to have_content(label)
      end
    end

    it "displays answers given by the user for the question in the subsection" do
      fill_in_number_question(empty_lettings_log.id, "age1", 28, "person-1-age")
      choose("lettings-log-sex1-x-field")
      click_button("Save and continue")
      visit("/lettings-logs/#{empty_lettings_log.id}/#{subsection}/check-answers")
      expect(page).to have_content("28")
      expect(page).to have_content("Non-binary")
    end

    # Regex explanation: match the string "Answer" but not if it's follow by "the missing questions"
    # This way only the links in the table will get picked up
    it "has an answer link with the check_answers_new_answer referrer for questions missing an answer" do
      visit("/lettings-logs/#{empty_lettings_log.id}/#{subsection}/check-answers?referrer=check_answers")
      assert_selector "a", text: "Change", count: 0
      expect(page).to have_link("Enter lead tenant’s age", href: "/lettings-logs/#{empty_lettings_log.id}/person-1-age?referrer=check_answers_new_answer")
    end

    it "has a change link for answered question" do
      fill_in_number_question(empty_lettings_log.id, "age1", 28, "person-1-age")
      visit("/lettings-logs/#{empty_lettings_log.id}/#{subsection}/check-answers")
      assert_selector "a", text: "Change", count: 1
      expect(page).to have_link("Change", href: "/lettings-logs/#{empty_lettings_log.id}/person-1-age?referrer=check_answers")
    end

    it "updates the add change link when answers get answered" do
      visit("/lettings-logs/#{empty_lettings_log.id}/household-needs/check-answers")
      assert_selector "a", text: "Change", count: 1
      visit("/lettings-logs/#{empty_lettings_log.id}/accessibility-requirements")
      check("lettings-log-accessibility-requirements-housingneeds-c-field")
      click_button("Save and continue")
      visit("/lettings-logs/#{empty_lettings_log.id}/household-needs/check-answers")
      assert_selector "a", text: "Change", count: 2
      expect(page).to have_link("Change", href: "/lettings-logs/#{empty_lettings_log.id}/accessibility-requirements?referrer=check_answers")
    end

    it "does not display conditional questions that were not visited" do
      visit("/lettings-logs/#{id}/#{conditional_subsection}/check-answers")
      question_labels = ["Has the condition been met?"]
      question_labels.each do |label|
        expect(page).to have_content(label)
      end

      excluded_question_labels = ["Has the next condition been met?", "Has the condition not been met?"]
      excluded_question_labels.each do |label|
        expect(page).not_to have_content(label)
      end
    end

    it "displays conditional question that were visited" do
      visit("/lettings-logs/#{id}/conditional-question")
      choose("lettings-log-preg-occ-2-field", allow_label_click: true)
      click_button("Save and continue")
      visit("/lettings-logs/#{id}/#{conditional_subsection}/check-answers")
      question_labels = ["Has the condition been met?", "Has the condition not been met?"]
      question_labels.each do |label|
        expect(page).to have_content(label)
      end

      excluded_question_labels = ["Has the next condition been met?"]
      excluded_question_labels.each do |label|
        expect(page).not_to have_content(label)
      end
    end

    it "does not group questions into summary cards if the questions in the subsection don't have a check_answers_card_number attribute" do
      visit("/lettings-logs/#{completed_lettings_log.id}/household-needs/check-answers")
      assert_selector ".govuk-summary-card__title", count: 0
    end

    context "when the user is checking their answers for the household characteristics subsection" do
      it "they see a separate summary card for each member of the household" do
        visit("/lettings-logs/#{completed_lettings_log.id}/#{subsection}/check-answers")
        assert_selector ".govuk-summary-card__title", text: "Lead tenant", count: 1
        assert_selector ".govuk-summary-card__title", text: "Person 2", count: 1
      end
    end

    context "when viewing setup section answers" do
      before do
        FactoryBot.create(:location, scheme:, startdate: Time.zone.local(2021, 1, 1))
      end

      it "displays inferred postcode with the location id" do
        lettings_log.update!(location:)
        visit("/lettings-logs/#{id}/setup/check-answers")
        expect(page).to have_content(location.name)
      end

      it "displays inferred postcode with the location_admin_district" do
        lettings_log.update!(location:)
        visit("/lettings-logs/#{id}/setup/check-answers")
        expect(page).to have_content(location.location_admin_district)
      end
    end

    context "when the user changes their answer from check answer page" do
      it "routes back to check answers" do
        visit("/lettings-logs/#{empty_lettings_log.id}/accessibility-requirements")
        check("lettings-log-accessibility-requirements-housingneeds-c-field")
        click_button("Save and continue")
        visit("/lettings-logs/#{empty_lettings_log.id}/household-needs/check-answers")
        first("a", text: /Change/).click
        uncheck("lettings-log-accessibility-requirements-housingneeds-c-field")
        check("lettings-log-accessibility-requirements-housingneeds-b-field")
        click_button("Save changes")
        expect(page).to have_current_path("/lettings-logs/#{empty_lettings_log.id}/household-needs/check-answers")
      end
    end

    context "when the user wants to bypass the tasklist page from check answers" do
      let(:section_completed_lettings_log) do
        FactoryBot.create(
          :lettings_log,
          :in_progress,
          assigned_to: user,
          tenancycode: "123",
          age1: 35,
          sex1: "M",
          hhmemb: 1,
        )
      end

      let(:next_section_in_progress_lettings_log) do
        FactoryBot.create(
          :lettings_log,
          :in_progress,
          assigned_to: user,
          tenancycode: "123",
          age1: 35,
          sex1: "M",
          hhmemb: 1,
          armedforces: 3,
          illness: 1,
        )
      end

      let(:skip_section_lettings_log) do
        FactoryBot.create(
          :lettings_log,
          :in_progress,
          assigned_to: user,
          tenancycode: "123",
          age1: 35,
          sex1: "M",
          hhmemb: 1,
          armedforces: 3,
          illness: 1,
          housingneeds_h: 1,
          la: "E06000014",
          illness_type_1: 1,
        )
      end

      let(:cycle_sections_lettings_log) do
        FactoryBot.create(
          :lettings_log,
          :in_progress,
          assigned_to: user,
          needstype: 1,
          tenancycode: nil,
          hhmemb: nil,
          age1: nil,
          layear: 2,
          waityear: 1,
          postcode_full: "NW1 5TY",
          reason: 4,
          ppostcode_full: "SE2 6RT",
          mrcdate: Time.zone.parse("03/11/2019"),
          renewal: 0,
        )
      end

      it "they can click a button to move onto the first page of the next (not started) incomplete section" do
        visit("/lettings-logs/#{section_completed_lettings_log.id}/household-characteristics/check-answers")
        click_link("Save and go to next incomplete section")
        expect(page).to have_current_path("/lettings-logs/#{section_completed_lettings_log.id}/armed-forces")
      end

      it "they can click a button to move onto the check answers page of the next (in progress) incomplete section" do
        visit("/lettings-logs/#{next_section_in_progress_lettings_log.id}/household-characteristics/check-answers")
        click_link("Save and go to next incomplete section")
        expect(page).to have_current_path("/lettings-logs/#{next_section_in_progress_lettings_log.id}/household-needs/check-answers")
      end

      it "they can click a button to skip sections until the next incomplete section" do
        visit("/lettings-logs/#{skip_section_lettings_log.id}/household-characteristics/check-answers")
        click_link("Save and go to next incomplete section")
        expect(page).to have_current_path("/lettings-logs/#{skip_section_lettings_log.id}/property-information/check-answers")
      end

      it "they can click a button to cycle around to the next incomplete section" do
        visit("/lettings-logs/#{cycle_sections_lettings_log.id}/declaration/check-answers")
        click_link("Save and go to next incomplete section")
        expect(page).to have_current_path("/lettings-logs/#{cycle_sections_lettings_log.id}/tenant-code-test")
      end
    end
  end
end
