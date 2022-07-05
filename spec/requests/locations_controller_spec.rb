require "rails_helper"

RSpec.describe LocationsController, type: :request do
  let(:page) { Capybara::Node::Simple.new(response.body) }
  let(:user) { FactoryBot.create(:user, :support) }
  let!(:scheme) { FactoryBot.create(:scheme, organisation: user.organisation) }

  describe "#new" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        get "/schemes/1/locations/new"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { FactoryBot.create(:user) }

      before do
        sign_in user
        get "/schemes/1/locations/new"
      end

      it "returns 401 unauthorized" do
        request
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { FactoryBot.create(:user, :data_coordinator) }
      let!(:scheme) { FactoryBot.create(:scheme, organisation: user.organisation) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/locations/new"
      end

      it "returns a template for a new location" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("Add a location to this scheme")
      end

      context "when trying to new location to a scheme that belongs to another organisation" do
        let(:another_scheme)  { FactoryBot.create(:scheme) }

        it "displays the new page with an error message" do
          get "/schemes/#{another_scheme.id}/locations/new"
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "when signed in as a support user" do
      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/schemes/#{scheme.id}/locations/new"
      end

      it "returns a template for a new location" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("Add a location to this scheme")
      end
    end
  end

  describe "#create" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        post "/schemes/1/locations"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { FactoryBot.create(:user) }

      before do
        sign_in user
        post "/schemes/1/locations"
      end

      it "returns 401 unauthorized" do
        request
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { FactoryBot.create(:user, :data_coordinator) }
      let!(:scheme) { FactoryBot.create(:scheme, organisation: user.organisation) }
      let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", add_another_location: "No", postcode: "ZZ1 1ZZ" } } }

      before do
        sign_in user
        post "/schemes/#{scheme.id}/locations", params: params
      end

      it "creates a new location for scheme with valid params and redirects to correct page" do
        expect { post "/schemes/#{scheme.id}/locations", params: }.to change(Location, :count).by(1)
        follow_redirect!
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("Check your answers before creating this scheme")
      end

      it "creates a new location for scheme with valid params" do
        expect(Location.last.scheme.organisation_id).to eq(user.organisation_id)
        expect(Location.last.name).to eq("Test")
        expect(Location.last.postcode).to eq("ZZ11ZZ")
        expect(Location.last.total_units).to eq(5)
        expect(Location.last.type_of_unit).to eq("Bungalow")
        expect(Location.last.wheelchair_adaptation).to eq("No")
      end

      context "when postcode is submitted with lower case" do
        let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", add_another_location: "No", postcode: "zz1 1zz" } } }

        it "creates a new location for scheme with postcode " do
          expect(Location.last.postcode).to eq("ZZ11ZZ")
        end
      end

      context "when trying to add location to a scheme that belongs to another organisation" do
        let(:another_scheme)  { FactoryBot.create(:scheme) }
        let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", add_another_location: "No", postcode: "ZZ1 1ZZ" } } }

        it "displays the new page with an error message" do
          post "/schemes/#{another_scheme.id}/locations", params: params
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when required postcode param is missing" do
        let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", add_another_location: "No" } } }

        it "displays the new page with an error message" do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(page).to have_content(I18n.t("validations.postcode"))
        end
      end

      context "when do you want to add another location is selected as yes" do
        let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", add_another_location: "Yes", postcode: "ZZ1 1ZZ" } } }

        it "creates a new location for scheme with valid params and redirects to correct page" do
          expect { post "/schemes/#{scheme.id}/locations", params: }.to change(Location, :count).by(1)
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("Add a location to this scheme")
        end

        it "creates a new location for scheme with valid params" do
          expect(Location.last.scheme.organisation_id).to eq(user.organisation_id)
          expect(Location.last.name).to eq("Test")
          expect(Location.last.total_units).to eq(5)
          expect(Location.last.type_of_unit).to eq("Bungalow")
          expect(Location.last.wheelchair_adaptation).to eq("No")
        end
      end

      context "when do you want to add another location is selected as no" do
        let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", add_another_location: "No", postcode: "ZZ1 1ZZ" } } }

        it "creates a new location for scheme with valid params and redirects to correct page" do
          expect { post "/schemes/#{scheme.id}/locations", params: }.to change(Location, :count).by(1)
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("Check your changes before creating this scheme")
        end

        it "creates a new location for scheme with valid params" do
          expect(Location.last.scheme.organisation_id).to eq(user.organisation_id)
          expect(Location.last.name).to eq("Test")
          expect(Location.last.total_units).to eq(5)
          expect(Location.last.type_of_unit).to eq("Bungalow")
          expect(Location.last.wheelchair_adaptation).to eq("No")
        end
      end

      context "when do you want to add another location is not selected" do
        let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", postcode: "ZZ1 1ZZ" } } }

        it "creates a new location for scheme with valid params and redirects to correct page" do
          expect { post "/schemes/#{scheme.id}/locations", params: }.to change(Location, :count).by(1)
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("Check your changes before creating this scheme")
        end

        it "creates a new location for scheme with valid params" do
          expect(Location.last.scheme.organisation_id).to eq(user.organisation_id)
          expect(Location.last.name).to eq("Test")
          expect(Location.last.total_units).to eq(5)
          expect(Location.last.type_of_unit).to eq("Bungalow")
          expect(Location.last.wheelchair_adaptation).to eq("No")
        end
      end
    end

    context "when signed in as a support user" do
      let(:user) { FactoryBot.create(:user, :support) }
      let!(:scheme) { FactoryBot.create(:scheme) }
      let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", add_another_location: "No", postcode: "ZZ1 1ZZ" } } }

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        post "/schemes/#{scheme.id}/locations", params: params
      end

      it "creates a new location for scheme with valid params and redirects to correct page" do
        expect { post "/schemes/#{scheme.id}/locations", params: }.to change(Location, :count).by(1)
        follow_redirect!
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("Check your answers before creating this scheme")
      end

      it "creates a new location for scheme with valid params" do
        expect(Location.last.name).to eq("Test")
        expect(Location.last.postcode).to eq("ZZ11ZZ")
        expect(Location.last.total_units).to eq(5)
        expect(Location.last.type_of_unit).to eq("Bungalow")
        expect(Location.last.wheelchair_adaptation).to eq("No")
      end

      context "when postcode is submitted with lower case" do
        let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", add_another_location: "No", postcode: "zz1 1zz" } } }

        it "creates a new location for scheme with postcode " do
          expect(Location.last.postcode).to eq("ZZ11ZZ")
        end
      end

      context "when required postcode param is missing" do
        let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", add_another_location: "No" } } }

        it "displays the new page with an error message" do
          post "/schemes/#{scheme.id}/locations", params: params
          expect(response).to have_http_status(:unprocessable_entity)
          expect(page).to have_content(I18n.t("validations.postcode"))
        end
      end

      context "when do you want to add another location is selected as yes" do
        let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", add_another_location: "Yes", postcode: "ZZ1 1ZZ" } } }

        it "creates a new location for scheme with valid params and redirects to correct page" do
          expect { post "/schemes/#{scheme.id}/locations", params: }.to change(Location, :count).by(1)
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("Add a location to this scheme")
        end

        it "creates a new location for scheme with valid params" do
          expect(Location.last.name).to eq("Test")
          expect(Location.last.total_units).to eq(5)
          expect(Location.last.type_of_unit).to eq("Bungalow")
          expect(Location.last.wheelchair_adaptation).to eq("No")
        end
      end

      context "when do you want to add another location is selected as no" do
        let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", add_another_location: "No", postcode: "ZZ1 1ZZ" } } }

        it "creates a new location for scheme with valid params and redirects to correct page" do
          expect { post "/schemes/#{scheme.id}/locations", params: }.to change(Location, :count).by(1)
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("Check your changes before creating this scheme")
        end

        it "creates a new location for scheme with valid params" do
          expect(Location.last.name).to eq("Test")
          expect(Location.last.total_units).to eq(5)
          expect(Location.last.type_of_unit).to eq("Bungalow")
          expect(Location.last.wheelchair_adaptation).to eq("No")
        end
      end

      context "when do you want to add another location is not selected" do
        let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", postcode: "ZZ1 1ZZ" } } }

        it "creates a new location for scheme with valid params and redirects to correct page" do
          expect { post "/schemes/#{scheme.id}/locations", params: }.to change(Location, :count).by(1)
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("Check your changes before creating this scheme")
        end

        it "creates a new location for scheme with valid params" do
          expect(Location.last.name).to eq("Test")
          expect(Location.last.total_units).to eq(5)
          expect(Location.last.type_of_unit).to eq("Bungalow")
          expect(Location.last.wheelchair_adaptation).to eq("No")
        end
      end
    end
  end

  describe "#edit" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        get "/schemes/1/locations/1/edit"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { FactoryBot.create(:user) }

      before do
        sign_in user
        get "/schemes/1/locations/1/edit"
      end

      it "returns 401 unauthorized" do
        request
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { FactoryBot.create(:user, :data_coordinator) }
      let!(:scheme) { FactoryBot.create(:scheme, organisation: user.organisation) }
      let!(:location) { FactoryBot.create(:location, scheme:) }

      before do
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/edit"
      end

      it "returns a template for a new location" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("Add a location to this scheme")
      end

      context "when trying to new location to a scheme that belongs to another organisation" do
        let(:another_scheme)  { FactoryBot.create(:scheme) }
        let(:another_location)  { FactoryBot.create(:location, scheme: another_scheme) }

        it "displays the new page with an error message" do
          get "/schemes/#{another_scheme.id}/locations/#{another_location.id}/edit"
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "when signed in as a support user" do
      let(:user) { FactoryBot.create(:user, :support) }
      let!(:scheme) { FactoryBot.create(:scheme, organisation: user.organisation) }
      let!(:location) { FactoryBot.create(:location, scheme:) }

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/schemes/#{scheme.id}/locations/#{location.id}/edit"
      end

      it "returns a template for a new location" do
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("Add a location to this scheme")
      end
    end
  end

  describe "#update" do
    context "when not signed in" do
      it "redirects to the sign in page" do
        patch "/schemes/1/locations/1"
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when signed in as a data provider" do
      let(:user) { FactoryBot.create(:user) }

      before do
        sign_in user
        patch "/schemes/1/locations/1"
      end

      it "returns 401 unauthorized" do
        request
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a data coordinator" do
      let(:user) { FactoryBot.create(:user, :data_coordinator) }
      let!(:scheme) { FactoryBot.create(:scheme, organisation: user.organisation) }
      let!(:location)  { FactoryBot.create(:location, scheme:) }
      let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", add_another_location: "No", postcode: "ZZ1 1ZZ" } } }

      before do
        sign_in user
        patch "/schemes/#{scheme.id}/locations/#{location.id}", params: params
      end

      it "updates existing location for scheme with valid params and redirects to correct page" do
        follow_redirect!
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("Check your answers before creating this scheme")
      end

      it "updates existing location for scheme with valid params" do
        expect(Location.last.scheme.organisation_id).to eq(user.organisation_id)
        expect(Location.last.name).to eq("Test")
        expect(Location.last.postcode).to eq("ZZ11ZZ")
        expect(Location.last.total_units).to eq(5)
        expect(Location.last.type_of_unit).to eq("Bungalow")
        expect(Location.last.wheelchair_adaptation).to eq("No")
      end

      context "when postcode is submitted with lower case" do
        let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", add_another_location: "No", postcode: "zz1 1zz" } } }

        it "updates existing location for scheme with postcode " do
          expect(Location.last.postcode).to eq("ZZ11ZZ")
        end
      end

      context "when trying to update location for a scheme that belongs to another organisation" do
        let(:another_scheme)  { FactoryBot.create(:scheme) }
        let(:another_location) { FactoryBot.create(:location) }
        let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", add_another_location: "No", postcode: "ZZ1 1ZZ" } } }

        it "displays the new page with an error message" do
          patch "/schemes/#{another_scheme.id}/locations/#{another_location.id}", params: params
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when required postcode param is invalid" do
        let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", add_another_location: "No", postcode: "invalid" } } }

        it "displays the new page with an error message" do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(page).to have_content(I18n.t("validations.postcode"))
        end
      end

      context "when do you want to add another location is selected as yes" do
        let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", add_another_location: "Yes", postcode: "ZZ1 1ZZ" } } }

        it "updates existing location for scheme with valid params and redirects to correct page" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("Add a location to this scheme")
        end

        it "updates existing location for scheme with valid params" do
          expect(Location.last.scheme.organisation_id).to eq(user.organisation_id)
          expect(Location.last.name).to eq("Test")
          expect(Location.last.total_units).to eq(5)
          expect(Location.last.type_of_unit).to eq("Bungalow")
          expect(Location.last.wheelchair_adaptation).to eq("No")
        end
      end

      context "when do you want to add another location is selected as no" do
        let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", add_another_location: "No", postcode: "ZZ1 1ZZ" } } }

        it "updates existing location for scheme with valid params and redirects to correct page" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("Check your changes before creating this scheme")
        end

        it "updates existing location for scheme with valid params" do
          expect(Location.last.scheme.organisation_id).to eq(user.organisation_id)
          expect(Location.last.name).to eq("Test")
          expect(Location.last.total_units).to eq(5)
          expect(Location.last.type_of_unit).to eq("Bungalow")
          expect(Location.last.wheelchair_adaptation).to eq("No")
        end
      end

      context "when do you want to add another location is not selected" do
        let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", postcode: "ZZ1 1ZZ" } } }

        it "updates existing location for scheme with valid params and redirects to correct page" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("Check your changes before creating this scheme")
        end

        it "updates existing location for scheme with valid params" do
          expect(Location.last.scheme.organisation_id).to eq(user.organisation_id)
          expect(Location.last.name).to eq("Test")
          expect(Location.last.total_units).to eq(5)
          expect(Location.last.type_of_unit).to eq("Bungalow")
          expect(Location.last.wheelchair_adaptation).to eq("No")
        end
      end
    end

    context "when signed in as a support user" do
      let(:user) { FactoryBot.create(:user, :data_coordinator) }
      let!(:scheme) { FactoryBot.create(:scheme, organisation: user.organisation) }
      let!(:location)  { FactoryBot.create(:location, scheme:) }
      let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", add_another_location: "No", postcode: "ZZ1 1ZZ" } } }

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        patch "/schemes/#{scheme.id}/locations/#{location.id}", params: params
      end

      it "updates a location for scheme with valid params and redirects to correct page" do
        follow_redirect!
        expect(response).to have_http_status(:ok)
        expect(page).to have_content("Check your answers before creating this scheme")
      end

      it "updates existing location for scheme with valid params" do
        expect(Location.last.name).to eq("Test")
        expect(Location.last.postcode).to eq("ZZ11ZZ")
        expect(Location.last.total_units).to eq(5)
        expect(Location.last.type_of_unit).to eq("Bungalow")
        expect(Location.last.wheelchair_adaptation).to eq("No")
      end

      context "when postcode is submitted with lower case" do
        let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", add_another_location: "No", postcode: "zz1 1zz" } } }

        it "updates a location for scheme with postcode " do
          expect(Location.last.postcode).to eq("ZZ11ZZ")
        end
      end

      context "when required postcode param is missing" do
        let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", add_another_location: "No", postcode: "invalid" } } }

        it "displays the new page with an error message" do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(page).to have_content(I18n.t("validations.postcode"))
        end
      end

      context "when do you want to add another location is selected as yes" do
        let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", add_another_location: "Yes", postcode: "ZZ1 1ZZ" } } }

        it "updates location for scheme with valid params and redirects to correct page" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("Add a location to this scheme")
        end

        it "updates existing location for scheme with valid params" do
          expect(Location.last.name).to eq("Test")
          expect(Location.last.total_units).to eq(5)
          expect(Location.last.type_of_unit).to eq("Bungalow")
          expect(Location.last.wheelchair_adaptation).to eq("No")
        end
      end

      context "when do you want to add another location is selected as no" do
        let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", add_another_location: "No", postcode: "ZZ1 1ZZ" } } }

        it "updates a location for scheme with valid params and redirects to correct page" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("Check your changes before creating this scheme")
        end

        it "updates existing location for scheme with valid params" do
          expect(Location.last.name).to eq("Test")
          expect(Location.last.total_units).to eq(5)
          expect(Location.last.type_of_unit).to eq("Bungalow")
          expect(Location.last.wheelchair_adaptation).to eq("No")
        end
      end

      context "when do you want to add another location is not selected" do
        let(:params) { { location: { name: "Test", total_units: "5", type_of_unit: "Bungalow", wheelchair_adaptation: "No", postcode: "ZZ1 1ZZ" } } }

        it "updates a location for scheme with valid params and redirects to correct page" do
          follow_redirect!
          expect(response).to have_http_status(:ok)
          expect(page).to have_content("Check your changes before creating this scheme")
        end

        it "updates a location for scheme with valid params" do
          expect(Location.last.name).to eq("Test")
          expect(Location.last.total_units).to eq(5)
          expect(Location.last.type_of_unit).to eq("Bungalow")
          expect(Location.last.wheelchair_adaptation).to eq("No")
        end
      end
    end
  end
end
