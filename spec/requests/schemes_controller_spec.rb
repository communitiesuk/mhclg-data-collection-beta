require "rails_helper"

RSpec.describe SchemesController, type: :request do
  let(:organisation) { user.organisation }
  let(:headers) { { "Accept" => "text/html" } }
  let(:page) { Capybara::Node::Simple.new(response.body) }
  let(:user) { create(:user, :support) }
  let!(:schemes) { create_list(:scheme, 5) }

  before do
    schemes.each do |scheme|
      create(:location, scheme:)
    end
  end

  describe "#index" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        get "/schemes"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider user" do
      let(:user) { create(:user) }

      before do
        sign_in user
        get "/schemes"
      end

      it "returns 200 success" do
        expect(response).to redirect_to(schemes_organisation_path(user.organisation.id))
      end
    end

    context "when signed in as a data coordinator user" do
      let(:user) { create(:user, :data_coordinator) }

      before do
        schemes.each do |scheme|
          scheme.update!(owning_organisation: user.organisation)
        end
        sign_in user
        get "/schemes"
      end

      it "redirects to the organisation schemes path" do
        expect(response).to redirect_to(schemes_organisation_path(user.organisation.id))
      end

      it "shows a list of schemes for the organisation" do
        follow_redirect!
        schemes.each do |scheme|
          expect(page).to have_content(scheme.id_to_display)
        end
      end

      context "when there are deleted schemes" do
        let!(:deleted_scheme) { create(:scheme, service_name: "deleted", discarded_at: Time.zone.yesterday, owning_organisation: user.organisation) }

        before do
          get "/schemes"
        end

        it "does not show deleted schemes" do
          follow_redirect!
          expect(page).not_to have_content(deleted_scheme.id_to_display)
        end
      end

      context "when parent organisation has schemes" do
        let(:parent_organisation) { create(:organisation) }
        let!(:parent_schemes) { create_list(:scheme, 5, owning_organisation: parent_organisation) }

        before do
          create(:organisation_relationship, parent_organisation:, child_organisation: user.organisation)
          parent_schemes.each do |scheme|
            create(:location, scheme:)
          end
          get "/schemes"
        end

        it "shows parent organisation schemes" do
          follow_redirect!
          parent_schemes.each do |scheme|
            expect(page).to have_content(scheme.id_to_display)
          end
        end
      end

      context "when a recently absorbed organisation has schemes" do
        let(:absorbed_org) { create(:organisation) }
        let!(:absorbed_org_schemes) { create_list(:scheme, 2, owning_organisation: absorbed_org) }

        before do
          absorbed_org.merge_date = 2.days.ago
          absorbed_org.absorbing_organisation = user.organisation
          absorbed_org.save!
        end

        it "shows absorbed organisation schemes" do
          get "/schemes"
          follow_redirect!
          absorbed_org_schemes.each do |scheme|
            expect(page).to have_content(scheme.id_to_display)
          end
        end
      end

      context "when a non-recently absorbed organisation has schemes" do
        let(:absorbed_org) { create(:organisation) }
        let!(:absorbed_org_schemes) { create_list(:scheme, 2, owning_organisation: absorbed_org) }

        before do
          absorbed_org.merge_date = 2.years.ago
          absorbed_org.absorbing_organisation = user.organisation
          absorbed_org.save!
        end

        it "shows absorbed organisation schemes" do
          get "/schemes"
          follow_redirect!
          absorbed_org_schemes.each do |scheme|
            expect(page).not_to have_content(scheme.id_to_display)
          end
        end
      end

      context "when filtering" do
        context "with owning organisation filter" do
          context "when user org does not have owning orgs or recently absorbed orgs" do
            it "does not show filter" do
              expect(page).not_to have_content("Owned by")
            end
          end

          context "when user org has owning orgs" do
            let!(:organisation1) { create(:organisation) }
            let!(:scheme1) { create(:scheme, owning_organisation: organisation1) }
            let!(:scheme2) { create(:scheme, owning_organisation: user.organisation) }

            before do
              org = user.organisation
              org.stock_owners = [organisation1, user.organisation]
              org.save!
            end

            context "when filtering by all owning orgs" do
              it "shows schemes for all owning orgs" do
                get "/schemes?owning_organisation_select=all", headers:, params: {}
                follow_redirect!

                expect(page).to have_content("Owned by")
                expect(page).to have_link(scheme1.service_name)
                expect(page).to have_link(scheme2.service_name)
              end
            end

            context "when filtering by an owning org" do
              it "when filtering by an owning org" do
                get "/schemes?owning_organisation=#{organisation1.id}", headers:, params: {}
                follow_redirect!

                expect(page).to have_content("Owned by")
                expect(page).to have_link(scheme1.service_name)
                expect(page).not_to have_link(scheme2.service_name)
              end
            end
          end
        end

        context "with status filter" do
          let!(:incomplete_scheme) { create(:scheme, :incomplete, owning_organisation: user.organisation) }
          let(:active_scheme) { create(:scheme, owning_organisation: user.organisation) }
          let!(:deactivated_scheme) { create(:scheme, owning_organisation: user.organisation) }

          before do
            create(:location, scheme: active_scheme)
            Timecop.freeze(Time.zone.local(2023, 11, 10))
            create(:scheme_deactivation_period, scheme: deactivated_scheme, deactivation_date: Time.zone.local(2022, 4, 1))
            Timecop.return
          end

          it "shows schemes for multiple selected statuses" do
            get "/schemes?status[]=incomplete&status[]=active", headers:, params: {}
            follow_redirect!
            expect(page).to have_link(incomplete_scheme.service_name)
            expect(page).to have_link(active_scheme.service_name)
            expect(page).not_to have_link(deactivated_scheme.service_name)
          end

          it "shows filtered incomplete schemes" do
            get "/schemes?status[]=incomplete", headers:, params: {}
            follow_redirect!
            expect(page).to have_link(incomplete_scheme.service_name)
            expect(page).not_to have_link(active_scheme.service_name)
            expect(page).not_to have_link(deactivated_scheme.service_name)
          end

          it "shows filtered active schemes" do
            get "/schemes?status[]=active", headers:, params: {}
            follow_redirect!
            expect(page).to have_link(active_scheme.service_name)
            expect(page).not_to have_link(incomplete_scheme.service_name)
            expect(page).not_to have_link(deactivated_scheme.service_name)
          end

          it "shows filtered deactivated schemes" do
            get "/schemes?status[]=deactivated", headers:, params: {}
            follow_redirect!
            expect(page).to have_link(deactivated_scheme.service_name)
            expect(page).not_to have_link(active_scheme.service_name)
            expect(page).not_to have_link(incomplete_scheme.service_name)
          end

          it "does not reset the filters" do
            get "/schemes?status[]=incomplete", headers:, params: {}
            follow_redirect!
            expect(page).to have_link(incomplete_scheme.service_name)
            expect(page).not_to have_link(active_scheme.service_name)
            expect(page).not_to have_link(deactivated_scheme.service_name)

            get "/schemes", headers:, params: {}
            follow_redirect!
            expect(page).to have_link(incomplete_scheme.service_name)
            expect(page).not_to have_link(active_scheme.service_name)
            expect(page).not_to have_link(deactivated_scheme.service_name)
          end
        end
      end
    end

    context "when signed in as a support user" do
      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/schemes"
      end

      it "has page heading" do
        expect(page).to have_content("Schemes")
      end

      context "when there are deleted schemes" do
        let!(:deleted_scheme) { create(:scheme, service_name: "deleted", discarded_at: Time.zone.yesterday, owning_organisation: user.organisation) }

        before do
          get "/schemes"
        end

        it "does not show deleted schemes" do
          expect(page).not_to have_content(deleted_scheme.id_to_display)
        end
      end

      describe "scheme and location csv downloads" do
        let!(:same_org_scheme) { create(:scheme, owning_organisation: user.organisation) }
        let!(:specific_organisation) { create(:organisation) }
        let!(:specific_org_scheme) { create(:scheme, owning_organisation: specific_organisation) }

        before do
          create(:location, scheme: same_org_scheme)
          create_list(:scheme, 5, owning_organisation: specific_organisation)
          create_list(:location, 3, scheme: specific_org_scheme)
        end

        it "shows scheme and location download links" do
          expect(page).to have_link("Download schemes (CSV)", href: csv_download_schemes_path(download_type: "schemes"))
          expect(page).to have_link("Download locations (CSV)", href: csv_download_schemes_path(download_type: "locations"))
          expect(page).to have_link("Download schemes and locations (CSV)", href: csv_download_schemes_path(download_type: "combined"))
        end

        context "when there are no schemes for any organisation" do
          before do
            Scheme.destroy_all
            get "/schemes"
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
            expect(page).to have_content("You've selected 12 schemes.")
          end
        end

        context "when downloading location data" do
          before do
            get csv_download_schemes_path(download_type: "locations")
          end

          it "redirects to the correct download page" do
            expect(page).to have_content("You've selected 9 locations from 12 schemes.")
          end
        end

        context "when downloading scheme and location data" do
          before do
            get csv_download_schemes_path(download_type: "combined")
          end

          it "redirects to the correct download page" do
            expect(page).to have_content("You've selected 12 schemes with 9 locations.")
          end
        end
      end

      it "shows all schemes" do
        schemes.each do |scheme|
          expect(page).to have_content(scheme.id_to_display)
        end
      end

      it "shows incomplete tag if the scheme is not confirmed" do
        schemes[0].update!(confirmed: nil)
        get "/schemes"
        assert_select ".govuk-tag", text: /Incomplete/, count: 1
      end

      it "shows schemes in alphabetical order" do
        schemes[0].update!(service_name: "aaa")
        schemes[1].update!(service_name: "daa")
        schemes[2].update!(service_name: "baa")
        schemes[3].update!(service_name: "Faa")
        schemes[4].update!(service_name: "Caa")
        get "/schemes", headers:, params: {}
        all_links = page.all(".govuk-link")
        scheme_links = all_links.select { |link| link[:href] =~ %r{^/schemes/\d+$} }

        expect(scheme_links[0][:href]).to eq("/schemes/#{schemes[0].id}")
        expect(scheme_links[1][:href]).to eq("/schemes/#{schemes[2].id}")
        expect(scheme_links[2][:href]).to eq("/schemes/#{schemes[4].id}")
        expect(scheme_links[3][:href]).to eq("/schemes/#{schemes[1].id}")
        expect(scheme_links[4][:href]).to eq("/schemes/#{schemes[3].id}")
      end

      it "displays a link to check answers page if the scheme is incomplete" do
        scheme = schemes[0]
        scheme.update!(confirmed: nil)
        get "/schemes"
        expect(page).to have_link(nil, href: /schemes\/#{scheme.id}\/check-answers/)
      end

      it "shows a search bar" do
        expect(page).to have_field("search", type: "search")
      end

      it "has correct title" do
        expect(page).to have_title("Supported housing schemes - Submit social housing lettings and sales data (CORE) - GOV.UK")
      end

      it "shows the total organisations count" do
        expect(CGI.unescape_html(response.body)).to match("<strong>#{schemes.count}</strong> total schemes")
      end

      context "when paginating over 20 results" do
        let(:total_schemes_count) { Scheme.count }

        before do
          create_list(:scheme, 20)
        end

        context "when on the first page" do
          before do
            get "/schemes"
          end

          it "shows the total schemes count" do
            expect(CGI.unescape_html(response.body)).to match("<strong>#{total_schemes_count}</strong> total schemes")
          end

          it "shows which schemes are being shown on the current page" do
            expect(CGI.unescape_html(response.body)).to match("Showing <b>1</b> to <b>20</b> of <b>#{total_schemes_count}</b> schemes")
          end

          it "has correct page 1 of 2 title" do
            expect(page).to have_title("Supported housing schemes (page 1 of 2) - Submit social housing lettings and sales data (CORE) - GOV.UK")
          end

          it "has pagination links" do
            expect(page).not_to have_content("Previous")
            expect(page).not_to have_link("Previous")
            expect(page).to have_content("Next")
            expect(page).to have_link("Next")
          end
        end

        xcontext "when on the second page" do
          before do
            get "/schemes?page=2"
          end

          it "shows the total schemes count" do
            expect(CGI.unescape_html(response.body)).to match("<strong>#{total_schemes_count}</strong> total schemes")
          end

          it "has pagination links" do
            expect(page).to have_content("Previous")
            expect(page).to have_link("Previous")
            expect(page).not_to have_content("Next")
            expect(page).not_to have_link("Next")
          end

          it "shows which schemes are being shown on the current page" do
            expect(CGI.unescape_html(response.body)).to match("Showing <b>21</b> to <b>25</b> of <b>#{total_schemes_count}</b> schemes")
          end

          it "has correct page 1 of 2 title" do
            expect(page).to have_title("Supported housing schemes (page 2 of 2) - Submit social housing lettings and sales data (CORE) - GOV.UK")
          end
        end
      end

      context "when searching" do
        let!(:searched_scheme) { create(:scheme) }
        let(:search_param) { searched_scheme.id_to_display }

        before do
          create(:location, scheme: searched_scheme)
          get "/schemes?search=#{search_param}"
        end

        it "returns matching results" do
          expect(page).to have_content(searched_scheme.id_to_display)
          schemes.each do |scheme|
            expect(page).not_to have_content(scheme.id_to_display)
          end
        end

        it "returns results with no location" do
          scheme_without_location = create(:scheme)
          get "/schemes?search=#{scheme_without_location.id}"
          expect(page).to have_content(scheme_without_location.id_to_display)
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

      context "when filtering" do
        context "with owning organisation filter" do
          context "when user org does not have owning orgs" do
            it "shows the filter" do
              expect(page).to have_content("Owned by")
            end
          end

          context "when user org has owning orgs" do
            let!(:organisation1) { create(:organisation) }
            let!(:scheme1) { create(:scheme, owning_organisation: organisation1) }
            let!(:scheme2) { create(:scheme, owning_organisation: user.organisation) }

            context "when filtering by all owning orgs" do
              it "shows schemes for all owning orgs" do
                get "/schemes?owning_organisation_select=all", headers:, params: {}

                expect(page).to have_content("Owned by")
                expect(page).to have_link(scheme1.service_name)
                expect(page).to have_link(scheme2.service_name)
              end
            end

            context "when filtering by an owning org" do
              it "when filtering by an owning org" do
                get "/schemes?owning_organisation=#{organisation1.id}", headers:, params: {}

                expect(page).to have_content("Owned by")
                expect(page).to have_link(scheme1.service_name)
                expect(page).not_to have_link(scheme2.service_name)
              end
            end
          end
        end

        context "with status filter" do
          let!(:incomplete_scheme) { create(:scheme, :incomplete) }
          let(:active_scheme) { create(:scheme) }
          let!(:deactivated_scheme) { create(:scheme) }

          before do
            create(:location, scheme: active_scheme)
            Timecop.freeze(Time.zone.local(2023, 11, 10))
            create(:scheme_deactivation_period, scheme: deactivated_scheme, deactivation_date: Time.zone.local(2022, 4, 1))
            Timecop.return
          end

          it "shows schemes for multiple selected statuses" do
            get "/schemes?status[]=incomplete&status[]=active", headers:, params: {}
            expect(page).to have_link(incomplete_scheme.service_name)
            expect(page).to have_link(active_scheme.service_name)
            expect(page).not_to have_link(deactivated_scheme.service_name)
          end

          it "shows filtered incomplete schemes" do
            get "/schemes?status[]=incomplete", headers:, params: {}
            expect(page).to have_link(incomplete_scheme.service_name)
            expect(page).not_to have_link(active_scheme.service_name)
            expect(page).not_to have_link(deactivated_scheme.service_name)
          end

          it "shows filtered active schemes" do
            get "/schemes?status[]=active", headers:, params: {}
            expect(page).to have_link(active_scheme.service_name)
            expect(page).not_to have_link(incomplete_scheme.service_name)
            expect(page).not_to have_link(deactivated_scheme.service_name)
          end

          it "shows filtered deactivated schemes" do
            get "/schemes?status[]=deactivated", headers:, params: {}
            expect(page).to have_link(deactivated_scheme.service_name)
            expect(page).not_to have_link(active_scheme.service_name)
            expect(page).not_to have_link(incomplete_scheme.service_name)
          end

          it "does not reset the filters" do
            get "/schemes?status[]=incomplete", headers:, params: {}
            expect(page).to have_link(incomplete_scheme.service_name)
            expect(page).not_to have_link(active_scheme.service_name)
            expect(page).not_to have_link(deactivated_scheme.service_name)

            get "/schemes", headers:, params: {}
            expect(page).to have_link(incomplete_scheme.service_name)
            expect(page).not_to have_link(active_scheme.service_name)
            expect(page).not_to have_link(deactivated_scheme.service_name)
          end
        end
      end
    end
  end

  describe "#show" do
    let(:specific_scheme) { schemes.first }

    context "when not signed in" do
      it "redirects to the sign in page" do
        get "/schemes/#{specific_scheme.id}"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider user" do
      let(:user) { create(:user) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}"
      end

      it "returns 200" do
        expect(response).to be_successful
      end
    end

    context "when signed in as a data coordinator user" do
      let(:user) { create(:user, :data_coordinator) }
      let!(:specific_scheme) { create(:scheme, owning_organisation: user.organisation) }

      before do
        sign_in user
      end

      it "has page heading" do
        get "/schemes/#{specific_scheme.id}"
        expect(page).to have_content(specific_scheme.id_to_display)
        expect(page).to have_content(specific_scheme.service_name)
        expect(page).to have_content(specific_scheme.sensitive)
        expect(page).to have_content(specific_scheme.scheme_type)
        expect(page).to have_content(specific_scheme.registered_under_care_act)
        expect(page).to have_content(specific_scheme.primary_client_group)
        expect(page).to have_content(specific_scheme.secondary_client_group)
        expect(page).to have_content(specific_scheme.support_type)
        expect(page).to have_content(specific_scheme.intended_stay)
      end

      context "when coordinator attempts to see scheme belonging to a different (and not their parent) organisation" do
        let!(:specific_scheme) { create(:scheme) }

        it "returns 401" do
          get "/schemes/#{specific_scheme.id}"
          expect(response).to be_unauthorized
        end
      end

      context "when the requested scheme does not exist" do
        it "returns not found" do
          get "/schemes/#{Scheme.maximum(:id) + 1}"
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when looking at scheme details" do
        let!(:scheme) { create(:scheme, owning_organisation: user.organisation) }
        let(:add_deactivations) { scheme.scheme_deactivation_periods << scheme_deactivation_period }

        before do
          create(:location, scheme:)
          Timecop.freeze(Time.utc(2022, 10, 10))
          sign_in user
          add_deactivations
          scheme.save!
          get "/schemes/#{scheme.id}"
        end

        after do
          Timecop.unfreeze
        end

        context "with active scheme" do
          let(:add_deactivations) {}

          it "renders deactivate this scheme" do
            expect(response).to have_http_status(:ok)
            expect(page).to have_link("Deactivate this scheme", href: "/schemes/#{scheme.id}/new-deactivation")
          end
        end

        context "with deactivated scheme" do
          let(:scheme_deactivation_period) { create(:scheme_deactivation_period, deactivation_date: Time.zone.local(2022, 10, 9), scheme:) }

          it "renders reactivate this scheme" do
            expect(response).to have_http_status(:ok)
            expect(page).to have_link("Reactivate this scheme", href: "/schemes/#{scheme.id}/new-reactivation")
          end

          it "does not render delete this scheme" do
            expect(response).to have_http_status(:ok)
            expect(page).not_to have_link("Delete this scheme", href: "/schemes/#{scheme.id}/delete-confirmation")
          end
        end

        context "with scheme that's deactivating soon" do
          let(:scheme_deactivation_period) { create(:scheme_deactivation_period, deactivation_date: Time.zone.local(2022, 10, 12), scheme:) }

          it "does render the reactivate this scheme button" do
            expect(response).to have_http_status(:ok)
            expect(page).to have_link("Reactivate this scheme")
            expect(page).not_to have_link("Deactivate this scheme")
          end
        end

        context "with scheme that's deactivating in more than 6 months" do
          let(:scheme_deactivation_period) { create(:scheme_deactivation_period, deactivation_date: Time.zone.local(2023, 5, 12), scheme:) }

          it "does not render toggle scheme link" do
            expect(response).to have_http_status(:ok)
            expect(page).not_to have_link("Reactivate this scheme")
            expect(page).to have_link("Deactivate this scheme")
            expect(response.body).not_to include("<strong class=\"govuk-tag govuk-tag--yellow\">Deactivating soon</strong>")
            expect(response.body).to include("<strong class=\"govuk-tag govuk-tag--green\">Active</strong>")
          end
        end
      end

      context "when coordinator attempts to see scheme belonging to a parent organisation" do
        let(:parent_organisation) { create(:organisation) }
        let!(:specific_scheme) { create(:scheme, owning_organisation: parent_organisation) }
        let(:add_deactivations) { specific_scheme.scheme_deactivation_periods << scheme_deactivation_period }

        before do
          create(:location, scheme: specific_scheme)
          create(:organisation_relationship, parent_organisation:, child_organisation: user.organisation)
          Timecop.freeze(Time.utc(2022, 10, 10))
          sign_in user
          add_deactivations
          specific_scheme.save!
          get "/schemes/#{specific_scheme.id}"
        end

        after do
          Timecop.unfreeze
        end

        context "with active scheme" do
          let(:add_deactivations) {}

          it "shows the scheme" do
            expect(page).to have_content(specific_scheme.id_to_display)
          end

          it "allows editing" do
            expect(page).to have_link("Change")
          end

          it "renders deactivate this scheme" do
            expect(response).to have_http_status(:ok)
            expect(page).to have_link("Deactivate this scheme", href: "/schemes/#{specific_scheme.id}/new-deactivation")
          end
        end

        context "with deactivated scheme" do
          let(:scheme_deactivation_period) { create(:scheme_deactivation_period, deactivation_date: Time.zone.local(2022, 10, 9), scheme: specific_scheme) }

          it "renders reactivate this scheme" do
            expect(response).to have_http_status(:ok)
            expect(page).to have_link("Reactivate this scheme", href: "/schemes/#{specific_scheme.id}/new-reactivation")
          end
        end

        context "with scheme that's deactivating soon" do
          let(:scheme_deactivation_period) { create(:scheme_deactivation_period, deactivation_date: Time.zone.local(2022, 10, 12), scheme: specific_scheme) }

          it "does render the reactivate this scheme button" do
            expect(response).to have_http_status(:ok)
            expect(page).to have_link("Reactivate this scheme")
            expect(page).not_to have_link("Deactivate this scheme")
          end
        end

        context "with scheme that's deactivating in more than 6 months" do
          let(:scheme_deactivation_period) { create(:scheme_deactivation_period, deactivation_date: Time.zone.local(2023, 5, 12), scheme: specific_scheme) }

          it "does not render toggle scheme link" do
            expect(response).to have_http_status(:ok)
            expect(page).not_to have_link("Reactivate this scheme")
            expect(page).to have_link("Deactivate this scheme")
            expect(response.body).not_to include("<strong class=\"govuk-tag govuk-tag--yellow\">Deactivating soon</strong>")
            expect(response.body).to include("<strong class=\"govuk-tag govuk-tag--green\">Active</strong>")
          end
        end
      end

      context "when coordinator attempts to see scheme belonging to a recently absorbed organisation" do
        let(:absorbed_organisation) { create(:organisation) }
        let!(:specific_scheme) { create(:scheme, owning_organisation: absorbed_organisation) }

        before do
          absorbed_organisation.merge_date = 2.days.ago
          absorbed_organisation.absorbing_organisation = user.organisation
          absorbed_organisation.save!

          get "/schemes/#{specific_scheme.id}"
        end

        it "shows the scheme" do
          expect(page).to have_content(specific_scheme.id_to_display)
        end

        it "allows editing" do
          expect(page).to have_link("Change")
        end
      end

      context "when the scheme has all details but no confirmed locations" do
        it "shows the scheme as incomplete with text to explain" do
          get scheme_path(specific_scheme)
          expect(page).to have_content "Incomplete"
          expect(page).to have_content "Complete this scheme by adding a location using the"
          expect(page).to have_link "‘locations’ tab"
        end
      end

      context "when the scheme has all details and confirmed locations" do
        it "shows the scheme as complete" do
          create(:location, scheme: specific_scheme)
          get scheme_path(specific_scheme)
          expect(page).to have_content "Active"
          expect(page).not_to have_content "Complete this scheme by adding a location using the"
          expect(page).not_to have_link "‘locations’ tab"
        end
      end
    end

    context "when signed in as a support user" do
      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/schemes/#{specific_scheme.id}"
      end

      it "has page heading" do
        expect(page).to have_content(specific_scheme.id_to_display)
        expect(page).to have_content(specific_scheme.service_name)
        expect(page).to have_content(specific_scheme.owning_organisation.name)
        expect(page).to have_content(specific_scheme.sensitive)
        expect(page).to have_content(specific_scheme.id_to_display)
        expect(page).to have_content(specific_scheme.service_name)
        expect(page).to have_content(specific_scheme.sensitive)
        expect(page).to have_content(specific_scheme.scheme_type)
        expect(page).to have_content(specific_scheme.registered_under_care_act)
        expect(page).to have_content(specific_scheme.primary_client_group)
        expect(page).to have_content(specific_scheme.secondary_client_group)
        expect(page).to have_content(specific_scheme.support_type)
        expect(page).to have_content(specific_scheme.intended_stay)
      end

      context "when looking at scheme details" do
        let!(:scheme) { create(:scheme, owning_organisation: user.organisation) }
        let(:add_deactivations) { scheme.scheme_deactivation_periods << scheme_deactivation_period }

        before do
          create(:location, scheme:)
          Timecop.freeze(Time.utc(2022, 10, 10))
          sign_in user
          add_deactivations
          scheme.save!
          get "/schemes/#{scheme.id}"
        end

        after do
          Timecop.unfreeze
        end

        context "with active scheme" do
          let(:add_deactivations) {}

          it "does not render delete this scheme" do
            expect(response).to have_http_status(:ok)
            expect(page).not_to have_link("Delete this scheme", href: "/schemes/#{scheme.id}/delete-confirmation")
          end

          it "does not render informative text about deleting the scheme" do
            expect(response).to have_http_status(:ok)
            expect(page).not_to have_content("This scheme was active in an open or editable collection year, and cannot be deleted.")
          end
        end

        context "with deactivated scheme" do
          let(:scheme_deactivation_period) { create(:scheme_deactivation_period, deactivation_date: Time.zone.local(2022, 10, 9), scheme:) }

          it "renders delete this scheme" do
            expect(response).to have_http_status(:ok)
            expect(page).to have_link("Delete this scheme", href: "/schemes/#{scheme.id}/delete-confirmation")
          end

          context "and associated logs in editable collection period" do
            before do
              create(:location, scheme:)
              create(:lettings_log, :sh, scheme:, startdate: Time.zone.local(2022, 9, 9), owning_organisation: user.organisation)
              get "/schemes/#{scheme.id}"
            end

            it "does not render delete this scheme" do
              expect(response).to have_http_status(:ok)
              expect(page).not_to have_link("Delete this scheme", href: "/schemes/#{scheme.id}/delete-confirmation")
            end

            it "adds informative text about deleting the scheme" do
              expect(response).to have_http_status(:ok)
              expect(page).to have_content("This scheme was active in an open or editable collection year, and cannot be deleted.")
            end
          end
        end

        context "with scheme that's deactivating soon" do
          let(:scheme_deactivation_period) { create(:scheme_deactivation_period, deactivation_date: Time.zone.local(2022, 10, 12), scheme:) }

          it "does not render delete this scheme" do
            expect(response).to have_http_status(:ok)
            expect(page).not_to have_link("Delete this scheme", href: "/schemes/#{scheme.id}/delete-confirmation")
          end
        end

        context "with scheme that's deactivating in more than 6 months" do
          let(:scheme_deactivation_period) { create(:scheme_deactivation_period, deactivation_date: Time.zone.local(2023, 5, 12), scheme:) }

          it "does not render delete this scheme" do
            expect(response).to have_http_status(:ok)
            expect(page).not_to have_link("Delete this scheme", href: "/schemes/#{scheme.id}/delete-confirmation")
          end
        end

        context "with incomplete scheme" do
          let(:add_deactivations) {}
          let!(:scheme) { create(:scheme, :incomplete, owning_organisation: user.organisation) }

          it "renders delete this scheme" do
            expect(response).to have_http_status(:ok)
            expect(page).to have_link("Delete this scheme", href: "/schemes/#{scheme.id}/delete-confirmation")
          end
        end
      end
    end
  end

  describe "#new" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        get "/schemes/new"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { create(:user) }

      before do
        sign_in user
        get "/schemes/new"
      end

      it "returns 401" do
        expect(response).to be_unauthorized
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { create(:user, :data_coordinator) }

      before do
        sign_in user
        get "/schemes/new"
      end

      it "returns a template for a new scheme" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("Create a new supported housing scheme")
      end
    end

    context "when signed in as a support user" do
      let(:user) { create(:user, :support) }

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/schemes/new"
      end

      it "returns a template for a new scheme" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("Create a new supported housing scheme")
      end
    end
  end

  describe "#create" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        post "/schemes"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { create(:user) }

      let(:params) do
        { scheme: { service_name: "asd",
                    sensitive: "1",
                    scheme_type: "Foyer",
                    registered_under_care_act: "No",
                    arrangement_type: "D" } }
      end

      before do
        sign_in user
        post "/schemes", params:
      end

      it "returns 401" do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { create(:user, :data_coordinator) }

      before do
        sign_in user
      end

      context "when making a scheme in the user's organisation" do
        let!(:params) do
          { scheme: { service_name: "  testy ",
                      sensitive: "1",
                      scheme_type: "Foyer",
                      registered_under_care_act: "No",
                      owning_organisation_id: user.organisation.id,
                      arrangement_type: "D" } }
        end

        it "creates a new scheme for user organisation with valid params and renders correct page" do
          expect { post "/schemes", params: }.to change(Scheme, :count).by(1)
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("What client group is this scheme intended for?")
        end

        it "creates a new scheme for user organisation with valid params" do
          post "/schemes", params: params

          expect(Scheme.last.owning_organisation_id).to eq(user.organisation_id)
          expect(Scheme.last.service_name).to eq("testy")
          expect(Scheme.last.scheme_type).to eq("Foyer")
          expect(Scheme.last.sensitive).to eq("Yes")
          expect(Scheme.last.registered_under_care_act).to eq("No")
          expect(Scheme.last.id).not_to eq(nil)
          expect(Scheme.last.has_other_client_group).to eq(nil)
          expect(Scheme.last.primary_client_group).to eq(nil)
          expect(Scheme.last.secondary_client_group).to eq(nil)
          expect(Scheme.last.support_type).to eq(nil)
          expect(Scheme.last.intended_stay).to eq(nil)
          expect(Scheme.last.id_to_display).to match(/S*/)
        end

        context "when support services provider is selected" do
          let(:params) do
            { scheme: { service_name: "testy",
                        sensitive: "1",
                        scheme_type: "Foyer",
                        registered_under_care_act: "No",
                        owning_organisation_id: user.organisation.id,
                        arrangement_type: "R" } }
          end

          it "creates a new scheme for user organisation with valid params and renders correct page" do
            expect { post "/schemes", params: }.to change(Scheme, :count).by(1)
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content(" What client group is this scheme intended for?")
          end

          it "creates a new scheme for user organisation with valid params" do
            post "/schemes", params: params

            expect(Scheme.last.owning_organisation_id).to eq(user.organisation_id)
            expect(Scheme.last.service_name).to eq("testy")
            expect(Scheme.last.scheme_type).to eq("Foyer")
            expect(Scheme.last.sensitive).to eq("Yes")
            expect(Scheme.last.registered_under_care_act).to eq("No")
            expect(Scheme.last.id).not_to eq(nil)
            expect(Scheme.last.has_other_client_group).to eq(nil)
            expect(Scheme.last.primary_client_group).to eq(nil)
            expect(Scheme.last.secondary_client_group).to eq(nil)
            expect(Scheme.last.support_type).to eq(nil)
            expect(Scheme.last.intended_stay).to eq(nil)
            expect(Scheme.last.id_to_display).to match(/S*/)
          end
        end

        context "when required params are missing" do
          let(:params) do
            { scheme: { service_name: "",
                        scheme_type: "",
                        registered_under_care_act: "",
                        arrangement_type: "" } }
          end

          it "renders the same page with error message" do
            post "/schemes", params: params
            expect(response).to have_http_status(:unprocessable_content)
            expect(page).to have_content("Create a new supported housing scheme")
            expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.scheme_type.invalid"))
            expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.registered_under_care_act.invalid"))
            expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.arrangement_type.invalid"))
            expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.service_name.invalid"))
          end
        end

        context "when there are no stock owners" do
          let(:params) do
            { scheme: { service_name: "  testy ",
                        sensitive: "1",
                        scheme_type: "Foyer",
                        registered_under_care_act: "No",
                        arrangement_type: "D" } }
          end

          before do
            user.organisation.stock_owners.destroy_all
          end

          it "infers the user's organisation" do
            post "/schemes", params: params
            expect(Scheme.last.owning_organisation_id).to eq(user.organisation_id)
          end
        end

        context "when the organisation id param is included" do
          let(:organisation) { create(:organisation) }
          let(:params) { { scheme: { owning_organisation: organisation } } }

          it "sets the owning organisation correctly" do
            post "/schemes", params: params
            expect(Scheme.last.owning_organisation_id).to eq(user.organisation_id)
          end
        end
      end

      context "when making a scheme in a parent organisation of the user's organisation" do
        let(:parent_organisation) { create(:organisation) }
        let!(:parent_schemes) { create_list(:scheme, 5, owning_organisation: parent_organisation) }
        let(:params) do
          { scheme: { service_name: "  testy ",
                      sensitive: "1",
                      scheme_type: "Foyer",
                      registered_under_care_act: "No",
                      owning_organisation_id: user.organisation.stock_owners.first.id,
                      arrangement_type: "D" } }
        end

        before do
          create(:organisation_relationship, parent_organisation:, child_organisation: user.organisation)
          parent_schemes.each do |scheme|
            create(:location, scheme:)
          end
        end

        it "creates a new scheme for user organisation with valid params and renders correct page" do
          expect { post "/schemes", params: }.to change(Scheme, :count).by(1)
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("What client group is this scheme intended for?")
        end

        it "creates a new scheme for user organisation with valid params" do
          post "/schemes", params: params

          expect(Scheme.last.owning_organisation_id).to eq(user.organisation.stock_owners.first.id)
          expect(Scheme.last.service_name).to eq("testy")
          expect(Scheme.last.scheme_type).to eq("Foyer")
          expect(Scheme.last.sensitive).to eq("Yes")
          expect(Scheme.last.registered_under_care_act).to eq("No")
          expect(Scheme.last.id).not_to eq(nil)
          expect(Scheme.last.has_other_client_group).to eq(nil)
          expect(Scheme.last.primary_client_group).to eq(nil)
          expect(Scheme.last.secondary_client_group).to eq(nil)
          expect(Scheme.last.support_type).to eq(nil)
          expect(Scheme.last.intended_stay).to eq(nil)
          expect(Scheme.last.id_to_display).to match(/S*/)
        end

        context "when support services provider is selected" do
          let(:params) do
            { scheme: { service_name: "testy",
                        sensitive: "1",
                        scheme_type: "Foyer",
                        registered_under_care_act: "No",
                        owning_organisation_id: user.organisation.stock_owners.first.id,
                        arrangement_type: "R" } }
          end

          it "creates a new scheme for user organisation with valid params and renders correct page" do
            expect { post "/schemes", params: }.to change(Scheme, :count).by(1)
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content(" What client group is this scheme intended for?")
          end

          it "creates a new scheme for user organisation with valid params" do
            post "/schemes", params: params

            expect(Scheme.last.owning_organisation_id).to eq(user.organisation.stock_owners.first.id)
            expect(Scheme.last.service_name).to eq("testy")
            expect(Scheme.last.scheme_type).to eq("Foyer")
            expect(Scheme.last.sensitive).to eq("Yes")
            expect(Scheme.last.registered_under_care_act).to eq("No")
            expect(Scheme.last.id).not_to eq(nil)
            expect(Scheme.last.has_other_client_group).to eq(nil)
            expect(Scheme.last.primary_client_group).to eq(nil)
            expect(Scheme.last.secondary_client_group).to eq(nil)
            expect(Scheme.last.support_type).to eq(nil)
            expect(Scheme.last.intended_stay).to eq(nil)
            expect(Scheme.last.id_to_display).to match(/S*/)
          end
        end

        context "when required params are missing" do
          let(:params) do
            { scheme: { service_name: "",
                        scheme_type: "",
                        registered_under_care_act: "",
                        arrangement_type: "",
                        owning_organisation_id: "" } }
          end

          it "renders the same page with error message" do
            post "/schemes", params: params
            expect(response).to have_http_status(:unprocessable_content)
            expect(page).to have_content("Create a new supported housing scheme")
            expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.scheme_type.invalid"))
            expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.registered_under_care_act.invalid"))
            expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.arrangement_type.invalid"))
            expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.owning_organisation_id.invalid"))
            expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.service_name.invalid"))
          end
        end

        context "when the organisation id param is included" do
          let(:organisation) { create(:organisation) }
          let(:params) { { scheme: { owning_organisation: organisation } } }

          it "sets the owning organisation correctly" do
            post "/schemes", params: params
            expect(Scheme.last.owning_organisation_id).to eq(user.organisation.stock_owners.first.id)
          end
        end
      end

      context "when making a scheme in an organisation recently absorbed by the users organisation" do
        let(:absorbed_organisation) { create(:organisation) }
        let(:params) do
          { scheme: { service_name: "  testy ",
                      sensitive: "1",
                      scheme_type: "Foyer",
                      registered_under_care_act: "No",
                      owning_organisation_id: absorbed_organisation.id,
                      arrangement_type: "D" } }
        end

        before do
          absorbed_organisation.merge_date = 2.days.ago
          absorbed_organisation.absorbing_organisation = user.organisation
          absorbed_organisation.save!
        end

        it "creates a new scheme for this organisation and renders correct page" do
          expect { post "/schemes", params: }.to change(Scheme, :count).by(1)
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("What client group is this scheme intended for?")
        end
      end
    end

    context "when signed in as a support user" do
      let(:organisation) { create(:organisation) }
      let(:user) { create(:user, :support) }
      let(:params) do
        { scheme: { service_name: "testy",
                    sensitive: "1",
                    scheme_type: "Foyer",
                    registered_under_care_act: "No",
                    owning_organisation_id: organisation.id,
                    arrangement_type: "D" } }
      end

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
      end

      it "creates a new scheme for user organisation with valid params and renders correct page" do
        expect { post "/schemes", params: }.to change(Scheme, :count).by(1)
        follow_redirect!
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("What client group is this scheme intended for?")
      end

      it "creates a new scheme for user organisation with valid params" do
        post "/schemes", params: params

        expect(Scheme.last.owning_organisation_id).to eq(organisation.id)
        expect(Scheme.last.service_name).to eq("testy")
        expect(Scheme.last.scheme_type).to eq("Foyer")
        expect(Scheme.last.sensitive).to eq("Yes")
        expect(Scheme.last.registered_under_care_act).to eq("No")
        expect(Scheme.last.id).not_to eq(nil)
        expect(Scheme.last.has_other_client_group).to eq(nil)
        expect(Scheme.last.primary_client_group).to eq(nil)
        expect(Scheme.last.secondary_client_group).to eq(nil)
        expect(Scheme.last.support_type).to eq(nil)
        expect(Scheme.last.intended_stay).to eq(nil)
        expect(Scheme.last.id_to_display).to match(/S*/)
      end

      context "when support services provider is selected" do
        let(:params) do
          { scheme: { service_name: "testy",
                      sensitive: "1",
                      scheme_type: "Foyer",
                      registered_under_care_act: "No",
                      owning_organisation_id: organisation.id,
                      support_services_provider_before_type_cast: "1" } }
        end

        it "creates a new scheme for user organisation with valid params and renders correct page" do
          expect { post "/schemes", params: }.to change(Scheme, :count).by(1)
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("What client group is this scheme intended for?")
        end

        it "creates a new scheme for user organisation with valid params" do
          post "/schemes", params: params
          expect(Scheme.last.owning_organisation_id).to eq(organisation.id)
          expect(Scheme.last.service_name).to eq("testy")
          expect(Scheme.last.scheme_type).to eq("Foyer")
          expect(Scheme.last.sensitive).to eq("Yes")
          expect(Scheme.last.registered_under_care_act).to eq("No")
          expect(Scheme.last.id).not_to eq(nil)
          expect(Scheme.last.has_other_client_group).to eq(nil)
          expect(Scheme.last.primary_client_group).to eq(nil)
          expect(Scheme.last.secondary_client_group).to eq(nil)
          expect(Scheme.last.support_type).to eq(nil)
          expect(Scheme.last.intended_stay).to eq(nil)
          expect(Scheme.last.id_to_display).to match(/S*/)
        end
      end

      context "when required params are missing" do
        let(:params) do
          { scheme: { service_name: "",
                      scheme_type: "",
                      registered_under_care_act: "",
                      owning_organisation_id: nil,
                      arrangement_type: "" } }
        end

        it "renders the same page with error message" do
          post "/schemes", params: params
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content("Create a new supported housing scheme")
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.scheme_type.invalid"))
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.registered_under_care_act.invalid"))
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.arrangement_type.invalid"))
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.service_name.invalid"))
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.owning_organisation_id.invalid"))
        end
      end

      context "when organisation id param refers to a non-stock-owning organisation" do
        let(:organisation_which_does_not_own_stock) { create(:organisation, holds_own_stock: false) }
        let(:params) { { scheme: { owning_organisation_id: organisation_which_does_not_own_stock.id } } }

        it "displays the new page with an error message" do
          post "/schemes", params: params
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content("Enter an organisation that owns housing stock")
        end
      end
    end
  end

  describe "#update" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        patch "/schemes/#{schemes.first.id}"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { create(:user) }

      before do
        sign_in user
        patch "/schemes/#{schemes.first.id}"
      end

      it "returns 401 unauthorized" do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { create(:user, :data_coordinator) }
      let(:scheme_to_update) { create(:scheme, owning_organisation: user.organisation, confirmed: nil) }

      before do
        sign_in user
        patch "/schemes/#{scheme_to_update.id}", params:
      end

      context "when confirming unfinished scheme" do
        let(:params) { { scheme: { owning_organisation_id: user.organisation.id, arrangement_type: nil, confirmed: true, page: "check-answers" } } }

        it "does not allow the scheme to be confirmed" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.arrangement_type.invalid"))
        end
      end

      context "when scheme is completed but not yet confirmed" do
        let(:params) { { scheme: { page: "check-answers" } } }

        it "is not confirmed" do
          expect(scheme_to_update.confirmed).to eq(nil)
        end

        context "when confirming finished scheme" do
          let(:params) { { scheme: { confirmed: true, page: "check-answers" } } }

          before do
            scheme_to_update.reload
          end

          it "confirms scheme" do
            expect(scheme_to_update.confirmed).to eq(true)
          end
        end
      end

      context "when required params are missing" do
        let(:params) do
          { scheme: {
            service_name: "",
            primary_client_group: "",
            secondary_client_group: "",
            scheme_type: "",
            registered_under_care_act: "",
            support_type: "",
            intended_stay: "",
            arrangement_type: "",
            has_other_client_group: "",
            page: "details",
          } }
        end

        it "renders the same page with error message" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content("Create a new supported housing scheme")
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.service_name.invalid"))
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.scheme_type.invalid"))
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.registered_under_care_act.invalid"))
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.primary_client_group.invalid"))
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.secondary_client_group.invalid"))
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.support_type.invalid"))
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.intended_stay.invalid"))
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.has_other_client_group.invalid"))
        end

        context "when updating from check answers page" do
          let(:params) { { scheme: { primary_client_group: "Homeless families with support needs", page: "primary-client-group", check_answers: "true" } } }

          it "renders check answers page after successful update" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("Check your changes before creating this scheme")
          end

          it "updates a scheme with valid params" do
            follow_redirect!
            expect(scheme_to_update.reload.primary_client_group).to eq("Homeless families with support needs")
          end
        end
      end

      context "when updating primary client group" do
        let(:params) { { scheme: { primary_client_group: "Homeless families with support needs", page: "primary-client-group" } } }

        it "renders confirm secondary group after successful update" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("Does this scheme provide for another client group?")
        end

        it "updates a scheme with valid params" do
          follow_redirect!
          expect(scheme_to_update.reload.primary_client_group).to eq("Homeless families with support needs")
        end

        context "when updating from check answers page" do
          let(:params) { { scheme: { primary_client_group: "Homeless families with support needs", page: "primary-client-group", check_answers: "true" } } }

          it "renders check answers page after successful update" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("Check your changes before creating this scheme")
          end

          it "updates a scheme with valid params" do
            follow_redirect!
            expect(scheme_to_update.reload.primary_client_group).to eq("Homeless families with support needs")
          end
        end
      end

      context "when updating confirm secondary client group" do
        let(:params) { { scheme: { has_other_client_group: "Yes", page: "confirm-secondary" } } }

        it "renders secondary client group after successful update" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("What is the other client group?")
        end

        it "updates a scheme with valid params" do
          follow_redirect!
          expect(scheme_to_update.reload.has_other_client_group).to eq("Yes")
        end

        context "when updating from check answers page with the answer YES and no secondary client group set" do
          let(:scheme_to_update) { create(:scheme, owning_organisation: user.organisation, confirmed: nil, secondary_client_group: nil) }
          let(:params) { { scheme: { has_other_client_group: "Yes", page: "confirm-secondary", check_answers: "true" } } }

          it "renders secondary client group page after successful update" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("What is the other client group?")
          end

          it "updates a scheme with valid params" do
            follow_redirect!
            expect(scheme_to_update.reload.has_other_client_group).to eq("Yes")
          end
        end

        context "when updating from check answers page with the answer YES and a secondary client group set" do
          let(:scheme_to_update) { create(:scheme, owning_organisation: user.organisation, confirmed: nil, secondary_client_group: "F") }
          let(:params) { { scheme: { has_other_client_group: "Yes", page: "confirm-secondary", check_answers: "true" } } }

          it "renders check answers page after successful update" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("Check your changes before creating this scheme")
          end

          it "updates a scheme with valid params" do
            follow_redirect!
            expect(scheme_to_update.reload.has_other_client_group).to eq("Yes")
          end
        end

        context "when updating from check answers page with the answer NO" do
          let(:params) { { scheme: { has_other_client_group: "No", page: "confirm-secondary", check_answers: "true" } } }

          it "renders check answers page after successful update" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("Check your changes before creating this scheme")
          end

          it "updates a scheme with valid params" do
            follow_redirect!
            expect(scheme_to_update.reload.has_other_client_group).to eq("No")
          end
        end
      end

      context "when updating secondary client group" do
        let(:params) { { scheme: { secondary_client_group: "Homeless families with support needs", page: "secondary-client-group" } } }

        it "renders confirm support page after successful update" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("What support does this scheme provide?")
        end

        it "updates a scheme with valid params" do
          follow_redirect!
          expect(scheme_to_update.reload.secondary_client_group).to eq("Homeless families with support needs")
        end

        context "when updating from check answers page" do
          let(:params) { { scheme: { secondary_client_group: "Homeless families with support needs", page: "secondary-client-group", check_answers: "true" } } }

          it "renders check answers page after successful update" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("Check your changes before creating this scheme")
          end

          it "updates a scheme with valid params" do
            follow_redirect!
            expect(scheme_to_update.reload.secondary_client_group).to eq("Homeless families with support needs")
          end
        end
      end

      context "when updating support" do
        let(:params) { { scheme: { intended_stay: "Medium stay", support_type: "Low level", page: "support" } } }

        it "renders the check answers page" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("Check your answers before creating this scheme")
        end

        it "updates a scheme with valid params" do
          follow_redirect!
          expect(scheme_to_update.reload.intended_stay).to eq("Medium stay")
          expect(scheme_to_update.reload.support_type).to eq("Low level")
        end

        context "when updating from check answers page" do
          let(:params) { { scheme: { intended_stay: "Medium stay", support_type: "Low level", page: "support", check_answers: "true" } } }

          it "renders check answers page after successful update" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("Check your changes before creating this scheme")
          end

          it "updates a scheme with valid params" do
            follow_redirect!
            expect(scheme_to_update.reload.intended_stay).to eq("Medium stay")
            expect(scheme_to_update.reload.support_type).to eq("Low level")
          end
        end
      end

      context "when updating details" do
        let(:params) do
          { scheme: { service_name: "testy",
                      sensitive: "1",
                      scheme_type: "Foyer",
                      registered_under_care_act: "No",
                      page: "details",
                      owning_organisation_id: organisation.id,
                      arrangement_type: "D" } }
        end

        it "renders confirm secondary group after successful update" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("What client group is this scheme intended for?")
        end

        it "updates a scheme with valid params" do
          follow_redirect!
          expect(scheme_to_update.reload.service_name).to eq("testy")
          expect(scheme_to_update.reload.scheme_type).to eq("Foyer")
          expect(scheme_to_update.reload.sensitive).to eq("Yes")
          expect(scheme_to_update.reload.registered_under_care_act).to eq("No")
        end

        context "when updating from check answers page" do
          let(:params) { { scheme: { service_name: "testy", sensitive: "1", scheme_type: "Foyer", registered_under_care_act: "No", page: "details", check_answers: "true" } } }

          it "renders check answers page after successful update" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("Check your changes before creating this scheme")
          end

          it "updates a scheme with valid params" do
            follow_redirect!
            expect(scheme_to_update.reload.service_name).to eq("testy")
            expect(scheme_to_update.reload.scheme_type).to eq("Foyer")
            expect(scheme_to_update.reload.sensitive).to eq("Yes")
            expect(scheme_to_update.reload.registered_under_care_act).to eq("No")
          end
        end
      end

      context "when editing scheme name details" do
        let(:params) { { scheme: { service_name: "testy", sensitive: "1", page: "edit-name" } } }

        it "renders scheme show page after successful update" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content(scheme_to_update.reload.service_name)
        end

        it "updates a scheme with valid params" do
          follow_redirect!
          expect(scheme_to_update.reload.service_name).to eq("testy")
          expect(scheme_to_update.reload.sensitive).to eq("Yes")
        end
      end

      context "when the requested scheme does not exist" do
        let(:scheme_to_update) { OpenStruct.new(id: Scheme.maximum(:id) + 1) }
        let(:params) { {} }

        it "returns not found" do
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "when signed in as a support user" do
      let(:user) { create(:user, :support) }
      let(:scheme_to_update) { create(:scheme, owning_organisation: user.organisation, confirmed: nil) }

      before do
        create(:location, scheme: scheme_to_update)
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        patch "/schemes/#{scheme_to_update.id}", params:
      end

      context "when confirming unfinished scheme" do
        let(:params) { { scheme: { owning_organisation_id: user.organisation.id, arrangement_type: nil, confirmed: true, page: "check-answers" } } }

        it "does not allow the scheme to be confirmed" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.arrangement_type.invalid"))
        end
      end

      context "when scheme is completed but not yet confirmed" do
        let(:params) { { scheme: { page: "check-answers" } } }

        it "is not confirmed" do
          expect(scheme_to_update.confirmed).to eq(nil)
        end

        context "when confirming finished scheme" do
          let(:params) { { scheme: { confirmed: true, page: "check-answers" } } }

          before do
            scheme_to_update.reload
          end

          it "confirms scheme" do
            expect(scheme_to_update.confirmed).to eq(true)
          end
        end
      end

      context "when required params are missing" do
        let(:params) do
          { scheme: {
            service_name: "",
            managing_organisation_id: "",
            owning_organisation_id: "",
            primary_client_group: "",
            secondary_client_group: "",
            scheme_type: "",
            registered_under_care_act: "",
            support_type: "",
            intended_stay: "",
            arrangement_type: "",
            has_other_client_group: "",
            page: "details",
          } }
        end

        it "renders the same page with error message" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content("Create a new supported housing scheme")
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.owning_organisation_id.invalid"))
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.service_name.invalid"))
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.scheme_type.invalid"))
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.registered_under_care_act.invalid"))
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.primary_client_group.invalid"))
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.secondary_client_group.invalid"))
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.support_type.invalid"))
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.intended_stay.invalid"))
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.has_other_client_group.invalid"))
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.arrangement_type.invalid"))
        end

        context "when updating from check answers page" do
          let(:params) { { scheme: { primary_client_group: "Homeless families with support needs", page: "primary-client-group", check_answers: "true" } } }

          it "renders check answers page after successful update" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("Check your changes before creating this scheme")
          end

          it "updates a scheme with valid params" do
            follow_redirect!
            expect(scheme_to_update.reload.primary_client_group).to eq("Homeless families with support needs")
          end
        end

        context "when saving a scheme" do
          let(:params) { { scheme: { page: "check-answers", confirmed: "true" } } }

          it "marks the scheme as confirmed" do
            expect(scheme_to_update.reload.confirmed?).to eq(true)
          end

          it "marks all the scheme locations as confirmed given they are complete" do
            expect(scheme_to_update.locations.count > 0).to eq(true)
            scheme_to_update.locations.each do |location|
              expect(location.confirmed?).to eq(true)
            end
          end
        end
      end

      context "when updating primary client group" do
        let(:params) { { scheme: { primary_client_group: "Homeless families with support needs", page: "primary-client-group" } } }

        it "renders confirm secondary group after successful update" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("Does this scheme provide for another client group?")
        end

        it "updates a scheme with valid params" do
          follow_redirect!
          expect(scheme_to_update.reload.primary_client_group).to eq("Homeless families with support needs")
        end

        context "when updating from check answers page" do
          let(:params) { { scheme: { primary_client_group: "Homeless families with support needs", page: "primary-client-group", check_answers: "true" } } }

          it "renders check answers page after successful update" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("Check your changes before creating this scheme")
          end

          it "updates a scheme with valid params" do
            follow_redirect!
            expect(scheme_to_update.reload.primary_client_group).to eq("Homeless families with support needs")
          end
        end
      end

      context "when updating confirm secondary client group" do
        let(:params) { { scheme: { has_other_client_group: "Yes", page: "confirm-secondary" } } }

        it "renders secondary client group after successful update" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("What is the other client group?")
        end

        it "updates a scheme with valid params" do
          follow_redirect!
          expect(scheme_to_update.reload.has_other_client_group).to eq("Yes")
        end

        context "when updating from check answers page with the answer YES and no existing secondary client group set" do
          let(:scheme_to_update) { create(:scheme, owning_organisation: user.organisation, confirmed: nil, secondary_client_group: nil) }
          let(:params) { { scheme: { has_other_client_group: "Yes", page: "confirm-secondary", check_answers: "true" } } }

          it "renders secondary client group page after successful update" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("What is the other client group?")
          end

          it "updates a scheme with valid params" do
            follow_redirect!
            expect(scheme_to_update.reload.has_other_client_group).to eq("Yes")
          end
        end

        context "when updating from check answers page with the answer YES and an existing secondary client group set" do
          let(:scheme_to_update) { create(:scheme, owning_organisation: user.organisation, confirmed: nil, secondary_client_group: "F") }
          let(:params) { { scheme: { has_other_client_group: "Yes", page: "confirm-secondary", check_answers: "true" } } }

          it "renders check answers page after successful update" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("Check your changes before creating this scheme")
          end

          it "updates a scheme with valid params" do
            follow_redirect!
            expect(scheme_to_update.reload.has_other_client_group).to eq("Yes")
          end
        end

        context "when updating from check answers page with the answer NO" do
          let(:params) { { scheme: { has_other_client_group: "No", page: "confirm-secondary", check_answers: "true" } } }

          it "renders check answers page after successful update" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("Check your changes before creating this scheme")
          end

          it "updates a scheme with valid params" do
            follow_redirect!
            expect(scheme_to_update.reload.has_other_client_group).to eq("No")
          end
        end
      end

      context "when updating secondary client group" do
        let(:params) { { scheme: { secondary_client_group: "Homeless families with support needs", page: "secondary-client-group" } } }

        it "renders confirm support page after successful update" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("What support does this scheme provide?")
        end

        it "updates a scheme with valid params" do
          follow_redirect!
          expect(scheme_to_update.reload.secondary_client_group).to eq("Homeless families with support needs")
        end

        context "when updating from check answers page" do
          let(:params) { { scheme: { secondary_client_group: "Homeless families with support needs", page: "secondary-client-group", check_answers: "true" } } }

          it "renders check answers page after successful update" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("Check your changes before creating this scheme")
          end

          it "updates a scheme with valid params" do
            follow_redirect!
            expect(scheme_to_update.reload.secondary_client_group).to eq("Homeless families with support needs")
          end
        end
      end

      context "when updating support" do
        let(:params) { { scheme: { intended_stay: "Medium stay", support_type: "Low level", page: "support" } } }

        it "renders scheme check your answers page after successful update" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("Check your answers before creating this scheme")
        end

        it "updates a scheme with valid params" do
          follow_redirect!
          expect(scheme_to_update.reload.intended_stay).to eq("Medium stay")
          expect(scheme_to_update.reload.support_type).to eq("Low level")
        end

        context "when updating from check answers page" do
          let(:params) { { scheme: { intended_stay: "Medium stay", support_type: "Low level", page: "support", check_answers: "true" } } }

          it "renders check answers page after successful update" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("Check your changes before creating this scheme")
          end

          it "updates a scheme with valid params" do
            follow_redirect!
            expect(scheme_to_update.reload.intended_stay).to eq("Medium stay")
            expect(scheme_to_update.reload.support_type).to eq("Low level")
          end
        end
      end

      context "when updating details" do
        let(:another_organisation) { create(:organisation) }
        let(:params) do
          { scheme: { service_name: "testy",
                      sensitive: "1",
                      scheme_type: "Foyer",
                      registered_under_care_act: "No",
                      page: "details",
                      arrangement_type: "The same organisation that owns the housing stock",
                      owning_organisation_id: another_organisation.id } }
        end

        it "renders confirm secondary group after successful update" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("What client group is this scheme intended for?")
        end

        it "updates a scheme with valid params" do
          follow_redirect!
          expect(scheme_to_update.reload.service_name).to eq("testy")
          expect(scheme_to_update.reload.scheme_type).to eq("Foyer")
          expect(scheme_to_update.reload.sensitive).to eq("Yes")
          expect(scheme_to_update.reload.registered_under_care_act).to eq("No")
          expect(scheme_to_update.reload.owning_organisation_id).to eq(another_organisation.id)
        end

        context "when updating from check answers page" do
          let(:params) { { scheme: { service_name: "testy", sensitive: "1", scheme_type: "Foyer", registered_under_care_act: "No", page: "details", check_answers: "true" } } }

          it "renders check answers page after successful update" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("Check your changes before creating this scheme")
          end

          it "updates a scheme with valid params" do
            follow_redirect!
            expect(scheme_to_update.reload.service_name).to eq("testy")
            expect(scheme_to_update.reload.scheme_type).to eq("Foyer")
            expect(scheme_to_update.reload.sensitive).to eq("Yes")
            expect(scheme_to_update.reload.registered_under_care_act).to eq("No")
          end
        end
      end

      context "when editing scheme name details" do
        let(:another_organisation) { create(:organisation) }
        let(:params) do
          { scheme: { service_name: "testy",
                      sensitive: "1",
                      page: "edit-name",
                      owning_organisation_id: another_organisation.id } }
        end

        it "renders scheme show page after successful update" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content(scheme_to_update.reload.service_name)
          expect(scheme_to_update.reload.owning_organisation_id).to eq(another_organisation.id)
        end

        it "updates a scheme with valid params" do
          follow_redirect!
          expect(scheme_to_update.reload.service_name).to eq("testy")
          expect(scheme_to_update.reload.sensitive).to eq("Yes")
        end
      end
    end
  end

  describe "#primary_client_group" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        get "/schemes/1/primary-client-group"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { create(:user) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation, confirmed: nil) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/primary-client-group"
      end

      it "returns 401" do
        expect(response).to be_unauthorized
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { create(:user, :data_coordinator) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation, confirmed: nil) }
      let(:another_scheme) { create(:scheme, confirmed: nil) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/primary-client-group"
      end

      it "returns a template for a primary-client-group" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("What client group is this scheme intended for?")
      end

      it "has correct back link" do
        expect(page).to have_link("Back", href: "/schemes/#{scheme.id}/details")
      end

      context "and accessed from check answers" do
        it "has correct back link" do
          get "/schemes/#{scheme.id}/primary-client-group?referrer=check-answers"
          expect(page).to have_link("Back", href: "/schemes/#{scheme.id}/check-answers")
        end
      end

      context "when attempting to access primary-client-group scheme page for another organisation" do
        before do
          get "/schemes/#{another_scheme.id}/primary-client-group"
        end

        it "returns 401" do
          expect(response).to be_unauthorized
        end
      end
    end

    context "when signed in as a support user" do
      let(:user) { create(:user, :support) }
      let!(:scheme) { create(:scheme, confirmed: nil) }

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/schemes/#{scheme.id}/primary-client-group"
      end

      it "returns a template for a primary-client-group" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("What client group is this scheme intended for?")
      end

      context "and the scheme is confirmed" do
        before do
          scheme.update!(confirmed: true)
          get "/schemes/#{scheme.id}/primary-client-group"
        end

        it "allows editing the primary client group" do
          expect(response).to have_http_status(:ok)
          expect(path).to match("/schemes/#{scheme.id}/primary-client-group")
        end
      end
    end
  end

  describe "#confirm_secondary_client_group" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        get "/schemes/1/confirm-secondary-client-group"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { create(:user) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation, confirmed: nil) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/confirm-secondary-client-group"
      end

      it "returns 401" do
        expect(response).to be_unauthorized
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { create(:user, :data_coordinator) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation, confirmed: nil) }
      let(:another_scheme) { create(:scheme, confirmed: nil) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/confirm-secondary-client-group"
      end

      it "returns a template for a confirm-secondary-client-group" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("Does this scheme provide for another client group?")
      end

      it "has correct back link" do
        expect(page).to have_link("Back", href: "/schemes/#{scheme.id}/primary-client-group")
      end

      context "and accessed from check answers" do
        it "has correct back link" do
          get "/schemes/#{scheme.id}/confirm-secondary-client-group?referrer=check-answers"
          expect(page).to have_link("Back", href: "/schemes/#{scheme.id}/check-answers")
        end
      end

      context "when attempting to access confirm-secondary-client-group scheme page for another organisation" do
        before do
          get "/schemes/#{another_scheme.id}/confirm-secondary-client-group"
        end

        it "returns 401" do
          expect(response).to be_unauthorized
        end
      end
    end

    context "when signed in as a support user" do
      let(:user) { create(:user, :support) }
      let!(:scheme) { create(:scheme, confirmed: nil) }

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/schemes/#{scheme.id}/confirm-secondary-client-group"
      end

      it "returns a template for a confirm-secondary-client-group" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("Does this scheme provide for another client group?")
      end

      context "and the scheme is confirmed" do
        before do
          scheme.update!(confirmed: true)
          get "/schemes/#{scheme.id}/confirm-secondary-client-group"
        end

        it "allows updating secondary client group" do
          expect(response).to have_http_status(:ok)
          expect(path).to match("/schemes/#{scheme.id}/confirm-secondary-client-group")
        end
      end
    end
  end

  describe "#secondary_client_group" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        get "/schemes/1/secondary-client-group"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { create(:user) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation, confirmed: nil) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/secondary-client-group"
      end

      it "returns 401" do
        expect(response).to be_unauthorized
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { create(:user, :data_coordinator) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation, confirmed: nil) }
      let(:another_scheme) { create(:scheme, confirmed: nil) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/secondary-client-group"
      end

      it "returns a template for a secondary-client-group" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("What is the other client group?")
      end

      it "has correct back link" do
        expect(page).to have_link("Back", href: "/schemes/#{scheme.id}/confirm-secondary-client-group")
      end

      context "and accessed from check answers" do
        it "has correct back link" do
          get "/schemes/#{scheme.id}/secondary-client-group?referrer=check-answers"
          expect(page).to have_link("Back", href: "/schemes/#{scheme.id}/check-answers")
        end
      end

      context "and accessed from has other client group" do
        it "has correct back link" do
          get "/schemes/#{scheme.id}/secondary-client-group?referrer=has-other-client-group"
          expect(page).to have_link("Back", href: "/schemes/#{scheme.id}/confirm-secondary-client-group?referrer=check-answers")
        end
      end

      context "when attempting to access secondary-client-group scheme page for another organisation" do
        before do
          get "/schemes/#{another_scheme.id}/secondary-client-group"
        end

        it "returns 401" do
          expect(response).to be_unauthorized
        end
      end
    end

    context "when signed in as a support user" do
      let(:user) { create(:user, :support) }
      let!(:scheme) { create(:scheme, confirmed: nil, primary_client_group: Scheme::PRIMARY_CLIENT_GROUP[:"Homeless families with support needs"]) }

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/schemes/#{scheme.id}/secondary-client-group"
      end

      it "returns a template for a secondary-client-group" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("What is the other client group?")
      end

      context "and the scheme is confirmed" do
        before do
          scheme.update!(confirmed: true)
          get "/schemes/#{scheme.id}/secondary-client-group"
        end

        it "allows editing secondary client group" do
          expect(response).to have_http_status(:ok)
          expect(path).to match("/schemes/#{scheme.id}/secondary-client-group")
        end
      end

      it "does not show the primary client group as an option" do
        expect(scheme.primary_client_group).not_to be_nil
        expect(page).not_to have_content("Homeless families with support needs")
      end
    end
  end

  describe "#support" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        get "/schemes/1/support"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { create(:user) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation, confirmed: nil) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/support"
      end

      it "returns 401 unauthorized" do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { create(:user, :data_coordinator) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation, confirmed: nil, has_other_client_group: "Yes") }
      let(:another_scheme) { create(:scheme, confirmed: nil) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/support"
      end

      it "returns a template for a support" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("What support does this scheme provide?")
      end

      context "when scheme has secondary client group" do
        it "has correct back link" do
          expect(page).to have_link("Back", href: "/schemes/#{scheme.id}/secondary-client-group")
        end
      end

      context "when scheme has no secondary client group" do
        let(:scheme) { create(:scheme, owning_organisation: user.organisation, confirmed: nil, has_other_client_group: "No") }

        it "has correct back link" do
          expect(page).to have_link("Back", href: "/schemes/#{scheme.id}/confirm-secondary-client-group")
        end
      end

      context "and accessed from check answers" do
        it "has correct back link" do
          get "/schemes/#{scheme.id}/support?referrer=check-answers"
          expect(page).to have_link("Back", href: "/schemes/#{scheme.id}/check-answers")
        end
      end

      context "when attempting to access secondary-client-group scheme page for another organisation" do
        before do
          get "/schemes/#{another_scheme.id}/support"
        end

        it "returns 401" do
          expect(response).to be_unauthorized
        end
      end

      context "and the scheme is confirmed" do
        before do
          scheme.update!(confirmed: true)
          get "/schemes/#{scheme.id}/support"
        end

        it "redirects to a view scheme page" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(path).to match("/schemes/#{scheme.id}")
          expect(page).to have_content(scheme.service_name)
          assert_select "a", text: /Change/, count: 3
        end
      end
    end

    context "when signed in as a support user" do
      let(:user) { create(:user, :support) }
      let!(:scheme) { create(:scheme, confirmed: nil) }

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/schemes/#{scheme.id}/support"
      end

      it "returns a template for a support" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("What support does this scheme provide?")
      end
    end
  end

  describe "#check-answers" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        get "/schemes/1/check-answers"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { create(:user) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/check-answers"
      end

      it "returns 200" do
        expect(response).to be_successful
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { create(:user, :data_coordinator) }
      let!(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let!(:another_scheme) { create(:scheme) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/check-answers"
      end

      it "returns a template for a support" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("Check your changes before creating this scheme")
      end

      context "when attempting to access check-answers scheme page for another organisation" do
        before do
          get "/schemes/#{another_scheme.id}/check-answers"
        end

        it "returns 401" do
          expect(response).to be_unauthorized
        end
      end
    end

    context "when signed in as a support user" do
      let(:user) { create(:user, :support) }
      let!(:scheme) { create(:scheme) }

      before do
        create(:location, scheme:)
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/schemes/#{scheme.id}/check-answers"
      end

      it "returns a template for a support" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("Check your changes before creating this scheme")
      end

      context "with an active scheme" do
        it "does not render delete this scheme" do
          expect(scheme.status).to eq(:active)
          expect(page).not_to have_link("Delete this scheme", href: "/schemes/#{scheme.id}/delete-confirmation")
        end
      end

      context "with an incomplete scheme" do
        let(:scheme) { create(:scheme, :incomplete) }

        it "renders delete this scheme" do
          expect(scheme.reload.status).to eq(:incomplete)
          expect(page).to have_link("Delete this scheme", href: "/schemes/#{scheme.id}/delete-confirmation")
        end
      end
    end
  end

  describe "#details" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        get "/schemes/1/details"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { create(:user) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation, confirmed: nil) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/details"
      end

      it "returns 401 unauthorized" do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { create(:user, :data_coordinator) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation, confirmed: nil) }
      let(:another_scheme) { create(:scheme, confirmed: nil) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/details"
      end

      it "returns a template for a support" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("Create a new supported housing scheme")
      end

      it "has correct back link" do
        expect(page).to have_link("Back", href: "/schemes")
      end

      context "and accessed from check answers" do
        it "has correct back link" do
          get "/schemes/#{scheme.id}/details?referrer=check-answers"
          expect(page).to have_link("Back", href: "/schemes/#{scheme.id}/check-answers")
        end
      end

      context "when attempting to access check-answers scheme page for another organisation" do
        before do
          get "/schemes/#{another_scheme.id}/details"
        end

        it "returns 401" do
          expect(response).to be_unauthorized
        end
      end

      context "and the scheme is confirmed" do
        before do
          scheme.update!(confirmed: true)
          get "/schemes/#{scheme.id}/details"
        end

        it "redirects to a view scheme page" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(path).to match("/schemes/#{scheme.id}")
          expect(page).to have_content(scheme.service_name)
          assert_select "a", text: /Change/, count: 3
        end
      end
    end

    context "when signed in as a support user" do
      let(:user) { create(:user, :support) }
      let!(:scheme) { create(:scheme, confirmed: nil) }

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/schemes/#{scheme.id}/details"
      end

      it "returns a template for a support" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("Create a new supported housing scheme")
      end
    end
  end

  describe "#edit_name" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        get "/schemes/1/edit-name"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { create(:user) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/edit-name"
      end

      it "returns 401" do
        expect(response).to be_unauthorized
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { create(:user, :data_coordinator) }
      let!(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let!(:another_scheme) { create(:scheme) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/edit-name"
      end

      it "returns a template for a edit-name" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("Scheme details")
        expect(page).to have_content("This scheme contains confidential information")
      end

      context "when there are stock owners" do
        let(:parent_organisation) { create(:organisation) }

        before do
          create(:organisation_relationship, parent_organisation:, child_organisation: user.organisation)
          get "/schemes/#{scheme.id}/edit-name"
        end

        it "includes the owning organisation question" do
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("Which organisation owns the housing stock for this scheme?")
        end
      end

      context "when there are no stock owners" do
        before do
          get "/schemes/#{scheme.id}/edit-name"
        end

        context "and there are no absorbed organisations" do
          it "does not include the owning organisation question" do
            expect(response).to have_http_status(:ok)
            expect(page).not_to have_content("Which organisation owns the housing stock for this scheme?")
          end
        end

        context "and there are organisations absorbed during an open collection period" do
          let(:merged_organisation) { create(:organisation) }

          before do
            merged_organisation.update!(absorbing_organisation: user.organisation, merge_date: Time.zone.today)
            get "/schemes/#{scheme.id}/edit-name"
          end

          it "includes the owning organisation question" do
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("Which organisation owns the housing stock for this scheme?")
          end
        end

        context "and there are no recently absorbed organisations" do
          let(:merged_organisation) { create(:organisation) }

          before do
            merged_organisation.update!(absorbing_organisation: user.organisation, merge_date: Time.zone.today - 2.years)
            get "/schemes/#{scheme.id}/edit-name"
          end

          it "does not include the owning organisation question" do
            expect(response).to have_http_status(:ok)
            expect(page).not_to have_content("Which organisation owns the housing stock for this scheme?")
          end
        end
      end

      context "when attempting to access secondary-client-group scheme page for another organisation" do
        before do
          get "/schemes/#{another_scheme.id}/edit-name"
        end

        it "returns 401" do
          expect(response).to be_unauthorized
        end
      end
    end

    context "when signed in as a support user" do
      let(:user) { create(:user, :support) }
      let!(:scheme) { create(:scheme) }

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/schemes/#{scheme.id}/edit-name"
      end

      it "returns a template for a secondary-client-group" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("Scheme details")
        expect(page).to have_content("This scheme contains confidential information")
        expect(page).to have_content("Which organisation owns the housing stock for this scheme?")
      end
    end
  end

  describe "#deactivate" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        patch "/schemes/1/new-deactivation"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { create(:user) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation, created_at: Time.zone.today) }

      before do
        sign_in user
        patch "/schemes/#{scheme.id}/new-deactivation"
      end

      it "returns 401" do
        expect(response).to be_unauthorized
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { create(:user, :data_coordinator) }
      let!(:scheme) { create(:scheme, owning_organisation: user.organisation, created_at: Time.zone.local(2023, 10, 11)) }
      let!(:location) { create(:location, scheme:) }
      let(:deactivation_date) { Time.utc(2022, 10, 10) }
      let(:lettings_log) { create(:lettings_log, :sh, location:, scheme:, startdate:, owning_organisation: user.organisation, assigned_to: user) }
      let(:startdate) { Time.utc(2022, 10, 11) }
      let(:setup_schemes) { nil }

      before do
        allow(FormHandler.instance).to receive(:lettings_in_crossover_period?).and_return(true)
        Timecop.freeze(Time.utc(2023, 10, 10))
        Singleton.__init__(FormHandler)
        lettings_log
        sign_in user
        setup_schemes
        patch "/schemes/#{scheme.id}/new-deactivation", params:
      end

      after do
        Timecop.unfreeze
        Singleton.__init__(FormHandler)
      end

      context "with default date" do
        let(:params) { { scheme_deactivation_period: { deactivation_date_type: "default", deactivation_date: } } }

        context "and affected logs" do
          it "redirects to the confirmation page" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("This change will affect #{scheme.lettings_logs.count} log and 1 location.")
          end
        end

        context "and no affected logs" do
          let(:setup_schemes) { scheme.lettings_logs.update(scheme: nil) }

          before do
            create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 4, 1), reactivation_date: nil, location:)
          end

          it "redirects to the scheme page and updates the deactivation period" do
            follow_redirect!
            follow_redirect!
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
            scheme.reload
            expect(scheme.scheme_deactivation_periods.count).to eq(1)
            expect(scheme.scheme_deactivation_periods.first.deactivation_date).to eq(Time.zone.local(2022, 4, 1))
          end
        end
      end

      context "with other date" do
        let(:params) { { scheme_deactivation_period: { deactivation_date_type: "other", "deactivation_date": "10/10/2022" } } }

        context "and affected logs" do
          it "redirects to the confirmation page" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("This change will affect #{scheme.lettings_logs.count} log and 1 location.")
          end
        end

        context "and no affected logs" do
          let(:setup_schemes) { scheme.lettings_logs.update(scheme: nil) }

          before do
            create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 4, 5), reactivation_date: nil, location:)
          end

          it "redirects to the scheme page and updates the deactivation period" do
            follow_redirect!
            follow_redirect!
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
            scheme.reload
            expect(scheme.scheme_deactivation_periods.count).to eq(1)
            expect(scheme.scheme_deactivation_periods.first.deactivation_date).to eq(Time.zone.local(2022, 10, 10))
          end
        end
      end

      context "when confirming deactivation" do
        let(:params) { { deactivation_date:, confirm: true, deactivation_date_type: "other" } }

        before do
          Timecop.freeze(Time.utc(2022, 10, 10))
          sign_in user
        end

        after do
          Timecop.unfreeze
        end

        context "and a log startdate is after scheme deactivation date" do
          before do
            allow(LocationOrSchemeDeactivationMailer).to receive(:send_deactivation_mail).and_call_original

            patch "/schemes/#{scheme.id}/deactivate", params:
          end

          it "updates existing scheme with valid deactivation date and renders scheme page" do
            follow_redirect!
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
            scheme.reload
            expect(scheme.scheme_deactivation_periods.count).to eq(1)
            expect(scheme.scheme_deactivation_periods.first.deactivation_date).to eq(deactivation_date)
          end

          it "clears the scheme and scheme answers" do
            expect(lettings_log.scheme).to eq(scheme)
            expect(lettings_log.scheme).to eq(scheme)
            lettings_log.reload
            expect(lettings_log.scheme).to eq(nil)
            expect(lettings_log.scheme).to eq(nil)
          end

          it "marks log as needing attention" do
            expect(lettings_log.unresolved).to eq(nil)
            lettings_log.reload
            expect(lettings_log.unresolved).to eq(true)
          end

          it "sends deactivation emails" do
            expect(LocationOrSchemeDeactivationMailer).to have_received(:send_deactivation_mail).with(
              user,
              1,
              update_logs_lettings_logs_url,
              scheme.service_name,
            )
          end
        end

        context "and a log startdate is before scheme deactivation date" do
          let(:startdate) { Time.utc(2022, 10, 9) }

          it "does not update the log" do
            expect(lettings_log.scheme).to eq(scheme)
            expect(lettings_log.scheme).to eq(scheme)
            lettings_log.reload
            expect(lettings_log.scheme).to eq(scheme)
            expect(lettings_log.scheme).to eq(scheme)
          end

          it "does not mark log as needing attention" do
            expect(lettings_log.unresolved).to eq(nil)
            lettings_log.reload
            expect(lettings_log.unresolved).to eq(nil)
          end
        end

        context "and there already is a deactivation period" do
          let(:add_deactivations) { create(:scheme_deactivation_period, deactivation_date: Time.zone.local(2023, 6, 5), reactivation_date: nil, scheme:) }

          before do
            create(:scheme_deactivation_period, deactivation_date: Time.zone.local(2023, 6, 5), reactivation_date: nil, scheme:)
            patch "/schemes/#{scheme.id}/deactivate", params:
          end

          it "updates existing scheme with valid deactivation date and renders scheme page" do
            follow_redirect!
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
            scheme.reload
            expect(scheme.scheme_deactivation_periods.count).to eq(1)
            expect(scheme.scheme_deactivation_periods.first.deactivation_date).to eq(deactivation_date)
          end

          it "clears the scheme and scheme answers" do
            expect(lettings_log.scheme).to eq(scheme)
            lettings_log.reload
            expect(lettings_log.scheme).to eq(nil)
            expect(lettings_log.scheme).to eq(nil)
          end

          it "marks log as needing attention" do
            expect(lettings_log.unresolved).to eq(nil)
            lettings_log.reload
            expect(lettings_log.unresolved).to eq(true)
          end
        end

        context "and the users need to be notified" do
          it "sends E-mails to the creators of affected logs with counts" do
            expect {
              patch "/schemes/#{scheme.id}/deactivate", params:
            }.to enqueue_job(ActionMailer::MailDeliveryJob)
          end
        end
      end

      context "when the date is not selected" do
        let(:params) { { scheme_deactivation_period: { "deactivation_date": "" } } }

        it "displays the new page with an error message" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("validations.scheme.toggle_date.not_selected"))
        end
      end

      context "when invalid date is entered" do
        let(:params) { { scheme_deactivation_period: { deactivation_date_type: "other", "deactivation_date": "10/44/2022" } } }

        it "displays the new page with an error message" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("validations.scheme.toggle_date.invalid"))
        end
      end

      context "when the date is entered is before the beginning of current collection window" do
        let(:params) { { scheme_deactivation_period: { deactivation_date_type: "other", "deactivation_date": "10/4/2020" } } }

        it "displays the new page with an error message" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("validations.scheme.toggle_date.out_of_range", date: "1 April 2022"))
        end
      end

      context "when the day is not entered" do
        let(:params) { { scheme_deactivation_period: { deactivation_date_type: "other", "deactivation_date": "/2/2022" } } }

        it "displays page with an error message" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("validations.scheme.toggle_date.invalid"))
        end
      end

      context "when the month is not entered" do
        let(:params) { { scheme_deactivation_period: { deactivation_date_type: "other", "deactivation_date": "2//2022" } } }

        it "displays page with an error message" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("validations.scheme.toggle_date.invalid"))
        end
      end

      context "when the year is not entered" do
        let(:params) { { scheme_deactivation_period: { deactivation_date_type: "other", "deactivation_date": "2/2/" } } }

        it "displays page with an error message" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("validations.scheme.toggle_date.invalid"))
        end
      end

      context "when there is an earlier open deactivation" do
        let(:deactivation_date) { Time.zone.local(2022, 10, 10) }
        let(:params) { { scheme_deactivation_period: { deactivation_date_type: "other", "deactivation_date": "8/9/2023" } } }
        let(:add_deactivations) { create(:scheme_deactivation_period, deactivation_date: Time.zone.local(2023, 6, 5), reactivation_date: nil, scheme:) }

        before do
          create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 4, 5), reactivation_date: nil, location:)
        end

        it "redirects to the scheme page and updates the existing deactivation period" do
          follow_redirect!
          follow_redirect!
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
          scheme.reload
          expect(scheme.scheme_deactivation_periods.count).to eq(1)
          expect(scheme.scheme_deactivation_periods.first.deactivation_date).to eq(Time.zone.local(2023, 9, 8))
        end
      end

      context "when there is a later open deactivation" do
        let(:deactivation_date) { Time.zone.local(2022, 10, 10) }
        let(:params) { { scheme_deactivation_period: { deactivation_date_type: "other", "deactivation_date": "8/9/2022" } } }
        let(:add_deactivations) { create(:scheme_deactivation_period, deactivation_date: Time.zone.local(2023, 6, 5), reactivation_date: nil, scheme:) }

        it "redirects to the confirmation page" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("This change will affect 1 log and 1 location.")
        end
      end
    end
  end

  describe "#delete-confirmation" do
    let(:scheme) { create(:scheme, owning_organisation: user.organisation) }

    before do
      Timecop.freeze(Time.utc(2022, 10, 10))
      scheme.scheme_deactivation_periods << create(:scheme_deactivation_period, deactivation_date: Time.zone.local(2022, 10, 9), scheme:)
      scheme.save!
      get "/schemes/#{scheme.id}/delete-confirmation"
    end

    after do
      Timecop.unfreeze
    end

    context "when not signed in" do
      it "redirects to the sign in page" do
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in" do
      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/schemes/#{scheme.id}/delete-confirmation"
      end

      context "with a data provider user" do
        let(:user) { create(:user) }

        it "returns 401 unauthorized" do
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "with a data coordinator user" do
        let(:user) { create(:user, :data_coordinator) }

        it "returns 401 unauthorized" do
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "with a support user user" do
        let(:user) { create(:user, :support) }

        it "shows the correct title" do
          expect(page.find("h1").text).to include "Are you sure you want to delete this scheme?"
        end

        it "shows a warning to the user" do
          expect(page).to have_selector(".govuk-warning-text", text: "You will not be able to undo this action")
        end

        it "shows a button to delete the selected scheme" do
          expect(page).to have_selector("form.button_to button", text: "Delete this scheme")
        end

        it "the delete scheme button submits the correct data to the correct path" do
          form_containing_button = page.find("form.button_to")

          expect(form_containing_button[:action]).to eq scheme_delete_path(scheme)
          expect(form_containing_button).to have_field "_method", type: :hidden, with: "delete"
        end

        it "shows a cancel link with the correct style" do
          expect(page).to have_selector("a.govuk-button--secondary", text: "Cancel")
        end

        it "shows cancel link that links back to the scheme page" do
          expect(page).to have_link(text: "Cancel", href: scheme_path(scheme))
        end
      end
    end
  end

  describe "#delete" do
    let(:scheme) { create(:scheme, service_name: "Scheme to delete", owning_organisation: user.organisation) }
    let!(:locations) { create_list(:location, 2, scheme:, created_at: Time.zone.local(2022, 4, 1)) }

    before do
      delete "/schemes/#{scheme.id}/delete"
    end

    context "when not signed in" do
      it "redirects to the sign in page" do
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in" do
      before do
        Timecop.freeze(Time.utc(2022, 10, 10))
        scheme.scheme_deactivation_periods << create(:scheme_deactivation_period, deactivation_date: Time.zone.local(2022, 10, 9), scheme:)
        scheme.save!
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        delete "/schemes/#{scheme.id}/delete"
      end

      after do
        Timecop.unfreeze
      end

      context "with a data provider user" do
        let(:user) { create(:user) }

        it "returns 401 unauthorized" do
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "with a data coordinator user" do
        let(:user) { create(:user, :data_coordinator) }

        it "returns 401 unauthorized" do
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "with a support user user" do
        let(:user) { create(:user, :support) }

        it "deletes the scheme" do
          scheme.reload
          expect(scheme.status).to eq(:deleted)
          expect(scheme.discarded_at).not_to be nil
        end

        it "deletes associated locations" do
          locations.each do |location|
            location.reload
            expect(location.status).to eq(:deleted)
            expect(location.discarded_at).not_to be nil
          end
        end

        it "redirects to the schemes list and displays a notice that the scheme has been deleted" do
          expect(response).to redirect_to schemes_organisation_path(scheme.owning_organisation)
          follow_redirect!
          expect(page).to have_selector(".govuk-notification-banner--success")
          expect(page).to have_selector(".govuk-notification-banner--success", text: "Scheme to delete has been deleted.")
        end

        it "does not display the deleted scheme" do
          expect(response).to redirect_to schemes_organisation_path(scheme.owning_organisation)
          follow_redirect!
          expect(page).not_to have_link("Scheme to delete")
        end
      end
    end
  end
end
