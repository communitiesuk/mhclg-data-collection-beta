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

      context "when parent organisation has schemes" do
        let(:parent_organisation) { FactoryBot.create(:organisation) }
        let!(:parent_schemes) { FactoryBot.create_list(:scheme, 5, owning_organisation: parent_organisation) }

        before do
          create(:organisation_relationship, parent_organisation:, child_organisation: user.organisation)
          parent_schemes.each do |scheme|
            FactoryBot.create(:location, scheme:)
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

      it "shows incomplete schemes at the top" do
        schemes[0].update!(confirmed: nil)
        schemes[2].update!(confirmed: false)
        schemes[4].update!(confirmed: false)
        get "/schemes"

        expect(page.all(".govuk-tag")[1].text).to eq("Incomplete")
        expect(page.all(".govuk-tag")[2].text).to eq("Incomplete")
        expect(page.all(".govuk-tag")[3].text).to eq("Incomplete")
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

        context "when on the second page" do
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
          expect(page).to have_content("1 scheme found matching ‘#{search_param}’")
        end

        it "has search in the title" do
          expect(page).to have_title("Supported housing schemes (1 scheme matching ‘#{search_param}’) - Submit social housing lettings and sales data (CORE) - GOV.UK")
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

      context "when coordinator attempts to see scheme belonging to a different organisation" do
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
        let(:user) { create(:user, :data_coordinator) }
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
        end

        context "with scheme that's deactivating soon" do
          let(:scheme_deactivation_period) { create(:scheme_deactivation_period, deactivation_date: Time.zone.local(2022, 10, 12), scheme:) }

          it "does not render toggle scheme link" do
            expect(response).to have_http_status(:ok)
            expect(page).not_to have_link("Reactivate this scheme")
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
        let(:parent_organisation) { FactoryBot.create(:organisation) }
        let!(:specific_scheme) { FactoryBot.create(:scheme, owning_organisation: parent_organisation) }

        before do
          FactoryBot.create(:location, scheme: specific_scheme)
          create(:organisation_relationship, parent_organisation:, child_organisation: user.organisation)
          get "/schemes/#{specific_scheme.id}"
        end

        it "shows the scheme" do
          expect(page).to have_content(specific_scheme.id_to_display)
        end

        it "does not allow editing the scheme" do
          expect(page).not_to have_link("Change")
          expect(page).not_to have_content("Reactivate this scheme")
          expect(page).not_to have_content("Deactivate this scheme")
        end
      end

      context "when the scheme has all details but no confirmed locations" do
        it "shows the scheme as incomplete with text to explain" do
          get scheme_path(specific_scheme)
          expect(page).to have_content "Incomplete"
          expect(page).to have_content "Add a location to complete this scheme"
        end
      end

      context "when the scheme has all details and confirmed locations" do
        it "shows the scheme as complete" do
          create(:location, scheme: specific_scheme)
          get scheme_path(specific_scheme)
          expect(page).to have_content "Active"
          expect(page).not_to have_content "Add a location to complete this scheme"
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
      let(:params) do
        { scheme: { service_name: "  testy ",
                    sensitive: "1",
                    scheme_type: "Foyer",
                    registered_under_care_act: "No",
                    arrangement_type: "D" } }
      end

      before do
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
          expect(response).to have_http_status(:unprocessable_entity)
          expect(page).to have_content("Create a new supported housing scheme")
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.scheme_type.invalid"))
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.registered_under_care_act.invalid"))
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.arrangement_type.invalid"))
          expect(page).to have_content(I18n.t("activerecord.errors.models.scheme.attributes.service_name.invalid"))
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
          expect(response).to have_http_status(:unprocessable_entity)
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
          expect(response).to have_http_status(:unprocessable_entity)
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
          expect(response).to have_http_status(:unprocessable_entity)
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
          expect(response).to have_http_status(:unprocessable_entity)
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

        context "when updating from check answers page with the answer YES" do
          let(:params) { { scheme: { has_other_client_group: "Yes", page: "confirm-secondary", check_answers: "true" } } }

          it "renders check answers page after successful update" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("What is the other client group?")
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
          expect(response).to have_http_status(:unprocessable_entity)
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
          expect(response).to have_http_status(:unprocessable_entity)
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

        context "when updating from check answers page with the answer YES" do
          let(:params) { { scheme: { has_other_client_group: "Yes", page: "confirm-secondary", check_answers: "true" } } }

          it "renders check answers page after successful update" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("What is the other client group?")
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

        it "redirects to a view scheme page" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(path).to match("/schemes/#{scheme.id}")
          expect(page).to have_content(scheme.service_name)
          assert_select "a", text: /Change/, count: 3
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

        it "redirects to a view scheme page" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(path).to match("/schemes/#{scheme.id}")
          expect(page).to have_content(scheme.service_name)
          assert_select "a", text: /Change/, count: 3
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

        it "redirects to a view scheme page" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(path).to match("/schemes/#{scheme.id}")
          expect(page).to have_content(scheme.service_name)
          assert_select "a", text: /Change/, count: 3
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
      let(:scheme) { create(:scheme, owning_organisation: user.organisation, confirmed: nil) }
      let(:another_scheme) { create(:scheme, confirmed: nil) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/support"
      end

      it "returns a template for a support" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("What support does this scheme provide?")
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
          assert_select "a", text: /Change/, count: 2
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
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/schemes/#{scheme.id}/check-answers"
      end

      it "returns a template for a support" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("Check your changes before creating this scheme")
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
          assert_select "a", text: /Change/, count: 2
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
        expect(page).not_to have_content("Which organisation owns the housing stock for this scheme?")
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
      let!(:scheme) { create(:scheme, owning_organisation: user.organisation, created_at: Time.zone.today) }
      let!(:location) { create(:location, scheme:) }
      let(:deactivation_date) { Time.utc(2022, 10, 10) }
      let(:lettings_log) { create(:lettings_log, :sh, location:, scheme:, startdate:, owning_organisation: user.organisation, created_by: user) }
      let(:startdate) { Time.utc(2022, 10, 11) }
      let(:setup_schemes) { nil }

      before do
        allow(FormHandler.instance).to receive(:lettings_in_crossover_period?).and_return(true)
        lettings_log
        Timecop.freeze(Time.utc(2023, 10, 10))
        sign_in user
        setup_schemes
        patch "/schemes/#{scheme.id}/new-deactivation", params:
      end

      after do
        Timecop.unfreeze
      end

      context "with default date" do
        let(:params) { { scheme_deactivation_period: { deactivation_date_type: "default", deactivation_date: } } }

        context "and affected logs" do
          it "redirects to the confirmation page" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("This change will affect #{scheme.lettings_logs.count} logs")
          end
        end

        context "and no affected logs" do
          let(:setup_schemes) { scheme.lettings_logs.update(scheme: nil) }

          it "redirects to the location page and updates the deactivation period" do
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
        let(:params) { { scheme_deactivation_period: { deactivation_date_type: "other", "deactivation_date(3i)": "10", "deactivation_date(2i)": "10", "deactivation_date(1i)": "2022" } } }

        context "and affected logs" do
          it "redirects to the confirmation page" do
            follow_redirect!
            expect(response).to have_http_status(:ok)
            expect(page).to have_content("This change will affect #{scheme.lettings_logs.count} logs")
          end
        end

        context "and no affected logs" do
          let(:setup_schemes) { scheme.lettings_logs.update(scheme: nil) }

          it "redirects to the location page and updates the deactivation period" do
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
          expect(response).to have_http_status(:unprocessable_entity)
          expect(page).to have_content(I18n.t("validations.scheme.toggle_date.not_selected"))
        end
      end

      context "when invalid date is entered" do
        let(:params) { { scheme_deactivation_period: { deactivation_date_type: "other", "deactivation_date(3i)": "10", "deactivation_date(2i)": "44", "deactivation_date(1i)": "2022" } } }

        it "displays the new page with an error message" do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(page).to have_content(I18n.t("validations.scheme.toggle_date.invalid"))
        end
      end

      context "when the date is entered is before the beginning of current collection window" do
        let(:params) { { scheme_deactivation_period: { deactivation_date_type: "other", "deactivation_date(3i)": "10", "deactivation_date(2i)": "4", "deactivation_date(1i)": "2020" } } }

        it "displays the new page with an error message" do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(page).to have_content(I18n.t("validations.scheme.toggle_date.out_of_range", date: "1 April 2022"))
        end
      end

      context "when the day is not entered" do
        let(:params) { { scheme_deactivation_period: { deactivation_date_type: "other", "deactivation_date(3i)": "", "deactivation_date(2i)": "2", "deactivation_date(1i)": "2022" } } }

        it "displays page with an error message" do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(page).to have_content(I18n.t("validations.scheme.toggle_date.invalid"))
        end
      end

      context "when the month is not entered" do
        let(:params) { { scheme_deactivation_period: { deactivation_date_type: "other", "deactivation_date(3i)": "2", "deactivation_date(2i)": "", "deactivation_date(1i)": "2022" } } }

        it "displays page with an error message" do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(page).to have_content(I18n.t("validations.scheme.toggle_date.invalid"))
        end
      end

      context "when the year is not entered" do
        let(:params) { { scheme_deactivation_period: { deactivation_date_type: "other", "deactivation_date(3i)": "2", "deactivation_date(2i)": "2", "deactivation_date(1i)": "" } } }

        it "displays page with an error message" do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(page).to have_content(I18n.t("validations.scheme.toggle_date.invalid"))
        end
      end

      context "when there is an earlier open deactivation" do
        let(:deactivation_date) { Time.zone.local(2022, 10, 10) }
        let(:params) { { scheme_deactivation_period: { deactivation_date_type: "other", "deactivation_date(3i)": "8", "deactivation_date(2i)": "9", "deactivation_date(1i)": "2023" } } }
        let(:add_deactivations) { create(:scheme_deactivation_period, deactivation_date: Time.zone.local(2023, 6, 5), reactivation_date: nil, scheme:) }

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
        let(:params) { { scheme_deactivation_period: { deactivation_date_type: "other", "deactivation_date(3i)": "8", "deactivation_date(2i)": "9", "deactivation_date(1i)": "2022" } } }
        let(:add_deactivations) { create(:scheme_deactivation_period, deactivation_date: Time.zone.local(2023, 6, 5), reactivation_date: nil, scheme:) }

        it "redirects to the confirmation page" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("This change will affect 1 logs")
        end
      end
    end
  end
end
