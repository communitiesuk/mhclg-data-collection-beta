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

  context "when user is signed in with a support user" do
    before do
      allow(support_user).to receive(:need_two_factor_authentication?).and_return(false)
      sign_in support_user
    end

    context "when creating a new merge request" do
      let(:params) { { merge_request: { requesting_organisation_id: support_user.organisation_id } } }

      before do
        post "/merge-request", headers:, params:
      end

      it "creates merge request with requesting organisation" do
        follow_redirect!
        expect(page).to have_content("Which organisation is absorbing the others?")
        expect(MergeRequest.first.requesting_organisation_id).to eq(support_user.organisation_id)
      end

      context "when passing a different requesting organisation id" do
        let(:params) { { merge_request: { requesting_organisation_id: other_organisation.id } } }

        it "creates merge request with current user organisation" do
          follow_redirect!
          expect(MergeRequest.count).to eq(1)
          expect(MergeRequest.first.requesting_organisation_id).to eq(support_user.organisation_id)
          expect(MergeRequest.first.merging_organisations.count).to eq(0)
        end
      end
    end

    describe "#merging-organisations" do
      context "when viewing merging organisations page" do
        before do
          merge_request.update!(absorbing_organisation_id: organisation.id)
          get "/merge-request/#{merge_request.id}/merging-organisations", headers:
        end

        it "shows the correct content" do
          expect(page).to have_content("Which organisations are merging into #{organisation.name}?")
        end
      end
    end

    describe "#update_merging_organisations" do
      let(:params) { { merge_request: { merging_organisation: other_organisation.id, new_merging_org_ids: [] } } }

      context "when updating a merge request with a new merging organisation" do
        before do
          patch "/merge-request/#{merge_request.id}/merging-organisations", headers:, params:
        end

        it "adds merging organisation to the page" do
          merge_request.reload
          expect(page).to have_content(organisation.name)
          expect(page).to have_content("Other Test Org")
          expect(page).to have_link("Remove")
        end
      end

      context "when the user selects an organisation that requested another merge" do
        let(:params) { { merge_request: { merging_organisation: other_organisation.id, new_merging_org_ids: [] } } }

        before do
          MergeRequest.create!(requesting_organisation_id: other_organisation.id, request_merged: true)
          patch "/merge-request/#{merge_request.id}/merging-organisations", headers:, params:
        end

        it "does not error" do
          merge_request.reload
          expect(page).not_to have_content(I18n.t("validations.merge_request.organisation_part_of_another_merge"))
        end
      end

      context "when the user updates merge request with organisation that is already part of another merge" do
        let(:another_organisation) { create(:organisation) }
        let(:other_merge_request) { create(:merge_request, merge_date: Time.zone.local(2022, 5, 4)) }
        let(:params) { { merge_request: { merging_organisation: another_organisation.id, new_merging_org_ids: [] } } }

        before do
          MergeRequestOrganisation.create!(merge_request_id: other_merge_request.id, merging_organisation_id: another_organisation.id)
          patch "/merge-request/#{merge_request.id}/merging-organisations", headers:, params:
        end

        it "displays the page with an error message" do
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content("Another merge request records #{another_organisation.name} as merging into #{other_merge_request.absorbing_organisation&.name} on 4 May 2022. Select another organisation or remove this organisation from the other merge request.")
        end
      end

      context "when the user selects an organisation that is a part of another merge" do
        let(:another_organisation) { create(:organisation) }
        let(:params) { { merge_request: { merging_organisation: another_organisation.id, new_merging_org_ids: [] } } }

        before do
          existing_merge_request = MergeRequest.create!(requesting_organisation_id: other_organisation.id, request_merged: true)
          MergeRequestOrganisation.create!(merge_request_id: existing_merge_request.id, merging_organisation_id: another_organisation.id)
          patch "/merge-request/#{merge_request.id}/merging-organisations", headers:, params:
        end

        it "does not update the merge request" do
          merge_request.reload
          expect(merge_request.merging_organisations.count).to eq(0)
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("validations.merge_request.organisation_part_of_another_merge"))
        end
      end

      context "when the user selects an organisation that is a part of another incomplete merge" do
        let(:another_organisation) { create(:organisation) }
        let(:params) { { merge_request: { merging_organisation: another_organisation.id, new_merging_org_ids: [] } } }

        before do
          existing_merge_request = MergeRequest.create!(requesting_organisation_id: other_organisation.id)
          MergeRequestOrganisation.create!(merge_request_id: existing_merge_request.id, merging_organisation_id: another_organisation.id)
          patch "/merge-request/#{merge_request.id}/merging-organisations", headers:, params:
        end

        it "does not error" do
          merge_request.reload
          expect(page).not_to have_content(I18n.t("validations.merge_request.organisation_part_of_another_merge"))
        end
      end

      context "when the user selects an organisation that is a part of current merge" do
        let(:another_organisation) { create(:organisation) }
        let(:params) { { merge_request: { merging_organisation: another_organisation.id, new_merging_org_ids: [] } } }

        before do
          merge_request.merging_organisations << another_organisation
          patch "/merge-request/#{merge_request.id}/merging-organisations", headers:, params:
        end

        it "does not update the merge request" do
          merge_request.reload
          expect(merge_request.merging_organisations.count).to eq(1)
        end
      end

      context "when the user does not select an organisation" do
        let(:params) { { merge_request: { merging_organisation: nil, new_merging_org_ids: [] } } }

        before do
          patch "/merge-request/#{merge_request.id}/merging-organisations", headers:, params:
        end

        it "does not update the merge request" do
          merge_request.reload
          expect(merge_request.merging_organisations.count).to eq(0)
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("validations.merge_request.organisation_not_selected"))
        end
      end

      context "when the user selects non existent id" do
        let(:params) { { merge_request: { merging_organisation: "clearly_not_an_id", new_merging_org_ids: [] } } }

        before do
          patch "/merge-request/#{merge_request.id}/merging-organisations", headers:, params:
        end

        it "does not update the merge request" do
          merge_request.reload
          expect(merge_request.merging_organisations.count).to eq(0)
          expect(response).to have_http_status(:unprocessable_content)
          expect(page).to have_content(I18n.t("validations.merge_request.organisation_not_selected"))
        end
      end
    end

    describe "#remove_organisation" do
      let(:params) { { merge_request: { merging_organisation: other_organisation.id } } }

      context "when removing an organisation from merge request" do
        before do
          MergeRequestOrganisation.create!(merge_request_id: merge_request.id, merging_organisation_id: other_organisation.id)
          get "/merge-request/#{merge_request.id}/merging-organisations/remove", headers:, params:
        end

        it "updates the merge request" do
          expect(merge_request.merging_organisations.count).to eq(0)
          expect(page).not_to have_link("Remove")
        end
      end

      context "when removing an organisation that is not part of a merge from merge request" do
        before do
          get "/merge-request/#{merge_request.id}/merging-organisations/remove", headers:, params:
        end

        it "does not throw an error" do
          expect(merge_request.merging_organisations.count).to eq(0)
          expect(page).not_to have_link("Remove")
        end
      end
    end

    describe "#absorbing_organisation" do
      let(:merge_request) { MergeRequest.create!(requesting_organisation: organisation) }

      before { get "/merge-request/#{merge_request.id}/absorbing-organisation", headers: }

      it "asks for the absorbing organisation" do
        expect(page).to have_content("Which organisation is absorbing the others?")
        expect(page).to have_content("Select organisation name")
      end

      it "has the correct back button" do
        expect(page).to have_link("Back", href: organisations_path(tab: "merge-requests"))
      end
    end

    describe "#merge_date" do
      context "when viewing merge date page" do
        before do
          merge_request.update!(absorbing_organisation_id: organisation.id)
          get "/merge-request/#{merge_request.id}/merge-date", headers:
        end

        it "shows the correct content" do
          expect(page).to have_content("What is the merge date?")
        end
      end
    end

    describe "#existing_absorbing_organisation" do
      context "when viewing helpdesk ticket page" do
        before do
          merge_request.update!(absorbing_organisation_id: organisation.id, merge_date: Time.zone.today)
          get "/merge-request/#{merge_request.id}/existing-absorbing-organisation", headers:
        end

        it "shows the correct content" do
          expect(page).to have_content("Was #{merge_request.absorbing_organisation.name} already active before the merge date?")
          expect(page).to have_content("Yes, this organisation existed before the merge")
          expect(page).to have_content("No, it is a new organisation created by this merge")
          expect(page).to have_link("Back", href: merge_date_merge_request_path(merge_request))
          expect(page).to have_button("Save and continue")
        end
      end
    end

    describe "#helpdesk_ticket" do
      context "when viewing helpdesk ticket page" do
        before do
          merge_request.update!(absorbing_organisation_id: organisation.id, merge_date: Time.zone.today)
          get "/merge-request/#{merge_request.id}/helpdesk-ticket", headers:
        end

        it "shows the correct content" do
          expect(page).to have_content("Was this merge reported by a helpdesk ticket?")
          expect(page).to have_link("Back", href: existing_absorbing_organisation_merge_request_path(merge_request))
          expect(page).to have_button("Save and continue")
        end
      end
    end

    describe "#update" do
      describe "from absorbing_organisation page" do
        context "when not answering the question" do
          let(:merge_request) { MergeRequest.create!(requesting_organisation: organisation, absorbing_organisation: other_organisation) }
          let(:params) do
            { merge_request: { page: "absorbing_organisation" } }
          end
          let(:request) do
            patch "/merge-request/#{merge_request.id}", headers:, params:
          end

          it "renders the error" do
            request

            expect(page).to have_content("Select the absorbing organisation")
          end

          it "does not update the request" do
            expect { request }.not_to(change { merge_request.reload.attributes })
          end
        end

        context "when absorbing_organisation_id set to id" do
          let(:merge_request) { MergeRequest.create!(requesting_organisation: organisation) }
          let(:params) do
            { merge_request: { absorbing_organisation_id: other_organisation.id, page: "absorbing_organisation" } }
          end

          let(:request) do
            patch "/merge-request/#{merge_request.id}", headers:, params:
          end

          it "redirects to merging organisations path" do
            request

            expect(response).to redirect_to(merging_organisations_merge_request_path(merge_request))
          end

          it "updates absorbing_organisation_id" do
            expect { request }.to change {
              merge_request.reload.absorbing_organisation
            }.from(nil).to(other_organisation)
          end
        end

        context "when updating from check_answers page" do
          let(:merge_request) { MergeRequest.create!(requesting_organisation: organisation) }
          let(:params) do
            { merge_request: { absorbing_organisation_id: "", page: "absorbing_organisation" } }
          end

          let(:request) do
            patch "/merge-request/#{merge_request.id}?referrer=check_answers", headers:, params:
          end

          it "keeps corrent links if validation fails" do
            request

            expect(page).to have_link("Cancel", href: merge_request_path(merge_request))
            expect(page).to have_button("Save changes")
          end
        end

        context "when absorbing_organisation_id set to one of the merging organisations" do
          let(:merge_request) { MergeRequest.create!(requesting_organisation: organisation) }
          let(:params) do
            { merge_request: { absorbing_organisation_id: other_organisation.id, page: "absorbing_organisation" } }
          end

          let(:request) do
            MergeRequestOrganisation.create!(merge_request_id: merge_request.id, merging_organisation_id: other_organisation.id)
            patch "/merge-request/#{merge_request.id}", headers:, params:
          end

          it "removes organisation from merge request organisations" do
            request

            merge_request.reload
            expect(merge_request.merging_organisations.count).to eq(0)
          end
        end
      end

      describe "from merge_date page" do
        context "when not answering the question" do
          let(:merge_request) { MergeRequest.create!(requesting_organisation: organisation, absorbing_organisation: other_organisation) }
          let(:params) do
            { merge_request: { merge_date: "", page: "merge_date" } }
          end
          let(:request) do
            patch "/merge-request/#{merge_request.id}", headers:, params:
          end

          it "renders the error" do
            request

            expect(response).to have_http_status(:unprocessable_content)
            expect(page).to have_content("Enter a merge date")
          end

          it "does not update the request" do
            expect { request }.not_to(change { merge_request.reload.attributes })
          end
        end

        context "when merge date set to an invalid date" do
          let(:merge_request) { MergeRequest.create!(requesting_organisation: organisation) }
          let(:params) do
            { merge_request: { page: "merge_date", "merge_date": "10/44/2022" } }
          end

          let(:request) do
            patch "/merge-request/#{merge_request.id}", headers:, params:
          end

          it "displays the page with an error message" do
            request

            expect(response).to have_http_status(:unprocessable_content)
            expect(page).to have_content("Enter a valid merge date")
          end
        end

        context "when merge date set to a valid date" do
          let(:merge_request) { MergeRequest.create!(requesting_organisation: organisation) }
          let(:params) do
            { merge_request: { page: "merge_date", "merge_date": "10/4/2022" } }
          end

          let(:request) do
            patch "/merge-request/#{merge_request.id}", headers:, params:
          end

          it "redirects to existing absorbing organisation path" do
            request

            expect(response).to redirect_to(existing_absorbing_organisation_merge_request_path(merge_request))
          end

          it "updates merge_date" do
            expect { request }.to change {
              merge_request.reload.merge_date
            }.from(nil).to(Time.zone.local(2022, 4, 10))
          end
        end

        context "when merge date set to a date more than 1 year in the future" do
          let(:merge_request) { MergeRequest.create!(requesting_organisation: organisation) }
          let(:params) do
            { merge_request: { page: "merge_date", "merge_date": [(Time.zone.now.day + 1).to_s, Time.zone.now.month.to_s, (Time.zone.now.year + 1).to_s].join("/") } }
          end

          let(:request) do
            patch "/merge-request/#{merge_request.id}", headers:, params:
          end

          it "displays the page with an error message" do
            request

            expect(response).to have_http_status(:unprocessable_content)
            expect(page).to have_content("The merge date must not be later than a year from today’s date.")
          end
        end
      end

      describe "from merging_organisations page" do
        context "when the user updates merge request with valid merging organisation ID" do
          let(:merge_request) { MergeRequest.create!(requesting_organisation: organisation) }
          let(:another_organisation) { create(:organisation) }
          let(:params) do
            { merge_request: { page: "merging_organisations", new_merging_org_ids: another_organisation.id } }
          end

          let(:request) do
            patch "/merge-request/#{merge_request.id}", headers:, params:
          end

          it "updates the merge request" do
            request

            merge_request.reload
            expect(merge_request.merging_organisations.count).to eq(1)
            expect(merge_request.merging_organisations.first.id).to eq(another_organisation.id)
          end
        end
      end

      describe "from existing_absorbing_organisation page" do
        context "when not answering the question" do
          let(:merge_request) { MergeRequest.create!(requesting_organisation: organisation, absorbing_organisation: other_organisation) }
          let(:params) do
            { merge_request: { page: "existing_absorbing_organisation" } }
          end
          let(:request) do
            patch "/merge-request/#{merge_request.id}", headers:, params:
          end

          it "renders the error" do
            request

            expect(response).to have_http_status(:unprocessable_content)
            expect(page).to have_content("You must answer absorbing organisation already active?")
          end

          it "does not update the request" do
            expect { request }.not_to(change { merge_request.reload.attributes })
          end
        end
      end

      describe "from helpdesk_ticket page" do
        context "when not answering the question" do
          let(:merge_request) { MergeRequest.create!(requesting_organisation: organisation, absorbing_organisation: other_organisation) }
          let(:params) do
            { merge_request: { page: "helpdesk_ticket" } }
          end
          let(:request) do
            patch "/merge-request/#{merge_request.id}", headers:, params:
          end

          it "renders the error" do
            request

            expect(response).to have_http_status(:unprocessable_content)
            expect(page).to have_content("You must answer was this merge reported by a helpdesk ticket?")
          end

          it "does not update the request" do
            expect { request }.not_to(change { merge_request.reload.attributes })
          end
        end

        context "when has_helpdesk_ticket is true but no ticket is given" do
          let(:merge_request) { MergeRequest.create!(requesting_organisation: organisation, absorbing_organisation: other_organisation) }
          let(:params) do
            { merge_request: { page: "helpdesk_ticket", has_helpdesk_ticket: true } }
          end
          let(:request) do
            patch "/merge-request/#{merge_request.id}", headers:, params:
          end

          it "renders the error" do
            request

            expect(response).to have_http_status(:unprocessable_content)
            expect(page).to have_content("You must answer the ticket number")
          end

          it "does not update the request" do
            expect { request }.not_to(change { merge_request.reload.attributes })
          end
        end

        context "when has_helpdesk_ticket is false" do
          let(:merge_request) { MergeRequest.create!(requesting_organisation: organisation, absorbing_organisation: other_organisation, helpdesk_ticket: "123") }
          let(:params) do
            { merge_request: { page: "helpdesk_ticket", has_helpdesk_ticket: false } }
          end
          let(:request) do
            patch "/merge-request/#{merge_request.id}", headers:, params:
          end

          it "updates has_helpdesk_ticket and clears helpdesk_ticket" do
            request
            expect(merge_request.reload.has_helpdesk_ticket).to eq(false)
            expect(merge_request.helpdesk_ticket).to eq(nil)
          end
        end

        context "when has_helpdesk_ticket is true and ticket is given" do
          let(:merge_request) { MergeRequest.create!(requesting_organisation: organisation, absorbing_organisation: other_organisation) }
          let(:params) do
            { merge_request: { page: "helpdesk_ticket", has_helpdesk_ticket: true, helpdesk_ticket: "321" } }
          end
          let(:request) do
            patch "/merge-request/#{merge_request.id}", headers:, params:
          end

          it "updates has_helpdesk_ticket and clears helpdesk_ticket" do
            request
            expect(merge_request.reload.has_helpdesk_ticket).to eq(true)
            expect(merge_request.helpdesk_ticket).to eq("321")
          end
        end
      end
    end

    describe "#merge_start_confirmation" do
      before do
        get "/merge-request/#{merge_request.id}/merge-start-confirmation", headers:
      end

      it "has correct content" do
        expect(page).to have_content("Are you sure you want to begin this merge?")
        expect(page).to have_content("You will not be able to undo this action")
        expect(page).to have_link("Back", href: merge_request_path(merge_request))
        expect(page).to have_button("Begin merge")
      end
    end

    describe "#start_merge" do
      let(:merge_request) { MergeRequest.create!(requesting_organisation: organisation, absorbing_organisation: organisation, merge_date: Time.zone.local(2022, 3, 3), existing_absorbing_organisation: true) }
      let(:merging_organisation) { create(:organisation, name: "Merging Test Org") }

      before do
        allow(ProcessMergeRequestJob).to receive(:perform_later).and_return(nil)
      end

      context "when merge request is ready to merge" do
        before do
          create(:merge_request_organisation, merge_request:, merging_organisation: other_organisation)
          create(:merge_request_organisation, merge_request:, merging_organisation:)
          create_list(:scheme, 2, owning_organisation: organisation)
          create(:lettings_log, owning_organisation: organisation)
          create(:sales_log, owning_organisation: organisation)
        end

        it "runs the job with correct merge request" do
          expect(merge_request.reload.status).to eq("ready_to_merge")
          expect(ProcessMergeRequestJob).to receive(:perform_later).with(merge_request:).once
          patch "/merge-request/#{merge_request.id}/start-merge"
          expect(merge_request.reload.status).to eq("processing")
          expect(merge_request.total_users).to eq(5)
          expect(merge_request.total_schemes).to eq(2)
          expect(merge_request.total_stock_owners).to eq(0)
          expect(merge_request.total_managing_agents).to eq(0)
          expect(merge_request.total_lettings_logs).to eq(1)
          expect(merge_request.total_sales_logs).to eq(1)
        end
      end

      context "when merge request is not ready to merge" do
        it "does not run the job" do
          expect(merge_request.status).to eq("incomplete")
          expect(ProcessMergeRequestJob).not_to receive(:perform_later).with(merge_request:)
          patch "/merge-request/#{merge_request.id}/start-merge"
          expect(merge_request.reload.status).to eq("incomplete")
        end
      end
    end

    describe "#show" do
      before do
        create(:merge_request_organisation, merge_request:, merging_organisation: other_organisation)
        create_list(:scheme, 2, owning_organisation: organisation)
        create_list(:scheme, 2, owning_organisation: other_organisation)
        create(:lettings_log, owning_organisation: organisation)
        create(:lettings_log, owning_organisation: other_organisation)
        create_list(:sales_log, 2, owning_organisation: other_organisation)
        create(:sales_log, owning_organisation: organisation)
        get "/merge-request/#{merge_request.id}", headers:
      end

      context "when request has previously failed" do
        let(:merge_request) { create(:merge_request, last_failed_attempt: Time.zone.yesterday) }

        it "shows a banner" do
          expect(page).to have_content("An error occurred while processing the merge.")
          expect(page).to have_content("No changes have been made. Try beginning the merge again.")
        end
      end

      context "when request has not previously failed" do
        let(:merge_request) { create(:merge_request, last_failed_attempt: nil) }

        it "does not show a banner" do
          expect(page).not_to have_content("An error occurred while processing the merge.")
          expect(page).not_to have_content("No changes have been made. Try beginning the merge again.")
        end
      end

      it "has begin merge button" do
        expect(page).to have_link("Begin merge", href: merge_start_confirmation_merge_request_path(merge_request))
      end

      context "with unmerged request" do
        let(:merge_request) { create(:merge_request, absorbing_organisation_id: organisation.id, merge_date: Time.zone.today, existing_absorbing_organisation: true) }

        it "shows outcomes count and has links to view merge outcomes" do
          expect(page).to have_link("View", href: user_outcomes_merge_request_path(merge_request))
          expect(page).to have_link("View", href: scheme_outcomes_merge_request_path(merge_request))
          expect(page).to have_link("View", href: relationship_outcomes_merge_request_path(merge_request))
          expect(page).to have_link("View", href: logs_outcomes_merge_request_path(merge_request))
          expect(page).to have_content("4 users")
          expect(page).to have_content("4 schemes")
          expect(page).to have_content("0 stock owners")
          expect(page).to have_content("0 managing agents")
          expect(page).to have_content("2 lettings logs")
          expect(page).to have_content("3 sales logs")
        end
      end

      context "with a merged request" do
        let(:merge_request) { create(:merge_request, request_merged: true, total_users: 34, total_schemes: 12, total_stock_owners: 8, total_managing_agents: 5, total_lettings_logs: 4, total_sales_logs: 5) }

        it "shows saved users count and doesn't have links to view merge outcomes" do
          expect(merge_request.status).to eq("request_merged")
          expect(page).not_to have_link("View", href: user_outcomes_merge_request_path(merge_request))
          expect(page).to have_content("34 users")
        end

        it "shows saved schemes count and doesn't have links to view merge outcomes" do
          expect(merge_request.status).to eq("request_merged")
          expect(page).not_to have_link("View", href: scheme_outcomes_merge_request_path(merge_request))
          expect(page).to have_content("12 schemes")
        end

        it "shows stock owners and managing agents count and doesn't have links to view merge outcomes" do
          expect(merge_request.status).to eq("request_merged")
          expect(page).not_to have_link("View", href: relationship_outcomes_merge_request_path(merge_request))
          expect(page).to have_content("8 stock owners")
          expect(page).to have_content("5 managing agents")
        end

        it "shows logs counts and doesn't have links to view merge outcomes" do
          expect(merge_request.status).to eq("request_merged")
          expect(page).not_to have_link("View", href: logs_outcomes_merge_request_path(merge_request))
          expect(page).to have_content("4 lettings logs")
          expect(page).to have_content("5 sales logs")
        end
      end

      context "with a processing request" do
        let(:merge_request) { create(:merge_request, processing: true, total_users: 51, total_schemes: 33, total_stock_owners: 15, total_managing_agents: 20) }

        it "shows saved users count and doesn't have links to view merge outcomes" do
          expect(merge_request.status).to eq("processing")
          expect(page).not_to have_link("View", href: user_outcomes_merge_request_path(merge_request))
          expect(page).to have_content("51 users")
        end

        it "shows saved schemes count and doesn't have links to view merge outcomes" do
          expect(merge_request.status).to eq("processing")
          expect(page).not_to have_link("View", href: scheme_outcomes_merge_request_path(merge_request))
          expect(page).to have_content("33 schemes")
        end

        it "shows stock owners and managing agents count and doesn't have links to view merge outcomes" do
          expect(merge_request.status).to eq("processing")
          expect(page).not_to have_link("View", href: relationship_outcomes_merge_request_path(merge_request))
          expect(page).to have_content("15 stock owners")
          expect(page).to have_content("20 managing agents")
        end
      end
    end

    describe "#user_outcomes" do
      let(:merge_request) { create(:merge_request, absorbing_organisation: organisation) }
      let(:organisation_with_no_users) { create(:organisation, name: "Organisation with no users", with_dsa: false) }
      let(:organisation_with_no_users_too) { create(:organisation, name: "Organisation with no users too", with_dsa: false) }
      let(:organisation_with_some_users) { create(:organisation, name: "Organisation with some users", with_dsa: false) }
      let(:organisation_with_some_more_users) { create(:organisation, name: "Organisation with many users", with_dsa: false) }

      before do
        create_list(:user, 4, organisation: organisation_with_some_users)
        create_list(:user, 12, organisation: organisation_with_some_more_users)
        create(:merge_request_organisation, merge_request:, merging_organisation: organisation_with_no_users)
        create(:merge_request_organisation, merge_request:, merging_organisation: organisation_with_no_users_too)
        create(:merge_request_organisation, merge_request:, merging_organisation: organisation_with_some_users)
        create(:merge_request_organisation, merge_request:, merging_organisation: organisation_with_some_more_users)
        get "/merge-request/#{merge_request.id}/user-outcomes", headers:
      end

      it "shows user outcomes after merge" do
        expect(page).to have_link("View all 4 Organisation with some users users (opens in a new tab)", href: users_organisation_path(organisation_with_some_users))
        expect(page).to have_link("View all 12 Organisation with many users users (opens in a new tab)", href: users_organisation_path(organisation_with_some_more_users))
        expect(page).to have_link("View all 3 #{organisation.name} users (opens in a new tab)", href: users_organisation_path(organisation))
        expect(page).to have_content("Organisation with no users and Organisation with no users too have no users.")
        expect(page).to have_content("19 users after merge")
      end
    end

    describe "#scheme_outcomes" do
      let(:merge_request) { create(:merge_request, absorbing_organisation: organisation) }
      let(:organisation_with_no_schemes) { create(:organisation, name: "Organisation with no schemes") }
      let(:organisation_with_no_schemes_too) { create(:organisation, name: "Organisation with no schemes too") }
      let(:organisation_with_some_schemes) { create(:organisation, name: "Organisation with some schemes") }
      let(:organisation_with_some_more_schemes) { create(:organisation, name: "Organisation with many schemes") }

      before do
        create_list(:scheme, 4, owning_organisation: organisation_with_some_schemes)
        create_list(:scheme, 6, owning_organisation: organisation_with_some_more_schemes)
        create_list(:scheme, 3, owning_organisation: organisation)
        create(:merge_request_organisation, merge_request:, merging_organisation: organisation_with_no_schemes)
        create(:merge_request_organisation, merge_request:, merging_organisation: organisation_with_no_schemes_too)
        create(:merge_request_organisation, merge_request:, merging_organisation: organisation_with_some_schemes)
        create(:merge_request_organisation, merge_request:, merging_organisation: organisation_with_some_more_schemes)
        get "/merge-request/#{merge_request.id}/scheme-outcomes", headers:
      end

      it "shows scheme outcomes after merge" do
        expect(page).to have_link("View all 4 Organisation with some schemes schemes (opens in a new tab)", href: schemes_organisation_path(organisation_with_some_schemes))
        expect(page).to have_link("View all 6 Organisation with many schemes schemes (opens in a new tab)", href: schemes_organisation_path(organisation_with_some_more_schemes))
        expect(page).to have_link("View all 3 #{organisation.name} schemes (opens in a new tab)", href: schemes_organisation_path(organisation))
        expect(page).to have_content("Organisation with no schemes and Organisation with no schemes too have no schemes.")
        expect(page).to have_content("13 schemes after merge")
      end
    end

    describe "#logs_outcomes" do
      let(:merge_request) { create(:merge_request, absorbing_organisation: organisation) }
      let(:organisation_with_no_logs) { create(:organisation, name: "Organisation with no logs") }
      let(:organisation_with_no_logs_too) { create(:organisation, name: "Organisation with no logs too") }
      let(:organisation_with_some_logs) { create(:organisation, name: "Organisation with some logs") }

      before do
        create_list(:lettings_log, 4, owning_organisation: organisation_with_some_logs)
        create_list(:sales_log, 2, owning_organisation: organisation_with_some_logs)
        create_list(:lettings_log, 2, owning_organisation: organisation)
        create_list(:sales_log, 3, owning_organisation: organisation)
        create(:merge_request_organisation, merge_request:, merging_organisation: organisation_with_no_logs)
        create(:merge_request_organisation, merge_request:, merging_organisation: organisation_with_no_logs_too)
        create(:merge_request_organisation, merge_request:, merging_organisation: organisation_with_some_logs)
        get "/merge-request/#{merge_request.id}/logs-outcomes", headers:
      end

      it "shows logs outcomes after merge" do
        expect(page).to have_link("View all 4 Organisation with some logs lettings logs (opens in a new tab)", href: lettings_logs_organisation_path(organisation_with_some_logs))
        expect(page).to have_link("View all 2 Organisation with some logs sales logs (opens in a new tab)", href: sales_logs_organisation_path(organisation_with_some_logs))
        expect(page).to have_link("View all 2 #{organisation.name} lettings logs (opens in a new tab)", href: lettings_logs_organisation_path(organisation))
        expect(page).to have_link("View all 3 #{organisation.name} sales logs (opens in a new tab)", href: sales_logs_organisation_path(organisation))
        expect(page).to have_content("Organisation with no logs and Organisation with no logs too have no lettings logs.")
        expect(page).to have_content("Organisation with no logs and Organisation with no logs too have no sales logs.")
        expect(page).to have_content("6 lettings logs after merge")
        expect(page).to have_content("5 sales logs after merge")
      end
    end
  end

  context "when user is signed in with a data coordinator user" do
    before do
      sign_in user
    end

    describe "#merging_organisations" do
      let(:params) { { merge_request: { requesting_organisation_id: other_organisation.id } } }

      context "when creating a new merge request" do
        before do
          post "/merge-request", headers:, params:
        end

        it "does not allow creating a new merge request" do
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when viewing existing merge request" do
        before do
          get "/merge-request/#{merge_request.id}/merging-organisations", headers:, params:
        end

        it "does not allow viewing a merge request" do
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe "#update_merging_organisations" do
      let(:params) { { merge_request: { merging_organisation: other_organisation.id } } }

      context "when updating a merge request with a new organisation" do
        before do
          patch "/merge-request/#{merge_request.id}/merging-organisations", headers:, params:
        end

        it "does not allow updaing a merge request" do
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe "#remove_merging_organisation" do
      let(:params) { { merge_request: { merging_organisation: other_organisation.id } } }

      context "when removing an organisation from merge request" do
        before do
          MergeRequestOrganisation.create!(merge_request_id: merge_request.id, merging_organisation_id: other_organisation.id)
          get "/merge-request/#{merge_request.id}/merging-organisations/remove", headers:, params:
        end

        it "does not allow removing an organisation" do
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe "#update" do
      describe "from absorbing_organisation page" do
        context "when absorbing_organisation_id set to id" do
          let(:merge_request) { MergeRequest.create!(requesting_organisation: organisation) }
          let(:params) do
            { merge_request: { absorbing_organisation_id: other_organisation.id, page: "absorbing_organisation" } }
          end

          before do
            patch "/merge-request/#{merge_request.id}", headers:, params:
          end

          it "does not allow updating absorbing organisation" do
            expect(response).to have_http_status(:not_found)
          end
        end
      end
    end
  end
end
