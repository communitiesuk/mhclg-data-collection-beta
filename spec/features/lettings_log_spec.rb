require "rails_helper"

RSpec.describe "Lettings Log Features" do
  context "when searching for specific logs" do
    context "when I am signed in and there are logs in the database" do
      let(:user) { create(:user, last_sign_in_at: Time.zone.now) }
      let!(:log_to_search) { create(:lettings_log, owning_organisation: user.organisation) }
      let!(:same_organisation_log) { create(:lettings_log, owning_organisation: user.organisation) }
      let!(:another_organisation_log) { create(:lettings_log) }

      before do
        visit("/lettings-logs")
        fill_in("user[email]", with: user.email)
        fill_in("user[password]", with: user.password)
        click_button("Sign in")
      end

      it "displays the logs belonging to the same organisation" do
        expect(page).to have_link(log_to_search.id.to_s)
        expect(page).to have_link(same_organisation_log.id.to_s)
        expect(page).not_to have_link(another_organisation_log.id.to_s)
      end

      context "when I search for a specific log" do
        it "there is a search bar with a message and search button for logs" do
          expect(page).to have_field("search")
          expect(page).to have_content("Search by log ID, tenant code, property reference or postcode")
          expect(page).to have_button("Search")
        end

        context "when I fill in search information and press the search button" do
          before do
            fill_in("search", with: log_to_search.id)
            click_button("Search")
          end

          it "displays log matching the log ID" do
            expect(page).to have_link(log_to_search.id.to_s)
            expect(page).not_to have_link(same_organisation_log.id.to_s)
            expect(page).not_to have_link(another_organisation_log.id.to_s)
          end

          context "when I want to clear results" do
            it "there is link to clear the search results" do
              expect(page).to have_link("Clear search")
            end

            it "displays the logs belonging to the same organisation after I clear the search results" do
              click_link("Clear search")
              expect(page).to have_link(log_to_search.id.to_s)
              expect(page).to have_link(same_organisation_log.id.to_s)
              expect(page).not_to have_link(another_organisation_log.id.to_s)
            end
          end
        end
      end
    end
  end

  context "when filtering logs" do
    let(:user) { create(:user, last_sign_in_at: Time.zone.now) }
    let(:stock_owner_1) { create(:organisation, name: "stock owner 1") }
    let(:stock_owner_2) { create(:organisation, name: "stock owner 2") }
    let(:managing_agent_1) { create(:organisation, name: "managing agent 1") }
    let(:managing_agent_2) { create(:organisation, name: "managing agent 2") }

    context "when I am signed in" do
      before do
        FactoryBot.create(:organisation_relationship, child_organisation: user.organisation, parent_organisation: stock_owner_1)
        FactoryBot.create(:organisation_relationship, child_organisation: user.organisation, parent_organisation: stock_owner_2)
        FactoryBot.create(:organisation_relationship, child_organisation: managing_agent_1, parent_organisation: user.organisation)
        FactoryBot.create(:organisation_relationship, child_organisation: managing_agent_2, parent_organisation: user.organisation)
        visit("/lettings-logs")
        fill_in("user[email]", with: user.email)
        fill_in("user[password]", with: user.password)
        click_button("Sign in")
      end

      context "when no filters are selected" do
        it "displays the filters component with no clear button" do
          expect(page).to have_content("No filters applied")
          expect(page).not_to have_link("Clear", href: "/clear-filters?filter_type=lettings_logs")
        end
      end

      context "when I have selected filters" do
        before do
          check("Not started")
          check("In progress")
          choose("You")
          choose("Specific owning organisation")
          select(stock_owner_1.name, from: "owning_organisation")
          choose("Specific managing organisation")
          select(managing_agent_1.name, from: "managing_organisation")
          click_button("Apply filters")
        end

        it "displays the filters component with a correct count and clear button" do
          expect(page).to have_content("5 filters applied")
          expect(page).to have_link("Clear", href: "/clear-filters?filter_type=lettings_logs")
        end

        context "when clearing the filters" do
          before do
            click_link("Clear")
          end

          it "clears the filters and displays the filter component as before" do
            expect(page).to have_content("No filters applied")
            expect(page).not_to have_link("Clear", href: "/clear-filters?filter_type=lettings_logs")
          end
        end
      end
    end
  end

  context "when the signed is user is a Support user" do
    let(:organisation) { create(:organisation, name: "User org") }
    let(:support_user) { create(:user, :support, last_sign_in_at: Time.zone.now, organisation:) }
    let(:devise_notify_mailer) { DeviseNotifyMailer.new }
    let(:notify_client) { instance_double(Notifications::Client) }
    let(:mfa_template_id) { User::MFA_TEMPLATE_ID }
    let(:otp) { "999111" }

    before do
      allow(DeviseNotifyMailer).to receive(:new).and_return(devise_notify_mailer)
      allow(devise_notify_mailer).to receive(:notify_client).and_return(notify_client)
      allow(notify_client).to receive(:send_email).and_return(true)
      allow(SecureRandom).to receive(:random_number).and_return(otp)
      visit("/account/sign-in")
      fill_in("user[email]", with: support_user.email)
      fill_in("user[password]", with: support_user.password)
      click_button("Sign in")
      fill_in("code", with: otp)
      click_button("Submit")
    end

    context "when completing the setup lettings log section", :aggregate_failure do
      before do
        Timecop.freeze(Time.zone.local(2023, 3, 3))
        Singleton.__init__(FormHandler)
      end

      after do
        Timecop.return
        Singleton.__init__(FormHandler)
      end

      it "includes the owning organisation and created by questions" do
        visit("/lettings-logs")
        click_button("Create a new lettings log")
        click_link("Set up this lettings log")
        select(support_user.organisation.name, from: "lettings-log-owning-organisation-id-field")
        click_button("Save and continue")
        select("#{support_user.name} (#{support_user.email})", from: "lettings-log-created-by-id-field")
        click_button("Save and continue")
        log_id = page.current_path.scan(/\d/).join
        visit("lettings-logs/#{log_id}/setup/check-answers")
        expect(page).to have_content("Stock owner User org", normalize_ws: true)
        expect(page).to have_content("You have answered 2 of 8 questions")
      end
    end

    context "when visiting a subsection check answers page" do
      let(:lettings_log) { create(:lettings_log, :setup_completed) }

      it "has the correct breadcrumbs with the correct links" do
        visit lettings_log_setup_check_answers_path(lettings_log)
        breadcrumbs = page.find_all(".govuk-breadcrumbs__link")
        expect(breadcrumbs.length).to eq 3
        expect(breadcrumbs[0].text).to eq "Home"
        expect(breadcrumbs[0][:href]).to eq root_path
        expect(breadcrumbs[1].text).to eq "Lettings logs (DLUHC)"
        expect(breadcrumbs[1][:href]).to eq lettings_logs_organisation_path(lettings_log.owning_organisation)
        expect(breadcrumbs[2].text).to eq "Log #{lettings_log.id}"
        expect(breadcrumbs[2][:href]).to eq lettings_log_path(lettings_log)
      end
    end

    context "when reviewing a complete log" do
      let(:lettings_log) { create(:lettings_log, :completed) }

      it "has the correct breadcrumbs with the correct links" do
        visit review_lettings_log_path(lettings_log)
        breadcrumbs = page.find_all(".govuk-breadcrumbs__link")
        expect(breadcrumbs.length).to eq 3
        expect(breadcrumbs[0].text).to eq "Home"
        expect(breadcrumbs[0][:href]).to eq root_path
        expect(breadcrumbs[1].text).to eq "Lettings logs (DLUHC)"
        expect(breadcrumbs[1][:href]).to eq lettings_logs_organisation_path(lettings_log.owning_organisation)
        expect(breadcrumbs[2].text).to eq "Log #{lettings_log.id}"
        expect(breadcrumbs[2][:href]).to eq lettings_log_path(lettings_log)
      end
    end

    context "when the owning organisation question isn't answered" do
      it "doesn't show the managing agent question" do
        visit("/lettings-logs")
        click_button("Create a new lettings log")
        click_link("Set up this lettings log")
        log_id = page.current_path.scan(/\d/).join
        click_link("Skip for now")
        expect(page).not_to have_current_path("/lettings-logs/#{log_id}/managing-organisation")
      end
    end

    context "when the owning organisation question is answered" do
      context "and the owning organisation does hold stock" do
        before do
          support_user.organisation.update!(holds_own_stock: true)
        end

        context "and the owning organisation has no managing agents" do
          it "doesn't show the managing organisation question" do
            visit("/lettings-logs")
            click_button("Create a new lettings log")
            click_link("Set up this lettings log")
            log_id = page.current_path.scan(/\d/).join
            select(support_user.organisation.name, from: "lettings-log-owning-organisation-id-field")
            click_button("Save and continue")
            expect(page).not_to have_current_path("/lettings-logs/#{log_id}/managing-organisation")
            visit("lettings-logs/#{log_id}/setup/check-answers")
            expect(page).not_to have_content("Managing agent ")
          end
        end

        context "and the owning organisation has 1 or more managing agents" do
          let(:managing_org1) { create(:organisation, name: "Managing org 1") }
          let!(:org_rel1) { create(:organisation_relationship, parent_organisation: support_user.organisation, child_organisation: managing_org1) }

          it "does show the managing organisation question" do
            visit("/lettings-logs")
            click_button("Create a new lettings log")
            click_link("Set up this lettings log")
            log_id = page.current_path.scan(/\d/).join
            select(support_user.organisation.name, from: "lettings-log-owning-organisation-id-field")
            click_button("Save and continue")
            expect(page).to have_current_path("/lettings-logs/#{log_id}/managing-organisation")
            select(managing_org1.name, from: "lettings-log-managing-organisation-id-field")
            click_button("Save and continue")
            visit("lettings-logs/#{log_id}/setup/check-answers")
            expect(page).to have_content("Managing agent Managing org 1", normalize_ws: true)
          end

          context "and the owning organisation has 2 or more managing agents" do
            let(:managing_org2) { create(:organisation, name: "Managing org 2") }
            let!(:org_rel2) { create(:organisation_relationship, parent_organisation: support_user.organisation, child_organisation: managing_org2) }

            context "and the organisation relationship for the selected managing agent is deleted" do
              it "doesn't change the CYA page text to be 'You didn't answer this question'" do
                visit("/lettings-logs")
                click_button("Create a new lettings log")
                click_link("Set up this lettings log")
                log_id = page.current_path.scan(/\d/).join
                select(support_user.organisation.name, from: "lettings-log-owning-organisation-id-field")
                click_button("Save and continue")
                expect(page).to have_current_path("/lettings-logs/#{log_id}/managing-organisation")
                select(managing_org1.name, from: "lettings-log-managing-organisation-id-field")
                click_button("Save and continue")
                visit("lettings-logs/#{log_id}/setup/check-answers")
                expect(page).to have_content("Managing agent Managing org 1", normalize_ws: true)
                org_rel1.destroy!
                visit("lettings-logs/#{log_id}/setup/check-answers")
                expect(page).to have_content("Managing agent Managing org 1", normalize_ws: true)
                expect(support_user.organisation.managing_agents).to eq([org_rel2.child_organisation])
              end
            end
          end
        end
      end
    end

    it "is possible to delete multiple logs" do
      postcode = "SW1A 1AA"
      lettings_log_1 = create(:lettings_log, :setup_completed, assigned_to: support_user, postcode_full: postcode)
      lettings_log_2 = create(:lettings_log, :in_progress, assigned_to: support_user, postcode_full: postcode)
      create_list(:lettings_log, 5, :in_progress)

      visit lettings_logs_path
      expect(page).to have_selector "article.app-log-summary", count: 7
      expect(page).not_to have_link "Delete logs"
      within ".app-filter" do
        check "status-in-progress-field"
        choose "assigned-to-you-field"
        click_button
      end
      expect(page).to have_selector "article.app-log-summary", count: 2
      expect(page).to have_link "Delete logs"
      click_link "Delete logs"

      expect(page).to have_current_path delete_logs_lettings_logs_path
      rows = page.find_all "tbody tr"
      expect(rows.count).to be 2
      id_to_delete, id_to_keep = rows.map { |row| row.first("td").text.to_i }
      expect([id_to_delete, id_to_keep]).to match_array [lettings_log_1.id, lettings_log_2.id]
      check "forms-delete-logs-form-selected-ids-#{id_to_delete}-field"
      uncheck "forms-delete-logs-form-selected-ids-#{id_to_keep}-field"
      click_button "Continue"

      expect(page).to have_current_path delete_logs_confirmation_lettings_logs_path
      expect(page.text).to include "You've selected 1 log to delete"
      expect(page.find("form.button_to")[:action]).to eq delete_logs_lettings_logs_path
      click_button "Delete logs"

      expect(page).to have_current_path lettings_logs_path
      expect(page).to have_selector "article.app-log-summary", count: 1
      expect(page.find("article.app-log-summary h2").text).to eq "Log #{id_to_keep}"
      deleted_log = LettingsLog.find(id_to_delete)
      expect(deleted_log.status).to eq "deleted"
      expect(deleted_log.discarded_at).not_to be nil
    end
  end

  context "when the signed is user is not a Support user" do
    let(:organisation) { create(:organisation, name: "User org") }
    let(:user) { create(:user, :data_coordinator, name: "User name", organisation:) }
    let(:devise_notify_mailer) { DeviseNotifyMailer.new }
    let(:notify_client) { instance_double(Notifications::Client) }

    before do
      allow(DeviseNotifyMailer).to receive(:new).and_return(devise_notify_mailer)
      allow(devise_notify_mailer).to receive(:notify_client).and_return(notify_client)
      allow(notify_client).to receive(:send_email).and_return(true)
      visit("/account/sign-in")
      fill_in("user[email]", with: user.email)
      fill_in("user[password]", with: user.password)
      click_button("Sign in")
    end

    context "when completing the setup log section" do
      context "and there is at most 1 potential stock owner" do
        it "does not include the owning organisation and includes the created by questions" do
          visit("/lettings-logs")
          click_button("Create a new lettings log")
          click_link("Set up this lettings log")
          select(user.name, from: "lettings-log-created-by-id-field")
          click_button("Save and continue")
          log_id = page.current_path.scan(/\d/).join
          expect(page).to have_current_path("/lettings-logs/#{log_id}/needs-type")
          visit("lettings-logs/#{log_id}/setup/check-answers")
          expect(page).not_to have_content("Stock owner ")
          expect(page).not_to have_content("Log owner ")
        end
      end

      context "and there are 2 or more potential stock owners" do
        let(:owning_org1) { create(:organisation, name: "Owning org 1") }
        let!(:org_rel1) { create(:organisation_relationship, child_organisation: user.organisation, parent_organisation: owning_org1) }

        it "does include the owning organisation question" do
          visit("/lettings-logs")
          click_button("Create a new lettings log")
          click_link("Set up this lettings log")
          log_id = page.current_path.scan(/\d/).join
          expect(page).to have_current_path("/lettings-logs/#{log_id}/stock-owner")
          visit("lettings-logs/#{log_id}/setup/check-answers")
          expect(page).to have_content("Stock owner User org", normalize_ws: true)
        end

        context "and there are 3 or more potential stock owners" do
          let(:owning_org2) { create(:organisation, name: "Owning org 2") }
          let!(:org_rel2) { create(:organisation_relationship, child_organisation: user.organisation, parent_organisation: owning_org2) }

          context "and the organisation relationship for the selected stock owner is deleted" do
            it "doesn't change the CYA page text to be 'You didn't answer this question'" do
              visit("/lettings-logs")
              click_button("Create a new lettings log")
              click_link("Set up this lettings log")
              log_id = page.current_path.scan(/\d/).join
              expect(page).to have_current_path("/lettings-logs/#{log_id}/stock-owner")
              select(owning_org1.name, from: "lettings-log-owning-organisation-id-field")
              click_button("Save and continue")
              visit("lettings-logs/#{log_id}/setup/check-answers")
              expect(page).to have_content("Stock owner Owning org 1", normalize_ws: true)
              org_rel1.destroy!
              visit("lettings-logs/#{log_id}/setup/check-answers")
              expect(page).to have_content("Stock owner Owning org 1", normalize_ws: true)
              expect(user.organisation.stock_owners).to eq([org_rel2.parent_organisation])
            end
          end
        end
      end

      context "when the current user's organisation doesn't hold stock" do
        let(:owning_org1) { create(:organisation, name: "Owning org 1") }
        let(:owning_org2) { create(:organisation, name: "Owning org 2") }
        let!(:org_rel1) { create(:organisation_relationship, child_organisation: user.organisation, parent_organisation: owning_org1) }
        let!(:org_rel2) { create(:organisation_relationship, child_organisation: user.organisation, parent_organisation: owning_org2) }

        it "does not show the managing organisation question, because managing organisation can be inferred" do
          user.organisation.update!(holds_own_stock: false)
          visit("/lettings-logs")
          click_button("Create a new lettings log")
          click_link("Set up this lettings log")
          log_id = page.current_path.scan(/\d/).join
          expect(page).to have_current_path("/lettings-logs/#{log_id}/stock-owner")
          select(owning_org1.name, from: "lettings-log-owning-organisation-id-field")
          click_button("Save and continue")
          visit("lettings-logs/#{log_id}/setup/check-answers")

          expect(page).not_to have_content("Managing agent User org", normalize_ws: true)
          expect(user.organisation.stock_owners).to eq([org_rel1.parent_organisation, org_rel2.parent_organisation])
          expect(LettingsLog.find(log_id).managing_organisation).to eq(user.organisation)
        end
      end

      context "when the current user's organisation does hold stock" do
        let!(:owning_org) { create(:organisation, name: "Owning org") }
        let!(:org_rel1) { create(:organisation_relationship, child_organisation: user.organisation, parent_organisation: owning_org) }

        before do
          user.organisation.update!(holds_own_stock: true)
        end

        context "and the user's organisation has no managing agents" do
          it "doesn't show the managing organisation question" do
            visit("/lettings-logs")
            click_button("Create a new lettings log")
            click_link("Set up this lettings log")
            log_id = page.current_path.scan(/\d/).join
            expect(page).to have_current_path("/lettings-logs/#{log_id}/stock-owner")
            select(owning_org.name, from: "lettings-log-owning-organisation-id-field")
            click_button("Save and continue")
            expect(page).not_to have_current_path("/lettings-logs/#{log_id}/managing-organisation")
            visit("lettings-logs/#{log_id}/setup/check-answers")
            expect(page).not_to have_content("Managing agent ")
            expect(user.organisation.stock_owners).to eq([org_rel1.parent_organisation])
          end
        end

        context "and the user's organisation has 1 or more managing agents" do
          let(:managing_org) { create(:organisation, name: "Managing org") }
          let!(:org_rel2) { create(:organisation_relationship, parent_organisation: user.organisation, child_organisation: managing_org) }

          it "does show the managing organisation question" do
            visit("/lettings-logs")
            click_button("Create a new lettings log")
            click_link("Set up this lettings log")
            log_id = page.current_path.scan(/\d/).join
            expect(page).to have_current_path("/lettings-logs/#{log_id}/stock-owner")
            select(user.organisation.name, from: "lettings-log-owning-organisation-id-field")
            click_button("Save and continue")
            expect(page).to have_current_path("/lettings-logs/#{log_id}/managing-organisation")
            select(managing_org.name, from: "lettings-log-managing-organisation-id-field")
            click_button("Save and continue")
            visit("lettings-logs/#{log_id}/setup/check-answers")
            expect(page).to have_content("Managing agent Managing org", normalize_ws: true)
            expect(user.organisation.managing_agents).to eq([org_rel2.child_organisation])
          end
        end
      end
    end

    context "when returning to the list of logs via breadcrumbs link" do
      before do
        visit("/lettings-logs")
        click_button("Create a new lettings log")
        find("a.govuk-breadcrumbs__link", text: "Lettings logs").click
      end

      it "navigates you to the lettings logs page" do
        expect(page).to have_current_path("/lettings-logs")
      end
    end

    context "when a log becomes a duplicate" do
      let(:lettings_log) { create(:lettings_log, :duplicate, owning_organisation: user.organisation, assigned_to: user) }
      let!(:duplicate_log) { create(:lettings_log, :duplicate, owning_organisation: user.organisation, assigned_to: user) }

      before do
        lettings_log.update!(tenancycode: "different")
        visit("/lettings-logs/#{lettings_log.id}/tenant-code")
        fill_in("lettings-log-tenancycode-field", with: duplicate_log.tenancycode)
        click_button("Save and continue")
      end

      it "allows keeping the original log and deleting duplicates" do
        lettings_log.reload
        duplicate_log.reload
        expect(lettings_log.duplicates.count).to eq(1)
        expect(lettings_log.duplicate_set_id).not_to be_nil
        expect(duplicate_log.duplicate_set_id).not_to be_nil
        expect(lettings_log.duplicates).to include(duplicate_log)

        expect(page).to have_current_path("/lettings-logs/#{lettings_log.id}/duplicate-logs?original_log_id=#{lettings_log.id}")
        click_link("Keep this log and delete duplicates", href: "/lettings-logs/#{lettings_log.id}/delete-duplicates?original_log_id=#{lettings_log.id}")
        expect(page).to have_current_path("/lettings-logs/#{lettings_log.id}/delete-duplicates?original_log_id=#{lettings_log.id}")
        click_button "Delete this log"
        duplicate_log.reload
        expect(duplicate_log.deleted?).to be true
        expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
        expect(page).to have_content("Log #{duplicate_log.id} has been deleted.")
        expect(page).to have_current_path("/lettings-logs/#{lettings_log.id}/duplicate-logs?organisation_id=&original_log_id=#{lettings_log.id}&referrer=")
        expect(page).not_to have_content("These logs are duplicates")
        expect(page).not_to have_link("Keep this log and delete duplicates")
        expect(page).to have_link("Back to Log #{lettings_log.id}", href: "/lettings-logs/#{lettings_log.id}")

        lettings_log.reload
        duplicate_log.reload

        expect(lettings_log.duplicates.count).to eq(0)
        expect(duplicate_log.duplicates.count).to eq(0)
        expect(lettings_log.duplicate_set_id).to be_nil
        expect(duplicate_log.duplicate_set_id).to be_nil
      end

      it "allows changing answers on remaining original log" do
        click_link("Keep this log and delete duplicates", href: "/lettings-logs/#{lettings_log.id}/delete-duplicates?original_log_id=#{lettings_log.id}")
        click_button "Delete this log"
        click_link("Change", href: "/lettings-logs/#{lettings_log.id}/tenant-code?original_log_id=#{lettings_log.id}&referrer=interruption_screen")
        click_button("Save and continue")
        expect(page).to have_current_path("/lettings-logs/#{lettings_log.id}/duplicate-logs?original_log_id=#{lettings_log.id}")
        expect(page).to have_link("Back to Log #{lettings_log.id}", href: "/lettings-logs/#{lettings_log.id}")
      end

      it "allows keeping the duplicate log and deleting the original one" do
        lettings_log.reload
        duplicate_log.reload
        expect(lettings_log.duplicates.count).to eq(1)
        expect(lettings_log.duplicate_set_id).not_to be_nil
        expect(duplicate_log.duplicate_set_id).not_to be_nil
        expect(duplicate_log.duplicates).to include(lettings_log)

        expect(page).to have_current_path("/lettings-logs/#{lettings_log.id}/duplicate-logs?original_log_id=#{lettings_log.id}")
        click_link("Keep this log and delete duplicates", href: "/lettings-logs/#{duplicate_log.id}/delete-duplicates?original_log_id=#{lettings_log.id}")
        expect(page).to have_current_path("/lettings-logs/#{duplicate_log.id}/delete-duplicates?original_log_id=#{lettings_log.id}")
        click_button "Delete this log"
        lettings_log.reload
        expect(lettings_log.status).to eq("deleted")
        expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
        expect(page).to have_content("Log #{lettings_log.id} has been deleted.")
        expect(page).to have_current_path("/lettings-logs/#{duplicate_log.id}/duplicate-logs?organisation_id=&original_log_id=#{lettings_log.id}&referrer=")
        expect(page).not_to have_content("These logs are duplicates")
        expect(page).not_to have_link("Keep this log and delete duplicates")
        expect(page).to have_link("Back to lettings logs", href: "/lettings-logs")

        lettings_log.reload
        duplicate_log.reload

        expect(lettings_log.duplicates.count).to eq(0)
        expect(duplicate_log.duplicates.count).to eq(0)
        expect(lettings_log.duplicate_set_id).to be_nil
        expect(duplicate_log.duplicate_set_id).to be_nil
      end

      it "allows changing answers to remaining duplicate log" do
        click_link("Keep this log and delete duplicates", href: "/lettings-logs/#{duplicate_log.id}/delete-duplicates?original_log_id=#{lettings_log.id}")
        click_button "Delete this log"
        click_link("Change", href: "/lettings-logs/#{duplicate_log.id}/tenant-code?original_log_id=#{lettings_log.id}&referrer=interruption_screen")
        click_button("Save and continue")
        expect(page).to have_current_path("/lettings-logs/#{duplicate_log.id}/duplicate-logs?original_log_id=#{lettings_log.id}")
        expect(page).to have_link("Back to lettings logs", href: "/lettings-logs")
      end

      it "allows deduplicating logs by changing the answers on the duplicate log" do
        lettings_log.reload
        duplicate_log.reload
        expect(lettings_log.duplicates.count).to eq(1)
        expect(lettings_log.duplicate_set_id).not_to be_nil
        expect(duplicate_log.duplicate_set_id).not_to be_nil
        expect(lettings_log.duplicates).to include(duplicate_log)

        expect(page).to have_current_path("/lettings-logs/#{lettings_log.id}/duplicate-logs?original_log_id=#{lettings_log.id}")
        click_link("Change", href: "/lettings-logs/#{duplicate_log.id}/tenant-code?first_remaining_duplicate_id=#{lettings_log.id}&original_log_id=#{lettings_log.id}&referrer=duplicate_logs")
        fill_in("lettings-log-tenancycode-field", with: "something else")
        click_button("Save changes")
        expect(page).to have_current_path("/lettings-logs/#{lettings_log.id}/duplicate-logs?original_log_id=#{lettings_log.id}&referrer=duplicate_logs")
        expect(page).to have_link("Back to Log #{lettings_log.id}", href: "/lettings-logs/#{lettings_log.id}")
        expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
        expect(page).to have_content("Log #{duplicate_log.id} is no longer a duplicate and has been removed from the list")
        expect(page).to have_content("You changed the tenant code.")

        lettings_log.reload
        duplicate_log.reload

        expect(lettings_log.duplicates.count).to eq(0)
        expect(duplicate_log.duplicates.count).to eq(0)
        expect(lettings_log.duplicate_set_id).to be_nil
        expect(duplicate_log.duplicate_set_id).to be_nil
      end

      it "allows deduplicating logs by changing the answers on the original log" do
        click_link("Change", href: "/lettings-logs/#{lettings_log.id}/tenant-code?first_remaining_duplicate_id=#{duplicate_log.id}&original_log_id=#{lettings_log.id}&referrer=duplicate_logs")
        fill_in("lettings-log-tenancycode-field", with: "something else")
        click_button("Save changes")
        expect(page).to have_current_path("/lettings-logs/#{duplicate_log.id}/duplicate-logs?original_log_id=#{lettings_log.id}&referrer=duplicate_logs")
        expect(page).to have_link("Back to Log #{lettings_log.id}", href: "/lettings-logs/#{lettings_log.id}")
        expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
        expect(page).to have_content("Log #{lettings_log.id} is no longer a duplicate and has been removed from the list")
        expect(page).to have_content("You changed the tenant code.")
        expect(duplicate_log.duplicates.count).to eq(0)
        expect(duplicate_log.duplicate_set_id).to be_nil
      end
    end
  end
end
