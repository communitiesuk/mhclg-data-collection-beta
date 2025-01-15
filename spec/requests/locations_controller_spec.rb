require "rails_helper"

RSpec.describe LocationsController, type: :request do
  let(:page) { Capybara::Node::Simple.new(response.body) }
  let(:user) { create(:user, :support) }
  let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
  let(:fake_2021_2022_form) { Form.new("spec/fixtures/forms/2021_2022.json") }

  before do
    Timecop.freeze(Time.zone.local(2024, 3, 1))
    Singleton.__init__(FormHandler)
    allow(FormHandler.instance).to receive(:current_lettings_form).and_return(fake_2021_2022_form)
  end

  after do
    Timecop.return
    Singleton.__init__(FormHandler)
  end

  describe "#create" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        get "/schemes/1/locations/create"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { create(:user) }

      before do
        sign_in user
        get "/schemes/1/locations/create"
      end

      it "returns 404" do
        expect(response).to be_not_found
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { create(:user, :data_coordinator) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }

      before do
        sign_in user
        post scheme_locations_path(scheme)
      end

      it "creates a new location for scheme and redirects to correct page" do
        expect { post scheme_locations_path(scheme) }.to change(Location, :count).by(1)
      end

      it "redirects to the postcode page" do
        follow_redirect!
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("What is the postcode?")
      end

      it "creates a new location for scheme with the right owning organisation" do
        expect(Location.last.scheme.owning_organisation_id).to eq(user.organisation_id)
      end

      context "when trying to add a new location to a scheme that belongs to another organisation" do
        let(:another_scheme) { create(:scheme) }

        it "displays the new page with an error message" do
          post scheme_locations_path(another_scheme)
          expect(response).to be_unauthorized
        end
      end
    end

    context "when signed in as a support user" do
      let(:user) { create(:user, :data_coordinator) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        post scheme_locations_path(scheme)
      end

      it "creates a new location for scheme and redirects to correct page" do
        expect { post scheme_locations_path(scheme) }.to change(Location, :count).by(1)
      end

      it "redirects to the postcode page" do
        follow_redirect!
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("What is the postcode?")
      end

      it "creates a new location for scheme with the right owning organisation" do
        expect(Location.last.scheme.owning_organisation_id).to eq(user.organisation_id)
      end

      context "when trying to add a new location to a scheme that belongs to another organisation" do
        let(:another_scheme) { create(:scheme) }

        it "displays the new page with an error message" do
          post scheme_locations_path(another_scheme)
          expect(response).to be_unauthorized
        end
      end
    end
  end

  describe "#index" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        get "/schemes/#{scheme.id}/locations"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider user" do
      let(:user) { create(:user) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/locations"
      end

      it "returns 200" do
        expect(response).to be_successful
      end

      context "when filtering" do
        context "with status filter" do
          let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
          let!(:incomplete_location) { create(:location, :incomplete, scheme:, startdate: Time.zone.local(2022, 4, 1)) }
          let!(:active_location) { create(:location, scheme:, startdate: Time.zone.local(2022, 4, 1)) }
          let!(:deactivated_location) { create(:location, scheme:, startdate: Time.zone.local(2022, 4, 1)) }

          before do
            Timecop.freeze(Time.zone.local(2023, 11, 10))
            create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 4, 1), location: deactivated_location)
            Timecop.freeze(2023, 3, 3)
          end

          it "shows locations for multiple selected statuses" do
            get "/schemes/#{scheme.id}/locations?status[]=incomplete&status[]=active", headers:, params: {}
            expect(page).to have_link(incomplete_location.postcode)
            expect(page).to have_link(active_location.postcode)
          end

          it "shows filtered incomplete locations" do
            get "/schemes/#{scheme.id}/locations?status[]=incomplete", headers:, params: {}
            expect(page).to have_link(incomplete_location.postcode)
            expect(page).not_to have_link(active_location.postcode)
          end

          it "shows filtered active locations" do
            get "/schemes/#{scheme.id}/locations?status[]=active", headers:, params: {}
            expect(page).to have_link(active_location.postcode)
            expect(page).not_to have_link(incomplete_location.postcode)
          end

          it "shows filtered deactivated locations" do
            get "/schemes/#{scheme.id}/locations?status[]=deactivated", headers:, params: {}
            expect(page).to have_link(deactivated_location.postcode)
            expect(page).not_to have_link(active_location.postcode)
            expect(page).not_to have_link(incomplete_location.postcode)
          end

          it "does not reset the filters" do
            get "/schemes/#{scheme.id}/locations?status[]=incomplete", headers:, params: {}
            expect(page).to have_link(incomplete_location.postcode)
            expect(page).not_to have_link(active_location.postcode)

            get "/schemes/#{scheme.id}/locations", headers:, params: {}
            expect(page).to have_link(incomplete_location.postcode)
            expect(page).not_to have_link(active_location.postcode)
          end
        end
      end
    end

    context "when signed in as a data coordinator user" do
      let(:user) { create(:user, :data_coordinator) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let!(:locations) { create_list(:location, 3, scheme:, startdate: Time.zone.local(2022, 4, 1)) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/locations"
      end

      context "when coordinator attempts to see scheme belonging to a different (and not their parent) organisation" do
        let(:another_scheme) { create(:scheme) }

        before do
          create(:location, scheme:, startdate: Time.zone.local(2022, 4, 1))
        end

        it "returns 401" do
          get "/schemes/#{another_scheme.id}/locations"
          expect(response).to be_unauthorized
        end
      end

      it "shows locations with correct data when the new locations layout feature toggle is enabled" do
        locations.each do |location|
          expect(page).to have_content(location.id)
          expect(page).to have_content(location.postcode)
          expect(page).to have_content(location.name)
          expect(page).to have_content(location.status)
        end
      end

      it "has page heading" do
        expect(page).to have_content(scheme.service_name)
      end

      it "has correct title" do
        expected_title = CGI.unescapeHTML("#{scheme.service_name} - Submit social housing lettings and sales data (CORE) - GOV.UK")
        expect(page).to have_title(expected_title)
      end

      context "when paginating over 20 results" do
        let!(:locations) { create_list(:location, 25, scheme:) }

        context "when on the first page" do
          before do
            get "/schemes/#{scheme.id}/locations"
          end

          it "shows which schemes are being shown on the current page" do
            expect(CGI.unescape_html(response.body)).to match("Showing <b>1</b> to <b>20</b> of <b>#{locations.count}</b> locations")
          end

          it "has correct page 1 of 2 title" do
            expected_title = CGI.unescapeHTML("#{scheme.service_name} (page 1 of 2) - Submit social housing lettings and sales data (CORE) - GOV.UK")
            expect(page).to have_title(expected_title)
          end

          it "has pagination links" do
            expect(page).not_to have_content("Previous")
            expect(page).not_to have_link("Previous")
            expect(page).to have_content("Next")
            expect(page).to have_link("Next")
          end
        end

        context "when on the second page" do
          before do
            get "/schemes/#{scheme.id}/locations?page=2"
          end

          it "shows which schemes are being shown on the current page" do
            expect(CGI.unescape_html(response.body)).to match("Showing <b>21</b> to <b>25</b> of <b>#{locations.count}</b> locations")
          end

          it "has correct page 2 of 2 title" do
            expected_title = CGI.unescapeHTML("#{scheme.service_name} (page 2 of 2) - Submit social housing lettings and sales data (CORE) - GOV.UK")
            expect(page).to have_title(expected_title)
          end

          it "has pagination links" do
            expect(page).to have_content("Previous")
            expect(page).to have_link("Previous")
            expect(page).not_to have_content("Next")
            expect(page).not_to have_link("Next")
          end
        end
      end

      context "when searching" do
        let(:searched_location) { locations.first }
        let(:search_param) { searched_location.name }

        before do
          get "/schemes/#{scheme.id}/locations?search=#{search_param}"
        end

        it "returns matching results" do
          expect(page).to have_content(searched_location.name)
          locations[1..].each do |location|
            expect(page).not_to have_content(location.name)
          end
        end

        it "updates the table caption" do
          expect(page).to have_content("1 location matching search")
        end

        it "has search in the title" do
          expected_title = CGI.unescapeHTML("#{scheme.service_name} (1 location matching ‘#{search_param}’) - Submit social housing lettings and sales data (CORE) - GOV.UK")
          expect(page.title).to eq(expected_title)
        end
      end

      context "when coordinator attempts to see scheme belonging to a parent organisation" do
        let(:parent_organisation) { FactoryBot.create(:organisation) }
        let!(:scheme) { FactoryBot.create(:scheme, owning_organisation: parent_organisation) }
        let!(:locations) { FactoryBot.create_list(:location, 3, scheme:, startdate: Time.zone.local(2022, 4, 1)) }

        before do
          create(:organisation_relationship, parent_organisation:, child_organisation: user.organisation)
          get "/schemes/#{scheme.id}/locations"
        end

        it "shows all the locations" do
          locations.each do |location|
            expect(page).to have_content(location.id)
            expect(page).to have_content(location.postcode)
            expect(page).to have_content(location.name)
            expect(page).to have_content(location.status)
          end
        end

        it "does allow adding new locations" do
          expect(page).to have_button("Add a location")
        end
      end
    end

    context "when signed in as a support user" do
      let(:user) { create(:user, :support) }
      let(:scheme) { create(:scheme) }
      let!(:locations) { create_list(:location, 3, scheme:, startdate: Time.zone.local(2022, 4, 1)) }

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/schemes/#{scheme.id}/locations"
      end

      it "shows locations with correct data when the new locations layout feature toggle is enabled" do
        locations.each do |location|
          expect(page).to have_content(location.id)
          expect(page).to have_content(location.postcode)
          expect(page).to have_content(location.name)
          expect(page).to have_content(location.status)
        end
        expect(page).to have_button("Add a location")
      end

      it "has page heading" do
        expect(page).to have_content(scheme.service_name)
      end

      it "has correct title" do
        expected_title = CGI.unescapeHTML("#{scheme.service_name} - Submit social housing lettings and sales data (CORE) - GOV.UK")
        expect(page).to have_title(expected_title)
      end

      context "when paginating over 20 results" do
        let!(:locations) { create_list(:location, 25, scheme:) }

        context "when on the first page" do
          before do
            get "/schemes/#{scheme.id}/locations"
          end

          it "shows which schemes are being shown on the current page" do
            expect(CGI.unescape_html(response.body)).to match("Showing <b>1</b> to <b>20</b> of <b>#{locations.count}</b> locations")
          end

          it "has correct page 1 of 2 title" do
            expected_title = CGI.unescapeHTML("#{scheme.service_name} (page 1 of 2) - Submit social housing lettings and sales data (CORE) - GOV.UK")
            expect(page).to have_title(expected_title)
          end

          it "has pagination links" do
            expect(page).not_to have_content("Previous")
            expect(page).not_to have_link("Previous")
            expect(page).to have_content("Next")
            expect(page).to have_link("Next")
          end
        end

        context "when on the second page" do
          before do
            get "/schemes/#{scheme.id}/locations?page=2"
          end

          it "shows which schemes are being shown on the current page" do
            expect(CGI.unescape_html(response.body)).to match("Showing <b>21</b> to <b>25</b> of <b>#{locations.count}</b> locations")
          end

          it "has correct page 1 of 2 title" do
            expected_title = CGI.unescapeHTML("#{scheme.service_name} (page 2 of 2) - Submit social housing lettings and sales data (CORE) - GOV.UK")
            expect(page).to have_title(expected_title)
          end

          it "has pagination links" do
            expect(page).to have_content("Previous")
            expect(page).to have_link("Previous")
            expect(page).not_to have_content("Next")
            expect(page).not_to have_link("Next")
          end
        end
      end

      context "when searching" do
        let(:searched_location) { locations.first }
        let(:search_param) { searched_location.name }

        before do
          get "/schemes/#{scheme.id}/locations?search=#{search_param}"
        end

        it "returns matching results" do
          expect(page).to have_content(searched_location.name)
          locations[1..].each do |location|
            expect(page).not_to have_content(location.name)
          end
        end

        it "updates the table caption" do
          expect(page).to have_content("1 location matching search")
        end

        it "has search in the title" do
          expected_title = CGI.unescapeHTML("#{scheme.service_name} (1 location matching ‘#{search_param}’) - Submit social housing lettings and sales data (CORE) - GOV.UK")
          expect(page).to have_title(expected_title)
        end
      end
    end
  end

  describe "#postcode" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        get "/schemes/1/locations/1/postcode"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { create(:user) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/postcode"
      end

      it "returns 401" do
        expect(response).to be_unauthorized
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { create(:user, :data_coordinator) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/postcode"
      end

      it "returns a template for a postcode" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("What is the postcode?")
      end

      context "when postcode is submitted with lower case" do
        let(:params) { { location: { postcode: "zz1 1zz" } } }

        before do
          patch "/schemes/#{scheme.id}/locations/#{location.id}/postcode", params:
        end

        it "adds postcode to location" do
          expect(Location.last.postcode).to eq("ZZ1 1ZZ")
        end

        it "redirects correctly when postcodes.io does return a local authority" do
          follow_redirect!
          expect(page).to have_content("What is the name of this location")
        end
      end

      context "when postcodes.io does not return a local authority" do
        let(:params) { { location: { postcode: "xx1 1xx" } } }

        before do
          patch "/schemes/#{scheme.id}/locations/#{location.id}/postcode", params:
        end

        it "adds postcode to location" do
          expect(Location.last.postcode).to eq("XX11XX")
        end

        it "redirects correctly" do
          follow_redirect!
          expect(page).to have_content("What is the local authority")
        end
      end

      context "when trying to edit postcode of location that belongs to another organisation" do
        let(:another_scheme) { create(:scheme) }
        let(:another_location) { create(:location, scheme: another_scheme) }

        it "displays the new page with an error message" do
          get "/schemes/#{another_scheme.id}/locations/#{another_location.id}/postcode"
          expect(response).to be_unauthorized
        end
      end
    end

    context "when signed in as a support user" do
      let(:user) { create(:user, :support) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/postcode"
      end

      it "returns a template for a postcode" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("What is the postcode?")
      end

      context "when postcode is submitted with lower case" do
        let(:params) { { location: { postcode: "zz1 1zz" } } }

        before do
          patch "/schemes/#{scheme.id}/locations/#{location.id}/postcode", params:
        end

        it "adds postcode to location" do
          expect(Location.last.postcode).to eq("ZZ1 1ZZ")
        end

        it "redirects correctly when postcodes.io does return a local authority" do
          follow_redirect!
          expect(page).to have_content("What is the name of this location")
        end
      end

      context "when postcodes.io does not return a local authority" do
        let(:params) { { location: { postcode: "xx1 1xx" } } }

        before do
          patch "/schemes/#{scheme.id}/locations/#{location.id}/postcode", params:
        end

        it "adds postcode to location" do
          expect(Location.last.postcode).to eq("XX11XX")
        end

        it "redirects correctly" do
          follow_redirect!
          expect(page).to have_content("What is the local authority")
        end
      end

      context "when the requested location does not exist" do
        let(:location) { OpenStruct.new(id: (Location.maximum(:id) || 0) + 1, scheme:) }

        it "returns not found" do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe "#local_authority" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        get "/schemes/1/locations/1/local-authority"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { create(:user) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/local-authority"
      end

      it "returns 401" do
        expect(response).to be_unauthorized
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { create(:user, :data_coordinator) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/local-authority"
      end

      it "returns a template for a local authority" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("What is the local authority")
      end

      context "when local authority is submitted" do
        let(:params) { { location: { location_admin_district: "Adur" } } }

        before do
          patch "/schemes/#{scheme.id}/locations/#{location.id}/local-authority", params:
        end

        it "adds local authority to location " do
          expect(Location.last.location_admin_district).to eq("Adur")
          expect(Location.last.location_code).to eq("E07000223")
        end

        it "redirects correctly" do
          follow_redirect!
          expect(page).to have_content("What is the name of this location?")
        end
      end

      context "when trying to edit local authority of location that belongs to another organisation" do
        let(:another_scheme) { create(:scheme) }
        let(:another_location) { create(:location, scheme: another_scheme) }

        it "displays the new page with an error message" do
          get "/schemes/#{another_scheme.id}/locations/#{another_location.id}/local-authority"
          expect(response).to be_unauthorized
        end
      end
    end

    context "when signed in as a support user" do
      let(:user) { create(:user, :support) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/local-authority"
      end

      it "returns a template for a local authority" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("What is the local authority")
      end

      context "when local authority is submitted" do
        let(:params) { { location: { location_admin_district: "Adur" } } }

        before do
          patch "/schemes/#{scheme.id}/locations/#{location.id}/local-authority", params:
        end

        it "adds local authority to location " do
          expect(Location.last.location_admin_district).to eq("Adur")
          expect(Location.last.location_code).to eq("E07000223")
        end

        it "redirects correctly" do
          follow_redirect!
          expect(page).to have_content("What is the name of this location?")
        end
      end

      context "when the requested location does not exist" do
        let(:location) { OpenStruct.new(id: (Location.maximum(:id) || 0) + 1, scheme:) }

        it "returns not found" do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe "#name" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        get "/schemes/1/locations/1/name"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { create(:user) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/name"
      end

      it "returns 401" do
        expect(response).to be_unauthorized
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { create(:user, :data_coordinator) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/name"
      end

      it "returns a template for a name" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("What is the name of this location?")
      end

      context "when name is submitted" do
        let(:params) { { location: { name: "a name" } } }

        before do
          patch "/schemes/#{scheme.id}/locations/#{location.id}/name", params:
        end

        it "adds name to location" do
          expect(Location.last.name).to eq("a name")
        end

        it "redirects correctly" do
          follow_redirect!
          expect(page).to have_content("How many units are at this location?")
        end
      end

      context "when trying to edit name of location that belongs to another organisation" do
        let(:another_scheme) { create(:scheme) }
        let(:another_location) { create(:location, scheme: another_scheme) }

        it "displays the new page with an error message" do
          get "/schemes/#{another_scheme.id}/locations/#{another_location.id}/name"
          expect(response).to be_unauthorized
        end
      end
    end

    context "when signed in as a support user" do
      let(:user) { create(:user, :support) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/name"
      end

      it "returns a template for a name" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("What is the name of this location?")
      end

      context "when name is submitted" do
        let(:params) { { location: { name: "a name" } } }

        before do
          patch "/schemes/#{scheme.id}/locations/#{location.id}/name", params:
        end

        it "adds name to location" do
          expect(Location.last.name).to eq("a name")
        end

        it "redirects correctly" do
          follow_redirect!
          expect(page).to have_content("How many units are at this location?")
        end
      end

      context "when the requested location does not exist" do
        let(:location) { OpenStruct.new(id: (Location.maximum(:id) || 0) + 1, scheme:) }

        it "returns not found" do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe "#units" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        get "/schemes/1/locations/1/units"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { create(:user) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/units"
      end

      it "returns 401" do
        expect(response).to be_unauthorized
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { create(:user, :data_coordinator) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/units"
      end

      it "returns a template for units" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("How many units are at this location?")
      end

      context "when units is submitted" do
        let(:params) { { location: { units: 6 } } }

        before do
          patch "/schemes/#{scheme.id}/locations/#{location.id}/units", params:
        end

        it "adds units to location" do
          expect(Location.last.units).to eq(6)
        end

        it "redirects correctly" do
          follow_redirect!
          expect(page).to have_content("What is the most common type of unit at this location?")
        end
      end

      context "when trying to edit units of location that belongs to another organisation" do
        let(:another_scheme) { create(:scheme) }
        let(:another_location) { create(:location, scheme: another_scheme) }

        it "displays the new page with an error message" do
          get "/schemes/#{another_scheme.id}/locations/#{another_location.id}/units"
          expect(response).to be_unauthorized
        end
      end
    end

    context "when signed in as a support user" do
      let(:user) { create(:user, :support) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/units"
      end

      it "returns a template for units" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("How many units are at this location?")
      end

      context "when units is submitted" do
        let(:params) { { location: { units: 6 } } }

        before do
          patch "/schemes/#{scheme.id}/locations/#{location.id}/units", params:
        end

        it "adds units to location" do
          expect(Location.last.units).to eq(6)
        end

        it "redirects correctly" do
          follow_redirect!
          expect(page).to have_content("What is the most common type of unit at this location?")
        end
      end

      context "when the requested location does not exist" do
        let(:location) { OpenStruct.new(id: (Location.maximum(:id) || 0) + 1, scheme:) }

        it "returns not found" do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe "#type_of_unit" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        get "/schemes/1/locations/1/type-of-unit"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { create(:user) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/type-of-unit"
      end

      it "returns 401" do
        expect(response).to be_unauthorized
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { create(:user, :data_coordinator) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/type-of-unit"
      end

      it "returns a template for type of unit" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("What is the most common type of unit at this location?")
      end

      context "when type of unit is submitted" do
        let(:params) { { location: { type_of_unit: "Bungalow" } } }

        before do
          patch "/schemes/#{scheme.id}/locations/#{location.id}/type-of-unit", params:
        end

        it "adds type of unit to location" do
          expect(Location.last.type_of_unit).to eq("Bungalow")
        end

        it "redirects correctly" do
          follow_redirect!
          expect(page).to have_content("What are the mobility standards for the majority of units in this location?")
        end
      end

      context "when trying to edit type_of_unit of location that belongs to another organisation" do
        let(:another_scheme) { create(:scheme) }
        let(:another_location) { create(:location, scheme: another_scheme) }

        it "displays the new page with an error message" do
          get "/schemes/#{another_scheme.id}/locations/#{another_location.id}/type-of-unit"
          expect(response).to be_unauthorized
        end
      end
    end

    context "when signed in as a support user" do
      let(:user) { create(:user, :support) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/type-of-unit"
      end

      it "returns a template for type of unit" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("What is the most common type of unit at this location?")
      end

      context "when type of unit is submitted" do
        let(:params) { { location: { type_of_unit: "Bungalow" } } }

        before do
          patch "/schemes/#{scheme.id}/locations/#{location.id}/type-of-unit", params:
        end

        it "adds type of unit to location" do
          expect(Location.last.type_of_unit).to eq("Bungalow")
        end

        it "redirects correctly" do
          follow_redirect!
          expect(page).to have_content("What are the mobility standards for the majority of units in this location?")
        end
      end

      context "when the requested location does not exist" do
        let(:location) { OpenStruct.new(id: (Location.maximum(:id) || 0) + 1, scheme:) }

        it "returns not found" do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe "#mobility_standards" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        get "/schemes/1/locations/1/mobility-standards"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { create(:user) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/mobility-standards"
      end

      it "returns 401" do
        expect(response).to be_unauthorized
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { create(:user, :data_coordinator) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/mobility-standards"
      end

      it "returns a template for mobility standards" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("What are the mobility standards for the majority of units in this location?")
      end

      context "when mobility standards is submitted" do
        let(:params) { { location: { mobility_type: "Wheelchair-user standard" } } }

        before do
          patch "/schemes/#{scheme.id}/locations/#{location.id}/mobility-standards", params:
        end

        it "adds mobility standards to location" do
          expect(Location.last.mobility_type).to eq("Wheelchair-user standard")
        end

        it "redirects correctly" do
          follow_redirect!
          expect(page).to have_content("When did the first property in this location become available under this scheme?")
        end
      end

      context "when trying to edit mobility_standards of location that belongs to another organisation" do
        let(:another_scheme) { create(:scheme) }
        let(:another_location) { create(:location, scheme: another_scheme) }

        it "displays the new page with an error message" do
          get "/schemes/#{another_scheme.id}/locations/#{another_location.id}/mobility-standards"
          expect(response).to be_unauthorized
        end
      end
    end

    context "when signed in as a support user" do
      let(:user) { create(:user, :support) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/mobility-standards"
      end

      it "returns a template for mobility standards" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("What are the mobility standards for the majority of units in this location?")
      end

      context "when mobility standards is submitted" do
        let(:params) { { location: { mobility_type: "Wheelchair-user standard" } } }

        before do
          patch "/schemes/#{scheme.id}/locations/#{location.id}/mobility-standards", params:
        end

        it "adds mobility standards to location" do
          expect(Location.last.mobility_type).to eq("Wheelchair-user standard")
        end

        it "redirects correctly" do
          follow_redirect!
          expect(page).to have_content("When did the first property in this location become available under this scheme?")
        end
      end

      context "when the requested location does not exist" do
        let(:location) { OpenStruct.new(id: (Location.maximum(:id) || 0) + 1, scheme:) }

        it "returns not found" do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe "#startdate" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        get "/schemes/1/locations/1/availability"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { create(:user) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/availability"
      end

      it "returns 401" do
        expect(response).to be_unauthorized
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { create(:user, :data_coordinator) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/availability"
      end

      it "returns a template for a startdate" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("When did the first property in this location become available under this scheme?")
      end

      context "when startdate is submitted" do
        let(:params) { { location: { "startdate": "2/1/2022" } } }

        before do
          patch "/schemes/#{scheme.id}/locations/#{location.id}/availability", params:
        end

        it "adds startdate to location" do
          expect(Location.last.startdate).to eq(Time.zone.local(2022, 1, 2))
        end

        it "redirects correctly" do
          follow_redirect!
          expect(page).to have_content("Check your answers")
        end
      end

      context "when startdate is submitted with leading zeroes" do
        let(:params) { { location: { "startdate": "02/01/2022" } } }

        before do
          patch "/schemes/#{scheme.id}/locations/#{location.id}/availability", params:
        end

        it "adds startdate correctly " do
          expect(Location.last.startdate).to eq(Time.zone.local(2022, 1, 2))
        end

        it "redirects correctly" do
          follow_redirect!
          expect(page).to have_content("Check your answers")
        end
      end

      context "when startdate is missing" do
        let(:params) { { location: { "startdate": "" } } }

        before do
          patch "/schemes/#{scheme.id}/locations/#{location.id}/availability", params:
        end

        it "displays the new page with an error message" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("validations.location.startdate_invalid"))
        end
      end

      context "when trying to edit startdate of location that belongs to another organisation" do
        let(:another_scheme) { create(:scheme) }
        let(:another_location) { create(:location, scheme: another_scheme) }

        it "displays the new page with an error message" do
          get "/schemes/#{another_scheme.id}/locations/#{another_location.id}/availability"
          expect(response).to be_unauthorized
        end
      end
    end

    context "when signed in as a support user" do
      let(:user) { create(:user, :support) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/availability"
      end

      it "returns a template for a startdate" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("When did the first property in this location become available under this scheme?")
      end

      context "when startdate is submitted" do
        let(:params) { { location: { "startdate": "2/1/2022" } } }

        before do
          patch "/schemes/#{scheme.id}/locations/#{location.id}/availability", params:
        end

        it "adds startdate to location" do
          expect(Location.last.startdate).to eq(Time.zone.local(2022, 1, 2))
        end

        it "redirects correctly" do
          follow_redirect!
          expect(page).to have_content("Check your answers")
        end
      end

      context "when startdate is submitted with leading zeroes" do
        let(:params) { { location: { "startdate": "02/01/2022" } } }

        before do
          patch "/schemes/#{scheme.id}/locations/#{location.id}/availability", params:
        end

        it "adds startdate correctly " do
          expect(Location.last.startdate).to eq(Time.zone.local(2022, 1, 2))
        end

        it "redirects correctly" do
          follow_redirect!
          expect(page).to have_content("Check your answers")
        end
      end

      context "when startdate is missing" do
        let(:params) { { location: { "startdate": "" } } }

        before do
          patch "/schemes/#{scheme.id}/locations/#{location.id}/availability", params:
        end

        it "displays the new page with an error message" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("validations.location.startdate_invalid"))
        end
      end

      context "when the requested location does not exist" do
        let(:location) { OpenStruct.new(id: (Location.maximum(:id) || 0) + 1, scheme:) }

        it "returns not found" do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe "#check_answers" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        get "/schemes/1/locations/1/check-answers"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { create(:user) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:, startdate: Time.zone.local(2000, 1, 1)) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/check-answers"
      end

      it "returns 200" do
        expect(response).to be_successful
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { create(:user, :data_coordinator) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:, startdate: Time.zone.local(2000, 1, 1)) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/check-answers"
      end

      it "returns the check answers page" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("Check your answers")
      end

      context "when location is confirmed" do
        let(:params) { { location: { confirmed: true } } }

        before do
          patch "/schemes/#{scheme.id}/locations/#{location.id}/confirm", params:
        end

        context "when location is complete" do
          it "confirms location" do
            expect(Location.last.confirmed).to eq(true)
          end

          it "redirects correctly and displays success banner" do
            follow_redirect!
            expect(page).to have_content("Success")
            expect(page).to have_content("added to this scheme")
          end
        end

        context "when location is not complete" do
          let(:location) { create(:location, scheme:, startdate: Time.zone.local(2000, 1, 1), postcode: nil) }

          it "does not confirm location" do
            expect(Location.last.confirmed).to eq(false)
          end

          it "redirects correctly and does not display success banner" do
            follow_redirect!
            expect(page).not_to have_content("Success")
            expect(page).not_to have_content("added to this scheme")
          end
        end

        context "when local authority is inferred" do
          let(:params) { { location: { postcode: "zz1 1zz" } } }

          before do
            patch "/schemes/#{scheme.id}/locations/#{location.id}/postcode?referrer=check_answers", params:
          end

          it "does not display local authority row" do
            location.reload
            follow_redirect!
            expect(location.is_la_inferred).to eq(true)
            expect(location.location_admin_district).to eq("Westminster")
            expect(page).not_to have_content("Local authority")
            expect(page).to have_content("Westminster")
          end
        end

        context "when local authority is not inferred" do
          let(:params) { { location: { postcode: "a1 1aa" } } }

          before do
            patch "/schemes/#{scheme.id}/locations/#{location.id}/postcode?referrer=check_answers", params:
          end

          it "displays local authority row" do
            location.reload
            get "/schemes/#{scheme.id}/locations/#{location.id}/check-answers"
            expect(location.is_la_inferred).to eq(false)
            expect(page).to have_content("Local authority")
          end
        end
      end

      context "when trying to edit check_answers of location that belongs to another organisation" do
        let(:another_scheme) { create(:scheme) }
        let(:another_location) { create(:location, scheme: another_scheme) }

        it "displays the new page with an error message" do
          get "/schemes/#{another_scheme.id}/locations/#{another_location.id}/check-answers"
          expect(response).to be_unauthorized
        end
      end
    end

    context "when signed in as a support user" do
      let(:user) { create(:user, :support) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:, startdate: Time.zone.local(2000, 1, 1)) }

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/check-answers"
      end

      it "returns the check answers page" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("Check your answers")
      end

      context "with an active location" do
        it "does not render delete this location" do
          expect(location.status).to eq(:active)
          expect(page).not_to have_link("Delete this location", href: "/schemes/#{scheme.id}/locations/#{location.id}/delete-confirmation")
        end
      end

      context "with an incomplete location" do
        it "renders delete this location" do
          location.update!(units: nil)
          get "/schemes/#{scheme.id}/locations/#{location.id}/check-answers"

          expect(location.reload.status).to eq(:incomplete)
          expect(page).to have_link("Delete this location", href: "/schemes/#{scheme.id}/locations/#{location.id}/delete-confirmation")
        end
      end

      context "when location is confirmed" do
        let(:params) { { location: { confirmed: true } } }

        before do
          patch "/schemes/#{scheme.id}/locations/#{location.id}/confirm", params:
        end

        context "when location is complete" do
          it "confirms location" do
            expect(Location.last.confirmed).to eq(true)
          end

          it "redirects correctly and displays success banner" do
            follow_redirect!
            expect(page).to have_content("Success")
            expect(page).to have_content("added to this scheme")
          end
        end

        context "when location is not complete" do
          let(:location) { create(:location, scheme:, startdate: Time.zone.local(2000, 1, 1), postcode: nil) }

          it "does not confirm location" do
            expect(Location.last.confirmed).to eq(false)
          end

          it "redirects correctly and does not display success banner" do
            follow_redirect!
            expect(page).not_to have_content("Success")
            expect(page).not_to have_content("added to this scheme")
          end
        end
      end

      context "when the requested location does not exist" do
        let(:location) { OpenStruct.new(id: (Location.maximum(:id) || 0) + 1, scheme:) }

        it "returns not found" do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe "#deactivate" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        patch "/schemes/1/locations/1/deactivate"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { create(:user) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:, created_at: Time.zone.local(2022, 4, 1)) }

      before do
        sign_in user
        patch "/schemes/#{scheme.id}/locations/#{location.id}/deactivate"
      end

      it "returns 401 unauthorized" do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { create(:user, :data_coordinator) }
      let!(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let!(:location) { create(:location, scheme:, created_at: Time.zone.local(2022, 4, 1)) }
      let(:deactivation_date) { Time.utc(2022, 10, 10) }
      let(:lettings_log) { create(:lettings_log, :sh, location:, scheme:, startdate:, owning_organisation: user.organisation) }
      let(:startdate) { Time.utc(2022, 10, 11) }
      let(:add_deactivations) { nil }
      let(:setup_locations) { nil }

      before do
        allow(FormHandler.instance).to receive(:lettings_in_crossover_period?).and_return(true)
        lettings_log
        Timecop.freeze(Time.utc(2023, 10, 10))
        sign_in user
        add_deactivations
        setup_locations
        location.save!
        patch "/schemes/#{scheme.id}/locations/#{location.id}/new-deactivation", params:
      end

      after do
        Timecop.unfreeze
      end

      context "with default date" do
        let(:params) { { location_deactivation_period: { deactivation_date_type: "default", deactivation_date: } } }

        context "and affected logs" do
          it "redirects to the confirmation page" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("This change will affect 1 logs")
          end
        end

        context "and no affected logs" do
          let(:setup_locations) { location.lettings_logs.update(location: nil) }

          it "redirects to the location page and updates the deactivation period" do
            follow_redirect!
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
            location.reload
            expect(location.location_deactivation_periods.count).to eq(1)
            expect(location.location_deactivation_periods.first.deactivation_date).to eq(Time.zone.local(2022, 4, 1))
          end
        end
      end

      context "with other date" do
        let(:params) { { location_deactivation_period: { deactivation_date_type: "other", "deactivation_date": "10/10/2022" } } }

        context "and affected logs" do
          it "redirects to the confirmation page" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("This change will affect #{location.lettings_logs.count} logs")
          end
        end

        context "and no affected logs" do
          let(:setup_locations) { location.lettings_logs.update(location: nil) }

          it "redirects to the location page and updates the deactivation period" do
            follow_redirect!
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
            location.reload
            expect(location.location_deactivation_periods.count).to eq(1)
            expect(location.location_deactivation_periods.first.deactivation_date).to eq(Time.zone.local(2022, 10, 10))
          end
        end
      end

      context "when confirming deactivation" do
        let(:params) { { deactivation_date:, confirm: true, deactivation_date_type: "other" } }

        let(:user_a) { create(:user) }
        let(:user_b) { create(:user) }

        before do
          allow(LocationOrSchemeDeactivationMailer).to receive(:send_deactivation_mail).and_call_original

          create(:lettings_log, :sh, owning_organisation: scheme.owning_organisation, location:, scheme:, startdate:, assigned_to: user_a)
          create_list(:lettings_log, 3, :sh, owning_organisation: scheme.owning_organisation, location:, scheme:, startdate:, assigned_to: user_b)

          Timecop.freeze(Time.utc(2022, 10, 10))
          sign_in user
        end

        after do
          Timecop.unfreeze
        end

        context "and a log startdate is after location deactivation date" do
          before do
            patch "/schemes/#{scheme.id}/locations/#{location.id}/deactivate", params:
          end

          it "updates existing location with valid deactivation date and renders location page" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
            location.reload
            expect(location.location_deactivation_periods.count).to eq(1)
            expect(location.location_deactivation_periods.first.deactivation_date).to eq(deactivation_date)
          end

          it "clears the location and scheme answers" do
            expect(lettings_log.location).to eq(location)
            expect(lettings_log.scheme).to eq(scheme)
            lettings_log.reload
            expect(lettings_log.location).to eq(nil)
            expect(lettings_log.scheme).to eq(nil)
          end

          it "marks log as needing attention" do
            expect(lettings_log.unresolved).to eq(nil)
            lettings_log.reload
            expect(lettings_log.unresolved).to eq(true)
          end

          it "sends deactivation emails" do
            expect(LocationOrSchemeDeactivationMailer).to have_received(:send_deactivation_mail).with(
              user_a,
              1,
              update_logs_lettings_logs_url,
              location.scheme.service_name,
              location.postcode,
            )

            expect(LocationOrSchemeDeactivationMailer).to have_received(:send_deactivation_mail).with(
              user_b,
              3,
              update_logs_lettings_logs_url,
              location.scheme.service_name,
              location.postcode,
            )
          end
        end

        context "and the users need to be notified" do
          it "sends E-mails to the creators of affected logs with counts" do
            expect {
              patch "/schemes/#{scheme.id}/locations/#{location.id}/deactivate", params:
            }.to enqueue_job(ActionMailer::MailDeliveryJob).at_least(2).times
          end
        end

        context "and a log startdate is before location deactivation date" do
          let(:startdate) { Time.utc(2022, 10, 9) }

          it "does not update the log" do
            expect(lettings_log.location).to eq(location)
            expect(lettings_log.scheme).to eq(scheme)
            lettings_log.reload
            expect(lettings_log.location).to eq(location)
            expect(lettings_log.scheme).to eq(scheme)
          end

          it "does not mark log as needing attention" do
            expect(lettings_log.unresolved).to eq(nil)
            lettings_log.reload
            expect(lettings_log.unresolved).to eq(nil)
          end
        end

        context "and there already is a deactivation period" do
          let(:add_deactivations) { create(:location_deactivation_period, deactivation_date: Time.zone.local(2023, 6, 5), reactivation_date: nil, location:) }

          before do
            patch "/schemes/#{scheme.id}/locations/#{location.id}/deactivate", params:
          end

          it "updates existing location with valid deactivation date and renders location page" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
            location.reload
            expect(location.location_deactivation_periods.count).to eq(1)
            expect(location.location_deactivation_periods.first.deactivation_date).to eq(deactivation_date)
          end

          it "clears the location and scheme answers" do
            expect(lettings_log.location).to eq(location)
            expect(lettings_log.scheme).to eq(scheme)
            lettings_log.reload
            expect(lettings_log.location).to eq(nil)
            expect(lettings_log.scheme).to eq(nil)
          end

          it "marks log as needing attention" do
            expect(lettings_log.unresolved).to eq(nil)
            lettings_log.reload
            expect(lettings_log.unresolved).to eq(true)
          end
        end
      end

      context "when the date is not selected" do
        let(:params) { { location_deactivation_period: { "deactivation_date": "" } } }

        it "displays the new page with an error message" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("validations.location.toggle_date.not_selected"))
        end
      end

      context "when invalid date is entered" do
        let(:params) { { location_deactivation_period: { deactivation_date_type: "other", "deactivation_date": "10/44/2022" } } }

        it "displays the new page with an error message" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("validations.location.toggle_date.invalid"))
        end
      end

      context "when the date entered is before the beginning of current collection window" do
        let(:params) { { location_deactivation_period: { deactivation_date_type: "other", "deactivation_date": "10/4/2020" } } }

        it "displays the new page with an error message" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("validations.location.toggle_date.out_of_range", date: "1 April 2022"))
        end
      end

      context "when the day is not entered" do
        let(:params) { { location_deactivation_period: { deactivation_date_type: "other", "deactivation_date": "/2/2022" } } }

        it "displays page with an error message" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("validations.location.toggle_date.invalid"))
        end
      end

      context "when the month is not entered" do
        let(:params) { { location_deactivation_period: { deactivation_date_type: "other", "deactivation_date": "2//2022" } } }

        it "displays page with an error message" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("validations.location.toggle_date.invalid"))
        end
      end

      context "when the year is not entered" do
        let(:params) { { location_deactivation_period: { deactivation_date_type: "other", "deactivation_date": "2/2/" } } }

        it "displays page with an error message" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("validations.location.toggle_date.invalid"))
        end
      end

      context "when deactivation date is during a deactivated period" do
        let(:deactivation_date) { Time.zone.local(2022, 10, 10) }
        let(:params) { { location_deactivation_period: { deactivation_date_type: "other", "deactivation_date": "8/9/2022" } } }
        let(:add_deactivations) { create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 5, 5), reactivation_date: Time.zone.local(2022, 10, 12), location:) }

        it "displays page with an error message" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("validations.location.deactivation.during_deactivated_period"))
        end
      end

      context "when there is an earlier open deactivation" do
        let(:deactivation_date) { Time.zone.local(2023, 10, 10) }
        let(:params) { { location_deactivation_period: { deactivation_date_type: "other", "deactivation_date": "8/9/2024" } } }
        let(:add_deactivations) { create(:location_deactivation_period, deactivation_date: Time.zone.local(2024, 6, 5), reactivation_date: nil, location:) }

        it "redirects to the location page and updates the existing deactivation period" do
          follow_redirect!
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
          location.reload
          expect(location.location_deactivation_periods.count).to eq(1)
          expect(location.location_deactivation_periods.first.deactivation_date).to eq(Time.zone.local(2024, 9, 8))
        end
      end

      context "when there is a later open deactivation" do
        let(:params) { { location_deactivation_period: { deactivation_date_type: "other", "deactivation_date": "8/9/2022" } } }
        let(:add_deactivations) { create(:location_deactivation_period, deactivation_date: Time.zone.local(2024, 6, 5), reactivation_date: nil, location:) }

        it "redirects to the confirmation page" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("This change will affect 1 logs")
        end
      end
    end
  end

  describe "#show" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        get "/schemes/1/locations/1"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { create(:user) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}"
      end

      it "returns 200" do
        expect(response).to be_successful
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { create(:user, :data_coordinator) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }
      let(:add_deactivations) { location.location_deactivation_periods << location_deactivation_period }

      before do
        Timecop.freeze(Time.utc(2022, 10, 10))
        sign_in user
        add_deactivations
        location.save!
        get "/schemes/#{scheme.id}/locations/#{location.id}"
      end

      after do
        Timecop.unfreeze
      end

      context "with active location" do
        let(:add_deactivations) {}

        it "renders deactivate this location" do
          expect(response).to have_http_status(:ok)
          expect(page).to have_link("Deactivate this location", href: "/schemes/#{scheme.id}/locations/#{location.id}/new-deactivation")
        end
      end

      context "with deactivated location" do
        let(:location_deactivation_period) { create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 10, 9), location:) }

        it "renders reactivate this location" do
          expect(response).to have_http_status(:ok)
          expect(page).to have_link("Reactivate this location", href: "/schemes/#{scheme.id}/locations/#{location.id}/new-reactivation")
        end

        it "does not render delete this location" do
          expect(response).to have_http_status(:ok)
          expect(page).not_to have_link("Delete this location", href: "/schemes/#{scheme.id}/locations/#{location.id}/delete-confirmation")
        end
      end

      context "with location that's deactivating soon" do
        let(:location_deactivation_period) { create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 10, 12), location:) }

        it "does not render toggle location link" do
          expect(response).to have_http_status(:ok)
          expect(page).not_to have_link("Reactivate this location")
          expect(page).not_to have_link("Deactivate this location")
          expect(page).to have_content("Deactivating soon")
        end
      end

      context "with location that's deactivating in more than 6 months" do
        let(:location_deactivation_period) { create(:location_deactivation_period, deactivation_date: Time.zone.local(2023, 6, 12), location:) }

        it "does render toggle location link" do
          expect(response).to have_http_status(:ok)
          expect(page).not_to have_link("Reactivate this location")
          expect(page).to have_link("Deactivate this location")
          expect(response.body).not_to include("<strong class=\"govuk-tag govuk-tag--yellow\">Deactivating soon</strong>")
          expect(response.body).to include("<strong class=\"govuk-tag govuk-tag--green\">Active</strong>")
        end
      end

      context "with location that's reactivating soon" do
        let(:location_deactivation_period) { create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 4, 12), reactivation_date: Time.zone.local(2022, 10, 12), location:) }

        it "does not render toggle location link" do
          expect(response).to have_http_status(:ok)
          expect(page).not_to have_link("Reactivate this location")
          expect(page).not_to have_link("Deactivate this location")
        end
      end

      context "and are viewing their parent organisation's location" do
        let(:parent_organisation) { FactoryBot.create(:organisation) }
        let!(:scheme) { FactoryBot.create(:scheme, owning_organisation: parent_organisation) }
        let!(:location) { FactoryBot.create(:location, scheme:) }
        let(:add_deactivations) {}

        before do
          create(:organisation_relationship, parent_organisation:, child_organisation: user.organisation)
        end

        it "shows the location" do
          get "/schemes/#{scheme.id}/locations/#{location.id}"

          expect(page).to have_content("Location name")
          expect(page).to have_content(location.name)
        end

        it "does not allow editing the location" do
          expect(page).not_to have_link("Change")
          expect(page).not_to have_link("Deactivate this location", href: "/schemes/#{scheme.id}/locations/#{location.id}/new-deactivation")
        end
      end
    end

    context "when signed in as a support user" do
      let(:user) { create(:user, :support) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }
      let(:add_deactivations) { location.location_deactivation_periods << location_deactivation_period }

      before do
        Timecop.freeze(Time.utc(2022, 10, 10))
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        add_deactivations
        location.save!
        get "/schemes/#{scheme.id}/locations/#{location.id}"
      end

      after do
        Timecop.unfreeze
      end

      context "with active location" do
        let(:add_deactivations) {}

        it "does not render delete this location" do
          expect(response).to have_http_status(:ok)
          expect(page).not_to have_link("Delete this location", href: "/schemes/#{scheme.id}/locations/#{location.id}/delete-confirmation")
        end

        it "does not render informative text about deleting the location" do
          expect(response).to have_http_status(:ok)
          expect(page).not_to have_content("This location was active in an open or editable collection year, and cannot be deleted.")
        end
      end

      context "with deactivated location" do
        let(:location_deactivation_period) { create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 10, 9), location:) }

        it "renders delete this location" do
          expect(response).to have_http_status(:ok)
          expect(page).to have_link("Delete this location", href: "/schemes/#{scheme.id}/locations/#{location.id}/delete-confirmation")
        end

        context "and associated logs in editable collection period" do
          before do
            create(:lettings_log, :sh, location:, scheme:, startdate: Time.zone.local(2022, 9, 9), owning_organisation: user.organisation)
            get "/schemes/#{scheme.id}/locations/#{location.id}"
          end

          it "does not render delete this location" do
            expect(response).to have_http_status(:ok)
            expect(page).not_to have_link("Delete this location", href: "/schemes/#{scheme.id}/locations/#{location.id}/delete-confirmation")
          end

          it "adds informative text about deleting the location" do
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("This location was active in an open or editable collection year, and cannot be deleted.")
          end
        end
      end

      context "with incomplete location" do
        let(:add_deactivations) {}

        before do
          location.update!(units: nil)
          get "/schemes/#{scheme.id}/locations/#{location.id}"
        end

        it "renders delete this location" do
          expect(location.reload.status).to eq(:incomplete)
          expect(response).to have_http_status(:ok)
          expect(page).to have_link("Delete this location", href: "/schemes/#{scheme.id}/locations/#{location.id}/delete-confirmation")
        end
      end

      context "with location that's deactivating soon" do
        let(:location_deactivation_period) { create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 10, 12), location:) }

        it "does not render delete this location" do
          expect(response).to have_http_status(:ok)
          expect(page).not_to have_link("Delete this location", href: "/schemes/#{scheme.id}/locations/#{location.id}/delete-confirmation")
        end
      end

      context "with location that's deactivating in more than 6 months" do
        let(:location_deactivation_period) { create(:location_deactivation_period, deactivation_date: Time.zone.local(2023, 6, 12), location:) }

        it "does not render delete this location" do
          expect(response).to have_http_status(:ok)
          expect(page).not_to have_link("Delete this location", href: "/schemes/#{scheme.id}/locations/#{location.id}/delete-confirmation")
        end
      end

      context "with location that's reactivating soon" do
        let(:location_deactivation_period) { create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 4, 12), reactivation_date: Time.zone.local(2022, 10, 12), location:) }

        it "does not render delete this location" do
          expect(response).to have_http_status(:ok)
          expect(page).not_to have_link("Delete this location", href: "/schemes/#{scheme.id}/locations/#{location.id}/delete-confirmation")
        end
      end
    end
  end

  describe "#reactivate" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        patch "/schemes/1/locations/1/reactivate"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { create(:user) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }

      before do
        sign_in user
        patch "/schemes/#{scheme.id}/locations/#{location.id}/reactivate"
      end

      it "returns 401 unauthorized" do
        expect(response).to be_unauthorized
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { create(:user, :data_coordinator) }
      let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
      let(:location) { create(:location, scheme:) }
      let(:deactivation_date) { Time.zone.local(2022, 4, 1) }
      let(:startdate) { Time.utc(2022, 9, 11) }

      before do
        Timecop.freeze(Time.utc(2023, 9, 10))
        sign_in user
        create(:location_deactivation_period, deactivation_date:, location:)
        location.save!
        patch "/schemes/#{scheme.id}/locations/#{location.id}/reactivate", params:
      end

      after do
        Timecop.unfreeze
      end

      context "with default date" do
        let(:params) { { location_deactivation_period: { reactivation_date_type: "default" } } }

        it "redirects to the location page and displays a success banner" do
          expect(response).to redirect_to("/schemes/#{scheme.id}/locations/#{location.id}")
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
          expect(page).to have_content("#{location.name} has been reactivated")
        end

        it "updates existing location deactivations with valid reactivation date" do
          follow_redirect!
          location.reload
          expect(location.location_deactivation_periods.count).to eq(1)
          expect(location.location_deactivation_periods.first.reactivation_date).to eq(Time.zone.local(2022, 4, 1))
        end
      end

      context "with other date" do
        let(:params) { { location_deactivation_period: { reactivation_date_type: "other", "reactivation_date": "10/9/2022" } } }

        it "redirects to the location page and displays a success banner" do
          expect(response).to redirect_to("/schemes/#{scheme.id}/locations/#{location.id}")
          follow_redirect!
          expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
          expect(page).to have_content("#{location.name} has been reactivated")
        end

        it "updates existing location deactivations with valid reactivation date" do
          follow_redirect!
          location.reload
          expect(location.location_deactivation_periods.count).to eq(1)
          expect(location.location_deactivation_periods.first.reactivation_date).to eq(Time.zone.local(2022, 9, 10))
        end
      end

      context "with other future date" do
        let(:params) { { location_deactivation_period: { reactivation_date_type: "other", "reactivation_date": "14/12/2023" } } }

        it "redirects to the location page and displays a success banner" do
          expect(response).to redirect_to("/schemes/#{scheme.id}/locations/#{location.id}")
          follow_redirect!
          expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
          expect(page).to have_content("#{location.name} will reactivate on 14 December 2023")
        end
      end

      context "when the date is not selected" do
        let(:params) { { location_deactivation_period: { "reactivation_date": "" } } }

        it "displays the new page with an error message" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("validations.location.toggle_date.not_selected"))
        end
      end

      context "when invalid date is entered" do
        let(:params) { { location_deactivation_period: { reactivation_date_type: "other", "reactivation_date": "10/44/2022" } } }

        it "displays the new page with an error message" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("validations.location.toggle_date.invalid"))
        end
      end

      context "when the date is entered is before the beginning of current collection window" do
        let(:params) { { location_deactivation_period: { reactivation_date_type: "other", "reactivation_date": "10/4/2020" } } }

        it "displays the new page with an error message" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("validations.location.toggle_date.out_of_range", date: "1 April 2022"))
        end
      end

      context "when the day is not entered" do
        let(:params) { { location_deactivation_period: { reactivation_date_type: "other", "reactivation_date": "/2/2022" } } }

        it "displays page with an error message" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("validations.location.toggle_date.invalid"))
        end
      end

      context "when the month is not entered" do
        let(:params) { { location_deactivation_period: { reactivation_date_type: "other", "reactivation_date": "2//2022" } } }

        it "displays page with an error message" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("validations.location.toggle_date.invalid"))
        end
      end

      context "when the year is not entered" do
        let(:params) { { location_deactivation_period: { reactivation_date_type: "other", "reactivation_date": "2/2/" } } }

        it "displays page with an error message" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("validations.location.toggle_date.invalid"))
        end
      end

      context "when the reactivation date is before deactivation date" do
        let(:deactivation_date) { Time.zone.local(2022, 10, 10) }
        let(:params) { { location_deactivation_period: { reactivation_date_type: "other", "reactivation_date": "8/9/2022" } } }

        it "displays page with an error message" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("validations.location.reactivation.before_deactivation", date: "10 October 2022"))
        end
      end
    end
  end

  describe "#delete-confirmation" do
    let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
    let(:location) { create(:location, scheme:, created_at: Time.zone.local(2022, 4, 1)) }

    before do
      get "/schemes/#{scheme.id}/locations/#{location.id}/delete-confirmation"
    end

    context "when not signed in" do
      it "redirects to the sign in page" do
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in" do
      before do
        Timecop.freeze(Time.utc(2022, 10, 10))
        location.location_deactivation_periods << create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 10, 9), location:)
        location.save!
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/delete-confirmation"
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

        it "shows the correct title" do
          expect(page.find("h1").text).to include "Are you sure you want to delete this location?"
        end

        it "shows a warning to the user" do
          expect(page).to have_selector(".govuk-warning-text", text: "You will not be able to undo this action")
        end

        it "shows a button to delete the selected location" do
          expect(page).to have_selector("form.button_to button", text: "Delete this location")
        end

        it "the delete location button submits the correct data to the correct path" do
          form_containing_button = page.find("form.button_to")

          expect(form_containing_button[:action]).to eq scheme_location_delete_path(scheme, location)
          expect(form_containing_button).to have_field "_method", type: :hidden, with: "delete"
        end

        it "shows a cancel link with the correct style" do
          expect(page).to have_selector("a.govuk-button--secondary", text: "Cancel")
        end

        it "shows cancel link that links back to the location page" do
          expect(page).to have_link(text: "Cancel", href: scheme_location_path(scheme, location))
        end
      end
    end
  end

  describe "#delete" do
    let(:scheme) { create(:scheme, owning_organisation: user.organisation) }
    let(:location) { create(:location, scheme:, name: "Location to delete", created_at: Time.zone.local(2022, 4, 1)) }

    before do
      Timecop.freeze(Time.utc(2022, 10, 10))
      location.location_deactivation_periods << create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 10, 9), location:)
      location.save!
      delete "/schemes/#{scheme.id}/locations/#{location.id}/delete"
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
        delete "/schemes/#{scheme.id}/locations/#{location.id}/delete"
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

        it "deletes the location" do
          location.reload
          expect(location.status).to eq(:deleted)
          expect(location.discarded_at).not_to be nil
        end

        it "redirects to the scheme locations list and displays a notice that the location has been deleted" do
          expect(response).to redirect_to scheme_locations_path(scheme)
          follow_redirect!
          expect(page).to have_selector(".govuk-notification-banner--success")
          expect(page).to have_selector(".govuk-notification-banner--success", text: "has been deleted.")
        end

        it "does not display the deleted location" do
          expect(response).to redirect_to scheme_locations_path(scheme)
          follow_redirect!
          expect(page).not_to have_content("Location to delete")
        end
      end
    end
  end
end
