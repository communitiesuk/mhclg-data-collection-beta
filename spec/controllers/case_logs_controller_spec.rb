require "rails_helper"

RSpec.describe CaseLogsController, type: :controller do
  let(:valid_session) { {} }

  context "Collection routes" do
    describe "GET #index" do
      it "returns a success response" do
        get :index, params: {}, session: valid_session
        expect(response).to be_successful
      end
    end

    describe "Post #create" do
      it "creates a new case log record" do
        expect {
          post :create, params: {}, session: valid_session
        }.to change(CaseLog, :count).by(1)
      end

      it "redirects to that case log" do
        post :create, params: {}, session: valid_session
        expect(response.status).to eq(302)
      end
    end
  end

  context "Instance routes" do
    let!(:case_log) { FactoryBot.create(:case_log) }
    let(:id) { case_log.id }

    describe "GET #show" do
      it "returns a success response" do
        get :show, params: { id: id }
        expect(response).to be_successful
      end
    end

    describe "GET #edit" do
      it "returns a success response" do
        get :edit, params: { id: id }
        expect(response).to be_successful
      end
    end
  end

  describe "submit_form" do
    let!(:case_log) { FactoryBot.create(:case_log) }
    let(:id) { case_log.id }

    it "returns a success response" do
      case_log_to_submit = { "accessibility_requirements" =>
                               ["Fully wheelchair accessible housing", "Wheelchair access to essential rooms", "Level access housing"],
                             "previous_page" => "accessibility_requirements" }
      post :submit_form, params: { id: id, case_log: case_log_to_submit }
      CaseLog.find(id)

      expect(CaseLog.find(id)["accessibility_requirements_fully_wheelchair_accessible_housing"]).to eq(true)
      expect(CaseLog.find(id)["accessibility_requirements_fully_wheelchair_accessible_housing"]).to eq(true)
      expect(CaseLog.find(id)["accessibility_requirements_fully_wheelchair_accessible_housing"]).to eq(true)
    end
  end
end
