require "rails_helper"

RSpec.describe OrganisationsController, type: :request do
  let(:organisation) { user.organisation }
  let!(:unauthorised_organisation) { create(:organisation) }
  let(:headers) { { "Accept" => "text/html" } }
  let(:page) { Capybara::Node::Simple.new(response.body) }
  let(:user) { create(:user, :data_coordinator) }
  let(:new_value) { "Test Name 35" }
  let(:active) { nil }
  let(:params) { { id: organisation.id, organisation: { name: new_value, active:, rent_periods: [], all_rent_periods: [] } } }

  before do
    Timecop.freeze(Time.zone.local(2024, 3, 1))
    Singleton.__init__(FormHandler)
  end

  after do
    Timecop.return
    Singleton.__init__(FormHandler)
  end

  context "when user is not signed in" do
    describe "#show" do
      it "does not let you see organisation details from org route" do
        get "/organisations/#{organisation.id}", headers: headers, params: {}
        expect(response).to redirect_to("/account/sign-in")
      end

      it "does not let you see organisation details from details route" do
        get "/organisations/#{organisation.id}/details", headers: headers, params: {}
        expect(response).to redirect_to("/account/sign-in")
      end

      it "does not let you see organisation users" do
        get "/organisations/#{organisation.id}/users", headers: headers, params: {}
        expect(response).to redirect_to("/account/sign-in")
      end

      it "does not let you see organisations list" do
        get "/organisations", headers: headers, params: {}
        expect(response).to redirect_to("/account/sign-in")
      end

      it "does not let you see schemes list" do
        get "/organisations/#{organisation.id}/schemes", headers: headers, params: {}
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    describe "#delete-confirmation" do
      let(:organisation) { create(:organisation) }

      before do
        get "/organisations/#{organisation.id}/delete-confirmation"
      end

      context "when not signed in" do
        it "redirects to the sign in page" do
          expect(response).to redirect_to("/account/sign-in")
        end
      end
    end

    describe "#delete" do
      let(:organisation) { create(:organisation) }

      before do
        delete "/organisations/#{organisation.id}/delete"
      end

      context "when not signed in" do
        it "redirects to the sign in page" do
          expect(response).to redirect_to("/account/sign-in")
        end
      end
    end

    describe "#search" do
      it "redirects to the sign in page" do
        get "/organisations/search"
        expect(response).to redirect_to("/account/sign-in")
      end
    end
  end

  context "when user is signed in" do
    describe "#schemes" do
      context "when support user" do
        let(:user) { create(:user, :support) }
        let!(:schemes) { create_list(:scheme, 5) }
        let!(:same_org_scheme) { create(:scheme, owning_organisation: user.organisation) }
        let!(:deleted_scheme) { create(:scheme, owning_organisation: user.organisation, discarded_at: Time.zone.yesterday) }

        before do
          allow(user).to receive(:need_two_factor_authentication?).and_return(false)
          sign_in user
          get "/organisations/#{organisation.id}/schemes", headers:, params: {}
        end

        it "has page heading" do
          expect(page).to have_content("Schemes")
        end

        it "shows a search bar" do
          expect(page).to have_field("search", type: "search")
        end

        describe "scheme and location csv downloads" do
          let!(:specific_organisation) { create(:organisation) }
          let!(:specific_org_scheme) { create(:scheme, owning_organisation: specific_organisation) }

          before do
            create_list(:scheme, 5, owning_organisation: specific_organisation)
            create_list(:location, 3, scheme: specific_org_scheme)
            get "/organisations/#{specific_organisation.id}/schemes", headers:, params: {}
          end

          it "shows scheme and location download links" do
            expect(page).to have_link("Download schemes (CSV)", href: schemes_csv_download_organisation_path(specific_organisation, download_type: "schemes"))
            expect(page).to have_link("Download locations (CSV)", href: schemes_csv_download_organisation_path(specific_organisation, download_type: "locations"))
            expect(page).to have_link("Download schemes and locations (CSV)", href: schemes_csv_download_organisation_path(specific_organisation, download_type: "combined"))
          end

          context "when there are no schemes for this organisation" do
            before do
              specific_organisation.owned_schemes.destroy_all
              get "/organisations/#{specific_organisation.id}/schemes", headers:, params: {}
            end

            it "does not display CSV download links" do
              expect(page).not_to have_link("Download schemes (CSV)")
              expect(page).not_to have_link("Download locations (CSV)")
              expect(page).not_to have_link("Download schemes and locations (CSV)")
            end
          end

          context "when downloading scheme data" do
            before do
              get schemes_csv_download_organisation_path(specific_organisation, download_type: "schemes")
            end

            it "redirects to the correct download page" do
              expect(page).to have_content("You've selected 6 schemes.")
            end
          end

          context "when downloading location data" do
            before do
              get schemes_csv_download_organisation_path(specific_organisation, download_type: "locations")
            end

            it "redirects to the correct download page" do
              expect(page).to have_content("You've selected 3 locations from 6 schemes.")
            end
          end

          context "when downloading scheme and location data" do
            before do
              get schemes_csv_download_organisation_path(specific_organisation, download_type: "combined")
            end

            it "redirects to the correct download page" do
              expect(page).to have_content("You've selected 6 schemes with 3 locations.")
            end
          end
        end

        it "has hidden accessibility field with description" do
          expected_field = "<h2 class=\"govuk-visually-hidden\">Supported housing schemes</h2>"
          expect(CGI.unescape_html(response.body)).to include(expected_field)
        end

        it "shows only schemes belonging to the same organisation" do
          expect(page).to have_content(same_org_scheme.id_to_display)
          schemes.each do |scheme|
            expect(page).not_to have_content(scheme.id_to_display)
          end
        end

        it "does not show deleted schemes" do
          expect(page).not_to have_content(deleted_scheme.id_to_display)
        end

        context "when searching" do
          let!(:searched_scheme) { create(:scheme, owning_organisation: user.organisation) }
          let(:search_param) { searched_scheme.id }

          before do
            create(:location, scheme: searched_scheme)
            allow(user).to receive(:need_two_factor_authentication?).and_return(false)
            get "/organisations/#{organisation.id}/schemes?search=#{search_param}"
          end

          it "returns matching results" do
            expect(page).to have_content(searched_scheme.id_to_display)
            schemes.each do |scheme|
              expect(page).not_to have_content(scheme.id_to_display)
            end
          end

          it "updates the table caption" do
            expect(page).to have_content("1 scheme matching search")
          end

          it "has search in the title" do
            expect(page).to have_title("#{user.organisation.name} (1 scheme matching ‘#{search_param}’) - Submit social housing lettings and sales data (CORE) - GOV.UK")
          end
        end

        context "when organisation has absorbed other organisations" do
          before do
            create(:organisation, merge_date: Time.zone.today, absorbing_organisation: organisation)
          end

          context "and it has duplicate schemes or locations" do
            before do
              create_list(:scheme, 2, :duplicate, owning_organisation: organisation)
              get "/organisations/#{organisation.id}/schemes", headers:, params: {}
            end

            it "displays a banner with correct content" do
              expect(page).to have_content("Some schemes and locations might be duplicates.")
              expect(page).to have_link("Review possible duplicates", href: "/organisations/#{organisation.id}/schemes/duplicates")
            end
          end
        end
      end

      context "when data coordinator user" do
        let(:user) { create(:user, :data_coordinator) }
        let!(:schemes) { create_list(:scheme, 5) }
        let!(:same_org_scheme) { create(:scheme, owning_organisation: user.organisation) }

        before do
          sign_in user
          get "/organisations/#{organisation.id}/schemes", headers:, params: {}
        end

        it "has page heading" do
          expect(page).to have_content("Schemes")
        end

        it "shows a search bar" do
          expect(page).to have_field("search", type: "search")
        end

        describe "scheme and location csv downloads" do
          before do
            create_list(:scheme, 5, owning_organisation: user.organisation)
            create_list(:location, 3, scheme: same_org_scheme)
          end

          it "shows scheme and location download links" do
            expect(page).to have_link("Download schemes (CSV)", href: csv_download_schemes_path(download_type: "schemes"))
            expect(page).to have_link("Download locations (CSV)", href: csv_download_schemes_path(download_type: "locations"))
            expect(page).to have_link("Download schemes and locations (CSV)", href: csv_download_schemes_path(download_type: "combined"))
          end

          context "when there are no schemes for this organisation" do
            before do
              user.organisation.owned_schemes.destroy_all
              get "/organisations/#{organisation.id}/schemes", headers:, params: {}
            end

            it "does not display CSV download links" do
              expect(page).not_to have_link("Download schemes (CSV)")
              expect(page).not_to have_link("Download locations (CSV)")
              expect(page).not_to have_link("Download schemes and locations (CSV)")
            end
          end

          context "when downloading scheme data" do
            before do
              get csv_download_schemes_path(download_type: "schemes")
            end

            it "redirects to the correct download page" do
              expect(page).to have_content("You've selected 6 schemes.")
            end
          end

          context "when downloading location data" do
            before do
              get csv_download_schemes_path(download_type: "locations")
            end

            it "redirects to the correct download page" do
              expect(page).to have_content("You've selected 3 locations from 6 schemes.")
            end
          end

          context "when downloading scheme and location data" do
            before do
              get csv_download_schemes_path(download_type: "combined")
            end

            it "redirects to the correct download page" do
              expect(page).to have_content("You've selected 6 schemes with 3 locations.")
            end
          end
        end

        it "shows only schemes belonging to the same organisation" do
          expect(page).to have_content(same_org_scheme.id_to_display)
          schemes.each do |scheme|
            expect(page).not_to have_content(scheme.id_to_display)
          end
        end

        it "shows schemes in alphabetical order" do
          schemes[0].update!(service_name: "aaa", owning_organisation: user.organisation)
          schemes[1].update!(service_name: "daa", owning_organisation: user.organisation)
          schemes[2].update!(service_name: "baa", owning_organisation: user.organisation)
          schemes[3].update!(service_name: "Faa", owning_organisation: user.organisation)
          schemes[4].update!(service_name: "Caa", owning_organisation: user.organisation)
          same_org_scheme.update!(service_name: "zzz", owning_organisation: user.organisation)
          get "/organisations/#{organisation.id}/schemes", headers:, params: {}
          all_links = page.all(".govuk-link")
          scheme_links = all_links.select { |link| link[:href] =~ %r{^/schemes/\d+$} }

          expect(scheme_links[0][:href]).to eq("/schemes/#{schemes[0].id}")
          expect(scheme_links[1][:href]).to eq("/schemes/#{schemes[2].id}")
          expect(scheme_links[2][:href]).to eq("/schemes/#{schemes[4].id}")
          expect(scheme_links[3][:href]).to eq("/schemes/#{schemes[1].id}")
          expect(scheme_links[4][:href]).to eq("/schemes/#{schemes[3].id}")
          expect(scheme_links[5][:href]).to eq("/schemes/#{same_org_scheme.id}")
        end

        context "with schemes that are not in scope for the user, i.e. that they do not belong to" do
          let!(:unauthorised_organisation) { create(:organisation) }

          before do
            get "/organisations/#{unauthorised_organisation.id}/schemes", headers:, params: {}
          end

          it "returns not found 404 from org details route" do
            expect(response).to have_http_status(:not_found)
          end
        end

        context "when searching" do
          let!(:searched_scheme) { create(:scheme, owning_organisation: user.organisation) }
          let(:search_param) { searched_scheme.id_to_display }

          before do
            create(:location, scheme: searched_scheme)
            get "/organisations/#{organisation.id}/schemes?search=#{search_param}"
          end

          it "returns matching results" do
            expect(page).to have_content(searched_scheme.id_to_display)
            schemes.each do |scheme|
              expect(page).not_to have_content(scheme.id_to_display)
            end
          end

          it "updates the table caption" do
            expect(page).to have_content("1 scheme matching search")
          end

          it "has search in the title" do
            expect(page).to have_title("Supported housing schemes (1 scheme matching ‘#{search_param}’) - Submit social housing lettings and sales data (CORE) - GOV.UK")
          end
        end
      end
    end

    describe "#duplicate_schemes" do
      context "with support user" do
        let(:user) { create(:user, :support) }

        before do
          allow(user).to receive(:need_two_factor_authentication?).and_return(false)
          sign_in user
          get "/organisations/#{organisation.id}/schemes/duplicates", headers:
        end

        context "with duplicate schemes and locations" do
          let(:schemes) { create_list(:scheme, 5, :duplicate, owning_organisation: organisation) }

          before do
            create_list(:location, 2, scheme: schemes.first, postcode: "M1 1AA", mobility_type: "M")
            create_list(:location, 2, scheme: schemes.first, postcode: "M1 1AA", mobility_type: "A")
            get "/organisations/#{organisation.id}/schemes/duplicates", headers:
          end

          it "displays the duplicate schemes" do
            expect(page).to have_content("This set of schemes might have duplicates")
          end

          it "displays the duplicate locations" do
            expect(page).to have_content("These 2 sets of locations might have duplicates")
          end

          it "has page heading" do
            expect(page).to have_content("Review these sets of schemes and locations")
          end
        end

        context "without duplicate schemes and locations" do
          it "does not display the schemes" do
            expect(page).not_to have_content("schemes might have duplicates")
          end

          it "does not display the locations" do
            expect(page).not_to have_content("locations might have duplicates")
          end
        end
      end

      context "with data coordinator user" do
        let(:user) { create(:user, :data_coordinator) }

        before do
          sign_in user
          create_list(:scheme, 5, :duplicate, owning_organisation: organisation)
          get "/organisations/#{organisation.id}/schemes/duplicates", headers:
        end

        it "has page heading" do
          expect(page).to have_content("Review these sets of schemes")
        end
      end

      context "with data provider user" do
        let(:user) { create(:user, :data_provider) }

        before do
          sign_in user
          get "/organisations/#{organisation.id}/schemes/duplicates", headers:
        end

        it "be unauthorised" do
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    describe "#show" do
      context "with an organisation that the user belongs to" do
        let(:set_time) {}

        before do
          set_time
          sign_in user
          get "/organisations/#{organisation.id}", headers:, params: {}
        end

        it "redirects to details" do
          expect(response).to have_http_status(:redirect)
        end
      end

      context "with an organisation that are not in scope for the user, i.e. that they do not belong to" do
        before do
          sign_in user
          get "/organisations/#{unauthorised_organisation.id}", headers:, params: {}
        end

        it "returns not found 404 from org route" do
          expect(response).to have_http_status(:not_found)
        end

        it "shows the 404 view" do
          expect(page).to have_content("Page not found")
        end
      end
    end

    context "with a data coordinator user" do
      before do
        sign_in user
      end

      context "when we access the details tab" do
        context "with an organisation that the user belongs to" do
          before do
            get "/organisations/#{organisation.id}/details", headers:, params: {}
          end

          it "shows the tab navigation" do
            expected_html = "<nav aria-label=\"Menu\" class=\"govuk-service-navigation__wrapper\""
            expect(response.body).to include(expected_html)
          end

          it "shows a summary list of org details" do
            expected_html = "<dl class=\"govuk-summary-list\""
            expect(response.body).to include(expected_html)
            expect(CGI.unescapeHTML(response.body)).to include(organisation.name)
          end

          it "does not include a change details link" do
            expected_html = "data-qa=\"change-name\" href=\"/organisations/#{organisation.id}/edit\""
            expect(response.body).not_to include(expected_html)
          end

          it "displays a link to merge organisations" do
            expect(page).to have_content("To report a merge or update your organisation details, ")
            expect(page).to have_link("contact the helpdesk", href: "https://mhclgdigital.atlassian.net/servicedesk/customer/portal/6/group/11")
          end

          it "does not display merge history if there is none" do
            expect(page).not_to have_content("View all organisations that were merged into #{organisation.name}")
          end

          context "when the organisation has absorbed other organisations" do
            let!(:absorbed_organisation) { create(:organisation, name: "First Absorbed Organisation", with_dsa: false, merge_date: Time.zone.local(2023, 4, 3), absorbing_organisation: organisation) }
            let!(:other_absorbed_organisation) { create(:organisation, name: "Other Absorbed Organisation", with_dsa: false, merge_date: Time.zone.local(2023, 4, 3), absorbing_organisation: organisation) }
            let!(:previously_absorbed_organisation) { create(:organisation, name: "Previously Absorbed Organisation", with_dsa: false, merge_date: Time.zone.local(2023, 4, 2), absorbing_organisation: organisation) }

            before do
              get "/organisations/#{organisation.id}/details", headers:, params: {}
            end

            it "displays separate lists of absorbed organisations" do
              expect(page).to have_content("View all organisations that were merged into #{organisation.name}")
              expect(page).to have_content("Merge date: 3 April 2023")
              expect(page).to have_content("First Absorbed Organisation")
              expect(page).to have_content("Other Absorbed Organisation")
              expect(page).to have_content("Previously Absorbed Organisation")
              expect(page).to have_content("ORG#{absorbed_organisation.id}")
              expect(page).to have_content("ORG#{other_absorbed_organisation.id}")
              expect(page).to have_content("Merge date: 2 April 2023")
              expect(page).to have_content("ORG#{previously_absorbed_organisation.id}")
            end
          end

          context "when the organisation has absorbed other organisations during a closed collection period" do
            before do
              create(:organisation, name: "First Absorbed Organisation", with_dsa: false, merge_date: Time.zone.today - 2.years, absorbing_organisation: organisation)
              create(:organisation, name: "Other Absorbed Organisation", with_dsa: false, merge_date: Time.zone.today - 2.years, absorbing_organisation: organisation)
              get "/organisations/#{organisation.id}/details", headers:, params: {}
            end

            it "displays absorbed organisations" do
              expect(page).to have_content("View all organisations that were merged into #{organisation.name}")
              expect(page).to have_content("First Absorbed Organisation")
              expect(page).to have_content("Other Absorbed Organisation")
            end
          end

          context "when the organisation has absorbed other organisations during a collection period before archived" do
            before do
              create(:organisation, name: "First Absorbed Organisation", with_dsa: false, merge_date: Time.zone.today - 3.years, absorbing_organisation: organisation)
              create(:organisation, name: "Other Absorbed Organisation", with_dsa: false, merge_date: Time.zone.today - 3.years, absorbing_organisation: organisation)
              get "/organisations/#{organisation.id}/details", headers:, params: {}
            end

            it "does not display absorbed organisations" do
              expect(page).not_to have_content("View all organisations that were merged into #{organisation.name}")
              expect(page).not_to have_content("Merge date: 3 April 2021")
              expect(page).not_to have_content("First Absorbed Organisation")
              expect(page).not_to have_content("Other Absorbed Organisation")
            end
          end

          context "when the organisation has absorbed other organisations without merge dates" do
            let!(:absorbed_organisation) { create(:organisation, name: "First Absorbed Organisation", with_dsa: false, merge_date: Time.zone.local(2023, 4, 3), absorbing_organisation: organisation) }
            let!(:other_absorbed_organisation) { create(:organisation, name: "Other Absorbed Organisation", with_dsa: false, merge_date: Time.zone.local(2023, 4, 3), absorbing_organisation: organisation) }

            before do
              get "/organisations/#{organisation.id}/details", headers:, params: {}
            end

            it "displays a list of absorbed organisations" do
              expect(page).to have_content("View all organisations that were merged into #{organisation.name}")
              expect(page).to have_content("Merge date:")
              expect(page).to have_content("First Absorbed Organisation")
              expect(page).to have_content("Other Absorbed Organisation")
              expect(page).to have_content("ORG#{absorbed_organisation.id}")
              expect(page).to have_content("ORG#{other_absorbed_organisation.id}")
            end
          end

          context "when viewing absorbed organisation" do
            let(:absorbing_organisation) { create(:organisation, name: "First Absorbing Organisation") }

            context "and your organisation was absorbed" do
              before do
                organisation.update!(merge_date: Time.zone.local(2023, 4, 3), absorbing_organisation:)
                get "/organisations/#{organisation.id}/details", headers:, params: {}
              end

              it "displays the organisation merge details" do
                expect(response).not_to have_http_status(:not_found)
                expect(page).to have_content("#{organisation.name} was merged into First Absorbing Organisation on 3 April 2023.")
              end
            end
          end
        end

        context "with organisation that are not in scope for the user, i.e. that they do not belong to" do
          before do
            get "/organisations/#{unauthorised_organisation.id}/details", headers:, params: {}
          end

          it "returns not found 404 from org details route" do
            expect(response).to have_http_status(:not_found)
          end
        end
      end

      context "when accessing the users tab" do
        context "with an organisation that the user belongs to" do
          let!(:other_user) { create(:user, organisation: user.organisation, name: "User 2") }
          let!(:inactive_user) { create(:user, organisation: user.organisation, active: false, name: "User 3") }
          let!(:other_org_user) { create(:user, name: "User 4") }

          before do
            get "/organisations/#{organisation.id}/users", headers:, params: {}
          end

          it "shows the tab navigation" do
            expected_html = "<nav aria-label=\"Menu\" class=\"govuk-service-navigation__wrapper\""
            expect(response.body).to include(expected_html)
          end

          it "shows a new user button" do
            expect(page).to have_link("Invite user")
          end

          it "shows a table of users" do
            expected_html = "<table class=\"govuk-table\""
            expect(response.body).to include(expected_html)
            expect(response.body).to include(user.email)
          end

          it "shows hidden accessibility fields only for active users in the current user's organisation" do
            expected_case_row_log = "<span class=\"govuk-visually-hidden\">User </span><span class=\"govuk-!-font-weight-regular app-!-colour-muted\">#{user.email}</span>"
            unauthorized_case_row_log = "<span class=\"govuk-visually-hidden\">User </span><span class=\"govuk-!-font-weight-regular app-!-colour-muted\">#{other_org_user.email}</span>"
            expect(CGI.unescape_html(response.body)).to include(expected_case_row_log)
            expect(CGI.unescape_html(response.body)).not_to include(unauthorized_case_row_log)
          end

          it "shows only active users in the current user's organisation" do
            expect(page).to have_content(user.name)
            expect(page).to have_content(other_user.name)
            expect(page).to have_content(inactive_user.name)
            expect(page).not_to have_content(other_org_user.name)
          end

          it "shows the pagination count" do
            expect(page).to have_content("#{user.organisation.users.count} total users")
          end
        end

        context "with an organisation that are not in scope for the user, i.e. that they do not belong to" do
          before do
            get "/organisations/#{unauthorised_organisation.id}/users", headers:, params: {}
          end

          it "returns not found 404 from users page" do
            expect(response).to have_http_status(:not_found)
          end
        end
      end

      describe "#edit" do
        context "with an organisation that the user belongs to" do
          before do
            get "/organisations/#{organisation.id}/edit", headers:, params: {}
          end

          it "shows an edit form without name field" do
            expect(CGI.unescapeHTML(response.body)).to include("Change #{organisation.name}’s details")
            expect(page).not_to have_field("organisation-name-field")
            expect(page).to have_field("organisation-phone-field")
          end
        end

        context "with an organisation that the user does not belong to" do
          before do
            get "/organisations/#{unauthorised_organisation.id}/edit", headers:, params: {}
          end

          it "returns a 404 not found" do
            expect(response).to have_http_status(:not_found)
          end

          it "shows the 404 view" do
            expect(page).to have_content("Page not found")
          end
        end
      end

      describe "#update" do
        context "with an organisation that the user belongs to" do
          before do
            patch "/organisations/#{organisation.id}", headers:, params:
          end

          it "updates the org" do
            organisation.reload
            expect(organisation.name).to eq(new_value)
          end

          it "redirects to the organisation details page" do
            expect(response).to redirect_to("/organisations/#{organisation.id}/details")
          end

          it "shows a success banner" do
            follow_redirect!
            expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
          end

          it "tracks who updated the record" do
            organisation.reload
            whodunnit_actor = organisation.versions.last.actor
            expect(whodunnit_actor).to be_a(User)
            expect(whodunnit_actor.id).to eq(user.id)
          end

          context "with active parameter true" do
            let(:active) { true }

            it "redirects" do
              expect(response).to have_http_status(:unauthorized)
            end
          end

          context "with active parameter false" do
            let(:active) { false }

            it "redirects" do
              expect(response).to have_http_status(:unauthorized)
            end
          end
        end

        context "with an organisation that the user does not belong to" do
          before do
            patch "/organisations/#{unauthorised_organisation.id}", headers:, params: {}
          end

          it "returns a 404 not found" do
            expect(response).to have_http_status(:not_found)
          end
        end
      end

      context "when viewing lettings logs for other organisation" do
        it "does not display the lettings logs" do
          get "/organisations/#{unauthorised_organisation.id}/lettings-logs", headers:, params: {}
          expect(response).to have_http_status(:unauthorized)
        end

        it "prevents CSV download" do
          expect {
            post "/organisations/#{unauthorised_organisation.id}/lettings-logs/email-csv", headers:, params: {}
          }.not_to enqueue_job(EmailCsvJob)
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "when viewing lettings logs for your organisation" do
        it "does not display the logs" do
          get "/organisations/#{organisation.id}/lettings-logs", headers:, params: {}
          expect(response).to have_http_status(:unauthorized)
        end

        it "prevents CSV download" do
          expect {
            post "/organisations/#{organisation.id}/lettings-logs/email-csv", headers:, params: {}
          }.not_to enqueue_job(EmailCsvJob)
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "when viewing sales logs for other organisation" do
        it "does not display the sales logs" do
          get "/organisations/#{unauthorised_organisation.id}/sales-logs", headers:, params: {}
          expect(response).to have_http_status(:unauthorized)
        end

        it "prevents CSV download" do
          expect {
            post "/organisations/#{unauthorised_organisation.id}/sales-logs/email-csv", headers:, params: {}
          }.not_to enqueue_job(EmailCsvJob)
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "when viewing sales logs for your organisation" do
        it "does not display the logs" do
          get "/organisations/#{organisation.id}/sales-logs", headers:, params: {}
          expect(response).to have_http_status(:unauthorized)
        end

        it "prevents CSV download" do
          expect {
            post "/organisations/#{organisation.id}/sales-logs/email-csv", headers:, params: {}
          }.not_to enqueue_job(EmailCsvJob)
          expect(response).to have_http_status(:unauthorized)
        end
      end

      describe "#index" do
        before do
          get "/organisations", headers:, params:
        end

        it "redirects to the user's organisation" do
          expect(response).to redirect_to("/organisations/#{user.organisation.id}")
        end
      end

      describe "#new" do
        let(:request) { get "/organisations/new", headers:, params: }

        it "returns 401 unauthorized" do
          request
          expect(response).to have_http_status(:unauthorized)
        end
      end

      describe "#create" do
        let(:params) do
          {
            "organisation": {
              name: "new organisation",
              address_line1: "12 Random Street",
              address_line2: "Manchester",
              postcode: "MD1 5TR",
              phone: "011101101",
              provider_type: "LA",
              holds_own_stock: "true",
              housing_registration_no: "7917937",
              rent_periods: [],
            },
          }
        end
        let(:request) { post "/organisations", headers:, params: }

        it "returns 401 unauthorized" do
          request
          expect(response).to have_http_status(:unauthorized)
        end

        it "does not create an organisation" do
          expect { request }.not_to change(Organisation, :count)
        end
      end

      describe "#merge" do
        context "with an organisation that the user belongs to" do
          before do
            get "/organisations/#{organisation.id}/merge-request", headers:, params: {}
          end

          it "shows the correct content" do
            expect(page).to have_content("Tell us if your organisation is merging")
          end

          it "has a correct back link" do
            expect(page).to have_link("Back", href: "/organisations/#{organisation.id}")
          end

          it "has a correct start now button" do
            expect(page).to have_button("Start now")
          end
        end

        context "with organisation that are not in scope for the user, i.e. that they do not belong to" do
          before do
            get "/organisations/#{unauthorised_organisation.id}/merge-request", headers:, params: {}
          end

          it "returns not found 404 from org details route" do
            expect(response).to have_http_status(:not_found)
          end
        end
      end

      describe "#delete-confirmation" do
        let(:organisation) { user.organisation }

        before do
          get "/organisations/#{organisation.id}/delete-confirmation"
        end

        context "with a data provider user" do
          let(:user) { create(:user) }

          it "returns 401 unauthorized" do
            expect(response).to have_http_status(:unauthorized)
          end
        end
      end

      describe "#delete" do
        let(:organisation) { user.organisation }

        before do
          delete "/organisations/#{organisation.id}/delete"
        end

        context "with a data provider user" do
          let(:user) { create(:user) }

          it "returns 401 unauthorized" do
            expect(response).to have_http_status(:unauthorized)
          end
        end
      end

      describe "#search" do
        let(:parent_organisation) { create(:organisation, name: "parent test organisation") }
        let(:child_organisation) { create(:organisation, name: "child test organisation") }

        before do
          user.organisation.update!(name: "test organisation")
          create(:organisation_relationship, parent_organisation: user.organisation, child_organisation:)
          create(:organisation_relationship, child_organisation: user.organisation, parent_organisation:)
          create(:organisation, name: "other organisation test organisation")
        end

        it "only searches within the current user's organisation, managing agents and stock owners" do
          get "/organisations/search", headers:, params: { query: "test organisation" }
          result = JSON.parse(response.body)
          expect(result.count).to eq(3)
          expect(result.keys).to match_array([user.organisation.id.to_s, parent_organisation.id.to_s, child_organisation.id.to_s])
        end
      end
    end

    context "with a data provider user" do
      let(:user) { create(:user) }

      before do
        sign_in user
      end

      context "when accessing the details tab" do
        context "with an organisation that the user belongs to" do
          before do
            get "/organisations/#{organisation.id}/details", headers:, params: {}
          end

          it "shows the tab navigation" do
            expected_html = "<nav aria-label=\"Menu\" class=\"govuk-service-navigation__wrapper\""
            expect(response.body).to include(expected_html)
          end

          it "shows a summary list of org details" do
            expected_html = "<dl class=\"govuk-summary-list\""
            expect(response.body).to include(expected_html)
            expect(CGI.unescapeHTML(response.body)).to include(organisation.name)
          end

          it "does not have a change details link" do
            expected_html = "data-qa=\"change-name\" href=\"/organisations/#{organisation.id}/edit\""
            expect(response.body).not_to include(expected_html)
          end
        end

        context "with an organisation that is not in scope for the user, i.e. that they do not belong to" do
          before do
            sign_in user
            get "/organisations/#{unauthorised_organisation.id}/details", headers:, params: {}
          end

          it "returns not found 404" do
            expect(response).to have_http_status(:not_found)
          end
        end
      end

      context "when accessing the users tab" do
        before do
          get "/organisations/#{organisation.id}/users", headers:, params: {}
        end

        it "returns 200" do
          expect(response).to have_http_status(:ok)
        end
      end

      describe "#edit" do
        before do
          get "/organisations/#{organisation.id}/edit", headers:, params: {}
        end

        it "redirects to home" do
          expect(response).to have_http_status(:unauthorized)
        end
      end

      describe "#update" do
        before do
          patch "/organisations/#{organisation.id}", headers:, params:
        end

        it "redirects to home" do
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "when viewing lettings logs for other organisation" do
        it "does not display the logs" do
          get "/organisations/#{unauthorised_organisation.id}/lettings-logs", headers:, params: {}
          expect(response).to have_http_status(:unauthorized)
        end

        it "prevents CSV download" do
          expect {
            post "/organisations/#{unauthorised_organisation.id}/lettings-logs/email-csv", headers:, params: {}
          }.not_to enqueue_job(EmailCsvJob)
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "when viewing lettings logs for your organisation" do
        it "does not display the logs" do
          get "/organisations/#{organisation.id}/lettings-logs", headers:, params: {}
          expect(response).to have_http_status(:unauthorized)
        end

        it "prevents CSV download" do
          expect {
            post "/organisations/#{organisation.id}/lettings-logs/email-csv", headers:, params: {}
          }.not_to enqueue_job(EmailCsvJob)
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "when viewing sales logs for other organisation" do
        it "does not display the logs" do
          get "/organisations/#{unauthorised_organisation.id}/sales-logs", headers:, params: {}
          expect(response).to have_http_status(:unauthorized)
        end

        it "prevents CSV download" do
          expect {
            post "/organisations/#{unauthorised_organisation.id}/sales-logs/email-csv", headers:, params: {}
          }.not_to enqueue_job(EmailCsvJob)
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "when viewing sales logs for your organisation" do
        it "does not display the logs" do
          get "/organisations/#{organisation.id}/sales-logs", headers:, params: {}
          expect(response).to have_http_status(:unauthorized)
        end

        it "prevents CSV download" do
          expect {
            post "/organisations/#{organisation.id}/sales-logs/email-csv", headers:, params: {}
          }.not_to enqueue_job(EmailCsvJob)
          expect(response).to have_http_status(:unauthorized)
        end
      end

      describe "#delete-confirmation" do
        let(:organisation) { user.organisation }

        before do
          get "/organisations/#{organisation.id}/delete-confirmation"
        end

        context "with a data provider user" do
          let(:user) { create(:user) }

          it "returns 401 unauthorized" do
            expect(response).to have_http_status(:unauthorized)
          end
        end
      end

      describe "#delete" do
        let(:organisation) { user.organisation }

        before do
          delete "/organisations/#{organisation.id}/delete"
        end

        context "with a data provider user" do
          let(:user) { create(:user) }

          it "returns 401 unauthorized" do
            expect(response).to have_http_status(:unauthorized)
          end
        end
      end
    end

    context "with a support user" do
      let(:user) { create(:user, :support) }

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
      end

      describe "#new" do
        let(:request) { get "/organisations/new", headers:, params: }

        it "shows the create organisation form" do
          request
          expect(page).to have_field("organisation[name]")
          expect(page).to have_field("organisation[phone]")
          expect(page).to have_field("organisation[provider_type]")
          expect(page).to have_field("organisation[address_line1]")
          expect(page).to have_field("organisation[address_line2]")
          expect(page).to have_field("organisation[postcode]")
          expect(page).to have_field("organisation[holds_own_stock]")
        end
      end

      describe "#index" do
        before do
          get "/organisations", headers:, params: {}
        end

        it "shows the organisation list" do
          expect(page).to have_content("Organisations")
        end

        it "has a create new organisation button" do
          expect(page).to have_link("Create a new organisation", href: "/organisations/new")
        end

        it "shows all organisations" do
          total_number_of_orgs = Organisation.all.count
          expect(page).to have_link organisation.name, href: "organisations/#{organisation.id}/lettings-logs"
          expect(page).to have_link unauthorised_organisation.name, href: "organisations/#{unauthorised_organisation.id}/lettings-logs"
          expect(page).to have_content("#{total_number_of_orgs} total organisations")
        end

        it "shows a search bar" do
          expect(page).to have_field("search", type: "search")
        end

        it "shows the merge request list" do
          expect(page).to have_content("Merge requests")
        end

        it "has a create new merge request button" do
          expect(page).to have_button("Create new merge request")
        end

        it "displays 'No merge requests' when @merge_requests is empty" do
          allow(MergeRequest).to receive(:visible).and_return(nil)
          expect(page).to have_content("No merge requests")
        end

        context "when viewing a specific organisation's lettings logs" do
          let(:parent_organisation) { create(:organisation) }
          let(:child_organisation) { create(:organisation) }
          let(:number_of_owned_org1_lettings_logs) { 2 }
          let(:number_of_managed_org1_lettings_logs) { 2 }
          let(:number_of_owned_and_managed_org1_lettings_logs) { 2 }
          let(:total_number_of_org1_logs) { number_of_owned_org1_lettings_logs + number_of_managed_org1_lettings_logs + number_of_owned_and_managed_org1_lettings_logs }
          let(:number_of_org2_lettings_logs) { 4 }

          before do
            create(:organisation_relationship, child_organisation: organisation, parent_organisation:)
            create(:organisation_relationship, child_organisation:, parent_organisation: organisation)
            create_list(:lettings_log, number_of_owned_org1_lettings_logs, assigned_to: user, owning_organisation: organisation, managing_organisation: child_organisation)
            create_list(:lettings_log, number_of_managed_org1_lettings_logs, assigned_to: user, owning_organisation: parent_organisation, managing_organisation: organisation)
            create_list(:lettings_log, number_of_owned_and_managed_org1_lettings_logs, assigned_to: user, owning_organisation: organisation, managing_organisation: organisation)
            create(:lettings_log, assigned_to: user, status: "pending")
            create_list(:lettings_log, number_of_org2_lettings_logs, assigned_to: nil, owning_organisation_id: unauthorised_organisation.id, managing_organisation_id: unauthorised_organisation.id)

            get "/organisations/#{organisation.id}/lettings-logs", headers:, params: {}
          end

          it "only shows logs for that organisation" do
            expect(page).to have_content("#{total_number_of_org1_logs} total logs")

            organisation.lettings_logs.visible.map(&:id).each do |lettings_log_id|
              expect(page).to have_link lettings_log_id.to_s, href: "/lettings-logs/#{lettings_log_id}"
            end

            organisation.managed_lettings_logs.visible.map(&:id).each do |lettings_log_id|
              expect(page).to have_link lettings_log_id.to_s, href: "/lettings-logs/#{lettings_log_id}"
            end

            unauthorised_organisation.lettings_logs.map(&:id).each do |lettings_log_id|
              expect(page).not_to have_link lettings_log_id.to_s, href: "/lettings-logs/#{lettings_log_id}"
            end
          end

          it "has filters" do
            expect(page).to have_content("Filters")
            expect(page).to have_content("Collection year")
          end

          it "does not have specific organisation filter" do
            expect(page).not_to have_content("Specific organisation")
          end

          it "has a sub-navigation with correct tabs" do
            expect(page).to have_css(".app-sub-navigation")
            expect(page).to have_content("About this organisation")
          end

          context "when using a search query" do
            let(:logs) { create_list(:lettings_log, 3, :completed, owning_organisation: user.organisation, assigned_to: user) }
            let(:log_to_search) { create(:lettings_log, :completed, owning_organisation: user.organisation, assigned_to: user) }
            let(:log_total_count) { LettingsLog.where(owning_organisation: user.organisation).count }

            it "has search results in the title" do
              get "/organisations/#{organisation.id}/lettings-logs?search=#{log_to_search.id}", headers: headers, params: {}
              expect(page).to have_title("#{organisation.name} (1 log matching ‘#{log_to_search.id}’) - Submit social housing lettings and sales data (CORE) - GOV.UK")
            end

            it "has search term in the search box" do
              get "/organisations/#{organisation.id}/lettings-logs?search=#{log_to_search.id}", headers: headers, params: {}
              expect(page).to have_field("search", with: log_to_search.id.to_s)
            end

            it "shows lettings logs matching the id" do
              get "/organisations/#{organisation.id}/lettings-logs?search=#{log_to_search.id}", headers: headers, params: {}
              expect(page).to have_link(log_to_search.id.to_s)
              logs.each do |log|
                expect(page).not_to have_link(log.id.to_s)
              end
            end

            it "shows lettings logs matching the tenant code" do
              get "/organisations/#{organisation.id}/lettings-logs?search=#{log_to_search.tenancycode}", headers: headers, params: {}
              expect(page).to have_link(log_to_search.id.to_s)
              logs.each do |log|
                expect(page).not_to have_link(log.id.to_s)
              end
            end

            it "shows lettings logs matching the property reference" do
              get "/organisations/#{organisation.id}/lettings-logs?search=#{log_to_search.propcode}", headers: headers, params: {}
              expect(page).to have_link(log_to_search.id.to_s)
              logs.each do |log|
                expect(page).not_to have_link(log.id.to_s)
              end
            end

            it "shows lettings logs matching the property postcode" do
              get "/organisations/#{organisation.id}/lettings-logs?search=#{log_to_search.postcode_full}", headers: headers, params: {}
              expect(page).to have_link(log_to_search.id.to_s)
              logs.each do |log|
                expect(page).not_to have_link(log.id.to_s)
              end
            end

            context "when more than one results with matching postcode" do
              let!(:matching_postcode_log) { create(:lettings_log, :completed, owning_organisation: user.organisation, postcode_full: log_to_search.postcode_full) }

              it "displays all matching logs" do
                get "/organisations/#{organisation.id}/lettings-logs?search=#{log_to_search.postcode_full}", headers: headers, params: {}
                expect(page).to have_link(log_to_search.id.to_s)
                expect(page).to have_link(matching_postcode_log.id.to_s)
                logs.each do |log|
                  expect(page).not_to have_link(log.id.to_s)
                end
              end
            end

            context "when there are more than 1 page of search results" do
              let(:postcode) { "XX11YY" }
              let(:logs) { create_list(:lettings_log, 30, :completed, owning_organisation: user.organisation, postcode_full: postcode) }
              let(:log_total_count) { LettingsLog.where(owning_organisation: user.organisation).count }

              it "has title with pagination details for page 1" do
                get "/organisations/#{organisation.id}/lettings-logs?search=#{logs[0].postcode_full}", headers: headers, params: {}
                expect(page).to have_title("#{organisation.name} (#{logs.count} logs matching ‘#{postcode}’) (page 1 of 2) - Submit social housing lettings and sales data (CORE) - GOV.UK")
              end

              it "has title with pagination details for page 2" do
                get "/organisations/#{organisation.id}/lettings-logs?search=#{logs[0].postcode_full}&page=2", headers: headers, params: {}
                expect(page).to have_title("#{organisation.name} (#{logs.count} logs matching ‘#{postcode}’) (page 2 of 2) - Submit social housing lettings and sales data (CORE) - GOV.UK")
              end
            end

            context "when search query doesn't match any logs" do
              it "doesn't display any logs" do
                get "/organisations/#{organisation.id}/lettings-logs?search=foobar", headers:, params: {}
                logs.each do |log|
                  expect(page).not_to have_link(log.id.to_s)
                end
                expect(page).not_to have_link(log_to_search.id.to_s)
              end
            end

            context "when search query is empty" do
              it "doesn't display any logs" do
                get "/organisations/#{organisation.id}/lettings-logs?search=", headers:, params: {}
                logs.each do |log|
                  expect(page).not_to have_link(log.id.to_s)
                end
                expect(page).not_to have_link(log_to_search.id.to_s)
              end
            end

            context "when search and filter is present" do
              let(:matching_postcode) { log_to_search.postcode_full }
              let(:matching_status) { "in_progress" }
              let!(:log_matching_filter_and_search) { create(:lettings_log, :in_progress, owning_organisation: user.organisation, postcode_full: matching_postcode, assigned_to: user) }

              it "shows only logs matching both search and filters" do
                get "/organisations/#{organisation.id}/lettings-logs?search=#{matching_postcode}&status[]=#{matching_status}", headers: headers, params: {}
                expect(page).to have_link(log_matching_filter_and_search.id.to_s)
                expect(page).not_to have_link(log_to_search.id.to_s)
                logs.each do |log|
                  expect(page).not_to have_link(log.id.to_s)
                end
              end
            end
          end

          context "when the organisation has absorbed another organisation" do
            let(:absorbed_organisation) { create(:organisation) }
            let(:number_of_absorbed_org_lettings_logs) { 3 }
            let(:lettings_log) { create(:lettings_log, owning_organisation: absorbed_organisation) }

            before do
              organisation.update!(absorbed_organisations: [absorbed_organisation])
              create_list(:lettings_log, number_of_absorbed_org_lettings_logs, owning_organisation: absorbed_organisation)
            end

            context "without search query" do
              before do
                get "/organisations/#{organisation.id}/lettings-logs", headers:, params: {}
              end

              it "returns a count of all logs for both the merging and absorbed organisations" do
                expect(page).to have_content("#{total_number_of_org1_logs + number_of_absorbed_org_lettings_logs} total logs")
              end
            end

            context "when searching for an absorbing organisation by ID" do
              before do
                get "/organisations/#{organisation.id}/lettings-logs?search=#{lettings_log.id}", headers:, params: {}
              end

              it "displays the lettings log from the absorbed organisation" do
                expect(page).to have_content(lettings_log.id)
              end
            end
          end
        end

        context "when viewing a specific organisation's sales logs" do
          let(:number_of_org1_sales_logs) { 2 }
          let(:number_of_org2_sales_logs) { 4 }

          before do
            create_list(:sales_log, number_of_org1_sales_logs, owning_organisation_id: organisation.id)
            create_list(:sales_log, number_of_org2_sales_logs, owning_organisation_id: unauthorised_organisation.id)

            get "/organisations/#{organisation.id}/sales-logs", headers:, params: {}
          end

          it "only shows logs for that organisation" do
            expect(page).to have_content("#{number_of_org1_sales_logs} total logs")
            organisation.sales_logs.map(&:id).each do |sales_log_id|
              expect(page).to have_link sales_log_id.to_s, href: "/sales-logs/#{sales_log_id}"
            end

            unauthorised_organisation.sales_logs.map(&:id).each do |sales_log_id|
              expect(page).not_to have_link sales_log_id.to_s, href: "/sales-logs/#{sales_log_id}"
            end
          end

          it "has filters" do
            expect(page).to have_content("Filters")
            expect(page).to have_content("Collection year")
          end

          it "does not have specific organisation filter" do
            expect(page).not_to have_content("Specific organisation")
          end

          it "has a sub-navigation with correct tabs" do
            expect(page).to have_css(".app-sub-navigation")
            expect(page).to have_content("About this organisation")
          end

          context "when using a search query" do
            let(:logs) { create_list(:sales_log, 3, :completed, owning_organisation: user.organisation, assigned_to: user) }
            let(:log_to_search) { create(:sales_log, :completed, owning_organisation: user.organisation, assigned_to: user) }
            let(:log_total_count) { LettingsLog.where(owning_organisation: user.organisation).count }

            it "has search results in the title" do
              get "/organisations/#{organisation.id}/sales-logs?search=#{log_to_search.id}", headers: headers, params: {}
              expect(page).to have_title("#{organisation.name} (1 log matching ‘#{log_to_search.id}’) - Submit social housing lettings and sales data (CORE) - GOV.UK")
            end

            it "shows sales logs matching the id" do
              get "/organisations/#{organisation.id}/sales-logs?search=#{log_to_search.id}", headers: headers, params: {}
              expect(page).to have_link(log_to_search.id.to_s)
              logs.each do |log|
                expect(page).not_to have_link(log.id.to_s)
              end
            end

            context "when search query doesn't match any logs" do
              it "doesn't display any logs" do
                get "/organisations/#{organisation.id}/sales-logs?search=foobar", headers:, params: {}
                logs.each do |log|
                  expect(page).not_to have_link(log.id.to_s)
                end
                expect(page).not_to have_link(log_to_search.id.to_s)
              end
            end

            context "when search query is empty" do
              it "doesn't display any logs" do
                get "/organisations/#{organisation.id}/sales-logs?search=", headers:, params: {}
                logs.each do |log|
                  expect(page).not_to have_link(log.id.to_s)
                end
                expect(page).not_to have_link(log_to_search.id.to_s)
              end
            end

            context "when search and filter is present" do
              let(:matching_status) { "completed" }
              let!(:log_matching_filter_and_search) { create(:sales_log, :completed, owning_organisation: user.organisation, assigned_to: user) }
              let(:matching_id) { log_matching_filter_and_search.id }

              it "shows only logs matching both search and filters" do
                get "/organisations/#{organisation.id}/sales-logs?search=#{matching_id}&status[]=#{matching_status}", headers: headers, params: {}
                expect(page).to have_link(log_matching_filter_and_search.id.to_s)
                expect(page).not_to have_link(log_to_search.id.to_s)
                logs.each do |log|
                  expect(page).not_to have_link(log.id.to_s)
                end
              end
            end
          end

          context "when the organisation has absorbed another organisation" do
            let(:absorbed_organisation) { create(:organisation) }
            let(:number_of_absorbed_org_sales_logs) { 3 }
            let(:sales_log) { create(:sales_log, owning_organisation: absorbed_organisation) }

            before do
              organisation.update!(absorbed_organisations: [absorbed_organisation])
              create_list(:sales_log, number_of_absorbed_org_sales_logs, owning_organisation: absorbed_organisation)
            end

            context "without search query" do
              before do
                get "/organisations/#{organisation.id}/sales-logs", headers:, params: {}
              end

              it "returns a count of all logs for both the merging and absorbed organisations" do
                expect(page).to have_content("#{number_of_org1_sales_logs + number_of_absorbed_org_sales_logs} total logs")
              end
            end

            context "when searching for an absorbing organisation by ID" do
              before do
                get "/organisations/#{organisation.id}/sales-logs?search=#{sales_log.id}", headers:, params: {}
              end

              it "displays the sales log from the absorbed organisation" do
                expect(page).to have_content(sales_log.id)
              end
            end
          end
        end

        context "when viewing a specific organisation's users" do
          let!(:users) { create_list(:user, 5, organisation:) }
          let!(:different_org_users) { create_list(:user, 5) }

          before do
            get "/organisations/#{organisation.id}/users", headers:, params: {}
          end

          it "displays the name of the organisation" do
            expect(page).to have_content(organisation.name)
          end

          it "has a sub-navigation with correct tabs" do
            expect(page).to have_css(".app-sub-navigation")
            expect(page).to have_content("Users")
          end

          it "displays users for this organisation" do
            expect(page).to have_content(user.email)
            users.each do |user|
              expect(page).to have_content(user.email)
            end
          end

          it "doesn't display users for other organisations" do
            different_org_users.each do |different_org_user|
              expect(page).not_to have_content(different_org_user.email)
            end
          end

          context "when a search parameter is passed" do
            let!(:matching_user) { create(:user, organisation:, name: "abcdefghijklmnopqrstuvwxyz", email: "matching@example.com") }
            let(:org_user_count) { User.where(organisation:).count }

            before do
              get "/organisations/#{user.organisation.id}/users?search=#{search_param}"
            end

            context "when our search string matches case" do
              let(:search_param) { "abcdefghijklmnopqrstuvwxyz" }

              it "returns only matching results" do
                expect(page).to have_content(matching_user.name)
                expect(page).not_to have_link(user.name)

                different_org_users.each do |different_org_user|
                  expect(page).not_to have_content(different_org_user.email)
                end

                users.each do |org_user|
                  expect(page).not_to have_content(org_user.email)
                end
              end

              it "updates the table caption" do
                expect(page).to have_content("1 user matching search")
              end

              context "when we need case insensitive search" do
                let(:search_param) { "Abcdefghijklmnopqrstuvwxyz" }

                it "returns only matching results" do
                  expect(page).to have_content(matching_user.name)
                  expect(page).not_to have_link(user.name)

                  different_org_users.each do |different_org_user|
                    expect(page).not_to have_content(different_org_user.email)
                  end

                  users.each do |org_user|
                    expect(page).not_to have_content(org_user.email)
                  end
                end

                it "updates the table caption" do
                  expect(page).to have_content("1 user matching search")
                end
              end
            end

            context "when our search term matches an email" do
              let(:search_param) { "matching@example.com" }

              it "returns only matching results" do
                expect(page).to have_content(matching_user.name)
                expect(page).not_to have_link(user.name)

                different_org_users.each do |different_org_user|
                  expect(page).not_to have_content(different_org_user.email)
                end

                users.each do |org_user|
                  expect(page).not_to have_content(org_user.email)
                end
              end

              it "updates the table caption" do
                expect(page).to have_content("1 user matching search")
              end

              context "when our search term matches an email and a name" do
                let!(:matching_user) { create(:user, organisation:, name: "Foobar", email: "some@example.com") }
                let!(:another_matching_user) { create(:user, organisation:, name: "Joe", email: "foobar@example.com") }
                let(:org_user_count) { User.where(organisation:).count }
                let(:search_param) { "Foobar" }

                before do
                  get "/organisations/#{user.organisation.id}/users?search=#{search_param}"
                end

                it "returns only matching results" do
                  expect(page).to have_link(matching_user.name)
                  expect(page).to have_link(another_matching_user.name)
                  expect(page).not_to have_link(user.name)

                  different_org_users.each do |different_org_user|
                    expect(page).not_to have_content(different_org_user.email)
                  end

                  users.each do |org_user|
                    expect(page).not_to have_content(org_user.email)
                  end
                end

                it "updates the table caption" do
                  expect(page).to have_content("2 users matching search")
                end
              end
            end
          end
        end

        context "when viewing a specific organisation's details" do
          before do
            get "/organisations/#{organisation.id}/details", headers:, params: {}
          end

          it "displays the name of the organisation" do
            expect(page).to have_content(organisation.name)
          end

          it "has a sub-navigation with correct tabs" do
            expect(page).to have_css(".app-sub-navigation")
            expect(page).to have_content("About this organisation")
          end

          it "allows to edit the organisation details" do
            expect(page).to have_link("Change")
          end
        end

        context "when there are more than 20 organisations" do
          let(:total_organisations_count) { Organisation.all.count }

          before do
            build_list(:organisation, 25) do |organisation, index|
              organisation.name = "Organisation #{index}"
              organisation.save!
            end
            get "/organisations"
          end

          context "when on the first page" do
            it "has pagination links" do
              expect(page).not_to have_content("Previous")
              expect(page).not_to have_link("Previous")
              expect(page).to have_content("Next")
              expect(page).to have_link("Next")
            end

            it "shows which organisations are being shown on the current page" do
              expect(CGI.unescape_html(response.body)).to match("Showing <b>1</b> to <b>20</b> of <b>#{total_organisations_count}</b> organisations")
            end

            it "has pagination in the title" do
              expect(page).to have_title("Organisations (page 1 of 2)")
            end
          end

          context "when on the second page" do
            before do
              get "/organisations?page=2", headers:, params: {}
            end

            it "shows the total organisations count" do
              expect(CGI.unescape_html(response.body)).to match("<strong>#{total_organisations_count}</strong> total organisations")
            end

            it "has pagination links" do
              expect(page).to have_content("Previous")
              expect(page).to have_link("Previous")
              expect(page).not_to have_content("Next")
              expect(page).not_to have_link("Next")
            end

            it "shows which logs are being shown on the current page" do
              expect(CGI.unescape_html(response.body)).to match("Showing <b>21</b> to <b>#{total_organisations_count}</b> of <b>#{total_organisations_count}</b> organisations")
            end

            it "has pagination in the title" do
              expect(page).to have_title("Organisations (page 2 of 2)")
            end
          end

          context "when searching" do
            let!(:searched_organisation) { create(:organisation, name: "Unusual name") }
            let!(:other_organisation) { create(:organisation, name: "Some other name") }
            let(:search_param) { "Unusual" }

            before do
              get "/organisations?search=#{search_param}"
            end

            it "returns matching results" do
              expect(page).to have_content(searched_organisation.name)
              expect(page).not_to have_content(other_organisation.name)
            end

            it "updates the table caption" do
              expect(page).to have_content("1 organisation matching search")
            end

            it "has search in the title" do
              expect(page).to have_title("Organisations (1 organisation matching ‘#{search_param}’) - Submit social housing lettings and sales data (CORE) - GOV.UK")
            end

            context "when the search term matches more than 1 result" do
              let(:search_param) { "name" }

              it "returns matching results" do
                expect(page).to have_content(searched_organisation.name)
                expect(page).to have_content(other_organisation.name)
              end

              it "updates the table caption" do
                expect(page).to have_content("2 organisations matching search")
              end

              it "has search in the title" do
                expect(page).to have_title("Organisations (2 organisations matching ‘#{search_param}’) - Submit social housing lettings and sales data (CORE) - GOV.UK")
              end
            end

            context "when search results require pagination" do
              let(:search_param) { "MHCLG" }

              before do
                build_list(:organisation, 27) do |organisation, index|
                  organisation.name = "MHCLG #{index}"
                  organisation.save!
                end
                get "/organisations?search=#{search_param}"
              end

              it "has search and pagination in the title" do
                expect(page).to have_title("Organisations (27 organisations matching ‘#{search_param}’) (page 1 of 2) - Submit social housing lettings and sales data (CORE) - GOV.UK")
              end
            end
          end
        end
      end

      describe "#show" do
        let(:organisation) { create(:organisation) }

        before do
          get "/organisations/#{organisation.id}", headers:, params: {}
        end

        context "with an active organisation" do
          it "does not render delete this organisation" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).not_to have_link("Delete this organisation", href: "/organisations/#{organisation.id}/delete-confirmation")
          end

          it "does not render informative text about deleting the organisation" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).not_to have_content("This organisation was active in an open or editable collection year, and cannot be deleted.")
          end
        end

        context "with an inactive organisation" do
          let(:organisation) { create(:organisation, active: false) }

          it "renders delete this organisation" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_link("Delete this organisation", href: "/organisations/#{organisation.id}/delete-confirmation")
          end

          context "and associated lettings logs in editable collection period" do
            before do
              create(:lettings_log, owning_organisation: organisation)
              get "/organisations/#{organisation.id}"
            end

            it "does not render delete this organisation" do
              follow_redirect!
              expect(response).to have_http_status(:ok)
              expect(page).not_to have_link("Delete this organisation", href: "/organisations/#{organisation.id}/delete-confirmation")
            end

            it "adds informative text about deleting the organisation" do
              follow_redirect!
              expect(response).to have_http_status(:ok)
              expect(page).to have_content("This organisation was active in an open or editable collection year, and cannot be deleted.")
            end
          end

          context "and associated sales logs in editable collection period" do
            before do
              create(:sales_log, owning_organisation: organisation)
              get "/organisations/#{organisation.id}"
            end

            it "does not render delete this organisation" do
              follow_redirect!
              expect(response).to have_http_status(:ok)
              expect(page).not_to have_link("Delete this organisation", href: "/organisations/#{organisation.id}/delete-confirmation")
            end

            it "adds informative text about deleting the organisation" do
              follow_redirect!
              expect(response).to have_http_status(:ok)
              expect(page).to have_content("This organisation was active in an open or editable collection year, and cannot be deleted.")
            end
          end
        end

        context "with merged organisation" do
          before do
            organisation.update!(merge_date: Time.zone.yesterday)
            get "/organisations/#{organisation.id}", headers:, params: {}
          end

          it "renders delete this organisation" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_link("Delete this organisation", href: "/organisations/#{organisation.id}/delete-confirmation")
          end
        end
      end

      describe "#update" do
        let(:params) { { id: organisation.id, organisation: { active:, rent_periods: [], all_rent_periods: [] } } }

        context "with active parameter false" do
          let(:active) { false }

          user_to_update = nil

          before do
            user_to_update = create(:user, :data_coordinator, organisation:)
            patch "/organisations/#{organisation.id}", headers:, params:
          end

          it "deactivates associated users" do
            user_to_update.reload
            expect(user_to_update.active).to eq(false)
            expect(user_to_update.reactivate_with_organisation).to eq(true)
          end
        end

        context "with active parameter true" do
          user_to_reactivate = nil
          user_not_to_reactivate = nil

          let(:notify_client) { instance_double(Notifications::Client) }
          let(:devise_notify_mailer) { DeviseNotifyMailer.new }
          let(:active) { true }
          let(:expected_personalisation) do
            {
              name: user_to_reactivate.name,
              email: user_to_reactivate.email,
              organisation: organisation.name,
              link: include("/account/confirmation?confirmation_token="),
            }
          end

          before do
            allow(DeviseNotifyMailer).to receive(:new).and_return(devise_notify_mailer)
            allow(devise_notify_mailer).to receive(:notify_client).and_return(notify_client)
            allow(notify_client).to receive(:send_email).and_return(true)

            user_to_reactivate = create(:user, :data_coordinator, organisation:, active: false, reactivate_with_organisation: true)
            FactoryBot.create(:legacy_user, old_user_id: user_to_reactivate.old_user_id, user: user_to_reactivate)
            user_not_to_reactivate = create(:user, :data_coordinator, organisation:, active: false, reactivate_with_organisation: false)
            patch "/organisations/#{organisation.id}", headers:, params:
          end

          it "reactivates users deactivated with organisation" do
            user_to_reactivate.reload
            user_not_to_reactivate.reload
            expect(user_to_reactivate.active).to eq(true)
            expect(user_to_reactivate.reactivate_with_organisation).to eq(false)
            expect(user_not_to_reactivate.active).to eq(false)
          end

          it "sends invitation emails" do
            expect(notify_client).to have_received(:send_email).with(email_address: user_to_reactivate.email, template_id: User::CONFIRMABLE_TEMPLATE_ID, personalisation: expected_personalisation).once
          end
        end
      end

      describe "#deactivate" do
        before do
          get "/organisations/#{organisation.id}/deactivate", headers:, params: {}
        end

        it "shows deactivation page with deactivate and cancel buttons for the organisation" do
          expect(path).to include("/organisations/#{organisation.id}/deactivate")
          expect(page).to have_content(organisation.name)
          expect(page).to have_content("Are you sure you want to deactivate this organisation?")
          expect(page).to have_button("Deactivate this organisation")
          expect(page).to have_link("Cancel", href: "/organisations/#{organisation.id}")
        end
      end

      describe "#reactivate" do
        let(:inactive_organisation) { create(:organisation, name: "Inactive org", active: false) }

        before do
          get "/organisations/#{inactive_organisation.id}/reactivate", headers:, params: {}
        end

        it "shows reactivation page with reactivate and cancel buttons for the organisation" do
          expect(path).to include("/organisations/#{inactive_organisation.id}/reactivate")
          expect(page).to have_content(inactive_organisation.name)
          expect(page).to have_content("Are you sure you want to reactivate this organisation?")
          expect(page).to have_button("Reactivate this organisation")
          expect(page).to have_link("Cancel", href: "/organisations/#{inactive_organisation.id}")
        end
      end

      describe "#create" do
        let(:name) { " Unique new org name" }
        let(:address_line1) { "12 Random Street" }
        let(:address_line2) { "Manchester" }
        let(:postcode) { "MD1 5TR" }
        let(:phone) { "011101101" }
        let(:provider_type) { "LA" }
        let(:holds_own_stock) { "true" }
        let(:housing_registration_no) { "7917937" }
        let(:params) do
          {
            "organisation": {
              name:,
              address_line1:,
              address_line2:,
              postcode:,
              phone:,
              provider_type:,
              holds_own_stock:,
              housing_registration_no:,
              rent_periods: [],
            },
          }
        end
        let(:request) { post "/organisations", headers:, params: }

        it "creates a new organisation" do
          expect { request }.to change(Organisation, :count).by(1)
        end

        it "sets the organisation attributes correctly" do
          request
          organisation = Organisation.find_by(housing_registration_no:)
          expect(organisation.name).to eq("Unique new org name")
          expect(organisation.address_line1).to eq(address_line1)
          expect(organisation.address_line2).to eq(address_line2)
          expect(organisation.postcode).to eq(postcode)
          expect(organisation.phone).to eq(phone)
          expect(organisation.holds_own_stock).to be true
        end

        it "redirects to the organisation list" do
          request
          organisation = Organisation.find_by(housing_registration_no:)
          expect(response).to redirect_to organisation_path(organisation)
        end

        context "when required params are missing" do
          let(:name) { "" }
          let(:provider_type) { "" }

          it "displays the form with an error message" do
            request
            expect(response).to have_http_status(:unprocessable_content)
            expect(page).to have_content(I18n.t("validations.organisation.name_missing"))
            expect(page).to have_content(I18n.t("validations.organisation.provider_type_missing"))
          end
        end
      end

      describe "#delete-confirmation" do
        let(:organisation) { create(:organisation, active: false) }

        before do
          get "/organisations/#{organisation.id}/delete-confirmation"
        end

        it "shows the correct title" do
          expect(page.find("h1").text).to include "Are you sure you want to delete this organisation?"
        end

        it "shows a warning to the user" do
          expect(page).to have_selector(".govuk-warning-text", text: "You will not be able to undo this action")
        end

        it "shows a button to delete the selected organisation" do
          expect(page).to have_selector("form.button_to button", text: "Delete this organisation")
        end

        it "the delete organisation button submits the correct data to the correct path" do
          form_containing_button = page.find("form.button_to")

          expect(form_containing_button[:action]).to eq delete_organisation_path(organisation)
          expect(form_containing_button).to have_field "_method", type: :hidden, with: "delete"
        end

        it "shows a cancel link with the correct style" do
          expect(page).to have_selector("a.govuk-button--secondary", text: "Cancel")
        end

        it "shows cancel link that links back to the organisation page" do
          expect(page).to have_link(text: "Cancel", href: organisation_path(organisation))
        end
      end

      describe "#delete" do
        let(:organisation) { create(:organisation, active: false) }
        let!(:org_user) { create(:user, active: false, organisation:) }
        let!(:scheme) { create(:scheme, owning_organisation: organisation) }
        let!(:location) { create(:location, scheme:) }

        before do
          scheme.scheme_deactivation_periods << SchemeDeactivationPeriod.new(deactivation_date: Time.zone.yesterday)
          location.location_deactivation_periods << LocationDeactivationPeriod.new(deactivation_date: Time.zone.yesterday)
          delete "/organisations/#{organisation.id}/delete"
        end

        it "deletes the organisation and related resources" do
          organisation.reload
          expect(organisation.status).to eq(:deleted)
          expect(organisation.discarded_at).not_to be nil
          expect(location.reload.status).to eq(:deleted)
          expect(location.discarded_at).not_to be nil
          expect(scheme.reload.status).to eq(:deleted)
          expect(scheme.discarded_at).not_to be nil
          expect(org_user.reload.status).to eq(:deleted)
          expect(org_user.discarded_at).not_to be nil
        end

        it "redirects to the organisations list and displays a notice that the organisation has been deleted" do
          expect(response).to redirect_to organisations_path
          follow_redirect!
          expect(page).to have_selector(".govuk-notification-banner--success")
          expect(page).to have_selector(".govuk-notification-banner--success", text: "#{organisation.name} has been deleted.")
        end

        it "does not display the deleted organisation" do
          expect(response).to redirect_to organisations_path
          follow_redirect!
          expect(page).not_to have_content("Organisation to delete")
        end
      end

      context "when they view the lettings logs tab" do
        let(:tenancycode) { "42" }

        before do
          create(:lettings_log, :in_progress, owning_organisation: organisation, tenancycode:)
        end

        context "when there is at least one log visible" do
          before do
            get lettings_logs_organisation_path(organisation, search: tenancycode)
          end

          it "shows the delete logs button with the correct path" do
            expect(page).to have_link "Delete logs", href: delete_lettings_logs_organisation_path(search: tenancycode)
          end

          it "has CSV download buttons with the correct paths" do
            expect(page).to have_link "Download (CSV)", href: lettings_logs_csv_download_organisation_path(organisation, codes_only: false, search: tenancycode)
            expect(page).to have_link "Download (CSV, codes only)", href: lettings_logs_csv_download_organisation_path(organisation, codes_only: true, search: tenancycode)
          end
        end

        context "when there are no visible logs" do
          before do
            LettingsLog.destroy_all
            get lettings_logs_organisation_path(organisation)
          end

          it "does not show the delete logs button " do
            expect(page).not_to have_link "Delete logs"
          end

          it "does not show the csv download buttons" do
            expect(page).not_to have_link "Download (CSV)"
            expect(page).not_to have_link "Download (CSV, codes only)"
          end
        end

        context "when you download the CSV" do
          let(:other_organisation) { create(:organisation) }
          let!(:lettings_logs) { create_list(:lettings_log, 2, :in_progress, owning_organisation: organisation) }
          let(:lettings_log_start_year) { lettings_logs[0].form.start_date.year }

          before do
            create(:lettings_log, :in_progress, owning_organisation: organisation, status: "pending")
            create_list(:lettings_log, 2, :in_progress, owning_organisation: other_organisation)
          end

          context "when no year filters are applied" do
            it "redirects to years filter page" do
              get "/organisations/#{organisation.id}/lettings-logs/csv-download?codes_only=false"
              expect(response).to redirect_to("/organisations/#{organisation.id}/lettings-logs/filters/years?codes_only=false")
              follow_redirect!
              expect(page).to have_button("Save changes")
            end
          end

          it "only includes logs from that organisation" do
            get "/organisations/#{organisation.id}/lettings-logs/csv-download?years[]=#{lettings_log_start_year}&codes_only=false"
            expect(page).to have_text("You've selected 3 logs.")
          end

          it "provides the organisation to the mail job" do
            expect {
              post "/organisations/#{organisation.id}/lettings-logs/email-csv?years[]=#{lettings_log_start_year}&status[]=completed&codes_only=false", headers:, params: {}
            }.to enqueue_job(EmailCsvJob).with(user, nil, { "status" => %w[completed], "years" => [lettings_log_start_year.to_s] }, false, organisation, false, "lettings", lettings_log_start_year)
          end

          it "provides the export type to the mail job" do
            codes_only_export_type = false
            expect {
              post "/organisations/#{organisation.id}/lettings-logs/email-csv?years[]=#{lettings_log_start_year}&codes_only=#{codes_only_export_type}", headers:, params: {}
            }.to enqueue_job(EmailCsvJob).with(user, nil, { "years" => [lettings_log_start_year.to_s] }, false, organisation, codes_only_export_type, "lettings", lettings_log_start_year)
            codes_only_export_type = true
            expect {
              post "/organisations/#{organisation.id}/lettings-logs/email-csv?years[]=#{lettings_log_start_year}&codes_only=#{codes_only_export_type}", headers:, params: {}
            }.to enqueue_job(EmailCsvJob).with(user, nil, { "years" => [lettings_log_start_year.to_s] }, false, organisation, codes_only_export_type, "lettings", lettings_log_start_year)
          end
        end

        context "when filters are applied" do
          before do
            get lettings_logs_organisation_path(organisation, status: %w[completed])
          end

          it "has clear filters link" do
            expect(page).to have_link("Clear", href: clear_filters_path(filter_type: "lettings_logs", filter_path_params: { organisation_id: organisation.id }))
          end
        end
      end

      context "when they view the sales logs tab" do
        before do
          create(:sales_log, :in_progress, owning_organisation: organisation)
        end

        it "has CSV download buttons with the correct paths if at least 1 log exists" do
          get "/organisations/#{organisation.id}/sales-logs"
          expect(page).to have_link("Download (CSV)", href: "/organisations/#{organisation.id}/sales-logs/csv-download?codes_only=false")
          expect(page).to have_link("Download (CSV, codes only)", href: "/organisations/#{organisation.id}/sales-logs/csv-download?codes_only=true")
        end

        context "when you download the CSV" do
          let(:other_organisation) { create(:organisation) }
          let(:sales_logs_start_year) { organisation.owned_sales_logs.first.form.start_date.year }

          before do
            create_list(:sales_log, 2, :in_progress, owning_organisation: organisation)
            create(:sales_log, :in_progress, owning_organisation: organisation, status: "pending")
            create_list(:sales_log, 2, :in_progress, owning_organisation: other_organisation)
          end

          it "only includes logs from that organisation" do
            get "/organisations/#{organisation.id}/sales-logs/csv-download?years[]=#{sales_logs_start_year}&codes_only=false"

            expect(page).to have_text("You've selected 3 logs.")
          end

          it "provides the organisation to the mail job" do
            expect {
              post "/organisations/#{organisation.id}/sales-logs/email-csv?years[]=#{sales_logs_start_year}&status[]=completed&codes_only=false", headers:, params: {}
            }.to enqueue_job(EmailCsvJob).with(user, nil, { "status" => %w[completed], "years" => [sales_logs_start_year.to_s] }, false, organisation, false, "sales", sales_logs_start_year)
          end

          it "provides the log type to the mail job" do
            log_type = "sales"
            expect {
              post "/organisations/#{organisation.id}/sales-logs/email-csv?years[]=#{sales_logs_start_year}&status[]=completed&codes_only=false", headers:, params: {}
            }.to enqueue_job(EmailCsvJob).with(user, nil, { "status" => %w[completed], "years" => [sales_logs_start_year.to_s] }, false, organisation, false, log_type, sales_logs_start_year)
          end

          it "provides the export type to the mail job" do
            codes_only_export_type = false
            expect {
              post "/organisations/#{organisation.id}/sales-logs/email-csv?years[]=#{sales_logs_start_year}&codes_only=#{codes_only_export_type}", headers:, params: {}
            }.to enqueue_job(EmailCsvJob).with(user, nil, { "years" => [sales_logs_start_year.to_s] }, false, organisation, codes_only_export_type, "sales", sales_logs_start_year)
            codes_only_export_type = true
            expect {
              post "/organisations/#{organisation.id}/sales-logs/email-csv?years[]=#{sales_logs_start_year}&codes_only=#{codes_only_export_type}", headers:, params: {}
            }.to enqueue_job(EmailCsvJob).with(user, nil, { "years" => [sales_logs_start_year.to_s] }, false, organisation, codes_only_export_type, "sales", sales_logs_start_year)
          end
        end
      end

      describe "GET #download_lettings_csv" do
        let(:search_term) { "blam" }
        let!(:lettings_log) { create(:lettings_log, :setup_completed, owning_organisation: organisation, tenancycode: search_term) }

        it "renders a page with the correct header" do
          get "/organisations/#{organisation.id}/lettings-logs/csv-download?years[]=#{lettings_log.form.start_date.year}&codes_only=false", headers:, params: {}
          header = page.find_css("h1")
          expect(header.text).to include("Download CSV")
        end

        it "renders a form with the correct target containing a button with the correct text" do
          get "/organisations/#{organisation.id}/lettings-logs/csv-download?years[]=#{lettings_log.form.start_date.year}&codes_only=false", headers:, params: {}
          form = page.find("form.button_to")
          expect(form[:method]).to eq("post")
          expect(form[:action]).to eq("/organisations/#{organisation.id}/lettings-logs/email-csv")
          expect(form).to have_button("Send email")
        end

        it "when codes_only query parameter is false, form contains hidden field with correct value" do
          codes_only = false
          get "/organisations/#{organisation.id}/lettings-logs/csv-download?years[]=#{lettings_log.form.start_date.year}&codes_only=#{codes_only}", headers:, params: {}
          hidden_field = page.find("form.button_to").find_field("codes_only", type: "hidden")
          expect(hidden_field.value).to eq(codes_only.to_s)
        end

        it "when codes_only query parameter is true, form contains hidden field with correct value" do
          codes_only = true
          get "/organisations/#{organisation.id}/lettings-logs/csv-download?years[]=#{lettings_log.form.start_date.year}&codes_only=#{codes_only}", headers:, params: {}
          hidden_field = page.find("form.button_to").find_field("codes_only", type: "hidden")
          expect(hidden_field.value).to eq(codes_only.to_s)
        end

        it "when query string contains search parameter, form contains hidden field with correct value" do
          get "/organisations/#{organisation.id}/lettings-logs/csv-download?years[]=#{lettings_log.form.start_date.year}&codes_only=true&search=#{search_term}", headers:, params: {}
          hidden_field = page.find("form.button_to").find_field("search", type: "hidden")
          expect(hidden_field.value).to eq(search_term)
        end
      end

      describe "GET #download_sales_csv" do
        let(:search_term) { "blam" }
        let!(:sales_log) { create(:sales_log, :in_progress, owning_organisation: organisation, purchid: search_term) }

        it "renders a page with the correct header" do
          get "/organisations/#{organisation.id}/sales-logs/csv-download?years[]=#{sales_log.form.start_date.year}&codes_only=false", headers:, params: {}
          header = page.find_css("h1")
          expect(header.text).to include("Download CSV")
        end

        it "renders a form with the correct target containing a button with the correct text" do
          get "/organisations/#{organisation.id}/sales-logs/csv-download?years[]=#{sales_log.form.start_date.year}&codes_only=false", headers:, params: {}
          form = page.find("form.button_to")
          expect(form[:method]).to eq("post")
          expect(form[:action]).to eq("/organisations/#{organisation.id}/sales-logs/email-csv")
          expect(form).to have_button("Send email")
        end

        it "when codes_only query parameter is false, form contains hidden field with correct value" do
          codes_only = false
          get "/organisations/#{organisation.id}/sales-logs/csv-download?years[]=#{sales_log.form.start_date.year}&codes_only=#{codes_only}", headers:, params: {}
          hidden_field = page.find("form.button_to").find_field("codes_only", type: "hidden")
          expect(hidden_field.value).to eq(codes_only.to_s)
        end

        it "when codes_only query parameter is true, form contains hidden field with correct value" do
          codes_only = true
          get "/organisations/#{organisation.id}/sales-logs/csv-download?years[]=#{sales_log.form.start_date.year}&codes_only=#{codes_only}", headers:, params: {}
          hidden_field = page.find("form.button_to").find_field("codes_only", type: "hidden")
          expect(hidden_field.value).to eq(codes_only.to_s)
        end

        it "when query string contains search parameter, form contains hidden field with correct value" do
          get "/organisations/#{organisation.id}/sales-logs/csv-download?years[]=#{sales_log.form.start_date.year}&codes_only=true&search=#{search_term}", headers:, params: {}
          hidden_field = page.find("form.button_to").find_field("search", type: "hidden")
          expect(hidden_field.value).to eq(search_term)
        end
      end

      context "when they view the users tab" do
        before do
          get "/organisations/#{organisation.id}/users"
        end

        it "has a CSV download button with the correct path" do
          expect(page).to have_link("Download (CSV)", href: "/organisations/#{organisation.id}/users.csv")
        end

        context "when you download the CSV" do
          let(:headers) { { "Accept" => "text/csv" } }
          let(:other_organisation) { create(:organisation) }

          before do
            create_list(:user, 3, organisation:)
            create_list(:user, 2, organisation: other_organisation)
          end

          it "only includes users from that organisation" do
            get "/organisations/#{other_organisation.id}/users", headers:, params: {}
            csv = CSV.parse(response.body)
            expect(csv.count).to eq(other_organisation.users.count + 1)
          end
        end
      end

      describe "#search" do
        let(:parent_organisation) { create(:organisation, name: "parent test organisation") }
        let(:child_organisation) { create(:organisation, name: "child test organisation") }
        let!(:other_organisation) { create(:organisation, name: "other organisation test organisation") }

        before do
          user.organisation.update!(name: "test organisation")
          create(:organisation_relationship, parent_organisation: user.organisation, child_organisation:)
          create(:organisation_relationship, child_organisation: user.organisation, parent_organisation:)
        end

        it "searches within all the organisations" do
          get "/organisations/search", headers:, params: { query: "test organisation" }
          result = JSON.parse(response.body)
          expect(result.count).to eq(4)
          expect(result.keys).to match_array([user.organisation.id.to_s, parent_organisation.id.to_s, child_organisation.id.to_s, other_organisation.id.to_s])
        end
      end
    end
  end

  describe "GET #data_sharing_agreement" do
    context "when not signed in" do
      it "redirects to sign in" do
        get "/organisations/#{organisation.id}/data-sharing-agreement", headers: headers
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in" do
      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
      end

      it "returns ok" do
        get "/organisations/#{organisation.id}/data-sharing-agreement", headers: headers
        expect(response).to have_http_status(:ok)
      end
    end

    context "when signed in as support" do
      let(:support_user) { create(:user, :support, with_dsa: false) }

      before do
        organisation.data_protection_confirmation.update!(signed_at: Time.zone.local(2001, 3, 2), organisation_name: "Org name")
        allow(support_user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in support_user
      end

      context "and viewing other org dsa" do
        it "shows correct org data and dates" do
          get "/organisations/#{organisation.id}/data-sharing-agreement", headers: headers
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("This agreement is made the 2nd day of March 2001")
          expect(page).to have_content("1) Org name")
        end
      end
    end
  end

  describe "POST #data_sharing_agreement" do
    let(:organisation) { create(:organisation, :without_dpc) }

    context "when not signed in" do
      it "redirects to sign in" do
        post "/organisations/#{organisation.id}/data-sharing-agreement", headers: headers
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in" do
      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
      end

      context "when user not dpo" do
        let(:user) { create(:user, is_dpo: false) }

        it "returns not found" do
          post "/organisations/#{organisation.id}/data-sharing-agreement", headers: headers
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when user is dpo" do
        context "when the organisation has a non-confirmed confirmation" do
          let(:user) { create(:user, is_dpo: false) }

          it "returns not found" do
            post "/organisations/#{organisation.id}/data-sharing-agreement", headers: headers
            expect(response).to have_http_status(:not_found)
          end
        end

        context "when the organisation does not have a confirmation" do
          before do
            Timecop.freeze(Time.zone.local(2022, 2, 1))
          end

          after do
            Timecop.unfreeze
          end

          let(:user) { create(:user, is_dpo: true, organisation:, with_dsa: false) }

          it "returns redirects to details page" do
            post "/organisations/#{organisation.id}/data-sharing-agreement", headers: headers

            expect(response).to redirect_to("/organisations/#{organisation.id}/details")
            expect(flash[:notice]).to eq("You have accepted the Data Sharing Agreement")
            expect(flash[:notification_banner_body]).to eq("Your organisation can now submit logs.")
          end

          it "creates a data sharing agreement" do
            expect(organisation.reload.data_protection_confirmation).to be_nil

            post("/organisations/#{organisation.id}/data-sharing-agreement", headers:)

            data_protection_confirmation = organisation.reload.data_protection_confirmation

            expect(data_protection_confirmation.organisation).to eq(organisation)
            expect(data_protection_confirmation.data_protection_officer).to eq(user)
            expect(data_protection_confirmation.signed_at).to eq(Time.zone.local(2022, 2, 1))
            expect(data_protection_confirmation.organisation_name).to eq(organisation.name)
            expect(data_protection_confirmation.organisation_address).to eq(organisation.address_row)
            expect(data_protection_confirmation.organisation_phone_number).to eq(organisation.phone)
            expect(data_protection_confirmation.data_protection_officer_email).to eq(user.email)
            expect(data_protection_confirmation.data_protection_officer_name).to eq(user.name)
          end

          context "when the user has already accepted the agreement" do
            before do
              create(:data_protection_confirmation, data_protection_officer: user, organisation: user.organisation)
            end

            it "returns not found" do
              post "/organisations/#{organisation.id}/data-sharing-agreement", headers: headers
              expect(response).to have_http_status(:not_found)
            end
          end
        end
      end
    end
  end

  describe "POST #confirm_duplicate_schemes" do
    let(:organisation) { create(:organisation) }

    context "when not signed in" do
      it "redirects to sign in" do
        post "/organisations/#{organisation.id}/schemes/duplicates", headers: headers
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in" do
      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
      end

      context "when user is data provider" do
        let(:user) { create(:user, role: "data_provider", organisation:) }

        it "returns not found" do
          post "/organisations/#{organisation.id}/schemes/duplicates", headers: headers
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "when user is coordinator" do
        let(:user) { create(:user, role: "data_coordinator", organisation:) }

        context "and the duplicate schemes have been confirmed" do
          let(:params) { { "organisation": { scheme_duplicates_checked: "true" } } }

          it "redirects to schemes page" do
            post "/organisations/#{organisation.id}/schemes/duplicates", headers: headers, params: params

            expect(response).to redirect_to("/organisations/#{organisation.id}/schemes")
            expect(flash[:notice]).to eq("You’ve confirmed the remaining schemes and locations are not duplicates.")
          end

          it "updates schemes_deduplicated_at" do
            expect(organisation.reload.schemes_deduplicated_at).to be_nil

            post "/organisations/#{organisation.id}/schemes/duplicates", headers: headers, params: params

            expect(organisation.reload.schemes_deduplicated_at).not_to be_nil
          end
        end

        context "and the duplicate schemes have not been confirmed" do
          let(:params) { { "organisation": { scheme_duplicates_checked: "" } } }

          it "displays an error" do
            post "/organisations/#{organisation.id}/schemes/duplicates", headers: headers, params: params

            expect(response).to have_http_status(:unprocessable_content)
            expect(page).to have_content("You must resolve all duplicates or indicate that there are no duplicates")
          end
        end
      end
    end
  end
end
