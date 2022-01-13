require "rails_helper"
require_relative "../request_helper"

RSpec.describe CaseLogsController, type: :request do
  let(:owning_organisation) { FactoryBot.create(:organisation) }
  let(:managing_organisation) { owning_organisation }
  let(:api_username) { "test_user" }
  let(:api_password) { "test_password" }
  let(:basic_credentials) do
    ActionController::HttpAuthentication::Basic
                        .encode_credentials(api_username, api_password)
  end

  let(:headers) do
    {
      "Content-Type" => "application/json",
      "Accept" => "application/json",
      "Authorization" => basic_credentials,
    }
  end

  before do
    RequestHelper.stub_http_requests
    allow(ENV).to receive(:[])
    allow(ENV).to receive(:[]).with("API_USER").and_return(api_username)
    allow(ENV).to receive(:[]).with("API_KEY").and_return(api_password)
  end

  describe "POST #create" do
    let(:tenant_code) { "T365" }
    let(:age1) { 35 }
    let(:offered) { 12 }
    let(:property_postcode) { "SE11 6TY" }
    let(:in_progress) { "in_progress" }
    let(:completed) { "completed" }

    let(:params) do
      {
        "owning_organisation_id": owning_organisation.id,
        "managing_organisation_id": managing_organisation.id,
        "tenant_code": tenant_code,
        "age1": age1,
        "property_postcode": property_postcode,
        "offered": offered,
      }
    end

    before do
      post "/logs", headers: headers, params: params.to_json
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "returns a serialized Case Log" do
      json_response = JSON.parse(response.body)
      expect(json_response.keys).to match_array(CaseLog.new.attributes.keys)
    end

    it "creates a case log with the values passed" do
      json_response = JSON.parse(response.body)
      expect(json_response["tenant_code"]).to eq(tenant_code)
      expect(json_response["age1"]).to eq(age1)
      expect(json_response["property_postcode"]).to eq(property_postcode)
    end

    context "invalid json params" do
      let(:age1) { 2000 }
      let(:offered) { 21 }

      it "validates case log parameters" do
        json_response = JSON.parse(response.body)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["errors"]).to match_array([["offered", ["Number of times property has been offered for relet must be a number between 0 and 20"]], ["age1", ["Tenant age must be an integer between 16 and 120"]]])
      end
    end

    context "partial case log submission" do
      it "marks the record as in_progress" do
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq(in_progress)
      end
    end

    context "complete case log submission" do
      let(:org_params) do
        {
          "case_log" => {
            "owning_organisation_id" => owning_organisation.id,
            "managing_organisation_id" => managing_organisation.id,
          },
        }
      end
      let(:case_log_params) { JSON.parse(File.open("spec/fixtures/complete_case_log.json").read) }
      let(:params) do
        case_log_params.merge(org_params) { |_k, a_val, b_val| a_val.merge(b_val) }
      end

      it "marks the record as completed" do
        json_response = JSON.parse(response.body)

        expect(json_response).not_to have_key("errors")
        expect(json_response["status"]).to eq(completed)
      end
    end

    context "request with invalid credentials" do
      let(:basic_credentials) do
        ActionController::HttpAuthentication::Basic.encode_credentials(api_username, "Oops")
      end

      it "returns 401" do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET" do
    let(:user) { FactoryBot.create(:user) }
    let(:organisation) { user.organisation }
    let(:other_organisation) { FactoryBot.create(:organisation) }
    let!(:case_log) do
      FactoryBot.create(
        :case_log,
        owning_organisation: organisation,
        managing_organisation: organisation,
      )
    end
    let!(:unauthorized_case_log) do
      FactoryBot.create(
        :case_log,
        owning_organisation: other_organisation,
        managing_organisation: other_organisation,
      )
    end

    context "collection" do
      let(:headers) { { "Accept" => "text/html" } }

      before do
        RequestHelper.stub_http_requests
        sign_in user
        get "/logs", headers: headers, params: {}
      end

      it "only shows case logs for your organisation" do
        expected_case_row_log = "<a class=\"govuk-link\" href=\"/logs/#{case_log.id}\">#{case_log.id}</a>"
        unauthorized_case_row_log = "<a class=\"govuk-link\" href=\"/logs/#{unauthorized_case_log.id}\">#{unauthorized_case_log.id}</a>"
        expect(CGI.unescape_html(response.body)).to include(expected_case_row_log)
        expect(CGI.unescape_html(response.body)).not_to include(unauthorized_case_row_log)
      end
    end

    context "member" do
      let(:completed_case_log) { FactoryBot.create(:case_log, :completed) }
      let(:id) { completed_case_log.id }

      before do
        get "/logs/#{id}", headers: headers
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "returns a serialized Case Log" do
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq(completed_case_log.status)
      end

      context "invalid case log id" do
        let(:id) { (CaseLog.order(:id).last&.id || 0) + 1 }

        it "returns 404" do
          expect(response).to have_http_status(:not_found)
        end
      end

      context "edit log" do
        let(:headers) { { "Accept" => "text/html" } }

        context "a user that is not signed in" do
          it "does not let the user get case log tasklist pages they don't have access to" do
            get "/logs/#{case_log.id}", headers: headers, params: {}
            expect(response).to redirect_to("/users/sign-in")
          end
        end

        context "a signed in user" do
          context "case logs that are owned or managed by your organisation" do
            before do
              sign_in user
              get "/logs/#{case_log.id}", headers: headers, params: {}
            end

            it "shows the tasklist for case logs you have access to" do
              expect(response.body).to match("Log")
              expect(response.body).to match(case_log.id.to_s)
            end

            it "displays a section status for a case log" do
              assert_select ".govuk-tag", text: /Not started/, count: 8
              assert_select ".govuk-tag", text: /Completed/, count: 0
              assert_select ".govuk-tag", text: /Cannot start yet/, count: 1
            end
          end

          context "case log with a single section complete" do
            let(:section_completed_case_log) do
              FactoryBot.create(
                :case_log,
                :conditional_section_complete,
                owning_organisation: organisation,
                managing_organisation: organisation,
              )
            end

            before do
              sign_in user
              get "/logs/#{section_completed_case_log.id}", headers: headers, params: {}
            end

            it "displays a section status for a case log" do
              assert_select ".govuk-tag", text: /Not started/, count: 7
              assert_select ".govuk-tag", text: /Completed/, count: 1
              assert_select ".govuk-tag", text: /Cannot start yet/, count: 1
            end
          end

          context "case logs that are not owned or managed by your organisation" do
            before do
              sign_in user
              get "/logs/#{unauthorized_case_log.id}", headers: headers, params: {}
            end

            it "does not show the tasklist for case logs you don't have access to" do
              expect(response).to have_http_status(:not_found)
            end
          end
        end
      end
    end

    context "Check answers" do
      let(:postcode_case_log) do
        FactoryBot.create(:case_log,
                          owning_organisation: organisation,
                          managing_organisation: organisation,
                          postcode_known: "No")
      end
      let(:id) { postcode_case_log.id }

      before do
        stub_request(:get, /api.postcodes.io/)
          .to_return(status: 200, body: "{\"status\":200,\"result\":{\"admin_district\":\"Manchester\"}}", headers: {})
        sign_in user
      end

      it "shows the inferred postcode" do
        case_log = FactoryBot.create(:case_log,
                                     owning_organisation: organisation,
                                     managing_organisation: organisation,
                                     postcode_known: "Yes",
                                     property_postcode: "PO5 3TE")
        id = case_log.id
        get "/logs/#{id}/property-information/check-answers"
        expected_inferred_answer = "<span class=\"govuk-!-font-weight-regular app-!-colour-muted\">Manchester</span>"
        expect(CGI.unescape_html(response.body)).to include(expected_inferred_answer)
      end

      it "does not show do you know the property postcode question" do
        get "/logs/#{id}/property-information/check-answers"
        expect(CGI.unescape_html(response.body)).not_to include("Do you know the property postcode?")
      end

      it "shows if the postcode is not known" do
        get "/logs/#{id}/property-information/check-answers"
        expect(CGI.unescape_html(response.body)).to include("Not known")
      end
    end
  end

  describe "PATCH" do
    let(:case_log) do
      FactoryBot.create(:case_log, :in_progress, tenant_code: "Old Value", property_postcode: "M1 1AE")
    end
    let(:params) do
      { tenant_code: "New Value" }
    end
    let(:id) { case_log.id }

    before do
      patch "/logs/#{id}", headers: headers, params: params.to_json
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "updates the case log with the given fields and keeps original values where none are passed" do
      case_log.reload
      expect(case_log.tenant_code).to eq("New Value")
      expect(case_log.property_postcode).to eq("M1 1AE")
    end

    context "invalid case log id" do
      let(:id) { (CaseLog.order(:id).last&.id || 0) + 1 }

      it "returns 404" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "invalid case log params" do
      let(:params) { { age1: 200 } }

      it "returns 422" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns an error message" do
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to eq({ "age1" => ["Tenant age must be an integer between 16 and 120"] })
      end
    end

    context "request with invalid credentials" do
      let(:basic_credentials) do
        ActionController::HttpAuthentication::Basic.encode_credentials(api_username, "Oops")
      end

      it "returns 401" do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  # We don't really have any meaningful distinction between PUT and PATCH here since you can update some or all
  # fields in both cases, and both route to #Update. Rails generally recommends PATCH as it more closely matches
  # what actually happens to an ActiveRecord object and what we're doing here, but either is allowed.
  describe "PUT" do
    let(:case_log) do
      FactoryBot.create(:case_log, :in_progress, tenant_code: "Old Value", property_postcode: "SW1A 2AA")
    end
    let(:params) do
      { tenant_code: "New Value" }
    end
    let(:id) { case_log.id }

    before do
      put "/logs/#{id}", headers: headers, params: params.to_json
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "updates the case log with the given fields and keeps original values where none are passed" do
      case_log.reload
      expect(case_log.tenant_code).to eq("New Value")
      expect(case_log.property_postcode).to eq("SW1A 2AA")
    end

    context "invalid case log id" do
      let(:id) { (CaseLog.order(:id).last&.id || 0) + 1 }

      it "returns 404" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "request with invalid credentials" do
      let(:basic_credentials) do
        ActionController::HttpAuthentication::Basic.encode_credentials(api_username, "Oops")
      end

      it "returns 401" do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE" do
    let!(:case_log) do
      FactoryBot.create(:case_log, :in_progress)
    end
    let(:id) { case_log.id }

    context "expected deletion" do
      before do
        delete "/logs/#{id}", headers: headers
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "soft deletes the case log" do
        expect { CaseLog.find(id) }.to raise_error(ActiveRecord::RecordNotFound)
        expect(CaseLog.with_discarded.find(id)).to be_a(CaseLog)
      end

      context "invalid case log id" do
        let(:id) { (CaseLog.order(:id).last&.id || 0) + 1 }

        it "returns 404" do
          expect(response).to have_http_status(:not_found)
        end
      end

      context "request with invalid credentials" do
        let(:basic_credentials) do
          ActionController::HttpAuthentication::Basic.encode_credentials(api_username, "Oops")
        end

        it "returns 401" do
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    context "deletion fails" do
      before do
        allow_any_instance_of(CaseLog).to receive(:discard).and_return(false)
        delete "/logs/#{id}", headers: headers
      end

      it "returns an unprocessable entity 422" do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
