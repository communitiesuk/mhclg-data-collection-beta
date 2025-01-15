require "rails_helper"
require_relative "helpers"

RSpec.describe "Form Page Routing" do
  include Helpers
  let(:user) { FactoryBot.create(:user) }
  let(:lettings_log) do
    FactoryBot.create(
      :lettings_log,
      :in_progress,
      assigned_to: user,
    )
  end
  let(:id) { lettings_log.id }
  let(:validator) { lettings_log._validators[nil].first }

  before do
    allow(lettings_log.form).to receive(:new_logs_end_date).and_return(Time.zone.today + 1.day)
    sign_in user
  end

  context "with 21/22 logs" do
    around do |example|
      Timecop.freeze(Time.zone.local(2022, 1, 1)) do
        Singleton.__init__(FormHandler)
        example.run
      end
      Timecop.return
      Singleton.__init__(FormHandler)
    end

    it "can route the user to a different page based on their answer on the current page", js: true do
      visit("/lettings-logs/#{id}/conditional-question")
      # using a question name that is already in the db to avoid
      # having to add a new column to the db for this test
      choose("lettings-log-preg-occ-1-field", allow_label_click: true)
      click_button("Save and continue")
      expect(page).to have_current_path("/lettings-logs/#{id}/conditional-question-yes-page")
      page.go_back
      expect(page).to have_current_path("/lettings-logs/#{id}/conditional-question")
      choose("lettings-log-preg-occ-2-field", allow_label_click: true)
      click_button("Save and continue")
      expect(page).to have_current_path("/lettings-logs/#{id}/conditional-question-no-page")
    end

    it "can route based on multiple conditions", js: true do
      visit("/lettings-logs/#{id}/person-1-gender")
      choose("lettings-log-sex1-f-field", allow_label_click: true)
      click_button("Save and continue")
      expect(page).to have_current_path("/lettings-logs/#{id}/person-1-working-situation")
      visit("/lettings-logs/#{id}/conditional-question")
      choose("lettings-log-preg-occ-2-field", allow_label_click: true)
      click_button("Save and continue")
      expect(page).to have_current_path("/lettings-logs/#{id}/conditional-question-no-page")
      choose("lettings-log-cbl-0-field", allow_label_click: true)
      click_button("Save and continue")
      expect(page).to have_current_path("/lettings-logs/#{id}/conditional-question/check-answers")
    end

    context "when the answers are inferred", js: true do
      it "shows question if the answer could not be inferred" do
        visit("/lettings-logs/#{id}/property-postcode")
        fill_in("lettings-log-postcode-full-field", with: "PO5 3TE")
        click_button("Save and continue")
        expect(page).to have_current_path("/lettings-logs/#{id}/do-you-know-the-local-authority")
      end

      it "shows question if the answer could not be inferred from an empty input" do
        visit("/lettings-logs/#{id}/property-postcode")
        click_button("Save and continue")
        expect(page).to have_current_path("/lettings-logs/#{id}/do-you-know-the-local-authority")
      end

      it "does not show question if the answer could be inferred" do
        stub_request(:get, /api\.postcodes\.io/)
          .to_return(status: 200, body: "{\"status\":200,\"result\":{\"admin_district\":\"Manchester\", \"codes\":{\"admin_district\": \"E08000003\"}}}", headers: {})

        visit("/lettings-logs/#{id}/property-postcode")
        fill_in("lettings-log-postcode-full-field", with: "P0 5ST")
        click_button("Save and continue")
        expect(page).to have_current_path("/lettings-logs/#{id}/property-wheelchair-accessible")
      end
    end

    context "when answer is invalid" do
      it "shows error with invalid value in the field" do
        visit("/lettings-logs/#{id}/property-postcode")
        fill_in("lettings-log-postcode-full-field", with: "FAKE_POSTCODE")
        click_button("Save and continue")

        expect(page).to have_current_path("/lettings-logs/#{id}/property-postcode")
        expect(find("#lettings-log-postcode-full-field-error").value).to eq("FAKE_POSTCODE")
      end

      it "does not reset the displayed date if it's an invalid date" do
        lettings_log.update!(startdate: "2021/10/13")
        visit("/lettings-logs/#{id}/tenancy-start-date")
        fill_in("lettings_log[startdate]", with: "0/32/202")
        click_button("Save and continue")

        expect(page).to have_current_path("/lettings-logs/#{id}/tenancy-start-date")
        expect(find_field("lettings_log[startdate]").value).to eq("13/10/2021")
      end

      it "displays the entered date if it's in a valid format" do
        lettings_log.update!(startdate: "2021/10/13")
        visit("/lettings-logs/#{id}/tenancy-start-date")
        fill_in("lettings_log[startdate]", with: "1/12/202")
        click_button("Save and continue")

        expect(page).to have_current_path("/lettings-logs/#{id}/tenancy-start-date")
        expect(find_field("lettings_log[startdate]").value).to eq("01/12/0202")
      end

      it "does not reset the displayed date if it's empty" do
        lettings_log.update!(startdate: nil)
        visit("/lettings-logs/#{id}/tenancy-start-date")
        fill_in("lettings_log[startdate]", with: "0/32/202")
        click_button("Save and continue")

        expect(page).to have_current_path("/lettings-logs/#{id}/tenancy-start-date")
        expect(find_field("lettings_log[startdate]").value).to eq(nil)
      end

      it "does not show see all related answers link if only 1 field has an error" do
        visit("/lettings-logs/#{id}/tenancy-start-date")
        fill_in("lettings_log[startdate]", with: "0/32/202")
        click_button("Save and continue")

        expect(page).not_to have_link("See all related answers")
      end
    end
  end

  context "when completing the setup section" do
    context "with a supported housing log" do
      let(:lettings_log) do
        FactoryBot.create(
          :lettings_log,
          owning_organisation: user.organisation,
          managing_organisation: user.organisation,
          assigned_to: user,
          needstype: 2,
        )
      end

      context "with a scheme with only 1 active location" do
        let(:scheme) { FactoryBot.create(:scheme, owning_organisation: user.organisation) }
        let!(:active_location) { FactoryBot.create(:location, scheme:) }

        before do
          FactoryBot.create(:location, scheme:, startdate: Time.zone.today + 20.days)
          visit("/lettings-logs/#{lettings_log.id}/scheme")
          select(scheme.service_name, from: "lettings_log[scheme_id]")
          click_button("Save and continue")
        end

        it "does not route to the scheme location question" do
          expect(page).to have_current_path("/lettings-logs/#{lettings_log.id}/renewal")
        end

        it "infers the scheme location" do
          expect(lettings_log.reload.location_id).to eq(active_location.id)
        end
      end
    end
  end

  describe "#depends_on_met" do
    it "returns true if there is no depends_on" do
      depends_on = nil

      expect(lettings_log.form.depends_on_met(depends_on, lettings_log)).to eq(true)
    end

    it "returns true if the depends_on is met" do
      depends_on = [{ "armedforces" => 1 }]
      lettings_log.armedforces = 1

      expect(lettings_log.form.depends_on_met(depends_on, lettings_log)).to eq(true)
    end

    it "returns false if the depends_on is not met" do
      depends_on = [{ "armedforces" => 1 }]
      lettings_log.armedforces = 0

      expect(lettings_log.form.depends_on_met(depends_on, lettings_log)).to eq(false)
    end

    it "returns true if a complex depends_on is met" do
      depends_on = [{ "is_la_inferred" => false, "is_general_needs?" => true }]
      lettings_log.is_la_inferred = false
      lettings_log.needstype = 1

      expect(lettings_log.form.depends_on_met(depends_on, lettings_log)).to eq(true)
    end

    it "returns false if any part of a complex depends_on is not met" do
      depends_on = [{ "is_la_inferred" => false, "is_general_needs?" => true }]
      lettings_log.is_la_inferred = false
      lettings_log.needstype = 2

      expect(lettings_log.form.depends_on_met(depends_on, lettings_log)).to eq(false)
    end

    it "returns true if the first of multiple depends_ons are met" do
      depends_on = [{ "is_la_inferred" => false }, { "is_general_needs?" => true }]
      lettings_log.is_la_inferred = false
      lettings_log.needstype = 2

      expect(lettings_log.form.depends_on_met(depends_on, lettings_log)).to eq(true)
    end

    it "returns true if the last of multiple depends_ons are met" do
      depends_on = [{ "is_la_inferred" => false }, { "is_general_needs?" => true }]
      lettings_log.is_la_inferred = true
      lettings_log.needstype = 1

      expect(lettings_log.form.depends_on_met(depends_on, lettings_log)).to eq(true)
    end

    context "with operator-based depends_ons" do
      it "returns true if an operator-based depends_on is met" do
        depends_on = [
          {
            "details_known_2" => 0,
            "age2" => {
              "operator" => ">",
              "operand" => 15,
            },
          },
          { "details_known_2" => 0, "age2" => nil },
        ]
        lettings_log.details_known_2 = 0
        lettings_log.age2 = 16

        expect(lettings_log.form.depends_on_met(depends_on, lettings_log)).to eq(true)
      end

      it "returns false if an operator-based depends_on is not met" do
        depends_on = [
          {
            "details_known_2" => 0,
            "age2" => {
              "operator" => ">",
              "operand" => 15,
            },
          },
          { "details_known_2" => 0, "age2" => nil },
        ]
        lettings_log.details_known_2 = 0
        lettings_log.age2 = 15

        expect(lettings_log.form.depends_on_met(depends_on, lettings_log)).to eq(false)
      end

      it "returns true if an operator-based depends_on is met on an inequality threshold" do
        depends_on = [
          {
            "details_known_2" => 0,
            "age2" => {
              "operator" => ">=",
              "operand" => 15,
            },
          },
          { "details_known_2" => 0, "age2" => nil },
        ]
        lettings_log.details_known_2 = 0
        lettings_log.age2 = 15

        expect(lettings_log.form.depends_on_met(depends_on, lettings_log)).to eq(true)
      end
    end
  end

  describe "composite validations" do
    context "when error is added to multiple fields" do
      before do
        lettings_log.update(needstype: 1, declaration: 1, ecstat1: 10, hhmemb: 2, net_income_known: 0, incfreq: 1, earnings: 1000)
      end

      it "does shows see all related answers link" do
        visit("/lettings-logs/#{id}/income-amount")
        fill_in("lettings-log-earnings-field", with: "100000")
        click_button("Save and continue")

        expect(page).to have_current_path("/lettings-logs/#{id}/income-amount")
        expect(page).to have_button("See all related answers")
      end
    end
  end
end
