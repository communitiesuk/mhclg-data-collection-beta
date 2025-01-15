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
          date = Time.zone.today.strftime("%d/%m/%Y")
          fill_in("sales_log[saledate]", with: date)
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
        logs_by_user = create_list(:sales_log, 2, assigned_to: user)

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

  context "when downloading logs" do
    let(:user) { create(:user, :support) }
    let(:other_user) { create(:user, organisation: user.organisation) }
    let(:current_year) { FormHandler.instance.current_sales_form.start_date.year }

    context "when I am signed in" do
      before do
        create(:sales_log, :in_progress, owning_organisation: user.organisation, assigned_to: user)
        create(:sales_log, :in_progress, owning_organisation: user.organisation, assigned_to: other_user)
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        visit("/sales-logs?search=1")
      end

      context "when no filters are selected" do
        it "requires year filter to be selected for non codes download" do
          click_link("Download (CSV)")
          expect(page).to have_current_path("/sales-logs/filters/years?codes_only=false&search=1")
          click_button("Save changes")

          expect(page).to have_selector(".govuk-error-summary__title")
          expect(page).to have_content("There is a problem")

          choose("years-2023-field", allow_label_click: true)
          click_button("Save changes")

          expect(page).to have_current_path("/sales-logs/csv-download?codes_only=false&search=1")
        end

        it "requires year filter to be selected for codes only download" do
          click_link("Download (CSV, codes only)")
          expect(page).to have_current_path("/sales-logs/filters/years?codes_only=true&search=1")
          click_button("Save changes")

          expect(page).to have_selector(".govuk-error-summary__title")
          expect(page).to have_content("There is a problem")

          choose("years-2023-field", allow_label_click: true)
          click_button("Save changes")

          expect(page).to have_current_path("/sales-logs/csv-download?codes_only=true&search=1")
        end

        it "allows cancelling the download without selecting the year filter" do
          click_link("Download (CSV)")

          click_link(text: "Cancel")
          expect(page).to have_current_path("/sales-logs")
        end
      end

      context "when one year filter is selected" do
        before do
          check("#{current_year} to #{current_year + 1}")
          click_button("Apply filters")
        end

        it "allows changing the filters and downloading the csv data" do
          click_link("Download (CSV)")

          expect(page).to have_current_path("/sales-logs/csv-download?codes_only=false&search=1")
          expect(page).to have_content("You've selected 2 logs")
        end

        it "allows updating filters" do
          click_link("Download (CSV, codes only)")
          expect(page).to have_content("You've selected 2 logs")
          click_link("Change", href: "/sales-logs/filters/assigned-to?codes_only=true&referrer=check_answers&search=1")

          choose("assigned-to-you-field", allow_label_click: true)
          click_button("Save changes")

          expect(page).to have_content("You've selected 1 logs")

          click_link("Change", href: "/sales-logs/filters/status?codes_only=true&referrer=check_answers&search=1")
          check("status-not-started-field", allow_label_click: true)
          click_button("Save changes")

          expect(page).to have_content("You haven't selected any logs. Please check your filters")
          expect(page).not_to have_button("Send email")
        end

        it "routes back to the filters CYA when cancel is pressed" do
          click_link("Download (CSV)")
          click_link("Change", href: "/sales-logs/filters/assigned-to?codes_only=false&referrer=check_answers&search=1")

          click_link(text: "Cancel")
          expect(page).to have_current_path("/sales-logs/csv-download?codes_only=false&search=1")
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
        expect(breadcrumbs.length).to eq 3
        expect(breadcrumbs[0].text).to eq "Home"
        expect(breadcrumbs[0][:href]).to eq root_path
        expect(breadcrumbs[1].text).to eq "Sales logs (#{sales_log.owning_organisation.name})"
        expect(breadcrumbs[1][:href]).to eq sales_logs_organisation_path(sales_log.owning_organisation)
        expect(breadcrumbs[2].text).to eq "Log #{sales_log.id}"
        expect(breadcrumbs[2][:href]).to eq sales_log_path(sales_log.id)
      end
    end

    context "when reviewing a complete log" do
      it "has the correct breadcrumbs with the correct links" do
        visit review_sales_log_path(sales_log.id, sales_log: true)
        breadcrumbs = page.find_all(".govuk-breadcrumbs__link")
        expect(breadcrumbs.length).to eq 3
        expect(breadcrumbs[0].text).to eq "Home"
        expect(breadcrumbs[0][:href]).to eq root_path
        expect(breadcrumbs[1].text).to eq "Sales logs (#{sales_log.owning_organisation.name})"
        expect(breadcrumbs[1][:href]).to eq sales_logs_organisation_path(sales_log.owning_organisation)
        expect(breadcrumbs[2].text).to eq "Log #{sales_log.id}"
        expect(breadcrumbs[2][:href]).to eq sales_log_path(sales_log.id)
      end
    end

    context "when visiting the bulk uploads page" do
      let(:bulk_upload_errors) { create_list(:bulk_upload_error, 2, category: nil) }
      let(:bulk_upload) { create(:bulk_upload, :sales, user:, bulk_upload_errors:, total_logs_count: 10) }
      let(:mock_storage_service) { instance_double("S3Service") }

      before do
        allow(Storage::S3Service).to receive(:new).and_return(mock_storage_service)
        allow(mock_storage_service).to receive(:get_presigned_url).with(bulk_upload.identifier, 60, response_content_disposition: "attachment; filename=#{bulk_upload.filename}").and_return("/sales-logs/bulk-uploads")
        bulk_upload
        visit("/sales-logs/bulk-uploads")
      end

      it "displays the right title" do
        expect(page).to have_content("Sales bulk uploads")
      end

      it "shows the bulk upload file name" do
        expect(page).to have_content(bulk_upload.filename)
      end

      it "redirects to the error report page when clicking 'View error report'" do
        click_link("View error report")
        expect(page).to have_current_path("/sales-logs/bulk-upload-results/#{bulk_upload.id}")
      end

      it "allows the user to download the file" do
        click_link("Download file", href: "/sales-logs/bulk-uploads/#{bulk_upload.id}/download")
        expect(page).to have_current_path("/sales-logs/bulk-uploads")
      end
    end

    context "when filling out address fields" do
      let(:sales_log) { create(:sales_log, :shared_ownership_setup_complete, assigned_to: user) }

      before do
        body = {
          results: [
            {
              DPA: {
                "POSTCODE": "AA1 1AA",
                "POST_TOWN": "Bristol",
                "ORGANISATION_NAME": "Some place",
              },
            },
          ],
        }.to_json

        WebMock.stub_request(:get, "https://api.os.uk/search/places/v1/uprn?dataset=DPA,LPI&key=OS_DATA_KEY&uprn=111")
        .to_return(status: 200, body:, headers: {})

        body = { results: [{ DPA: { UPRN: "111" } }] }.to_json
        WebMock.stub_request(:get, "https://api.os.uk/search/places/v1/find?query=Address+line+1%2C+AA1+1AA&key=OS_DATA_KEY&maxresults=10&minmatch=0.4")
               .to_return(status: 200, body:, headers: {})

        WebMock.stub_request(:get, "https://api.postcodes.io/postcodes/AA11AA")
        .to_return(status: 200, body: "{\"status\":200,\"result\":{\"postcode\":\"AA1 1AA\",\"admin_district\":\"Westminster\",\"codes\":{\"admin_district\":\"E09000033\"}}}", headers: {})

        WebMock.stub_request(:get, "https://api.postcodes.io/postcodes/AA12AA")
        .to_return(status: 200, body: "{\"status\":200,\"result\":{\"postcode\":\"AA1 2AA\",\"admin_district\":\"Wigan\",\"codes\":{\"admin_district\":\"E08000010\"}}}", headers: {})

        body = { results: [] }.to_json
        WebMock.stub_request(:get, "https://api.os.uk/search/places/v1/find?query=Address+line+1%2C+AA1+1AB&key=OS_DATA_KEY&maxresults=10&minmatch=0.4")
               .to_return(status: 200, body:, headers: {})

        visit("/sales-logs/#{sales_log.id}/uprn")
      end

      context "and uprn is known and answered" do
        before do
          choose "Yes"
          fill_in("sales_log[uprn]", with: "111")
          click_button("Save and continue")
        end

        context "and uprn is confirmed" do
          it "sets correct address fields" do
            sales_log.reload
            expect(sales_log.uprn_known).to eq(1) # yes
            expect(sales_log.uprn).to eq("111")
            expect(sales_log.uprn_confirmed).to eq(nil)
            expect(sales_log.uprn_selection).to eq(nil)
            expect(sales_log.pcodenk).to eq(0)
            expect(sales_log.postcode_full).to eq("AA1 1AA")
            expect(sales_log.address_line1).to eq("Some Place")
            expect(sales_log.address_line2).to eq(nil)
            expect(sales_log.town_or_city).to eq("Bristol")
            expect(sales_log.address_line1_input).to eq(nil)
            expect(sales_log.postcode_full_input).to eq(nil)
            expect(sales_log.address_search_value_check).to eq(nil)
            expect(sales_log.la).to eq("E09000033")

            choose "Yes"
            click_button("Save and continue")

            sales_log.reload
            expect(sales_log.uprn_known).to eq(1) # yes
            expect(sales_log.uprn).to eq("111")
            expect(sales_log.uprn_confirmed).to eq(1) # yes
            expect(sales_log.uprn_selection).to eq(nil)
            expect(sales_log.pcodenk).to eq(0)
            expect(sales_log.postcode_full).to eq("AA1 1AA")
            expect(sales_log.address_line1).to eq("Some Place")
            expect(sales_log.address_line2).to eq(nil)
            expect(sales_log.town_or_city).to eq("Bristol")
            expect(sales_log.address_line1_input).to eq(nil)
            expect(sales_log.postcode_full_input).to eq(nil)
            expect(sales_log.address_search_value_check).to eq(nil)
            expect(sales_log.la).to eq("E09000033")
          end

          context "and changes to uprn not known" do
            it "sets correct address fields" do
              visit("/sales-logs/#{sales_log.id}/uprn")

              choose "No"
              click_button("Save and continue")

              sales_log.reload
              expect(sales_log.uprn_known).to eq(0) # no
              expect(sales_log.uprn).to eq(nil)
              expect(sales_log.uprn_confirmed).to eq(nil)
              expect(sales_log.uprn_selection).to eq(nil)
              expect(sales_log.pcodenk).to eq(nil)
              expect(sales_log.postcode_full).to eq(nil)
              expect(sales_log.address_line1).to eq(nil)
              expect(sales_log.address_line2).to eq(nil)
              expect(sales_log.town_or_city).to eq(nil)
              expect(sales_log.address_line1_input).to eq(nil)
              expect(sales_log.postcode_full_input).to eq(nil)
              expect(sales_log.address_search_value_check).to eq(nil)
              expect(sales_log.la).to eq(nil)
            end
          end
        end

        context "and uprn is not confirmed" do
          before do
            choose "No, I want to search for the address instead"
            click_button("Save and continue")
          end

          it "sets correct address fields" do
            sales_log.reload

            expect(sales_log.uprn_known).to eq(0) # no
            expect(sales_log.uprn).to eq(nil)
            expect(sales_log.uprn_confirmed).to eq(nil)
            expect(sales_log.uprn_selection).to eq(nil)
            expect(sales_log.pcodenk).to eq(nil)
            expect(sales_log.postcode_full).to eq(nil)
            expect(sales_log.address_line1).to eq(nil)
            expect(sales_log.address_line2).to eq(nil)
            expect(sales_log.town_or_city).to eq(nil)
            expect(sales_log.address_line1_input).to eq(nil)
            expect(sales_log.postcode_full_input).to eq(nil)
            expect(sales_log.address_search_value_check).to eq(nil)
            expect(sales_log.la).to eq(nil)
          end
        end
      end

      context "and uprn is not known" do
        before do
          choose "No"
          click_button("Save and continue")
        end

        it "sets correct address fields" do
          sales_log.reload
          expect(sales_log.uprn_known).to eq(0) # no
          expect(sales_log.uprn).to eq(nil)
          expect(sales_log.uprn_confirmed).to eq(nil)
          expect(sales_log.uprn_selection).to eq(nil)
          expect(sales_log.pcodenk).to eq(nil)
          expect(sales_log.postcode_full).to eq(nil)
          expect(sales_log.address_line1).to eq(nil)
          expect(sales_log.address_line2).to eq(nil)
          expect(sales_log.town_or_city).to eq(nil)
          expect(sales_log.address_line1_input).to eq(nil)
          expect(sales_log.postcode_full_input).to eq(nil)
          expect(sales_log.address_search_value_check).to eq(nil)
          expect(sales_log.la).to eq(nil)
        end

        context "and the address is not found" do
          it "sets correct address fields" do
            fill_in("sales_log[address_line1_input]", with: "Address line 1")
            fill_in("sales_log[postcode_full_input]", with: "AA1 1AB")
            click_button("Search")

            sales_log.reload
            expect(sales_log.uprn_known).to eq(0) # no
            expect(sales_log.uprn).to eq(nil)
            expect(sales_log.uprn_confirmed).to eq(nil)
            expect(sales_log.uprn_selection).to eq(nil)
            expect(sales_log.pcodenk).to eq(nil)
            expect(sales_log.postcode_full).to eq(nil)
            expect(sales_log.address_line1).to eq(nil)
            expect(sales_log.address_line2).to eq(nil)
            expect(sales_log.town_or_city).to eq(nil)
            expect(sales_log.address_line1_input).to eq("Address line 1")
            expect(sales_log.postcode_full_input).to eq("AA1 1AB")
            expect(sales_log.address_search_value_check).to eq(nil)
            expect(sales_log.la).to eq(nil)

            click_button("Confirm and continue")

            sales_log.reload
            expect(sales_log.uprn_known).to eq(0) # no
            expect(sales_log.uprn).to eq(nil)
            expect(sales_log.uprn_confirmed).to eq(nil)
            expect(sales_log.uprn_selection).to eq(nil)
            expect(sales_log.pcodenk).to eq(nil)
            expect(sales_log.postcode_full).to eq(nil)
            expect(sales_log.address_line1).to eq(nil)
            expect(sales_log.address_line2).to eq(nil)
            expect(sales_log.town_or_city).to eq(nil)
            expect(sales_log.address_line1_input).to eq("Address line 1")
            expect(sales_log.postcode_full_input).to eq("AA1 1AB")
            expect(sales_log.address_search_value_check).to eq(0)
            expect(sales_log.la).to eq(nil)
          end
        end

        context "and address is found, re-searched and not found" do
          before do
            fill_in("sales_log[address_line1_input]", with: "Address line 1")
            fill_in("sales_log[postcode_full_input]", with: "AA1 1AA")
            click_button("Search")
            visit("/sales-logs/#{sales_log.id}/address-matcher")

            fill_in("sales_log[address_line1_input]", with: "Address line 1")
            fill_in("sales_log[postcode_full_input]", with: "AA1 1AB")
            click_button("Search")
          end

          it "routes to the correct page" do
            expect(page).to have_current_path("/sales-logs/#{sales_log.id}/no-address-found")
          end
        end

        context "and the user selects 'address_not_listed'" do
          before do
            fill_in("sales_log[address_line1_input]", with: "Address line 1")
            fill_in("sales_log[postcode_full_input]", with: "AA1 1AA")
            click_button("Search")
            choose "The address is not listed, I want to enter the address manually"
            click_button("Save and continue")
          end

          it "sets correct address fields" do
            sales_log.reload
            expect(sales_log.uprn_known).to eq(0) # no
            expect(sales_log.uprn).to eq(nil)
            expect(sales_log.uprn_confirmed).to eq(nil)
            expect(sales_log.uprn_selection).to eq("uprn_not_listed")
            expect(sales_log.pcodenk).to eq(0)
            expect(sales_log.postcode_full).to eq("AA1 1AA")
            expect(sales_log.address_line1).to eq("Address line 1")
            expect(sales_log.address_line2).to eq(nil)
            expect(sales_log.town_or_city).to eq(nil)
            expect(sales_log.address_line1_input).to eq("Address line 1")
            expect(sales_log.postcode_full_input).to eq("AA1 1AA")
            expect(sales_log.address_search_value_check).to eq(nil)
            expect(sales_log.la).to eq("E09000033")
          end

          context "and the user enters a new address manually" do
            context "without changing a valid postcode" do
              before do
                fill_in("sales_log[town_or_city]", with: "Town")
                click_button("Save and continue")
              end

              it "sets correct address fields" do
                sales_log.reload
                expect(sales_log.uprn_known).to eq(0) # no
                expect(sales_log.uprn).to eq(nil)
                expect(sales_log.uprn_confirmed).to eq(nil)
                expect(sales_log.uprn_selection).to eq("uprn_not_listed")
                expect(sales_log.pcodenk).to eq(0)
                expect(sales_log.postcode_full).to eq("AA1 1AA")
                expect(sales_log.address_line1).to eq("Address line 1")
                expect(sales_log.address_line2).to eq("")
                expect(sales_log.town_or_city).to eq("Town")
                expect(sales_log.address_line1_input).to eq("Address line 1")
                expect(sales_log.postcode_full_input).to eq("AA1 1AA")
                expect(sales_log.address_search_value_check).to eq(nil)
                expect(sales_log.la).to eq("E09000033")
              end
            end

            context "with changing the postcode" do
              before do
                fill_in("sales_log[town_or_city]", with: "Town")
                fill_in("sales_log[postcode_full]", with: "AA12AA")
                click_button("Save and continue")
              end

              it "sets correct address fields" do
                sales_log.reload
                expect(sales_log.uprn_known).to eq(0) # no
                expect(sales_log.uprn).to eq(nil)
                expect(sales_log.uprn_confirmed).to eq(nil)
                expect(sales_log.uprn_selection).to eq("uprn_not_listed")
                expect(sales_log.pcodenk).to eq(0)
                expect(sales_log.postcode_full).to eq("AA1 2AA")
                expect(sales_log.address_line1).to eq("Address line 1")
                expect(sales_log.address_line2).to eq("")
                expect(sales_log.town_or_city).to eq("Town")
                expect(sales_log.address_line1_input).to eq("Address line 1")
                expect(sales_log.postcode_full_input).to eq("AA1 1AA")
                expect(sales_log.address_search_value_check).to eq(nil)
                expect(sales_log.la).to eq("E08000010")
              end
            end
          end
        end

        context "and the user selects 'address_not_listed' when partial postcode is given" do
          before do
            fill_in("sales_log[address_line1_input]", with: "Address line 1")
            fill_in("sales_log[postcode_full_input]", with: "1AA")
            click_button("Search")
            choose "The address is not listed, I want to enter the address manually"
            click_button("Save and continue")
          end

          it "sets correct address fields" do
            sales_log.reload
            expect(sales_log.uprn_known).to eq(0) # no
            expect(sales_log.uprn).to eq(nil)
            expect(sales_log.uprn_confirmed).to eq(nil)
            expect(sales_log.uprn_selection).to eq("uprn_not_listed")
            expect(sales_log.pcodenk).to eq(nil)
            expect(sales_log.postcode_full).to eq(nil)
            expect(sales_log.address_line1).to eq("Address line 1")
            expect(sales_log.address_line2).to eq(nil)
            expect(sales_log.town_or_city).to eq(nil)
            expect(sales_log.address_line1_input).to eq("Address line 1")
            expect(sales_log.postcode_full_input).to eq("1AA")
            expect(sales_log.address_search_value_check).to eq(nil)
            expect(sales_log.la).to eq(nil)
          end
        end

        context "and the user selects 'address_not_listed' and then changes their mind and selects an address" do
          before do
            fill_in("sales_log[address_line1_input]", with: "Address line 1")
            fill_in("sales_log[postcode_full_input]", with: "AA1 1AA")
            click_button("Search")
            choose "The address is not listed, I want to enter the address manually"
            click_button("Save and continue")

            visit("/sales-logs/#{sales_log.id}/uprn-selection")
            choose("sales-log-uprn-selection-111-field", allow_label_click: true)
            click_button("Save and continue")
          end

          it "sets correct address fields" do
            sales_log.reload
            expect(sales_log.uprn_known).to eq(1)
            expect(sales_log.uprn).to eq("111")
            expect(sales_log.uprn_confirmed).to eq(1)
            expect(sales_log.uprn_selection).to eq(nil)
            expect(sales_log.pcodenk).to eq(0)
            expect(sales_log.postcode_full).to eq("AA1 1AA")
            expect(sales_log.address_line1).to eq("Some Place")
            expect(sales_log.address_line2).to eq(nil)
            expect(sales_log.town_or_city).to eq("Bristol")
            expect(sales_log.address_line1_input).to eq("Address line 1")
            expect(sales_log.postcode_full_input).to eq("AA1 1AA")
            expect(sales_log.address_search_value_check).to eq(nil)
            expect(sales_log.la).to eq("E09000033")
          end
        end

        context "and possible addresses found and selected" do
          before do
            fill_in("sales_log[address_line1_input]", with: "Address line 1")
            fill_in("sales_log[postcode_full_input]", with: "AA1 1AA")
            click_button("Search")
            choose("sales-log-uprn-selection-111-field", allow_label_click: true)
            click_button("Save and continue")
          end

          it "sets correct address fields" do
            sales_log.reload
            expect(sales_log.uprn_known).to eq(1)
            expect(sales_log.uprn).to eq("111")
            expect(sales_log.uprn_confirmed).to eq(1)
            expect(sales_log.uprn_selection).to eq(nil)
            expect(sales_log.pcodenk).to eq(0)
            expect(sales_log.postcode_full).to eq("AA1 1AA")
            expect(sales_log.address_line1).to eq("Some Place")
            expect(sales_log.address_line2).to eq(nil)
            expect(sales_log.town_or_city).to eq("Bristol")
            expect(sales_log.address_line1_input).to eq("Address line 1")
            expect(sales_log.postcode_full_input).to eq("AA1 1AA")
            expect(sales_log.address_search_value_check).to eq(nil)
            expect(sales_log.la).to eq("E09000033")
          end
        end
      end
    end
  end

  context "when a log becomes a duplicate" do
    before do
      Timecop.freeze(Time.zone.local(2024, 3, 3))
      Singleton.__init__(FormHandler)
    end

    after do
      Timecop.return
      Singleton.__init__(FormHandler)
    end

    context "and updating duplicate log" do
      let(:user) { create(:user, :data_coordinator) }
      let(:sales_log) { create(:sales_log, :duplicate, assigned_to: user) }
      let!(:duplicate_log) { create(:sales_log, :duplicate, assigned_to: user) }

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
end
