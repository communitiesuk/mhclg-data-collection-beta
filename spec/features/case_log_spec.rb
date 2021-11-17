require "rails_helper"
RSpec.describe "Test Features" do
  let!(:case_log) { FactoryBot.create(:case_log, :in_progress) }
  let!(:empty_case_log) { FactoryBot.create(:case_log) }
  let(:id) { case_log.id }
  let(:status) { case_log.status }

  question_answers = {
    tenant_code: { type: "text", answer: "BZ737", path: "tenant_code" },
    age1: { type: "numeric", answer: 25, path: "person_1_age" },
    sex1: { type: "radio", answer: "Female", path: "person_1_gender" },
    other_hhmemb: { type: "numeric", answer: 2, path: "household_number_of_other_members" },
  }

  def fill_in_number_question(case_log_id, question, value, path)
    visit("/case_logs/#{case_log_id}/#{path}")
    fill_in("case-log-#{question.to_s.dasherize}-field", with: value)
    click_button("Save and continue")
  end

  def answer_all_questions_in_income_subsection
    visit("/case_logs/#{empty_case_log.id}/net_income")
    fill_in("case-log-earnings-field", with: 18_000)
    choose("case-log-incfreq-yearly-field")
    click_button("Save and continue")
    choose("case-log-benefits-all-field")
    click_button("Save and continue")
    choose("case-log-hb-housing-benefit-but-not-universal-credit-field")
    click_button("Save and continue")
  end

  describe "Create new log" do
    it "redirects to the task list for the new log" do
      visit("/case_logs")
      click_link("Create new log")
      id = CaseLog.order(created_at: :desc).first.id
      expect(page).to have_content("Tasklist for log #{id}")
    end
  end

  describe "Viewing a log" do
    context "tasklist page" do
      it "displays a tasklist header" do
        visit("/case_logs/#{id}")
        expect(page).to have_content("Tasklist for log #{id}")
        expect(page).to have_content("This submission is #{status.humanize.downcase}")
      end

      it "displays a section status" do
        visit("/case_logs/#{empty_case_log.id}")

        assert_selector ".govuk-tag", text: /Not started/, count: 8
        assert_selector ".govuk-tag", text: /Completed/, count: 0
        assert_selector ".govuk-tag", text: /Cannot start yet/, count: 1
      end

      it "shows the correct status if one section is completed" do
        answer_all_questions_in_income_subsection
        visit("/case_logs/#{empty_case_log.id}")

        assert_selector ".govuk-tag", text: /Not started/, count: 7
        assert_selector ".govuk-tag", text: /Completed/, count: 1
        assert_selector ".govuk-tag", text: /Cannot start yet/, count: 1
      end

      it "skips to the first section if no answers are completed" do
        visit("/case_logs/#{empty_case_log.id}")
        expect(page).to have_link("Skip to next incomplete section", href: /#household_characteristics/)
      end

      it "shows the number of completed sections if no sections are completed" do
        visit("/case_logs/#{empty_case_log.id}")
        expect(page).to have_content("You've completed 0 of 9 sections.")
      end

      it "shows the number of completed sections if one section is completed" do
        answer_all_questions_in_income_subsection
        visit("/case_logs/#{empty_case_log.id}")
        expect(page).to have_content("You've completed 1 of 9 sections.")
      end
    end

    describe "form questions" do
      let(:case_log_with_checkbox_questions_answered) do
        FactoryBot.create(
          :case_log, :in_progress,
          housingneeds_a: "Yes",
          housingneeds_c: "Yes"
        )
      end

      context "Validate pregnancy questions" do
        it "Cannot answer yes if no female tenants" do
          expect {
            CaseLog.create!(preg_occ: "Yes",
                            sex1: "Male",
                            age1: 20)
          }.to raise_error(ActiveRecord::RecordInvalid)
        end

        it "Cannot answer yes if no female tenants within age range" do
          expect {
            CaseLog.create!(preg_occ: "Yes",
                            sex1: "Female",
                            age1: 51)
          }.to raise_error(ActiveRecord::RecordInvalid)
        end

        it "Cannot answer prefer not to say if no valid tenants" do
          expect {
            CaseLog.create!(preg_occ: "Prefer not to say",
                            sex1: "Male",
                            age1: 20)
          }.to raise_error(ActiveRecord::RecordInvalid)
        end

        it "Can answer yes if valid tenants" do
          expect {
            CaseLog.create!(preg_occ: "Yes",
                            sex1: "Female",
                            age1: 20)
          }.not_to raise_error
        end

        it "Can answer yes if valid second tenant" do
          expect {
            CaseLog.create!(preg_occ: "Yes",
                            sex1: "Male", age1: 99,
                            sex2: "Female",
                            age2: 20)
          }.not_to raise_error
        end
      end

      it "can be accessed by url" do
        visit("/case_logs/#{id}/person_1_age")
        expect(page).to have_field("case-log-age1-field")
      end

      it "updates model attributes correctly for each question" do
        question_answers.each do |question, hsh|
          type = hsh[:type]
          answer = hsh[:answer]
          path = hsh[:path]
          original_value = case_log.send(question)
          visit("/case_logs/#{id}/#{path}")
          case type
          when "text"
            fill_in("case-log-#{question.to_s.dasherize}-field", with: answer)
          when "radio"
            choose("case-log-#{question.to_s.dasherize}-#{answer.parameterize}-field")
          else
            fill_in("case-log-#{question.to_s.dasherize}-field", with: answer)
          end
          expect { click_button("Save and continue") }.to change {
            case_log.reload.send(question.to_s)
          }.from(original_value).to(answer)
        end
      end

      it "updates total value of the rent", js: true do
        visit("/case_logs/#{id}/rent")

        fill_in("case-log-brent-field", with: 3)
        expect(page).to have_field("case-log-tcharge-field", with: "3")

        fill_in("case-log-scharge-field", with: 2)
        expect(page).to have_field("case-log-tcharge-field", with: "5")

        fill_in("case-log-pscharge-field", with: 1)
        expect(page).to have_field("case-log-tcharge-field", with: "6")

        fill_in("case-log-supcharg-field", with: 4)
        expect(page).to have_field("case-log-tcharge-field", with: "10")
      end

      it "displays number answers in inputs if they are already saved" do
        visit("/case_logs/#{id}/property_postcode")
        expect(page).to have_field("case-log-property-postcode-field", with: "P0 5ST")
      end

      it "displays text answers in inputs if they are already saved" do
        visit("/case_logs/#{id}/person_1_age")
        expect(page).to have_field("case-log-age1-field", with: "17")
      end

      it "displays checkbox answers in inputs if they are already saved" do
        visit("/case_logs/#{case_log_with_checkbox_questions_answered.id}/accessibility_requirements")
        # Something about our styling makes the selenium webdriver think the actual radio buttons are not visible so we pass false here
        expect(page).to have_checked_field(
          "case-log-accessibility-requirements-housingneeds-a-field",
          visible: false,
        )
        expect(page).to have_unchecked_field(
          "case-log-accessibility-requirements-housingneeds-b-field",
          visible: false,
        )
        expect(page).to have_checked_field(
          "case-log-accessibility-requirements-housingneeds-c-field",
          visible: false,
        )
      end
    end

    describe "Back link directs correctly", js: true do
      it "go back to tasklist page from tenant code" do
        visit("/case_logs/#{id}")
        visit("/case_logs/#{id}/tenant_code")
        click_link(text: "Back")
        expect(page).to have_content("Tasklist for log #{id}")
      end

      it "go back to tenant code page from tenant age page", js: true do
        visit("/case_logs/#{id}/tenant_code")
        click_button("Save and continue")
        visit("/case_logs/#{id}/person_1_age")
        click_link(text: "Back")
        expect(page).to have_field("case-log-tenant-code-field")
      end

      it "doesn't get stuck in infinite loops", js: true do
        visit("/case_logs")
        visit("/case_logs/#{id}/net_income")
        fill_in("case-log-earnings-field", with: 740)
        choose("case-log-incfreq-weekly-field", allow_label_click: true)
        click_button("Save and continue")
        click_link(text: "Back")
        click_link(text: "Back")
        expect(page).to have_current_path("/case_logs")
      end
    end
  end

  describe "Form flow is correct" do
    context "given an ordered list of pages" do
      it "leads to the next one in the correct order" do
        pages = question_answers.map { |_key, val| val[:path] }
        pages[0..-2].each_with_index do |val, index|
          visit("/case_logs/#{id}/#{val}")
          click_button("Save and continue")
          expect(page).to have_current_path("/case_logs/#{id}/#{pages[index + 1]}")
        end
      end

      context "when changing an answer from the check answers page", js: true do
        it "the back button routes correctly" do
          visit("/case_logs/#{id}/household_characteristics/check_answers")
          first("a", text: /Answer/).click
          click_link("Back")
          expect(page).to have_current_path("/case_logs/#{id}/household_characteristics/check_answers")
        end
      end
    end
  end

  describe "check answers page" do
    let(:subsection) { "household_characteristics" }
    let(:conditional_subsection) { "conditional_question" }

    context "when the user needs to check their answers for a subsection" do
      it "can be visited by URL" do
        visit("case_logs/#{id}/#{subsection}/check_answers")
        expect(page).to have_content("Check the answers you gave for #{subsection.tr('_', ' ')}")
      end

      let(:last_question_for_subsection) { "household_number_of_other_members" }
      it "redirects to the check answers page when answering the last question and clicking save and continue" do
        fill_in_number_question(id, "other_hhmemb", 0, last_question_for_subsection)
        expect(page).to have_current_path("/case_logs/#{id}/#{subsection}/check_answers")
      end

      it "has question headings based on the subsection" do
        visit("case_logs/#{id}/#{subsection}/check_answers")
        question_labels = ["Tenant code", "Tenant's age", "Tenant's gender", "Number of Other Household Members"]
        question_labels.each do |label|
          expect(page).to have_content(label)
        end
      end

      it "should display answers given by the user for the question in the subsection" do
        fill_in_number_question(empty_case_log.id, "age1", 28, "person_1_age")
        choose("case-log-sex1-non-binary-field")
        click_button("Save and continue")
        visit("/case_logs/#{empty_case_log.id}/#{subsection}/check_answers")
        expect(page).to have_content("28")
        expect(page).to have_content("Non-binary")
      end

      it "should have an answer link for questions missing an answer" do
        visit("case_logs/#{empty_case_log.id}/#{subsection}/check_answers")
        assert_selector "a", text: /Answer\z/, count: 4
        assert_selector "a", text: "Change", count: 0
        expect(page).to have_link("Answer", href: "/case_logs/#{empty_case_log.id}/person_1_age")
      end

      it "should have a change link for answered questions" do
        fill_in_number_question(empty_case_log.id, "age1", 28, "person_1_age")
        visit("/case_logs/#{empty_case_log.id}/#{subsection}/check_answers")
        assert_selector "a", text: /Answer\z/, count: 3
        assert_selector "a", text: "Change", count: 1
        expect(page).to have_link("Change", href: "/case_logs/#{empty_case_log.id}/person_1_age")
      end

      it "should have a change link for answered questions" do
        visit("/case_logs/#{empty_case_log.id}/household_needs/check_answers")
        assert_selector "a", text: /Answer\z/, count: 4
        assert_selector "a", text: "Change", count: 0
        visit("/case_logs/#{empty_case_log.id}/accessibility_requirements")
        check("case-log-accessibility-requirements-housingneeds-c-field")
        click_button("Save and continue")
        visit("/case_logs/#{empty_case_log.id}/household_needs/check_answers")
        assert_selector "a", text: /Answer\z/, count: 3
        assert_selector "a", text: "Change", count: 1
        expect(page).to have_link("Change", href: "/case_logs/#{empty_case_log.id}/accessibility_requirements")
      end

      it "should have a link pointing to the first question if no questions are answered" do
        visit("/case_logs/#{empty_case_log.id}/#{subsection}/check_answers")
        expect(page).to have_content("You answered 0 of 4 questions")
        expect(page).to have_link("Answer the missing questions", href: "/case_logs/#{empty_case_log.id}/tenant_code")
      end

      it "should have a link pointing to the next empty question if some questions are answered" do
        fill_in_number_question(empty_case_log.id, "earnings", 18_000, "net_income")

        visit("/case_logs/#{empty_case_log.id}/income_and_benefits/check_answers")
        expect(page).to have_content("You answered 1 of 4 questions")
        expect(page).to have_link("Answer the missing questions", href: "/case_logs/#{empty_case_log.id}/net_income")
      end

      it "should not display the missing answer questions link if all questions are answered" do
        answer_all_questions_in_income_subsection
        expect(page).to have_content("You answered all the questions")
        assert_selector "a", text: "Answer the missing questions", count: 0
      end

      it "does not display conditional questions that were not visited" do
        visit("case_logs/#{id}/#{conditional_subsection}/check_answers")
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
        visit("/case_logs/#{id}/conditional_question")
        choose("case-log-preg-occ-no-field")
        click_button("Save and continue")
        visit("/case_logs/#{id}/#{conditional_subsection}/check_answers")
        question_labels = ["Has the condition been met?", "Has the condition not been met?"]
        question_labels.each do |label|
          expect(page).to have_content(label)
        end

        excluded_question_labels = ["Has the next condition been met?"]
        excluded_question_labels.each do |label|
          expect(page).not_to have_content(label)
        end
      end
    end
  end

  describe "Conditional questions" do
    context "given a page where some questions are only conditionally shown, depending on how you answer the first question" do
      it "initially hides conditional questions" do
        visit("/case_logs/#{id}/armed_forces")
        expect(page).not_to have_selector("#armed_forces_injured_div")
      end

      it "shows conditional questions if the required answer is selected and hides it again when a different answer option is selected", js: true do
        visit("/case_logs/#{id}/armed_forces")
        # Something about our styling makes the selenium webdriver think the actual radio buttons are not visible so we allow label click here
        choose("case-log-armed-forces-yes-a-regular-field", allow_label_click: true)
        expect(page).to have_selector("#reservist_div")
        choose("case-log-reservist-no-field", allow_label_click: true)
        expect(page).to have_checked_field("case-log-reservist-no-field", visible: false)
        choose("case-log-armed-forces-no-field", allow_label_click: true)
        expect(page).not_to have_selector("#reservist_div")
        choose("case-log-armed-forces-yes-a-regular-field", allow_label_click: true)
        expect(page).to have_unchecked_field("case-log-reservist-no-field", visible: false)
      end
    end
  end

  describe "Question validation" do
    context "given an invalid tenant age" do
      it " of less than 0 it shows validation" do
        visit("/case_logs/#{id}/person_1_age")
        fill_in_number_question(empty_case_log.id, "age1", -5, "person_1_age")
        expect(page).to have_selector("#error-summary-title")
        expect(page).to have_selector("#case-log-age1-error")
        expect(page).to have_selector("#case-log-age1-field-error")
      end

      it " of greater than 120 it shows validation" do
        visit("/case_logs/#{id}/person_1_age")
        fill_in_number_question(empty_case_log.id, "age1", 121, "person_1_age")
        expect(page).to have_selector("#error-summary-title")
        expect(page).to have_selector("#case-log-age1-error")
        expect(page).to have_selector("#case-log-age1-field-error")
      end
    end
  end

  describe "Soft Validation" do
    context "given a weekly net income that is above the expected amount for the given economic status but below the hard max" do
      let(:case_log) { FactoryBot.create(:case_log, :in_progress, ecstat1: "Full-time - 30 hours or more") }
      let(:income_over_soft_limit) { 750 }
      let(:income_under_soft_limit) { 700 }

      it "prompts the user to confirm the value is correct", js: true do
        visit("/case_logs/#{case_log.id}/net_income")
        fill_in("case-log-earnings-field", with: income_over_soft_limit)
        choose("case-log-incfreq-weekly-field", allow_label_click: true)
        click_button("Save and continue")
        expect(page).to have_content("Are you sure this is correct?")
        check("case-log-override-net-income-validation-override-net-income-validation-field", allow_label_click: true)
        click_button("Save and continue")
        expect(page).to have_current_path("/case_logs/#{case_log.id}/net_income_uc_proportion")
      end

      it "does not require confirming the value if the value is amended" do
        visit("/case_logs/#{case_log.id}/net_income")
        fill_in("case-log-earnings-field", with: income_over_soft_limit)
        choose("case-log-incfreq-weekly-field", allow_label_click: true)
        click_button("Save and continue")
        fill_in("case-log-earnings-field", with: income_under_soft_limit)
        click_button("Save and continue")
        expect(page).to have_current_path("/case_logs/#{case_log.id}/net_income_uc_proportion")
        case_log.reload
        expect(case_log.override_net_income_validation).to be_nil
      end

      it "clears the confirmation question if the amount was amended and the page is returned to using the back button", js: true do
        visit("/case_logs/#{case_log.id}/net_income")
        fill_in("case-log-earnings-field", with: income_over_soft_limit)
        choose("case-log-incfreq-weekly-field", allow_label_click: true)
        click_button("Save and continue")
        fill_in("case-log-earnings-field", with: income_under_soft_limit)
        click_button("Save and continue")
        click_link(text: "Back")
        expect(page).to have_no_content("Are you sure this is correct?")
      end

      it "does not clear the confirmation question if the page is returned to using the back button and the amount is still over the soft limit", js: true do
        visit("/case_logs/#{case_log.id}/net_income")
        fill_in("case-log-earnings-field", with: income_over_soft_limit)
        choose("case-log-incfreq-weekly-field", allow_label_click: true)
        click_button("Save and continue")
        check("case-log-override-net-income-validation-override-net-income-validation-field", allow_label_click: true)
        click_button("Save and continue")
        click_link(text: "Back")
        expect(page).to have_content("Are you sure this is correct?")
      end
    end
  end

  describe "conditional page routing", js: true do
    before do
      allow_any_instance_of(CaseLogValidator).to receive(:validate_pregnancy).and_return(true)
    end

    it "can route the user to a different page based on their answer on the current page" do
      visit("case_logs/#{id}/conditional_question")
      # using a question name that is already in the db to avoid
      # having to add a new column to the db for this test
      choose("case-log-preg-occ-yes-field", allow_label_click: true)
      click_button("Save and continue")
      expect(page).to have_current_path("/case_logs/#{id}/conditional_question_yes_page")
      click_link(text: "Back")
      expect(page).to have_current_path("/case_logs/#{id}/conditional_question")
      choose("case-log-preg-occ-no-field", allow_label_click: true)
      click_button("Save and continue")
      expect(page).to have_current_path("/case_logs/#{id}/conditional_question_no_page")
    end

    it "can route based on multiple conditions" do
      visit("/case_logs/#{id}/person_1_gender")
      choose("case-log-sex1-female-field", allow_label_click: true)
      click_button("Save and continue")
      expect(page).to have_current_path("/case_logs/#{id}/household_number_of_other_members")
      visit("/case_logs/#{id}/conditional_question")
      choose("case-log-preg-occ-no-field", allow_label_click: true)
      click_button("Save and continue")
      expect(page).to have_current_path("/case_logs/#{id}/conditional_question_no_page")
      click_button("Save and continue")
      expect(page).to have_current_path("/case_logs/#{id}/conditional_question/check_answers")
    end
  end

  describe "date validation", js: true do
    def fill_in_date(case_log_id, question, day, month, year, path)
      visit("/case_logs/#{case_log_id}/#{path}")
      fill_in("#{question}_1i", with: year)
      fill_in("#{question}_2i", with: month)
      fill_in("#{question}_3i", with: day)
    end
    it "does not allow out of range dates to be submitted" do
      fill_in_date(id, "case_log_mrcdate", 3100, 12, 2000, "property_major_repairs")
      click_button("Save and continue")
      expect(page).to have_current_path("/case_logs/#{id}/property_major_repairs")

      fill_in_date(id, "case_log_mrcdate", 12, 1, 20_000, "property_major_repairs")
      click_button("Save and continue")
      expect(page).to have_current_path("/case_logs/#{id}/property_major_repairs")

      fill_in_date(id, "case_log_mrcdate", 13, 100, 2020, "property_major_repairs")
      click_button("Save and continue")
      expect(page).to have_current_path("/case_logs/#{id}/property_major_repairs")

      fill_in_date(id, "case_log_mrcdate", 21, 11, 2020, "property_major_repairs")
      click_button("Save and continue")
      expect(page).to have_current_path("/case_logs/#{id}/local_authority/check_answers")
    end

    it "does not allow non numeric inputs to be submitted" do
      fill_in_date(id, "case_log_mrcdate", "abc", "de", "ff", "property_major_repairs")
      click_button("Save and continue")
      expect(page).to have_current_path("/case_logs/#{id}/property_major_repairs")
    end

    it "does not allow partial inputs to be submitted" do
      fill_in_date(id, "case_log_mrcdate", 21, 12, nil, "property_major_repairs")
      click_button("Save and continue")
      expect(page).to have_current_path("/case_logs/#{id}/property_major_repairs")

      fill_in_date(id, "case_log_mrcdate", 12, nil, 2000, "property_major_repairs")
      click_button("Save and continue")
      expect(page).to have_current_path("/case_logs/#{id}/property_major_repairs")

      fill_in_date(id, "case_log_mrcdate", nil, 10, 2020, "property_major_repairs")
      click_button("Save and continue")
      expect(page).to have_current_path("/case_logs/#{id}/property_major_repairs")
    end

    it "allows valid inputs to be submitted" do
      fill_in_date(id, "case_log_mrcdate", 21, 11, 2020, "property_major_repairs")
      click_button("Save and continue")
      expect(page).to have_current_path("/case_logs/#{id}/local_authority/check_answers")
    end
  end
end
