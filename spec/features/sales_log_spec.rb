require "rails_helper"

RSpec.describe "Sales Log Features" do
  context "when searching for specific sales logs" do
    context "when I am signed in and there are sales logs in the database" do
      let(:user) { FactoryBot.create(:user, last_sign_in_at: Time.zone.now, name: "Jimbo") }
      let!(:log_to_search) { FactoryBot.create(:sales_log, owning_organisation: user.organisation) }
      let!(:same_organisation_log) { FactoryBot.create(:sales_log, owning_organisation: user.organisation) }
      let!(:another_organisation_log) { FactoryBot.create(:sales_log) }

      before do
        sign_in user
        visit sales_logs_path
      end

      it "displays the logs belonging to the same organisation" do
        expect(page).to have_link(log_to_search.id.to_s)
        expect(page).to have_link(same_organisation_log.id.to_s)
        expect(page).not_to have_link(another_organisation_log.id.to_s)
      end

      context "when returning to the list of logs via breadcrumbs link" do
        before do
          click_button("Create a new sales log")
          find("a.govuk-breadcrumbs__link", text: "Sales logs").click
        end

        it "navigates you to the sales logs page" do
          expect(page).to have_current_path sales_logs_path
        end
      end

      context "when completing the setup sales log section" do
        it "includes the purchaser code and sale completion date questions" do
          click_button "Create a new sales log"
          click_link "Set up this sales log"
          fill_in("sales_log[saledate(1i)]", with: Time.zone.today.year)
          fill_in("sales_log[saledate(2i)]", with: Time.zone.today.month)
          fill_in("sales_log[saledate(3i)]", with: Time.zone.today.day)
          click_button "Save and continue"
          fill_in "sales_log[purchid]", with: "PC123"
          click_button "Save and continue"
          log_id = page.current_path.scan(/\d/).join
          visit sales_log_setup_check_answers_path(log_id)
          expect(page).to have_content "Sale completion date"
          expect(page).to have_content(Time.zone.today.year)
          expect(page).to have_content "Purchaser code"
          expect(page).to have_content "PC123"
        end
      end

      it "is possible to delete multiple logs" do
        log_card_selector = "article.app-log-summary"
        logs_by_user = create_list(:sales_log, 2, created_by: user)

        visit sales_logs_path
        expect(page).to have_selector log_card_selector, count: 4
        expect(page).not_to have_link "Delete logs"

        within ".app-filter" do
          choose "assigned-to-you-field"
          click_button
        end

        expect(page).to have_selector log_card_selector, count: 2
        expect(page).to have_link "Delete logs"

        click_link "Delete logs"

        expect(page).to have_current_path delete_logs_sales_logs_path

        rows = page.find_all "tbody tr"
        expect(rows.count).to be 2
        id_to_delete, id_to_keep = rows.map { |row| row.first("td").text.to_i }
        expect([id_to_delete, id_to_keep]).to match_array logs_by_user.map(&:id)
        check "forms-delete-logs-form-selected-ids-#{id_to_delete}-field"
        uncheck "forms-delete-logs-form-selected-ids-#{id_to_keep}-field"
        click_button "Continue"

        expect(page).to have_current_path delete_logs_confirmation_sales_logs_path
        expect(page.text).to include "You've selected 1 log to delete"
        button = page.find("form.button_to")
        expect(button[:action]).to eq delete_logs_sales_logs_path
        expect(button.text).to eq "Delete logs"
        click_button "Delete logs"

        expect(page).to have_current_path sales_logs_path
        expect(page).to have_selector "article.app-log-summary", count: 1
        expect(page.find("article.app-log-summary h2").text).to eq "Log #{id_to_keep}"
        deleted_log = SalesLog.find(id_to_delete)
        expect(deleted_log.status).to eq "deleted"
        expect(deleted_log.discarded_at).not_to be nil
      end
    end
  end

  context "when filtering logs" do
    let(:user) { create(:user, last_sign_in_at: Time.zone.now) }

    context "when I am signed in" do
      before do
        visit("/sales-logs")
        fill_in("user[email]", with: user.email)
        fill_in("user[password]", with: user.password)
        click_button("Sign in")
      end

      context "when no filters are selected" do
        it "displays the filters component with no clear button" do
          expect(page).to have_content("No filters applied")
          expect(page).not_to have_link("Clear", href: "/clear-filters?filter_type=sales_logs")
        end
      end

      context "when I have selected filters" do
        before do
          check("Not started")
          check("In progress")
          choose("You")
          click_button("Apply filters")
        end

        it "displays the filters component with a correct count and clear button" do
          expect(page).to have_content("3 filters applied")
          expect(page).to have_link("Clear", href: "/clear-filters?filter_type=sales_logs")
        end

        context "when clearing the filters" do
          before do
            click_link("Clear")
          end

          it "clears the filters and displays the filter component as before" do
            expect(page).to have_content("No filters applied")
            expect(page).not_to have_link("Clear", href: "/clear-filters?filter_type=sales_logs")
          end
        end
      end
    end
  end

  context "when signed in as a support user" do
    let(:devise_notify_mailer) { DeviseNotifyMailer.new }
    let(:notify_client) { instance_double(Notifications::Client) }
    let(:otp) { "999111" }
    let(:organisation) { FactoryBot.create(:organisation, name: "Big ORG") }
    let(:user) { FactoryBot.create(:user, :support, last_sign_in_at: Time.zone.now, organisation:) }
    let(:sales_log) { FactoryBot.create(:sales_log, :completed) }

    before do
      allow(DeviseNotifyMailer).to receive(:new).and_return(devise_notify_mailer)
      allow(devise_notify_mailer).to receive(:notify_client).and_return(notify_client)
      allow(notify_client).to receive(:send_email).and_return(true)
      allow(SecureRandom).to receive(:random_number).and_return(otp)
      visit("/sales-logs")
      fill_in("user[email]", with: user.email)
      fill_in("user[password]", with: user.password)
      click_button("Sign in")
      fill_in("code", with: otp)
      click_button("Submit")
    end

    context "when visiting a subsection check answers page as a support user" do
      it "has the correct breadcrumbs with the correct links" do
        visit sales_log_setup_check_answers_path(sales_log.id)
        breadcrumbs = page.find_all(".govuk-breadcrumbs__link")
        expect(breadcrumbs.first.text).to eq "Sales logs (DLUHC)"
        expect(breadcrumbs.first[:href]).to eq sales_logs_organisation_path(sales_log.owning_organisation)
        expect(breadcrumbs[1].text).to eq "Log #{sales_log.id}"
        expect(breadcrumbs[1][:href]).to eq sales_log_path(sales_log.id)
      end
    end

    context "when reviewing a complete log" do
      it "has the correct breadcrumbs with the correct links" do
        visit review_sales_log_path(sales_log.id, sales_log: true)
        breadcrumbs = page.find_all(".govuk-breadcrumbs__link")
        expect(breadcrumbs.first.text).to eq "Sales logs (DLUHC)"
        expect(breadcrumbs.first[:href]).to eq sales_logs_organisation_path(sales_log.owning_organisation)
        expect(breadcrumbs[1].text).to eq "Log #{sales_log.id}"
        expect(breadcrumbs[1][:href]).to eq sales_log_path(sales_log.id)
      end
    end
  end

  context "when a log becomes a duplicate" do
    let(:user) { create(:user, :data_coordinator) }
    let(:sales_log) { create(:sales_log, :duplicate, created_by: user) }
    let!(:duplicate_log) { create(:sales_log, :duplicate, created_by: user) }

    before do
      allow(user).to receive(:need_two_factor_authentication?).and_return(false)
      sign_in user
      sales_log.update!(purchid: "different")
      visit("/sales-logs/#{sales_log.id}/purchaser-code")
      fill_in("sales-log-purchid-field", with: duplicate_log.purchid)
      click_button("Save and continue")
    end

    it "allows keeping the original log and deleting duplicates" do
      sales_log.reload
      duplicate_log.reload
      expect(sales_log.duplicates.count).to eq(1)
      expect(duplicate_log.duplicates.count).to eq(1)
      expect(sales_log.duplicate_set_id).not_to be_nil
      expect(duplicate_log.duplicate_set_id).not_to be_nil
      expect(sales_log.duplicates).to include(duplicate_log)

      expect(page).to have_current_path("/sales-logs/#{sales_log.id}/duplicate-logs?original_log_id=#{sales_log.id}")
      click_link("Keep this log and delete duplicates", href: "/sales-logs/#{sales_log.id}/delete-duplicates?original_log_id=#{sales_log.id}")
      expect(page).to have_current_path("/sales-logs/#{sales_log.id}/delete-duplicates?original_log_id=#{sales_log.id}")
      click_button "Delete this log"
      duplicate_log.reload
      expect(duplicate_log.deleted?).to be true
      expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
      expect(page).to have_content("Log #{duplicate_log.id} has been deleted.")
      expect(page).to have_current_path("/sales-logs/#{sales_log.id}/duplicate-logs?organisation_id=&original_log_id=#{sales_log.id}&referrer=")
      expect(page).not_to have_content("These logs are duplicates")
      expect(page).not_to have_link("Keep this log and delete duplicates")
      expect(page).to have_link("Back to Log #{sales_log.id}", href: "/sales-logs/#{sales_log.id}")

      sales_log.reload
      duplicate_log.reload

      expect(sales_log.duplicates.count).to eq(0)
      expect(duplicate_log.duplicates.count).to eq(0)
      expect(sales_log.duplicate_set_id).to be_nil
      expect(duplicate_log.duplicate_set_id).to be_nil
    end

    it "allows changing answer on remaining original log" do
      click_link("Keep this log and delete duplicates", href: "/sales-logs/#{sales_log.id}/delete-duplicates?original_log_id=#{sales_log.id}")
      click_button "Delete this log"
      click_link("Change", href: "/sales-logs/#{sales_log.id}/purchaser-code?original_log_id=#{sales_log.id}&referrer=interruption_screen")
      click_button("Save and continue")
      expect(page).to have_current_path("/sales-logs/#{sales_log.id}/duplicate-logs?original_log_id=#{sales_log.id}")
      expect(page).to have_link("Back to Log #{sales_log.id}", href: "/sales-logs/#{sales_log.id}")
    end

    it "allows keeping the duplicate log and deleting the original one" do
      sales_log.reload
      duplicate_log.reload
      expect(sales_log.duplicates.count).to eq(1)
      expect(duplicate_log.duplicates.count).to eq(1)
      expect(sales_log.duplicate_set_id).not_to be_nil
      expect(duplicate_log.duplicate_set_id).not_to be_nil
      expect(duplicate_log.duplicates).to include(sales_log)

      expect(page).to have_current_path("/sales-logs/#{sales_log.id}/duplicate-logs?original_log_id=#{sales_log.id}")
      click_link("Keep this log and delete duplicates", href: "/sales-logs/#{duplicate_log.id}/delete-duplicates?original_log_id=#{sales_log.id}")
      expect(page).to have_current_path("/sales-logs/#{duplicate_log.id}/delete-duplicates?original_log_id=#{sales_log.id}")
      click_button "Delete this log"
      sales_log.reload
      expect(sales_log.status).to eq("deleted")
      expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
      expect(page).to have_content("Log #{sales_log.id} has been deleted.")
      expect(page).to have_current_path("/sales-logs/#{duplicate_log.id}/duplicate-logs?organisation_id=&original_log_id=#{sales_log.id}&referrer=")
      expect(page).not_to have_content("These logs are duplicates")
      expect(page).not_to have_link("Keep this log and delete duplicates")
      expect(page).to have_link("Back to sales logs", href: "/sales-logs")

      sales_log.reload
      duplicate_log.reload

      expect(sales_log.duplicates.count).to eq(0)
      expect(duplicate_log.duplicates.count).to eq(0)
      expect(sales_log.duplicate_set_id).to be_nil
      expect(duplicate_log.duplicate_set_id).to be_nil
    end

    it "allows changing answers on remaining duplicate log" do
      click_link("Keep this log and delete duplicates", href: "/sales-logs/#{duplicate_log.id}/delete-duplicates?original_log_id=#{sales_log.id}")
      click_button "Delete this log"
      click_link("Change", href: "/sales-logs/#{duplicate_log.id}/purchaser-code?original_log_id=#{sales_log.id}&referrer=interruption_screen")
      click_button("Save and continue")
      expect(page).to have_current_path("/sales-logs/#{duplicate_log.id}/duplicate-logs?original_log_id=#{sales_log.id}")
      expect(page).to have_link("Back to sales logs", href: "/sales-logs")
    end

    it "allows deduplicating logs by changing the answers on the duplicate log" do
      sales_log.reload
      duplicate_log.reload
      expect(sales_log.duplicates.count).to eq(1)
      expect(duplicate_log.duplicates.count).to eq(1)
      expect(sales_log.duplicate_set_id).not_to be_nil
      expect(duplicate_log.duplicate_set_id).not_to be_nil
      expect(sales_log.duplicates).to include(duplicate_log)

      expect(page).to have_current_path("/sales-logs/#{sales_log.id}/duplicate-logs?original_log_id=#{sales_log.id}")
      click_link("Change", href: "/sales-logs/#{duplicate_log.id}/purchaser-code?first_remaining_duplicate_id=#{sales_log.id}&original_log_id=#{sales_log.id}&referrer=duplicate_logs")
      fill_in("sales-log-purchid-field", with: "something else")
      click_button("Save changes")
      expect(page).to have_current_path("/sales-logs/#{sales_log.id}/duplicate-logs?original_log_id=#{sales_log.id}&referrer=duplicate_logs")
      expect(page).to have_link("Back to Log #{sales_log.id}", href: "/sales-logs/#{sales_log.id}")
      expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
      expect(page).to have_content("Log #{duplicate_log.id} is no longer a duplicate and has been removed from the list")
      expect(page).to have_content("You changed the purchaser code.")

      sales_log.reload
      duplicate_log.reload

      expect(sales_log.duplicates.count).to eq(0)
      expect(duplicate_log.duplicates.count).to eq(0)
      expect(sales_log.duplicate_set_id).to be_nil
      expect(duplicate_log.duplicate_set_id).to be_nil
    end

    it "allows deduplicating logs by changing the answers on the original log" do
      click_link("Change", href: "/sales-logs/#{sales_log.id}/purchaser-code?first_remaining_duplicate_id=#{duplicate_log.id}&original_log_id=#{sales_log.id}&referrer=duplicate_logs")
      fill_in("sales-log-purchid-field", with: "something else")
      click_button("Save changes")
      expect(page).to have_current_path("/sales-logs/#{duplicate_log.id}/duplicate-logs?original_log_id=#{sales_log.id}&referrer=duplicate_logs")
      expect(page).to have_link("Back to Log #{sales_log.id}", href: "/sales-logs/#{sales_log.id}")
      expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
      expect(page).to have_content("Log #{sales_log.id} is no longer a duplicate and has been removed from the list")
      expect(page).to have_content("You changed the purchaser code.")

      expect(sales_log.duplicates.count).to eq(0)
      expect(duplicate_log.duplicates.count).to eq(0)
      expect(sales_log.duplicate_set_id).to be_nil
      expect(duplicate_log.duplicate_set_id).to be_nil
    end
  end
end
