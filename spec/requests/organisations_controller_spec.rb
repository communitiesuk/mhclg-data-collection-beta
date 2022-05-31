require "rails_helper"

RSpec.describe OrganisationsController, type: :request do
  let(:organisation) { user.organisation }
  let!(:unauthorised_organisation) { FactoryBot.create(:organisation) }
  let(:headers) { { "Accept" => "text/html" } }
  let(:page) { Capybara::Node::Simple.new(response.body) }
  let(:user) { FactoryBot.create(:user, :data_coordinator) }
  let(:new_value) { "Test Name 35" }
  let(:params) { { id: organisation.id, organisation: { name: new_value } } }

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
    end
  end

  context "when user is signed in" do
    describe "#show" do
      context "with an organisation that the user belongs to" do
        before do
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
            expected_html = "<nav class=\"app-primary-navigation\""
            expect(response.body).to include(expected_html)
          end

          it "shows a summary list of org details" do
            expected_html = "<dl class=\"govuk-summary-list\""
            expect(response.body).to include(expected_html)
            expect(response.body).to include(organisation.name)
          end

          it "has a hidden header title" do
            expected_html = "<h2 class=\"govuk-visually-hidden\">  Details"
            expect(response.body).to include(expected_html)
          end

          it "has a change details link" do
            expected_html = "data-qa=\"change-name\" href=\"/organisations/#{organisation.id}/edit\""
            expect(response.body).to include(expected_html)
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
          let!(:other_user) { FactoryBot.create(:user, organisation: user.organisation, name: "User 2") }
          let!(:inactive_user) { FactoryBot.create(:user, organisation: user.organisation, active: false, name: "User 3") }
          let!(:other_org_user) { FactoryBot.create(:user, name: "User 4") }

          before do
            get "/organisations/#{organisation.id}/users", headers:, params: {}
          end

          it "shows the tab navigation" do
            expected_html = "<nav class=\"app-primary-navigation\""
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

          it "has a hidden header title" do
            expected_html = "<h2 class=\"govuk-visually-hidden\">  Users"
            expect(response.body).to include(expected_html)
          end

          it "shows only active users in the current user's organisation" do
            expect(page).to have_content(user.name)
            expect(page).to have_content(other_user.name)
            expect(page).not_to have_content(inactive_user.name)
            expect(page).not_to have_content(other_org_user.name)
          end

          it "shows the pagination count" do
            expect(page).to have_content("2 total users")
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

          it "shows an edit form" do
            expect(response.body).to include("Change #{organisation.name}’s details")
            expect(page).to have_field("organisation-name-field")
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

      context "when viewing logs for other organisation" do
        before do
          get "/organisations/#{unauthorised_organisation.id}/logs", headers:, params: {}
        end

        it "returns not found 404 from org details route" do
          expect(response).to have_http_status(:not_found)
        end

        it "shows the 404 view" do
          expect(page).to have_content("Page not found")
        end
      end

      context "when viewing logs for your organisation" do
        before do
          get "/organisations/#{organisation.id}/logs", headers:, params: {}
        end

        it "redirects to /logs page" do
          expect(response).to redirect_to("/logs")
        end
      end
    end

    context "with a data provider user" do
      let(:user) { FactoryBot.create(:user) }

      before do
        sign_in user
      end

      context "when accessing the details tab" do
        context "with an organisation that the user belongs to" do
          before do
            get "/organisations/#{organisation.id}/details", headers:, params: {}
          end

          it "shows the tab navigation" do
            expected_html = "<nav class=\"app-primary-navigation\""
            expect(response.body).to include(expected_html)
          end

          it "shows a summary list of org details" do
            expected_html = "<dl class=\"govuk-summary-list\""
            expect(response.body).to include(expected_html)
            expect(response.body).to include(organisation.name)
          end

          it "has a hidden header title" do
            expected_html = "<h2 class=\"govuk-visually-hidden\">  Details"
            expect(response.body).to include(expected_html)
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

      context "when viewing logs for other organisation" do
        before do
          get "/organisations/#{unauthorised_organisation.id}/logs", headers:, params: {}
        end

        it "returns not found 404 from org details route" do
          expect(response).to have_http_status(:not_found)
        end

        it "shows the 404 view" do
          expect(page).to have_content("Page not found")
        end
      end

      context "when viewing logs for your organisation" do
        before do
          get "/organisations/#{organisation.id}/logs", headers:, params: {}
        end

        it "redirects to /logs page" do
          expect(response).to redirect_to("/logs")
        end
      end
    end

    context "with a support user" do
      let(:user) { FactoryBot.create(:user, :support) }

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/organisations"
      end

      it "shows all organisations" do
        total_number_of_orgs = Organisation.all.count
        expect(page).to have_link organisation.name, href: "organisations/#{organisation.id}/logs"
        expect(page).to have_link unauthorised_organisation.name, href: "organisations/#{unauthorised_organisation.id}/logs"
        expect(page).to have_content("#{total_number_of_orgs} total organisations")
      end

      it "shows a search bar" do
        expect(page).to have_field("search", type: "search")
      end

      context "when viewing a specific organisation" do
        let(:number_of_org1_case_logs) { 2 }
        let(:number_of_org2_case_logs) { 4 }

        before do
          FactoryBot.create_list(:case_log, number_of_org1_case_logs, owning_organisation_id: organisation.id, managing_organisation_id: organisation.id)
          FactoryBot.create_list(:case_log, number_of_org2_case_logs, owning_organisation_id: unauthorised_organisation.id, managing_organisation_id: unauthorised_organisation.id)

          get "/organisations/#{organisation.id}/logs", headers:, params: {}
        end

        it "only shows logs for that organisation" do
          expect(page).to have_content("#{number_of_org1_case_logs} total logs")
          organisation.case_logs.map(&:id).each do |case_log_id|
            expect(page).to have_link case_log_id.to_s, href: "/logs/#{case_log_id}"
          end

          unauthorised_organisation.case_logs.map(&:id).each do |case_log_id|
            expect(page).not_to have_link case_log_id.to_s, href: "/logs/#{case_log_id}"
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
          let(:logs) { FactoryBot.create_list(:case_log, 3, :completed, owning_organisation: user.organisation) }
          let(:log_to_search) { FactoryBot.create(:case_log, :completed, owning_organisation: user.organisation) }
          let(:log_total_count) { CaseLog.where(owning_organisation: user.organisation).count }

          it "has search results in the title" do
            get "/organisations/#{organisation.id}/logs?search=#{log_to_search.id}", headers: headers, params: {}
            expect(page).to have_title("Your organisation (1 log matching ‘#{log_to_search.id}’ of #{log_total_count} total logs) - Submit social housing lettings and sales data (CORE) - GOV.UK")
          end

          it "shows case logs matching the id" do
            get "/organisations/#{organisation.id}/logs?search=#{log_to_search.id}", headers: headers, params: {}
            expect(page).to have_link(log_to_search.id.to_s)
            logs.each do |log|
              expect(page).not_to have_link(log.id.to_s)
            end
          end

          it "shows case logs matching the tenant code" do
            get "/organisations/#{organisation.id}/logs?search=#{log_to_search.tenant_code}", headers: headers, params: {}
            expect(page).to have_link(log_to_search.id.to_s)
            logs.each do |log|
              expect(page).not_to have_link(log.id.to_s)
            end
          end

          it "shows case logs matching the property reference" do
            get "/organisations/#{organisation.id}/logs?search=#{log_to_search.propcode}", headers: headers, params: {}
            expect(page).to have_link(log_to_search.id.to_s)
            logs.each do |log|
              expect(page).not_to have_link(log.id.to_s)
            end
          end

          it "shows case logs matching the property postcode" do
            get "/organisations/#{organisation.id}/logs?search=#{log_to_search.postcode_full}", headers: headers, params: {}
            expect(page).to have_link(log_to_search.id.to_s)
            logs.each do |log|
              expect(page).not_to have_link(log.id.to_s)
            end
          end

          context "when more than one results with matching postcode" do
            let!(:matching_postcode_log) { FactoryBot.create(:case_log, :completed, owning_organisation: user.organisation, postcode_full: log_to_search.postcode_full) }

            it "displays all matching logs" do
              get "/organisations/#{organisation.id}/logs?search=#{log_to_search.postcode_full}", headers: headers, params: {}
              expect(page).to have_link(log_to_search.id.to_s)
              expect(page).to have_link(matching_postcode_log.id.to_s)
              logs.each do |log|
                expect(page).not_to have_link(log.id.to_s)
              end
            end
          end

          context "when there are more than 1 page of search results" do
            let(:postcode) { "XX11YY" }
            let(:logs) { FactoryBot.create_list(:case_log, 30, :completed, owning_organisation: user.organisation, postcode_full: postcode) }
            let(:log_total_count) { CaseLog.where(owning_organisation: user.organisation).count }

            it "has title with pagination details for page 1" do
              get "/organisations/#{organisation.id}/logs?search=#{logs[0].postcode_full}", headers: headers, params: {}
              expect(page).to have_title("Your organisation (#{logs.count} logs matching ‘#{postcode}’ of #{log_total_count} total logs) (page 1 of 2) - Submit social housing lettings and sales data (CORE) - GOV.UK")
            end

            it "has title with pagination details for page 2" do
              get "/organisations/#{organisation.id}/logs?search=#{logs[0].postcode_full}&page=2", headers: headers, params: {}
              expect(page).to have_title("Your organisation (#{logs.count} logs matching ‘#{postcode}’ of #{log_total_count} total logs) (page 2 of 2) - Submit social housing lettings and sales data (CORE) - GOV.UK")
            end
          end

          context "when search query doesn't match any logs" do
            it "doesn't display any logs" do
              get "/organisations/#{organisation.id}/logs?search=foobar", headers:, params: {}
              logs.each do |log|
                expect(page).not_to have_link(log.id.to_s)
              end
              expect(page).not_to have_link(log_to_search.id.to_s)
            end
          end

          context "when search query is empty" do
            it "doesn't display any logs" do
              get "/organisations/#{organisation.id}/logs?search=", headers:, params: {}
              logs.each do |log|
                expect(page).not_to have_link(log.id.to_s)
              end
              expect(page).not_to have_link(log_to_search.id.to_s)
            end
          end

          context "when search and filter is present" do
            let(:matching_postcode) { log_to_search.postcode_full }
            let(:matching_status) { "in_progress" }
            let!(:log_matching_filter_and_search) { FactoryBot.create(:case_log, :in_progress, owning_organisation: user.organisation, postcode_full: matching_postcode) }

            it "shows only logs matching both search and filters" do
              get "/organisations/#{organisation.id}/logs?search=#{matching_postcode}&status[]=#{matching_status}", headers: headers, params: {}
              expect(page).to have_content(log_matching_filter_and_search.id)
              expect(page).not_to have_content(log_to_search.id)
              logs.each do |log|
                expect(page).not_to have_content(log.id)
              end
            end
          end
        end
      end

      context "when viewing a specific organisation details" do
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
          expect(page).to have_link("Change", count: 3)
        end
      end
    end

    context "when there are more than 20 organisations" do
      let(:support_user) { FactoryBot.create(:user, :support) }

      let(:total_organisations_count) { Organisation.all.count }

      before do
        FactoryBot.create_list(:organisation, 25)
        allow(support_user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in support_user
        get "/organisations"
      end

      context "when on the first page" do
        it "has pagination links" do
          expect(page).to have_content("Previous")
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
          expect(CGI.unescape_html(response.body)).to match("<strong>#{total_organisations_count}</strong> total organisations.")
        end

        it "has pagination links" do
          expect(page).to have_content("Previous")
          expect(page).to have_link("Previous")
          expect(page).to have_content("Next")
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
        let!(:searched_organisation) { FactoryBot.create(:organisation, name: "Unusual name") }
        let!(:other_organisation) { FactoryBot.create(:organisation, name: "Some other name") }
        let(:search_param) { "Unusual" }

        before do
          get "/organisations?search=#{search_param}"
        end

        it "returns matching results" do
          expect(page).to have_content(searched_organisation.name)
          expect(page).not_to have_content(other_organisation.name)
        end

        it "updates the table caption" do
          expect(page).to have_content("1 organisation found matching ‘#{search_param}’ of 29 total organisations.")
        end

        it "has search in the title" do
          expect(page).to have_title("Organisations (1 organisation matching ‘#{search_param}’ of 29 total organisations) - Submit social housing lettings and sales data (CORE) - GOV.UK")
        end

        context "when the search term matches more than 1 result" do
          let(:search_param) { "name" }

          it "returns matching results" do
            expect(page).to have_content(searched_organisation.name)
            expect(page).to have_content(other_organisation.name)
          end

          it "updates the table caption" do
            expect(page).to have_content("2 organisations found matching ‘#{search_param}’ of 29 total organisations.")
          end

          it "has search in the title" do
            expect(page).to have_title("Organisations (2 organisations matching ‘#{search_param}’ of 29 total organisations) - Submit social housing lettings and sales data (CORE) - GOV.UK")
          end
        end

        context "when search results require pagination" do
          let(:search_param) { "DLUHC" }

          it "has search and pagination in the title" do
            expect(page).to have_title("Organisations (27 organisations matching ‘#{search_param}’ of 29 total organisations) (page 1 of 2) - Submit social housing lettings and sales data (CORE) - GOV.UK")
          end
        end
      end
    end
  end
end
