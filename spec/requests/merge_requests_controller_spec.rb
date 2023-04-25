require "rails_helper"

RSpec.describe MergeRequestsController, type: :request do
  let(:organisation) { user.organisation }
  let(:other_organisation) { create(:organisation, name: "Other Test Org") }
  let(:headers) { { "Accept" => "text/html" } }
  let(:page) { Capybara::Node::Simple.new(response.body) }
  let(:user) { create(:user, :data_coordinator) }
  let(:support_user) { create(:user, :support, organisation:) }
  let(:merge_request) { MergeRequest.create!(requesting_organisation: organisation) }
  let(:other_merge_request) { MergeRequest.create!(requesting_organisation: other_organisation) }

  context "when user is signed in with a data coordinator user" do
    before { sign_in user }

    describe "#organisations" do
      let(:params) { { merge_request: { requesting_organisation_id: "9", status: "unsubmitted" } } }

      context "when creating a new merge request" do
        before do
          post "/merge-request", headers:, params:
        end

        it "creates merge request with requesting organisation" do
          follow_redirect!
          expect(page).to have_content("Which organisations are merging?")
          expect(page).to have_content(organisation.name)
          expect(page).not_to have_link("Remove")
        end

        context "when passing a different requesting organisation id" do
          let(:params) { { merge_request: { requesting_organisation_id: other_organisation.id, status: "unsubmitted" } } }

          it "creates merge request with current user organisation" do
            follow_redirect!
            expect(MergeRequest.count).to eq(1)
            expect(MergeRequest.first.requesting_organisation_id).to eq(organisation.id)
            expect(MergeRequest.first.merging_organisations.count).to eq(1)
            expect(MergeRequest.first.merging_organisations.first.id).to eq(organisation.id)
          end
        end
      end

      context "when viewing existing merge request" do
        before do
          get "/merge-request/#{merge_request.id}/organisations", headers:, params:
        end

        it "shows merge request with requesting organisation" do
          expect(page).to have_content("Which organisations are merging?")
          expect(page).to have_content(organisation.name)
        end
      end

      context "when viewing existing merge request of a different (unauthorised) organisation" do
        before do
          get "/merge-request/#{other_merge_request.id}/organisations", headers:, params:
        end

        it "shows merge request with requesting organisation" do
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe "#update_organisations" do
      let(:params) { { merge_request: { merging_organisation: other_organisation.id } } }

      context "when updating a merge request with a new organisation" do
        before do
          patch "/merge-request/#{merge_request.id}/organisations", headers:, params:
        end

        it "updates the merge request" do
          merge_request.reload
          expect(merge_request.merging_organisations.count).to eq(1)
          expect(page).to have_content("Test Org")
          expect(page).to have_content("Other Test Org")
          expect(page).to have_link("Remove")
        end
      end

      context "when the user selects an organisation that requested another merge" do
        let(:params) { { merge_request: { merging_organisation: other_organisation.id } } }

        before do
          MergeRequest.create!(requesting_organisation_id: other_organisation.id, status: "submitted")
          patch "/merge-request/#{merge_request.id}/organisations", headers:, params:
        end

        it "does not update the merge request" do
          merge_request.reload
          expect(merge_request.merging_organisations.count).to eq(0)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(page).to have_content(I18n.t("validations.merge_request.organisation_part_of_another_merge"))
        end
      end

      context "when the user selects an organisation that has another non submitted merge" do
        let(:params) { { merge_request: { merging_organisation: other_organisation.id } } }

        before do
          MergeRequest.create!(requesting_organisation_id: other_organisation.id, status: "unsubmitted")
          patch "/merge-request/#{merge_request.id}/organisations", headers:, params:
        end

        it "updates the merge request" do
          merge_request.reload
          expect(merge_request.merging_organisations.count).to eq(1)
          expect(page).not_to have_content(I18n.t("validations.merge_request.organisation_part_of_another_merge"))
        end
      end

      context "when the user selects an organisation that is a part of another merge" do
        let(:another_organisation) { create(:organisation, name: "Other Test Org") }
        let(:params) { { merge_request: { merging_organisation: another_organisation.id } } }

        before do
          existing_merge_request = MergeRequest.create!(requesting_organisation_id: other_organisation.id, status: "submitted")
          MergeRequestOrganisation.create!(merge_request_id: existing_merge_request.id, merging_organisation_id: another_organisation.id)
          patch "/merge-request/#{merge_request.id}/organisations", headers:, params:
        end

        it "does not update the merge request" do
          merge_request.reload
          expect(merge_request.merging_organisations.count).to eq(0)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(page).to have_content(I18n.t("validations.merge_request.organisation_part_of_another_merge"))
        end
      end

      context "when the user selects an organisation that is a part of another unsubmitted merge" do
        let(:another_organisation) { create(:organisation, name: "Other Test Org") }
        let(:params) { { merge_request: { merging_organisation: another_organisation.id } } }

        before do
          existing_merge_request = MergeRequest.create!(requesting_organisation_id: other_organisation.id, status: "unsubmitted")
          MergeRequestOrganisation.create!(merge_request_id: existing_merge_request.id, merging_organisation_id: another_organisation.id)
          patch "/merge-request/#{merge_request.id}/organisations", headers:, params:
        end

        it "does not update the merge request" do
          merge_request.reload
          expect(merge_request.merging_organisations.count).to eq(1)
          expect(page).not_to have_content(I18n.t("validations.merge_request.organisation_part_of_another_merge"))
        end
      end

      context "when the user selects an organisation that is a part of current merge" do
        let(:another_organisation) { create(:organisation, name: "Other Test Org") }
        let(:params) { { merge_request: { merging_organisation: another_organisation.id } } }

        before do
          merge_request.merging_organisations << another_organisation
          patch "/merge-request/#{merge_request.id}/organisations", headers:, params:
        end

        it "does not update the merge request" do
          merge_request.reload
          expect(merge_request.merging_organisations.count).to eq(1)
        end
      end

      context "when the user selects an organisation that is requesting this merge" do
        let(:params) { { merge_request: { merging_organisation: merge_request.requesting_organisation_id } } }

        before do
          patch "/merge-request/#{merge_request.id}/organisations", headers:, params:
        end

        it "does not update the merge request" do
          merge_request.reload
          expect(page).not_to have_content(I18n.t("validations.merge_request.organisation_part_of_another_merge"))
          expect(merge_request.merging_organisations.count).to eq(1)
        end
      end

      context "when the user does not select an organisation" do
        let(:params) { { merge_request: { merging_organisation: nil } } }

        before do
          patch "/merge-request/#{merge_request.id}/organisations", headers:, params:
        end

        it "does not update the merge request" do
          merge_request.reload
          expect(merge_request.merging_organisations.count).to eq(0)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(page).to have_content(I18n.t("validations.merge_request.organisation_not_selected"))
        end
      end

      context "when the user selects non existent id" do
        let(:params) { { merge_request: { merging_organisation: "clearly_not_an_id" } } }

        before do
          patch "/merge-request/#{merge_request.id}/organisations", headers:, params:
        end

        it "does not update the merge request" do
          merge_request.reload
          expect(merge_request.merging_organisations.count).to eq(0)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(page).to have_content(I18n.t("validations.merge_request.organisation_not_selected"))
        end
      end
    end

    describe "#remove_organisation" do
      let(:params) { { merge_request: { merging_organisation: other_organisation.id } } }

      context "when removing an organisation from merge request" do
        before do
          MergeRequestOrganisation.create!(merge_request_id: merge_request.id, merging_organisation_id: other_organisation.id)
          get "/merge-request/#{merge_request.id}/organisations/remove", headers:, params:
        end

        it "updates the merge request" do
          expect(merge_request.merging_organisations.count).to eq(0)
          expect(page).not_to have_link("Remove")
        end
      end

      context "when removing an organisation that is not part of a merge from merge request" do
        before do
          get "/merge-request/#{merge_request.id}/organisations/remove", headers:, params:
        end

        it "does not throw an error" do
          expect(merge_request.merging_organisations.count).to eq(0)
          expect(page).not_to have_link("Remove")
        end
      end
    end

    describe "#update" do
      before { sign_in user }

      describe "#other_merging_organisations" do
        let(:other_merging_organisations) { "A list of other merging organisations" }
        let(:params) { { merge_request: { other_merging_organisations: } } }
        let(:request) do
          patch "/merge-request/#{merge_request.id}", headers:, params:
        end

        context "when adding other merging organisations" do
          before do
            MergeRequestOrganisation.create!(merge_request_id: merge_request.id, merging_organisation_id: other_organisation.id)
          end

          it "updates the merge request" do
            expect { request }.to change { merge_request.reload.other_merging_organisations }.from(nil).to(other_merging_organisations)
          end

          it "redirects telephone number path" do
            request

            expect(response).to redirect_to(absorbing_organisation_merge_request_path(merge_request))
          end
        end
      end

      context "when absorbing_organisation_id set to other" do
        let(:params) do
          { merge_request: { absorbing_organisation_id: "other" } }
        end

        before do
          patch "/merge-request/#{merge_request.id}", headers:, params:
        end

        it "redirects to new org path" do
          expect(response).to redirect_to(new_org_name_merge_request_path(merge_request))
        end
      end

      context "when absorbing_organisation_id set to id" do
        let(:params) do
          { merge_request: { absorbing_organisation_id: other_organisation.id } }
        end

        let(:request) do
          patch "/merge-request/#{merge_request.id}", headers:, params:
        end

        it "redirects telephone number path" do
          request

          expect(response).to redirect_to(confirm_telephone_number_merge_request_path(merge_request))
        end

        it "updates the merge request" do
          expect { request }.to change { merge_request.reload.absorbing_organisation_id }.from(nil).to(other_organisation.id)
        end
      end
    end
  end

  context "when user is signed in as a support user" do
    before do
      allow(support_user).to receive(:need_two_factor_authentication?).and_return(false)
      sign_in support_user
    end

    describe "#organisations" do
      let(:params) { { merge_request: { requesting_organisation_id: other_organisation.id, status: "unsubmitted" } } }

      before do
        post "/merge-request", headers:, params:
      end

      it "creates merge request with requesting organisation" do
        follow_redirect!
        expect(MergeRequest.count).to eq(1)
        expect(MergeRequest.first.requesting_organisation_id).to eq(other_organisation.id)
      end
    end
  end
end
