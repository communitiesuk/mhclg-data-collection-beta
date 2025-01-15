require "rails_helper"
require_relative "helpers"

RSpec.describe "validations" do
  around do |example|
    Timecop.freeze(Time.zone.local(2022, 1, 1)) do
      Singleton.__init__(FormHandler)
      example.run
    end
    Timecop.return
    Singleton.__init__(FormHandler)
  end

  let(:fake_2021_2022_form) { Form.new("spec/fixtures/forms/2021_2022.json") }
  let(:user) { FactoryBot.create(:user) }
  let(:lettings_log) do
    FactoryBot.create(
      :lettings_log,
      :in_progress,
      assigned_to: user,
      renewal: 0,
    )
  end
  let(:empty_lettings_log) do
    FactoryBot.create(
      :lettings_log,
      assigned_to: user,
    )
  end
  let(:id) { lettings_log.id }

  before do
    allow(fake_2021_2022_form).to receive(:new_logs_end_date).and_return(Time.zone.today + 1.day)
    allow(lettings_log.form).to receive(:new_logs_end_date).and_return(Time.zone.today + 1.day)
    sign_in user
    allow(FormHandler.instance).to receive(:current_lettings_form).and_return(fake_2021_2022_form)
  end

  include Helpers

  describe "Question validation" do
    context "when the tenant age is invalid" do
      it "shows validation for under 0" do
        visit("/lettings-logs/#{id}/person-1-age")
        fill_in_number_question(empty_lettings_log.id, "age1", -5, "person-1-age")
        expect(page).to have_selector(".govuk-error-summary__title")
        expect(page).to have_selector("#lettings-log-age1-error")
        expect(page).to have_selector("#lettings-log-age1-field-error")
        expect(page).to have_title("Error")
      end

      it "shows validation for over 120" do
        visit("/lettings-logs/#{id}/person-1-age")
        fill_in_number_question(empty_lettings_log.id, "age1", 121, "person-1-age")
        expect(page).to have_selector(".govuk-error-summary__title")
        expect(page).to have_selector("#lettings-log-age1-error")
        expect(page).to have_selector("#lettings-log-age1-field-error")
        expect(page).to have_title("Error")
      end
    end
  end

  describe "date validation", js: true do
    def fill_in_date(lettings_log_id, question, day, month, year, path)
      visit("/lettings-logs/#{lettings_log_id}/#{path}")
      fill_in("lettings_log[#{question}]", with: [day, month, year].join("/"))
    end

    it "does not allow out of range dates to be submitted" do
      fill_in_date(id, "mrcdate", 3100, 12, 2000, "property-major-repairs")
      click_button("Save and continue")
      expect(page).to have_current_path("/lettings-logs/#{id}/property-major-repairs")

      fill_in_date(id, "mrcdate", 12, 1, 20_000, "property-major-repairs")
      click_button("Save and continue")
      expect(page).to have_current_path("/lettings-logs/#{id}/property-major-repairs")

      fill_in_date(id, "mrcdate", 13, 100, 2020, "property-major-repairs")
      click_button("Save and continue")
      expect(page).to have_current_path("/lettings-logs/#{id}/property-major-repairs")

      fill_in_date(id, "mrcdate", 21, 11, 2020, "property-major-repairs")
      click_button("Save and continue")
      expect(page).to have_current_path("/lettings-logs/#{id}/local-authority/check-answers")
    end

    it "does not allow non numeric inputs to be submitted" do
      fill_in_date(id, "mrcdate", "abc", "de", "ff", "property-major-repairs")
      click_button("Save and continue")
      expect(page).to have_current_path("/lettings-logs/#{id}/property-major-repairs")
    end

    it "does not allow partial inputs to be submitted" do
      fill_in_date(id, "mrcdate", 21, 12, nil, "property-major-repairs")
      click_button("Save and continue")
      expect(page).to have_current_path("/lettings-logs/#{id}/property-major-repairs")

      fill_in_date(id, "mrcdate", 12, nil, 2000, "property-major-repairs")
      click_button("Save and continue")
      expect(page).to have_current_path("/lettings-logs/#{id}/property-major-repairs")

      fill_in_date(id, "mrcdate", nil, 10, 2020, "property-major-repairs")
      click_button("Save and continue")
      expect(page).to have_current_path("/lettings-logs/#{id}/property-major-repairs")
    end

    it "allows valid inputs to be submitted" do
      fill_in_date(id, "mrcdate", 21, 11, 2020, "property-major-repairs")
      click_button("Save and continue")
      expect(page).to have_current_path("/lettings-logs/#{id}/local-authority/check-answers")
    end
  end

  describe "Soft Validation" do
    context "when a weekly net income is above the expected amount for the given economic status but below the hard max" do
      let(:lettings_log) do
        FactoryBot.create(
          :lettings_log,
          :in_progress,
          hhmemb: 1,
          ecstat1: 1,
          assigned_to: user,
        )
      end
      let(:income_over_soft_limit) { 750 }
      let(:income_under_soft_limit) { 700 }

      before do
        visit("/lettings-logs/#{lettings_log.id}/net-income")
        fill_in("lettings-log-earnings-field", with: income_over_soft_limit)
        choose("lettings-log-incfreq-1-field", allow_label_click: true)
        click_button("Save and continue")
      end

      it "prompts the user to confirm the value is correct with an interruption screen" do
        expect(page).to have_current_path("/lettings-logs/#{lettings_log.id}/net-income-value-check")
        expect(page).to have_content("You told us that the household’s income is £750.00 weekly")
        expect(page).to have_content("This is higher than we would expect for the household’s working situation.")
        expect(page).not_to have_button("Save changes")
        click_button("Confirm and continue")
        expect(page).to have_current_path("/lettings-logs/#{lettings_log.id}/net-income-uc-proportion")
      end

      it "allows to fix the questions that trigger the soft validation" do
        expect(page).to have_current_path("/lettings-logs/#{lettings_log.id}/net-income-value-check")
        expect(page).to have_link("Change", href: "/lettings-logs/#{lettings_log.id}/net-income?referrer=interruption_screen").twice
        expect(page).to have_link("Change", href: "/lettings-logs/#{lettings_log.id}/person-1-working-situation?referrer=interruption_screen")
        expect(page).to have_current_path("/lettings-logs/#{lettings_log.id}/net-income-value-check")
        click_link("Change", href: "/lettings-logs/#{lettings_log.id}/net-income?referrer=interruption_screen", match: :first)
        expect(page).to have_current_path("/lettings-logs/#{lettings_log.id}/net-income?referrer=interruption_screen")
        fill_in("lettings-log-earnings-field", with: income_under_soft_limit)
        choose("lettings-log-incfreq-1-field", allow_label_click: true)
        click_button("Save and continue")
        expect(page).to have_current_path("/lettings-logs/#{lettings_log.id}/net-income-value-check")
        expect(page).not_to have_content("You told us that the household’s income is £750.00 weekly")
        expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
      end

      it "allows to fix the questions from different sections" do
        expect(page).to have_current_path("/lettings-logs/#{lettings_log.id}/net-income-value-check")
        expect(page).to have_link("Change", href: "/lettings-logs/#{lettings_log.id}/net-income?referrer=interruption_screen").twice
        expect(page).to have_link("Change", href: "/lettings-logs/#{lettings_log.id}/person-1-working-situation?referrer=interruption_screen")
        expect(page).to have_current_path("/lettings-logs/#{lettings_log.id}/net-income-value-check")
        click_link("Change", href: "/lettings-logs/#{lettings_log.id}/person-1-working-situation?referrer=interruption_screen")
        expect(page).to have_current_path("/lettings-logs/#{lettings_log.id}/person-1-working-situation?referrer=interruption_screen")
        choose("lettings-log-ecstat1-10-field", allow_label_click: true)
        click_button("Save and continue")
        expect(page).to have_current_path("/lettings-logs/#{lettings_log.id}/net-income-value-check")
        expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
      end

      it "returns the user back to the check_your_answers after fixing a validation from check_your_answers" do
        lettings_log.update!(earnings: income_under_soft_limit, incfreq: 1, net_income_value_check: 1)
        visit("/lettings-logs/#{lettings_log.id}/income-and-benefits/check-answers")
        click_link("Change", href: "/lettings-logs/#{lettings_log.id}/net-income?referrer=check_answers", match: :first)
        expect(page).to have_current_path("/lettings-logs/#{lettings_log.id}/net-income?referrer=check_answers")
        fill_in("lettings-log-earnings-field", with: income_over_soft_limit)
        click_button("Save changes")
        expect(page).to have_current_path("/lettings-logs/#{lettings_log.id}/net-income-value-check?referrer=check_answers")
        click_link("Change", href: "/lettings-logs/#{lettings_log.id}/net-income?referrer=interruption_screen", match: :first)
        expect(page).to have_current_path("/lettings-logs/#{lettings_log.id}/net-income?referrer=interruption_screen")
        fill_in("lettings-log-earnings-field", with: income_under_soft_limit)
        click_button("Save and continue")
        expect(page).to have_current_path("/lettings-logs/#{lettings_log.id}/net-income-value-check?referrer=check_answers")
        click_button("Confirm and continue")
        expect(page).to have_current_path("/lettings-logs/#{lettings_log.id}/income-and-benefits/check-answers")
      end
    end
  end
end
