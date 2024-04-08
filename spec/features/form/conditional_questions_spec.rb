require "rails_helper"
require_relative "helpers"

RSpec.describe "Form Conditional Questions" do
  around do |example|
    Timecop.freeze(Time.zone.local(2022, 1, 1)) do
      Singleton.__init__(FormHandler)
      example.run
    end
    Timecop.return
    Singleton.__init__(FormHandler)
  end

  include Helpers
  let(:user) { FactoryBot.create(:user) }
  let(:lettings_log) do
    FactoryBot.create(
      :lettings_log,
      :in_progress,
      assigned_to: user,
    )
  end
  let(:sales_log) do
    FactoryBot.create(
      :sales_log,
      :completed,
      assigned_to: user,
      saledate: Time.zone.local(2022, 1, 1),
    )
  end
  let(:id) { lettings_log.id }
  let(:fake_2021_2022_form) { Form.new("spec/fixtures/forms/2021_2022.json") }

  before do
    sign_in user
  end

  context "with a page where some questions are only conditionally shown, depending on how you answer the first question" do
    before do
      allow(sales_log.form).to receive(:new_logs_end_date).and_return(Time.zone.today + 1.day)
      allow(lettings_log.form).to receive(:new_logs_end_date).and_return(Time.zone.today + 1.day)
      allow(FormHandler.instance).to receive(:current_lettings_form).and_return(fake_2021_2022_form)
    end

    it "initially hides conditional questions" do
      visit("/lettings-logs/#{id}/armed-forces")
      expect(page).not_to have_selector("#armed_forces_injured_div")
    end

    it "shows conditional questions if the required answer is selected and hides it again when a different answer option is selected", js: true do
      visit("/lettings-logs/#{id}/armed-forces")
      # Something about our styling makes the selenium webdriver think the actual radio buttons are not visible so we allow label click here
      choose("lettings-log-armedforces-1-field", allow_label_click: true)
      fill_in("lettings-log-leftreg-field", with: "text")
      choose("lettings-log-armedforces-4-field", allow_label_click: true)
      expect(page).not_to have_field("lettings-log-leftreg-field")
      choose("lettings-log-armedforces-1-field", allow_label_click: true)
      expect(page).to have_field("lettings-log-leftreg-field", with: "")
    end
  end

  context "when a conditional question has a saved answer", js: true do
    before do
      allow(sales_log.form).to receive(:new_logs_end_date).and_return(Time.zone.today + 1.day)
      allow(lettings_log.form).to receive(:new_logs_end_date).and_return(Time.zone.today + 1.day)
      allow(FormHandler.instance).to receive(:current_lettings_form).and_return(fake_2021_2022_form)
    end

    it "is displayed correctly" do
      lettings_log.update!(postcode_known: 1, postcode_full: "NW1 6RT")
      visit("/lettings-logs/#{id}/property-postcode")
      expect(page).to have_field("lettings-log-postcode-full-field", with: "NW1 6RT")
    end

    it "gets cleared if the conditional question is hidden after editing the answer" do
      sales_log.update!(age1_known: 0, age1: 50)
      visit("/sales-logs/#{sales_log.id}/buyer-1-age")
      expect(page).to have_field("sales-log-age1-field", with: 50)

      choose("sales-log-age1-known-1-field", allow_label_click: true)
      choose("sales-log-age1-known-0-field", allow_label_click: true)
      expect(page).to have_field("sales-log-age1-field", with: "")
    end
  end

  context "when a conditional question has an error" do
    let(:lettings_log) do
      FactoryBot.create(
        :lettings_log,
        :completed,
        assigned_to: user,
      )
    end

    before do
      FormHandler.instance.use_real_forms!
    end

    it "shows conditional questions if the required answer is selected and hides it again when a different answer option is selected", js: true do
      visit("/lettings-logs/#{id}/lead-tenant-age")
      choose("lettings-log-age1-known-0-field", allow_label_click: true)
      fill_in("lettings-log-age1-field", with: "200")
      click_button("Save and continue")
      expect(page).not_to have_field("lettings-log-age1-field")
      expect(page).to have_field("lettings-log-age1-field-error")
      choose("lettings-log-age1-known-1-field", allow_label_click: true)
      expect(page).not_to have_field("lettings-log-age1-field")
      expect(page).not_to have_field("lettings-log-age1-field-error")
      choose("lettings-log-age1-known-0-field", allow_label_click: true)
      expect(page).not_to have_field("lettings-log-age1-field")
      expect(page).to have_field("lettings-log-age1-field-error", with: "")
    end
  end
end
