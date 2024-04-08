require "rails_helper"

RSpec.describe LettingsLogsController, type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:owning_organisation) { user.organisation }
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
  let(:fake_2021_2022_form) { Form.new("spec/fixtures/forms/2021_2022.json") }

  before do
    allow(ENV).to receive(:[])
    allow(ENV).to receive(:[]).with("API_USER").and_return(api_username)
    allow(ENV).to receive(:[]).with("API_KEY").and_return(api_password)
    allow(FormHandler.instance).to receive(:current_lettings_form).and_return(fake_2021_2022_form)
  end

  describe "POST #create" do
    let(:tenant_code) { "T365" }
    let(:age1) { 35 }
    let(:offered) { 12 }
    let(:period) { 2 }
    let(:postcode_full) { "SE11 6TY" }
    let(:in_progress) { "in_progress" }
    let(:completed) { "completed" }

    context "when API" do
      let(:params) do
        {
          "owning_organisation_id": owning_organisation.id,
          "managing_organisation_id": managing_organisation.id,
          "assigned_to_id": user.id,
          "tenancycode": tenant_code,
          "age1": age1,
          "postcode_full": postcode_full,
          "offered": offered,
          "period": period,
        }
      end

      before do
        Timecop.freeze(Time.utc(2022, 2, 8))
        post "/lettings-logs", headers:, params: params.to_json
      end

      after do
        Timecop.unfreeze
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "returns a serialized lettings log" do
        json_response = JSON.parse(response.body)
        expect(json_response.keys).to match_array(LettingsLog.new.attributes.keys)
      end

      it "creates a lettings log with the values passed" do
        json_response = JSON.parse(response.body)
        expect(json_response["tenancycode"]).to eq(tenant_code)
        expect(json_response["age1"]).to eq(age1)
        expect(json_response["postcode_full"]).to eq(postcode_full)
      end

      context "with invalid json parameters" do
        let(:age1) { 2000 }
        let(:offered) { 21 }

        it "validates lettings log parameters" do
          json_response = JSON.parse(response.body)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response["errors"]).to match_array([["offered", [I18n.t("validations.numeric.within_range", field: "Times previously offered since becoming available", min: 0, max: 20)]], ["age1", [I18n.t("validations.numeric.within_range", field: "Lead tenant’s age", min: 16, max: 120)]]])
        end
      end

      context "with a partial lettings log submission" do
        it "marks the record as in_progress" do
          json_response = JSON.parse(response.body)
          expect(json_response["status"]).to eq(in_progress)
        end
      end

      context "with a complete lettings log submission" do
        let(:org_params) do
          {
            "lettings_log" => {
              "owning_organisation_id" => owning_organisation.id,
              "managing_organisation_id" => managing_organisation.id,
              "assigned_to_id" => user.id,
            },
          }
        end
        let(:lettings_log_params) { JSON.parse(File.open("spec/fixtures/complete_lettings_log.json").read) }
        let(:params) do
          lettings_log_params.merge(org_params) { |_k, a_val, b_val| a_val.merge(b_val) }
        end

        xit "marks the record as completed" do
          json_response = JSON.parse(response.body)

          expect(json_response).not_to have_key("errors")
          expect(json_response["status"]).to eq(completed)
        end
      end

      context "with a request containing invalid credentials" do
        let(:basic_credentials) do
          ActionController::HttpAuthentication::Basic.encode_credentials(api_username, "Oops")
        end

        it "returns 401" do
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    context "when UI" do
      let(:user) { FactoryBot.create(:user) }
      let(:headers) { { "Accept" => "text/html" } }

      before do
        RequestHelper.stub_http_requests
        sign_in user
        post "/lettings-logs", headers:
      end

      it "tracks who created the record" do
        created_id = response.location.match(/[0-9]+/)[0]
        whodunnit_actor = LettingsLog.find_by(id: created_id).versions.last.actor
        expect(whodunnit_actor).to be_a(User)
        expect(whodunnit_actor.id).to eq(user.id)
      end

      context "when creating a new log" do
        context "when the user is support" do
          let(:organisation) { FactoryBot.create(:organisation) }
          let(:support_user) { FactoryBot.create(:user, :support, organisation:) }

          before do
            allow(support_user).to receive(:need_two_factor_authentication?).and_return(false)
            sign_in support_user
            post "/lettings-logs", headers:
          end

          it "sets the managing org and stock-owning org as nil" do
            created_id = response.location.match(/[0-9]+/)[0]
            lettings_log = LettingsLog.find_by(id: created_id)
            expect(lettings_log.owning_organisation).to eq(nil)
            expect(lettings_log.managing_organisation).to eq(nil)
          end
        end

        context "when the user is not support" do
          context "when the user's org holds stock" do
            let(:organisation) { FactoryBot.create(:organisation, name: "User org", holds_own_stock: true) }
            let(:user) { FactoryBot.create(:user, :data_coordinator, organisation:) }

            before do
              RequestHelper.stub_http_requests
              sign_in user
              post "/lettings-logs", headers:
            end

            it "sets the managing org and stock-owning org as the user's org" do
              created_id = response.location.match(/[0-9]+/)[0]
              lettings_log = LettingsLog.find_by(id: created_id)
              expect(lettings_log.owning_organisation.name).to eq("User org")
              expect(lettings_log.managing_organisation.name).to eq("User org")
            end
          end

          context "when the user's org doesn't hold stock" do
            let(:organisation) { FactoryBot.create(:organisation, name: "User org", holds_own_stock: false) }
            let(:user) { FactoryBot.create(:user, :data_coordinator, organisation:) }

            before do
              RequestHelper.stub_http_requests
              sign_in user
              post "/lettings-logs", headers:
            end

            it "sets the managing org as the user's org but the stock-owning org as nil" do
              created_id = response.location.match(/[0-9]+/)[0]
              lettings_log = LettingsLog.find_by(id: created_id)
              expect(lettings_log.owning_organisation).to eq(nil)
              expect(lettings_log.managing_organisation.name).to eq("User org")
            end
          end
        end
      end
    end
  end

  describe "GET" do
    let(:page) { Capybara::Node::Simple.new(response.body) }
    let(:user) { FactoryBot.create(:user) }
    let(:organisation) { user.organisation }
    let(:other_user) { FactoryBot.create(:user) }
    let(:other_organisation) { other_user.organisation }
    let!(:lettings_log) do
      FactoryBot.create(
        :lettings_log,
        assigned_to: user,
        tenancycode: "LC783",
      )
    end
    let!(:unauthorized_lettings_log) do
      FactoryBot.create(
        :lettings_log,
        assigned_to: other_user,
        tenancycode: "UA984",
      )
    end
    let!(:pending_lettings_log) do
      FactoryBot.create(
        :lettings_log,
        assigned_to: user,
        tenancycode: "LC999",
        status: "pending",
        skip_update_status: true,
      )
    end

    context "when displaying a collection of logs" do
      let(:headers) { { "Accept" => "text/html" } }

      context "when you visit the index page" do
        before do
          allow(user).to receive(:need_two_factor_authentication?).and_return(false)
          sign_in user
        end

        it "does not have a button for creating sales logs" do
          get lettings_logs_path, headers:, params: {}
          page.assert_selector(".govuk-button", text: "Create a new sales log", count: 0)
          page.assert_selector(".govuk-button", text: "Create a new lettings log", count: 1)
        end

        context "and the state of filters and search is such that display_delete_logs returns true" do
          before do
            allow_any_instance_of(LogListHelper).to receive(:display_delete_logs?).and_return(true) # rubocop:disable RSpec/AnyInstance
          end

          it "displays the delete logs button with the correct path if there are logs visibile" do
            get lettings_logs_path(search: "LC783")
            expect(page).to have_link "Delete logs", href: delete_logs_lettings_logs_path(search: "LC783")
          end

          it "does not display the delete logs button if there are no logs displayed" do
            LettingsLog.destroy_all
            get lettings_logs_path
            expect(page).not_to have_link "Delete logs"
          end
        end

        context "and the state of filters and search is such that display_delete_logs returns false" do
          before do
            allow_any_instance_of(LogListHelper).to receive(:display_delete_logs?).and_return(false) # rubocop:disable RSpec/AnyInstance
          end

          it "does not display the delete logs button even if there are logs displayed" do
            get lettings_logs_path
            expect(page).to have_selector "article.app-log-summary"
            expect(page).not_to have_link "Delete logs"
          end
        end

        context "and organisation has absorbed organisations" do
          let(:merged_organisation) { FactoryBot.create(:organisation) }

          before do
            merged_organisation.update!(absorbing_organisation: organisation, merge_date: Time.zone.yesterday)
          end

          it "shows organisation labels" do
            get "/lettings-logs", headers:, params: {}
            expect(page).to have_content("Owned by")
            expect(page).to have_content("Managed by")
          end
        end

        context "and organisation does not own stock or have valid stock owners" do
          before do
            organisation.update!(holds_own_stock: false)
          end

          it "hides button to create a new log" do
            get "/lettings-logs"
            expect(page).not_to have_content("Create a new lettings log")
          end

          context "with coordinator user" do
            let(:user) { FactoryBot.create(:user, :data_coordinator) }

            it "displays a banner exlaining why create new logs button is missing" do
              get "/lettings-logs", headers:, params: {}
              expect(page).to have_css(".govuk-notification-banner")
              expect(page).to have_content("Your organisation does not own stock.")
              expect(page).to have_link("add a stock owner", href: /stock-owners\/add/)
              expect(page).not_to have_link("users page", href: /users/)
            end
          end

          context "with provider user" do
            let(:user) { FactoryBot.create(:user, :data_provider) }

            it "displays a banner exlaining why create new logs button is missing" do
              get "/lettings-logs", headers:, params: {}
              expect(page).to have_css(".govuk-notification-banner")
              expect(page).to have_content("Your organisation does not own stock.")
              expect(page).not_to have_link("add a stock owner", href: /stock-owners\/add/)
              expect(page).to have_link("users page", href: /users/)
            end
          end
        end

        context "and organisation owns stock" do
          before do
            organisation.update!(holds_own_stock: true)
          end

          it "displays button to create a new log" do
            get "/lettings-logs"
            expect(page).to have_content("Create a new lettings log")
          end

          it "does not display the missing stock owners banner" do
            get "/lettings-logs", headers:, params: {}
            expect(page).not_to have_css(".govuk-notification-banner")
            expect(page).not_to have_content("Your organisation does not own stock.")
            expect(page).not_to have_link("add a stock owner", href: /stock-owners\/add/)
            expect(page).not_to have_link("users page", href: /users/)
          end
        end
      end

      context "when the user is a customer support user" do
        let(:user) { FactoryBot.create(:user, :support) }

        before do
          allow(user).to receive(:need_two_factor_authentication?).and_return(false)
          sign_in user
        end

        it "does have organisation values" do
          get "/lettings-logs", headers:, params: {}
          expect(page).to have_content("Owned by")
          expect(page).to have_content("Managed by")
        end

        it "shows lettings logs for all organisations" do
          get "/lettings-logs", headers:, params: {}
          expect(page).to have_content("LC783")
          expect(page).to have_content("UA984")
          expect(page).not_to have_content(pending_lettings_log.tenancycode)
        end

        it "displays CSV download links with the correct paths" do
          get "/lettings-logs", headers:, params: {}
          expect(page).to have_link("Download (CSV)", href: "/lettings-logs/csv-download?codes_only=false")
          expect(page).to have_link("Download (CSV, codes only)", href: "/lettings-logs/csv-download?codes_only=true")
        end

        context "when there are duplicate logs for this user" do
          before do
            FactoryBot.create_list(:lettings_log, 2, :duplicate, owning_organisation: user.organisation, assigned_to: user)
          end

          it "does not show a notification banner even if there are duplicate logs for this user" do
            get lettings_logs_path
            expect(page).not_to have_content "duplicate logs"
            expect(page).not_to have_link "Review logs"
          end
        end

        context "when there are no logs in the database" do
          before do
            LettingsLog.destroy_all
          end

          it "does not display CSV download links" do
            get "/lettings-logs", headers:, params: {}
            expect(page).not_to have_link("Download (CSV)")
            expect(page).not_to have_link("Download (CSV, codes only)")
          end

          it "page has correct title" do
            get "/lettings-logs", headers:, params: {}
            expect(page).to have_title("Lettings logs - Submit social housing lettings and sales data (CORE) - GOV.UK")
          end
        end

        context "when filtering" do
          before do
            Timecop.freeze(Time.utc(2024, 3, 3))
            Singleton.__init__(FormHandler)
          end

          after do
            Timecop.return
            Singleton.__init__(FormHandler)
          end

          context "with status filter" do
            let(:organisation_2) { FactoryBot.create(:organisation) }
            let(:user_2) { FactoryBot.create(:user, organisation: organisation_2) }
            let!(:in_progress_lettings_log) do
              FactoryBot.create(:lettings_log, :in_progress,
                                owning_organisation: organisation,
                                managing_organisation: organisation,
                                assigned_to: user)
            end
            let!(:completed_lettings_log) do
              FactoryBot.create(:lettings_log, :completed,
                                owning_organisation: organisation_2,
                                managing_organisation: organisation,
                                assigned_to: user_2)
            end

            it "shows lettings logs for multiple selected statuses" do
              get "/lettings-logs?status[]=in_progress&status[]=completed", headers:, params: {}
              expect(page).to have_link(in_progress_lettings_log.id.to_s)
              expect(page).to have_link(completed_lettings_log.id.to_s)
            end

            it "shows lettings logs for one selected status" do
              get "/lettings-logs?status[]=in_progress", headers:, params: {}
              expect(page).to have_link(in_progress_lettings_log.id.to_s)
              expect(page).not_to have_link(completed_lettings_log.id.to_s)
            end

            it "filters on owning organisation" do
              get "/lettings-logs?owning_organisation[]=#{organisation_2.id}", headers:, params: {}
              expect(page).to have_link(completed_lettings_log.id.to_s)
              expect(page).not_to have_link(in_progress_lettings_log.id.to_s)
            end

            it "filtering on owning organisation does not return managed orgs" do
              get "/lettings-logs?owning_organisation[]=#{organisation.id}", headers:, params: {}
              expect(page).not_to have_link(completed_lettings_log.id.to_s)
              expect(page).to have_link(in_progress_lettings_log.id.to_s)
            end

            it "does not reset the filters" do
              get "/lettings-logs?status[]=in_progress", headers:, params: {}
              expect(page).to have_link(in_progress_lettings_log.id.to_s)
              expect(page).not_to have_link(completed_lettings_log.id.to_s)

              get "/lettings-logs", headers:, params: {}
              expect(page).to have_link(in_progress_lettings_log.id.to_s)
              expect(page).not_to have_link(completed_lettings_log.id.to_s)
            end
          end

          context "with year filter" do
            around do |example|
              Timecop.freeze(2022, 3, 1) do
                example.run
              end
            end

            let!(:lettings_log_2021) do
              lettings_log = FactoryBot.build(:lettings_log, :in_progress,
                                              assigned_to: user,
                                              startdate: Time.zone.local(2022, 3, 1))
              lettings_log.save!(validate: false)
              lettings_log
            end

            let!(:lettings_log_2022) do
              lettings_log = FactoryBot.build(:lettings_log, :completed,
                                              owning_organisation: organisation,
                                              mrcdate: Time.zone.local(2022, 2, 1),
                                              startdate: Time.zone.local(2022, 12, 1),
                                              tenancy: 6,
                                              managing_organisation: organisation)
              lettings_log.save!(validate: false)
              lettings_log
            end

            it "shows lettings logs for multiple selected years" do
              get "/lettings-logs?years[]=2021&years[]=2022", headers:, params: {}
              expect(page).to have_link(lettings_log_2021.id.to_s)
              expect(page).to have_link(lettings_log_2022.id.to_s)
            end

            it "shows lettings logs for one selected year" do
              get "/lettings-logs?years[]=2021", headers:, params: {}
              expect(page).to have_link(lettings_log_2021.id.to_s)
              expect(page).not_to have_link(lettings_log_2022.id.to_s)
            end
          end

          context "with year and status filter" do
            before do
              Timecop.freeze(Time.zone.local(2022, 3, 1))
              Singleton.__init__(FormHandler)
              lettings_log_2021.update!(startdate: Time.zone.local(2022, 3, 1))
              Timecop.freeze(Time.zone.local(2022, 12, 1))
            end

            after do
              Timecop.unfreeze
            end

            let!(:lettings_log_2021) do
              FactoryBot.create(:lettings_log, :in_progress,
                                owning_organisation: organisation,
                                managing_organisation: organisation,
                                assigned_to: user)
            end
            let!(:lettings_log_2022) do
              FactoryBot.create(:lettings_log, :completed,
                                owning_organisation: organisation,
                                mrcdate: Time.zone.local(2022, 2, 1),
                                startdate: Time.zone.local(2022, 12, 1),
                                voiddate: Time.zone.local(2022, 2, 1),
                                tenancy: 6,
                                managing_organisation: organisation,
                                assigned_to: user)
            end
            let!(:lettings_log_2022_in_progress) do
              FactoryBot.build(:lettings_log, :in_progress,
                               owning_organisation: organisation,
                               mrcdate: Time.zone.local(2022, 2, 1),
                               startdate: Time.zone.local(2022, 12, 1),
                               tenancy: 6,
                               managing_organisation: organisation,
                               tenancycode: nil,
                               assigned_to: user)
            end

            it "shows lettings logs for multiple selected statuses and years" do
              get "/lettings-logs?years[]=2021&years[]=2022&status[]=in_progress&status[]=completed", headers:, params: {}
              expect(page).to have_link(lettings_log_2021.id.to_s)
              expect(page).to have_link(lettings_log_2022.id.to_s)
              expect(page).to have_link(lettings_log_2022_in_progress.id.to_s)
            end

            it "shows lettings logs for one selected status" do
              get "/lettings-logs?years[]=2022&status[]=in_progress", headers:, params: {}
              expect(page).to have_link(lettings_log_2022_in_progress.id.to_s)
              expect(page).not_to have_link(lettings_log_2021.id.to_s)
              expect(page).not_to have_link(lettings_log_2022.id.to_s)
            end
          end

          context "with bulk_upload_id filter" do
            before do
              Timecop.freeze(2023, 4, 1)
              Singleton.__init__(FormHandler)
            end

            after do
              Timecop.unfreeze
              Singleton.__init__(FormHandler)
            end

            context "with bulk upload that belongs to current user" do
              let(:organisation) { create(:organisation) }

              let(:user) { create(:user, organisation:) }
              let(:bulk_upload) { create(:bulk_upload, :lettings, user:) }

              let!(:included_log) { create(:lettings_log, :completed, age1: nil, bulk_upload:, owning_organisation: organisation) }
              let!(:excluded_log) { create(:lettings_log, :in_progress, owning_organisation: organisation, tenancycode: "fake_code") }

              before do
                create(:bulk_upload_error, bulk_upload:, col: "A", row: 1)
              end

              it "returns logs only associated with the bulk upload" do
                get "/lettings-logs?bulk_upload_id[]=#{bulk_upload.id}"

                expect(page).to have_content(included_log.id)
                expect(page).not_to have_content(excluded_log.tenancycode)
              end

              it "dislays bulk uplaoad header" do
                get "/lettings-logs?bulk_upload_id[]=#{bulk_upload.id}"
                expect(page).to have_content("Fix the errors from this bulk upload")
              end

              it "displays filter" do
                get "/lettings-logs?bulk_upload_id[]=#{bulk_upload.id}"
                expect(page).to have_content("With logs from bulk upload")
              end

              it "hides collection year filter" do
                get "/lettings-logs?bulk_upload_id[]=#{bulk_upload.id}"
                expect(page).not_to have_content("Collection year")
              end

              it "hides status filter" do
                get "/lettings-logs?bulk_upload_id[]=#{bulk_upload.id}"
                expect(page).not_to have_content("Status")
              end

              it "has correct filter count and clear button" do
                get "/lettings-logs?bulk_upload_id[]=#{bulk_upload.id}"
                expect(page).to have_content("1 filter applied")
                expect(page).to have_content("Clear")
              end

              it "hides button to create a new log" do
                get "/lettings-logs?bulk_upload_id[]=#{bulk_upload.id}"
                expect(page).not_to have_content("Create a new lettings log")
              end

              it "displays card with help info" do
                get "/lettings-logs?bulk_upload_id[]=#{bulk_upload.id}"
                expect(page).to have_content("You have uploaded 1 log. There are errors in 1 log, and 1 error in total. Select the log to fix the errors.")
              end

              it "displays dynamic error number" do
                included_log.update!(age2: nil)
                get "/lettings-logs?bulk_upload_id[]=#{bulk_upload.id}"
                expect(page).to have_content("You have uploaded 1 log. There are errors in 1 log, and 2 errors in total. Select the log to fix the errors.")
              end

              it "displays meta info about the bulk upload" do
                get "/lettings-logs?bulk_upload_id[]=#{bulk_upload.id}"
                expect(page).to have_content(bulk_upload.filename)
                expect(page).to have_content(bulk_upload.created_at.to_fs(:govuk_date_and_time))
              end
            end

            context "with bulk upload that belongs to another user" do
              let(:organisation) { create(:organisation) }

              let(:user) { create(:user, organisation:) }
              let(:other_user) { create(:user, organisation:) }
              let(:bulk_upload) { create(:bulk_upload, :lettings, user: other_user) }

              before do
                create(:lettings_log, bulk_upload:, owning_organisation: organisation, tenancycode: "fake_code_1")
                create(:lettings_log, owning_organisation: organisation, tenancycode: "fake_code_2")
              end

              it "does not return any logs" do
                get "/lettings-logs?bulk_upload_id[]=#{bulk_upload.id}"

                expect(page).not_to have_content("fake_code_1")
                expect(page).not_to have_content("fake_code_2")
              end
            end

            context "when bulk upload has been resolved" do
              let(:organisation) { create(:organisation) }

              let(:user) { create(:user, organisation:) }
              let(:bulk_upload) { create(:bulk_upload, :lettings, user:) }

              it "redirects to resume the bulk upload" do
                get "/lettings-logs?bulk_upload_id[]=#{bulk_upload.id}"

                expect(response).to redirect_to(resume_bulk_upload_lettings_result_path(bulk_upload))
              end

              it "allows returning to all logs" do
                get "/lettings-logs?bulk_upload_id[]=#{bulk_upload.id}"

                follow_redirect!
                expect(page).to have_link("Return to lettings logs", href: clear_filters_path(filter_type: "lettings_logs"))
              end
            end
          end

          context "without bulk_upload_id" do
            it "does not display filter" do
              get "/lettings-logs"
              expect(page).not_to have_content("With logs from bulk upload")
            end

            it "displays button to create a new log" do
              get "/lettings-logs"
              expect(page).to have_content("Create a new lettings log")
            end

            it "does not display card with help info" do
              get "/lettings-logs"
              expect(page).not_to have_content("The following logs are from your recent bulk upload")
            end
          end
        end
      end

      context "when the user is a data provider" do
        before do
          sign_in user
        end

        it "does not have organisation columns" do
          get "/lettings-logs", headers:, params: {}
          expect(page).not_to have_content("Owning organisation")
          expect(page).not_to have_content("Managing organisation")
        end

        it "displays standard CSV download link only, with the correct path" do
          get "/lettings-logs", headers:, params: {}
          expect(page).to have_link("Download (CSV)", href: "/lettings-logs/csv-download?codes_only=false")
          expect(page).not_to have_link("Download (CSV, codes only)")
        end

        it "does not display CSV download links if there are no logs" do
          LettingsLog.destroy_all
          get "/lettings-logs", headers:, params: {}
          expect(page).not_to have_link("Download (CSV)")
          expect(page).not_to have_link("Download (CSV, codes only)")
        end

        it "does not show a notification banner even if there are duplicate logs for this user" do
          get lettings_logs_path
          expect(page).not_to have_content "duplicate logs"
          expect(page).not_to have_link "Review logs"
        end

        context "when using a search query" do
          let(:logs) { FactoryBot.create_list(:lettings_log, 3, :completed, owning_organisation: user.organisation, assigned_to: user) }
          let(:log_to_search) { FactoryBot.create(:lettings_log, :completed, owning_organisation: user.organisation, assigned_to: user) }
          let(:log_total_count) { LettingsLog.where(owning_organisation: user.organisation).count }

          before do
            Timecop.freeze(Time.utc(2024, 3, 3))
            Singleton.__init__(FormHandler)
          end

          after do
            Timecop.return
            Singleton.__init__(FormHandler)
          end

          it "has search results in the title" do
            get "/lettings-logs?search=#{log_to_search.id}", headers:, params: {}
            expect(page).to have_title("Lettings logs (1 logs matching ‘#{log_to_search.id}’) - Submit social housing lettings and sales data (CORE) - GOV.UK")
          end

          it "shows lettings logs matching the id" do
            get "/lettings-logs?search=#{log_to_search.id}", headers:, params: {}
            expect(page).to have_link(log_to_search.id.to_s)
            logs.each do |log|
              expect(page).not_to have_link(log.id.to_s)
            end
          end

          it "shows lettings logs matching the tenant code" do
            get "/lettings-logs?search=#{log_to_search.tenancycode}", headers:, params: {}
            expect(page).to have_link(log_to_search.id.to_s)
            logs.each do |log|
              expect(page).not_to have_link(log.id.to_s)
            end
          end

          it "shows lettings logs matching the property reference" do
            get "/lettings-logs?search=#{log_to_search.propcode}", headers:, params: {}
            expect(page).to have_link(log_to_search.id.to_s)
            logs.each do |log|
              expect(page).not_to have_link(log.id.to_s)
            end
          end

          it "shows lettings logs matching the property postcode" do
            get "/lettings-logs?search=#{log_to_search.postcode_full}", headers:, params: {}
            expect(page).to have_link(log_to_search.id.to_s)
            logs.each do |log|
              expect(page).not_to have_link(log.id.to_s)
            end
          end

          it "includes the search on the CSV links" do
            search_term = "foo"
            FactoryBot.create(:lettings_log, assigned_to: user, owning_organisation: user.organisation, tenancycode: "foo")
            get "/lettings-logs?search=#{search_term}", headers:, params: {}
            download_link = page.find_link("Download (CSV)")
            download_link_params = CGI.parse(URI.parse(download_link[:href]).query)
            expect(download_link_params).to include("search" => [search_term])
          end

          context "when more than one results with matching postcode" do
            let!(:matching_postcode_log) { FactoryBot.create(:lettings_log, :completed, owning_organisation: user.organisation, postcode_full: log_to_search.postcode_full) }

            it "displays all matching logs" do
              get "/lettings-logs?search=#{log_to_search.postcode_full}", headers:, params: {}
              expect(page).to have_link(log_to_search.id.to_s)
              expect(page).to have_link(matching_postcode_log.id.to_s)
              logs.each do |log|
                expect(page).not_to have_link(log.id.to_s)
              end
            end
          end

          context "when there are more than 1 page of search results" do
            let(:postcode) { "XX11YY" }
            let(:logs) { FactoryBot.create_list(:lettings_log, 30, :completed, owning_organisation: user.organisation, postcode_full: postcode, assigned_to: user) }
            let(:log_total_count) { LettingsLog.where(owning_organisation: user.organisation).count }

            it "has title with pagination details for page 1" do
              get "/lettings-logs?search=#{logs[0].postcode_full}", headers:, params: {}
              expect(page).to have_title("Lettings logs (#{logs.count} logs matching ‘#{postcode}’) (page 1 of 2) - Submit social housing lettings and sales data (CORE) - GOV.UK")
            end

            xit "has title with pagination details for page 2" do
              get "/lettings-logs?search=#{logs[0].postcode_full}&page=2", headers:, params: {}
              expect(page).to have_title("Lettings logs (#{logs.count} logs matching ‘#{postcode}’) (page 2 of 2) - Submit social housing lettings and sales data (CORE) - GOV.UK")
            end
          end

          context "when search query doesn't match any logs" do
            it "doesn't display any logs" do
              get "/lettings-logs?search=foobar", headers:, params: {}
              logs.each do |log|
                expect(page).not_to have_link(log.id.to_s)
              end
              expect(page).not_to have_link(log_to_search.id.to_s)
            end
          end

          context "when search query is empty" do
            it "doesn't display any logs" do
              get "/lettings-logs?search=", headers:, params: {}
              logs.each do |log|
                expect(page).not_to have_link(log.id.to_s)
              end
              expect(page).not_to have_link(log_to_search.id.to_s)
            end
          end

          context "when search and filter is present" do
            let(:matching_postcode) { log_to_search.postcode_full }
            let(:matching_status) { "in_progress" }
            let!(:log_matching_filter_and_search) { FactoryBot.create(:lettings_log, :in_progress, owning_organisation: user.organisation, postcode_full: matching_postcode, assigned_to: user) }

            it "shows only logs matching both search and filters" do
              get "/lettings-logs?search=#{matching_postcode}&status[]=#{matching_status}", headers:, params: {}
              expect(page).to have_link(log_matching_filter_and_search.id.to_s)
              expect(page).not_to have_link(log_to_search.id.to_s)
              logs.each do |log|
                expect(page).not_to have_link(log.id.to_s)
              end
            end
          end
        end

        context "when there are fewer than 20 logs" do
          before do
            get "/lettings-logs", headers:, params: {}
          end

          it "shows a table of logs" do
            expect(CGI.unescape_html(response.body)).to match(/<article class="app-log-summary">/)
            expect(CGI.unescape_html(response.body)).to match(/lettings-logs/)
          end

          it "only shows lettings logs for your organisation" do
            expected_case_row_log = "Log #{lettings_log.id}"
            unauthorized_case_row_log = "Log #{unauthorized_lettings_log.id}"
            expect(CGI.unescape_html(response.body)).to include(expected_case_row_log)
            expect(CGI.unescape_html(response.body)).not_to include(unauthorized_case_row_log)
          end

          it "shows the formatted created at date for each log" do
            formatted_date = lettings_log.created_at.to_formatted_s(:govuk_date)
            expect(CGI.unescape_html(response.body)).to include(formatted_date)
          end

          it "shows the log's status" do
            expect(CGI.unescape_html(response.body)).to include(lettings_log.status.humanize)
          end

          it "shows the total log count" do
            expect(CGI.unescape_html(response.body)).to match("<strong>1</strong> total logs")
          end

          it "does not show the pagination links" do
            expect(page).not_to have_link("Previous")
            expect(page).not_to have_link("Next")
          end

          it "does not show the pagination result line" do
            expect(CGI.unescape_html(response.body)).not_to match("Showing <b>1</b> to <b>20</b> of <b>26</b> logs")
          end

          it "does not have pagination in the title" do
            expect(page).to have_title("Lettings logs - Submit social housing lettings and sales data (CORE) - GOV.UK")
          end

          it "shows the CSV download link" do
            expect(page).to have_link("Download (CSV)", href: "/lettings-logs/csv-download?codes_only=false")
          end

          it "does not show the organisation filter" do
            expect(page).not_to have_field("organisation-field")
          end
        end

        context "when the user is a customer support user" do
          let(:user) { FactoryBot.create(:user, :support) }
          let(:org_1) { FactoryBot.create(:organisation) }
          let(:org_2) { FactoryBot.create(:organisation) }
          let(:tenant_code_1) { "TC5638" }
          let(:tenant_code_2) { "TC8745" }

          before do
            FactoryBot.create(:lettings_log, :in_progress, owning_organisation: org_1, tenancycode: tenant_code_1, assigned_to: user)
            FactoryBot.create(:lettings_log, :in_progress, owning_organisation: org_2, tenancycode: tenant_code_2)
            allow(user).to receive(:need_two_factor_authentication?).and_return(false)
            sign_in user
          end

          it "shows all logs by default" do
            get "/lettings-logs", headers:, params: {}
            expect(page).to have_content(tenant_code_1)
            expect(page).to have_content(tenant_code_2)
          end

          context "when filtering by a specific user" do
            it "only show the selected user's logs" do
              get "/lettings-logs?assigned_to=specific_user&user=#{user.id}", headers:, params: {}
              expect(page).to have_content(tenant_code_1)
              expect(page).not_to have_content(tenant_code_2)
            end
          end

          context "when the support user has filtered by organisation, then switches back to all organisations" do
            it "shows all organisations" do
              get "http://localhost:3000/lettings-logs?%5Byears%5D%5B%5D=&%5Bstatus%5D%5B%5D=&assigned_to=all&organisation_select=all&organisation=#{org_1.id}", headers:, params: {}
              expect(page).to have_content(tenant_code_1)
              expect(page).to have_content(tenant_code_2)
            end
          end
        end

        context "when there are more than 20 logs" do
          before do
            FactoryBot.create_list(:lettings_log, 25, assigned_to: user)
          end

          context "when on the first page" do
            before do
              get "/lettings-logs", headers:, params: {}
            end

            it "has pagination links" do
              expect(page).not_to have_content("Previous")
              expect(page).not_to have_link("Previous")
              expect(page).to have_content("Next")
              expect(page).to have_link("Next")
            end

            it "shows which logs are being shown on the current page" do
              expect(CGI.unescape_html(response.body)).to match("Showing <b>1</b> to <b>20</b> of <b>26</b> logs")
            end

            it "has pagination in the title" do
              expect(page).to have_title("Lettings logs (page 1 of 2) - Submit social housing lettings and sales data (CORE) - GOV.UK")
            end
          end

          xcontext "when on the second page" do
            before do
              get "/lettings-logs?page=2", headers:, params: {}
            end

            it "shows the total log count" do
              expect(CGI.unescape_html(response.body)).to match("<strong>26</strong> total logs")
            end

            it "has pagination links" do
              expect(page).to have_content("Previous")
              expect(page).to have_link("Previous")
              expect(page).not_to have_content("Next")
              expect(page).not_to have_link("Next")
            end

            it "shows which logs are being shown on the current page" do
              expect(CGI.unescape_html(response.body)).to match("Showing <b>21</b> to <b>26</b> of <b>26</b> logs")
            end

            it "has pagination in the title" do
              expect(page).to have_title("Lettings logs (page 2 of 2) - Submit social housing lettings and sales data (CORE) - GOV.UK")
            end
          end
        end

        context "and there are duplicate logs for this user" do
          let!(:duplicate_logs) { FactoryBot.create_list(:lettings_log, 2, :duplicate, owning_organisation: user.organisation, assigned_to: user) }

          it "displays a notification banner with a link to review logs" do
            get lettings_logs_path
            expect(page).to have_content "duplicate logs"
            expect(page).to have_link "Review logs", href: "/duplicate-logs?referrer=duplicate_logs_banner"
          end

          context "when there is one set of duplicates" do
            it "displays the correct copy in the banner" do
              get lettings_logs_path
              expect(page).to have_content "There is 1 set of duplicate logs"
            end

            context "when the set is not editable" do
              before do
                duplicate_logs.each do |log|
                  log.startdate = Time.zone.now - 3.years
                  log.save!(validate: false)
                end
              end

              it "does not display the banner" do
                get lettings_logs_path
                expect(page).not_to have_content "duplicate logs"
              end
            end
          end

          context "when there are multiple sets of duplicates" do
            before do
              Timecop.freeze(Time.zone.local(2024, 3, 1))
              Singleton.__init__(FormHandler)
              FactoryBot.create_list(:sales_log, 2, :duplicate, owning_organisation: user.organisation, assigned_to: user)
            end

            after do
              Timecop.return
              Singleton.__init__(FormHandler)
            end

            it "displays the correct copy in the banner" do
              get lettings_logs_path
              expect(page).to have_content "There are 2 sets of duplicate logs"
              expect(page).to have_link "Review logs", href: "/duplicate-logs?referrer=duplicate_logs_banner"
            end

            context "when one set is not editable" do
              before do
                log = duplicate_logs.first
                log.startdate = Time.zone.now - 3.years
                log.save!(validate: false)
              end

              it "displays the correct copy in the banner" do
                get lettings_logs_path
                expect(page).to have_content "There is 1 set of duplicate logs"
                expect(page).to have_link "Review logs", href: "/duplicate-logs?referrer=duplicate_logs_banner"
              end
            end
          end
        end
      end
    end

    context "when requesting a specific lettings log" do
      let!(:completed_lettings_log) { FactoryBot.create(:lettings_log, :completed, owning_organisation: user.organisation, managing_organisation: user.organisation, assigned_to: user) }
      let(:id) { completed_lettings_log.id }

      before do
        get "/lettings-logs/#{id}", headers:
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "returns a serialized lettings log" do
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq(completed_lettings_log.status)
      end

      context "when requesting an invalid lettings log id" do
        let(:id) { (LettingsLog.order(:id).last&.id || 0) + 1 }

        it "returns 404" do
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when viewing a pending log" do
        let(:completed_lettings_log) do
          FactoryBot.create(
            :lettings_log,
            :completed,
            owning_organisation: user.organisation,
            managing_organisation: user.organisation,
            assigned_to: user,
            status: "pending",
            skip_update_status: true,
          )
        end

        it "returns 404" do
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when editing a lettings log" do
        let(:headers) { { "Accept" => "text/html" } }

        context "with a user that is not signed in" do
          it "does not let the user get lettings log tasklist pages they don't have access to" do
            get "/lettings-logs/#{lettings_log.id}", headers:, params: {}
            expect(response).to redirect_to("/account/sign-in")
          end
        end

        context "with a signed in user" do
          before do
            Timecop.freeze(2021, 4, 1)
            Singleton.__init__(FormHandler)
            completed_lettings_log.update!(startdate: Time.zone.local(2021, 4, 1), voiddate: Time.zone.local(2021, 4, 1), mrcdate: Time.zone.local(2021, 4, 1))
            completed_lettings_log.reload
          end

          context "with lettings logs that are owned or managed by your organisation" do
            before do
              sign_in user
              get "/lettings-logs/#{lettings_log.id}", headers:, params: {}
            end

            after do
              Timecop.return
              Singleton.__init__(FormHandler)
            end

            it "shows the tasklist for lettings logs you have access to" do
              expect(response.body).to match("Log")
              expect(response.body).to match(lettings_log.id.to_s)
            end

            it "displays a section status for a lettings log" do
              assert_select ".govuk-tag", text: /Not started/, count: 6
              assert_select ".govuk-tag", text: /In progress/, count: 2
              assert_select ".govuk-tag", text: /Completed/, count: 0
              assert_select ".govuk-tag", text: /Cannot start yet/, count: 1
            end

            it "displays a link to update the log for currently editable logs" do
              completed_lettings_log.update!(startdate: Time.zone.local(2021, 4, 1), tenancylength: nil)
              completed_lettings_log.reload

              get "/lettings-logs/#{completed_lettings_log.id}", headers:, params: {}
              expect(completed_lettings_log.form.new_logs_end_date).to eq(Time.zone.local(2022, 11, 20))
              expect(completed_lettings_log.status).to eq("completed")
              expect(page).to have_link("review and make changes to this log", href: "/lettings-logs/#{completed_lettings_log.id}/review")
            end
          end

          context "with lettings logs from a closed collection period before the previous collection" do
            before do
              sign_in user
              Timecop.return
              Singleton.__init__(FormHandler)
              get "/lettings-logs/#{completed_lettings_log.id}", headers:, params: {}
            end

            it "redirects to review page" do
              expect(response).to redirect_to("/lettings-logs/#{completed_lettings_log.id}/review")
            end
          end

          context "with lettings logs from a closed previous collection period" do
            before do
              sign_in user
              Timecop.freeze(2023, 2, 1)
              Singleton.__init__(FormHandler)
              get "/lettings-logs/#{completed_lettings_log.id}", headers:, params: {}
            end

            after do
              Timecop.return
              Singleton.__init__(FormHandler)
            end

            it "redirects to review page" do
              expect(response).to redirect_to("/lettings-logs/#{completed_lettings_log.id}/review")
            end

            it "displays a closed collection window message for previous collection year logs" do
              get "/lettings-logs/#{completed_lettings_log.id}", headers:, params: {}
              expect(completed_lettings_log.form.new_logs_end_date).to eq(Time.zone.local(2022, 11, 20))
              expect(completed_lettings_log.status).to eq("completed")
              follow_redirect!
              expect(page).to have_content("This log is from the 2021/2022 collection window, which is now closed.")
            end
          end

          context "when a lettings log is for a renewal of supported housing, property information does not need to show" do
            let(:lettings_log) do
              FactoryBot.create(
                :lettings_log,
                owning_organisation: user.organisation,
                managing_organisation: user.organisation,
                assigned_to: user,
                startdate: Time.zone.now,
                renewal: 1,
                needstype: 2,
                rent_type: 3,
                postcode_known: 0,
              )
            end

            before do
              sign_in user
            end

            around do |example|
              FormHandler.instance.use_real_forms!
              example.run
              FormHandler.instance.use_fake_forms!
            end

            it "does not crash the app if postcode_known is not nil" do
              expect {
                get "/lettings-logs/#{lettings_log.id}", headers:, params: {}
              }.not_to raise_error(ActionView::Template::Error)
            end
          end

          context "with a lettings log with a single section complete" do
            let(:section_completed_lettings_log) do
              FactoryBot.create(
                :lettings_log,
                :conditional_section_complete,
                assigned_to: user,
              )
            end

            before do
              Timecop.freeze(2021, 4, 1)
              Singleton.__init__(FormHandler)
              sign_in user
              get "/lettings-logs/#{section_completed_lettings_log.id}", headers:, params: {}
            end

            after do
              Timecop.unfreeze
              Singleton.__init__(FormHandler)
            end

            it "displays a section status for a lettings log" do
              assert_select ".govuk-tag", text: /Not started/, count: 6
              assert_select ".govuk-tag", text: /Completed/, count: 1
              assert_select ".govuk-tag", text: /Cannot start yet/, count: 1
            end
          end

          context "with lettings logs that are not owned or managed by your organisation" do
            before do
              sign_in user
              get "/lettings-logs/#{unauthorized_lettings_log.id}", headers:, params: {}
            end

            it "does not show the tasklist for lettings logs you don't have access to" do
              expect(response).to have_http_status(:not_found)
            end
          end

          context "when the log is unresolved" do
            let!(:scheme) { FactoryBot.create(:scheme, owning_organisation: user.organisation) }
            let!(:location) { FactoryBot.create(:location, scheme:) }

            before do
              Timecop.freeze(2021, 4, 1)
              Singleton.__init__(FormHandler)
              FactoryBot.create_list(:lettings_log, 3, unresolved: true, assigned_to: user)
              lettings_log.update!(needstype: 2, scheme:, location:, unresolved: true)
              sign_in user
              get "/lettings-logs/#{lettings_log.id}", headers:, params: {}
            end

            after do
              Timecop.return
              Singleton.__init__(FormHandler)
            end

            it "marks it as resolved when both scheme and location exist" do
              lettings_log.reload
              expect(lettings_log.unresolved).to eq(false)
            end

            it "displays a success banner" do
              expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
              expect(page).to have_content("You’ve updated all the fields affected by the scheme change")
              expect(page).to have_link("Update 3 more logs", href: "/lettings-logs/update-logs")
            end
          end
        end
      end
    end

    context "when accessing the check answers page" do
      before do
        Timecop.freeze(2021, 4, 1)
        Singleton.__init__(FormHandler)
        completed_lettings_log.update!(startdate: Time.zone.local(2021, 4, 1), voiddate: Time.zone.local(2021, 4, 1), mrcdate: Time.zone.local(2021, 4, 1))
        Timecop.unfreeze
        stub_request(:get, /api.postcodes.io/)
          .to_return(status: 200, body: "{\"status\":200,\"result\":{\"admin_district\":\"Manchester\", \"codes\":{\"admin_district\": \"E08000003\"}}}", headers: {})
        sign_in user
      end

      let(:postcode_lettings_log) do
        FactoryBot.create(:lettings_log,
                          assigned_to: user,
                          postcode_known: "No")
      end
      let(:id) { postcode_lettings_log.id }
      let(:completed_lettings_log) { FactoryBot.create(:lettings_log, :completed, owning_organisation: user.organisation, managing_organisation: user.organisation, assigned_to: user) }

      it "shows the inferred la" do
        lettings_log = FactoryBot.create(:lettings_log,
                                         assigned_to: user,
                                         postcode_known: 1,
                                         postcode_full: "PO5 3TE")
        id = lettings_log.id
        get "/lettings-logs/#{id}/property-information/check-answers"
        expected_inferred_answer = "<span class=\"govuk-!-font-weight-regular app-!-colour-muted\">Manchester</span>"
        expect(CGI.unescape_html(response.body)).to include(expected_inferred_answer)
      end

      it "does not show do you know the property postcode question" do
        get "/lettings-logs/#{id}/property-information/check-answers"
        expect(CGI.unescape_html(response.body)).not_to include("Do you know the property postcode?")
      end

      it "shows if the postcode is not known" do
        get "/lettings-logs/#{id}/property-information/check-answers"
        expect(CGI.unescape_html(response.body)).to include("Not known")
      end

      it "shows `you haven't answered this question` if the question wasn’t answered" do
        get "/lettings-logs/#{id}/income-and-benefits/check-answers"
        expect(CGI.unescape_html(response.body)).to include("You didn’t answer this question")
      end

      it "does not allow you to change the answers for previous collection year logs" do
        get "/lettings-logs/#{completed_lettings_log.id}/setup/check-answers", headers: { "Accept" => "text/html" }, params: {}
        expect(page).not_to have_link("Change")
        expect(page).not_to have_link("Answer")

        get "/lettings-logs/#{completed_lettings_log.id}/income-and-benefits/check-answers", headers: { "Accept" => "text/html" }, params: {}
        expect(page).not_to have_link("Change")
        expect(page).not_to have_link("Answer")
      end

      context "when the edit end date is in the future" do
        before do
          Timecop.freeze(2022, 7, 5)
        end

        after do
          Timecop.return
        end

        it "allows you to change the answers for previous collection year logs" do
          get "/lettings-logs/#{completed_lettings_log.id}/setup/check-answers", headers: { "Accept" => "text/html" }, params: {}
          expect(page).to have_link("Change")

          get "/lettings-logs/#{completed_lettings_log.id}/income-and-benefits/check-answers", headers: { "Accept" => "text/html" }, params: {}
          expect(page).to have_link("Change")
        end

        it "lets the user navigate to questions for previous collection year logs" do
          get "/lettings-logs/#{completed_lettings_log.id}/needs-type", headers: { "Accept" => "text/html" }, params: {}
          expect(response).to have_http_status(:ok)
        end
      end

      it "does not let the user navigate to questions for previous collection year logs" do
        get "/lettings-logs/#{completed_lettings_log.id}/needs-type", headers: { "Accept" => "text/html" }, params: {}
        expect(response).to redirect_to("/lettings-logs/#{completed_lettings_log.id}")
      end
    end

    context "when requesting CSV download" do
      let(:headers) { { "Accept" => "text/html" } }
      let(:search_term) { "foo" }

      before do
        sign_in user
        get "/lettings-logs/csv-download?search=#{search_term}&codes_only=false", headers:
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "shows a confirmation button" do
        expect(page).to have_button("Send email")
      end

      it "includes the search term" do
        expect(page).to have_field("search", type: "hidden", with: search_term)
      end
    end

    context "when confirming the CSV email" do
      let(:headers) { { "Accept" => "text/html" } }

      context "when a log exists" do
        before do
          sign_in user
        end

        it "confirms that the user will receive an email with the requested CSV" do
          get "/lettings-logs/csv-confirmation"
          expect(CGI.unescape_html(response.body)).to include("We’re sending you an email")
        end
      end
    end

    context "when viewing a collection of logs affected by deactivated location" do
      let!(:affected_lettings_logs) { FactoryBot.create_list(:lettings_log, 3, unresolved: true, assigned_to: user) }
      let!(:other_user_affected_lettings_log) { FactoryBot.create(:lettings_log, unresolved: true) }
      let!(:non_affected_lettings_logs) { FactoryBot.create_list(:lettings_log, 4, assigned_to: user) }
      let(:other_user) { FactoryBot.create(:user, organisation: user.organisation) }
      let(:headers) { { "Accept" => "text/html" } }

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
      end

      it "displays logs in a table" do
        get "/lettings-logs/update-logs", headers:, params: {}
        expect(page).to have_content("Log ID")
        expect(page).to have_content("Tenancy code")
        expect(page).to have_content("Property reference")
        expect(page).to have_content("Status")

        expect(page).to have_content(affected_lettings_logs.first.id)
        expect(page).to have_content(affected_lettings_logs.first.tenancycode)
        expect(page).to have_content(affected_lettings_logs.first.propcode)
        expect(page).to have_link("Update now", href: "/lettings-logs/#{affected_lettings_logs.first.id}/tenancy-start-date")
      end

      it "only displays affected logs" do
        get "/lettings-logs/update-logs", headers:, params: {}
        expect(page).to have_content("You need to update 3 logs")
        expect(page).to have_link("Update now", href: "/lettings-logs/#{affected_lettings_logs.first.id}/tenancy-start-date")
        expect(page).not_to have_link("Update now", href: "/lettings-logs/#{non_affected_lettings_logs.first.id}/tenancy-start-date")
      end

      it "only displays the logs assigned to the user" do
        get "/lettings-logs/update-logs", headers:, params: {}
        expect(page).to have_link("Update now", href: "/lettings-logs/#{affected_lettings_logs.second.id}/tenancy-start-date")
        expect(page).not_to have_link("Update now", href: "/lettings-logs/#{other_user_affected_lettings_log.id}/tenancy-start-date")
        expect(page).to have_content("You need to update 3 logs")
      end

      it "displays correct content when there are no unresolved logs" do
        LettingsLog.where(unresolved: true).update!(unresolved: false)
        get "/lettings-logs/update-logs", headers:, params: {}
        expect(page).to have_content("There are no more logs that need updating")
        expect(page).to have_content("You’ve completed all the logs that were affected by scheme changes.")
        page.assert_selector(".govuk-button", text: "Back to all logs")
      end

      it "displays a banner on the lettings log page" do
        get "/lettings-logs", headers:, params: {}
        expect(page).to have_css(".govuk-notification-banner")
        expect(page).to have_content("A scheme has changed and it has affected 3 logs")
        expect(page).to have_link("Update logs", href: "/lettings-logs/update-logs")
      end
    end

    context "when viewing a specific log affected by deactivated location" do
      let!(:affected_lettings_log) { FactoryBot.create(:lettings_log, unresolved: true, assigned_to: user, needstype: 2) }
      let(:headers) { { "Accept" => "text/html" } }

      before do
        allow(affected_lettings_log.form).to receive(:edit_end_date).and_return(Time.zone.today + 1.day)
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
      end

      it "routes to the tenancy date question" do
        get "/lettings-logs/#{affected_lettings_log.id}", headers:, params: {}
        expect(response).to redirect_to("/lettings-logs/#{affected_lettings_log.id}/tenancy-start-date")
        follow_redirect!
        expect(page).to have_content("What is the tenancy start date?")
      end

      it "tenancy start date page links to the scheme page" do
        get "/lettings-logs/#{affected_lettings_log.id}/tenancy-start-date", headers:, params: {}
        expect(page).to have_link("Skip for now", href: "/lettings-logs/#{affected_lettings_log.id}/scheme")
      end

      it "scheme page links to the locations page" do
        get "/lettings-logs/#{affected_lettings_log.id}/scheme", headers:, params: {}
        expect(page).to have_link("Skip for now", href: "/lettings-logs/#{affected_lettings_log.id}/location")
      end

      it "displays inset hint text on the tenancy start date question" do
        get "/lettings-logs/#{affected_lettings_log.id}/tenancy-start-date", headers:, params: {}
        expect(page).to have_content("Some scheme details have changed, and now this log needs updating. Check that the tenancy start date is correct.")
      end
    end
  end

  describe "PATCH" do
    let(:lettings_log) do
      FactoryBot.create(:lettings_log, :in_progress, tenancycode: "Old Value", postcode_full: "M1 1AE")
    end
    let(:params) do
      { tenancycode: "New Value" }
    end
    let(:id) { lettings_log.id }

    before do
      patch "/lettings-logs/#{id}", headers:, params: params.to_json
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "updates the lettings log with the given fields and keeps original values where none are passed" do
      lettings_log.reload
      expect(lettings_log.tenancycode).to eq("New Value")
      expect(lettings_log.postcode_full).to eq("M1 1AE")
    end

    context "with an invalid lettings log id" do
      let(:id) { (LettingsLog.order(:id).last&.id || 0) + 1 }

      it "returns 404" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with an invalid lettings log params" do
      around do |example|
        Timecop.freeze(Time.zone.local(2022, 1, 1)) do
          Singleton.__init__(FormHandler)
          example.run
        end
        Timecop.return
        Singleton.__init__(FormHandler)
      end

      let(:params) { { age1: 200 } }

      it "returns 422" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns an error message" do
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to eq({ "age1" => ["Lead tenant’s age must be between 16 and 120"] })
      end
    end

    context "with a request containing invalid credentials" do
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
    let(:lettings_log) do
      FactoryBot.create(:lettings_log, :in_progress, tenancycode: "Old Value", postcode_full: "SW1A 2AA")
    end
    let(:params) do
      { tenancycode: "New Value" }
    end
    let(:id) { lettings_log.id }

    before do
      put "/lettings-logs/#{id}", headers:, params: params.to_json
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "updates the lettings log with the given fields and keeps original values where none are passed" do
      lettings_log.reload
      expect(lettings_log.tenancycode).to eq("New Value")
      expect(lettings_log.postcode_full).to eq("SW1A 2AA")
    end

    context "with an invalid lettings log id" do
      let(:id) { (LettingsLog.order(:id).last&.id || 0) + 1 }

      it "returns 404" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with a request containing invalid credentials" do
      let(:basic_credentials) do
        ActionController::HttpAuthentication::Basic.encode_credentials(api_username, "Oops")
      end

      it "returns 401" do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE" do
    let(:headers) { { "Accept" => "text/html" } }
    let(:page) { Capybara::Node::Simple.new(response.body) }
    let(:user) { create(:user, :support) }
    let!(:lettings_log) do
      create(:lettings_log, :completed)
    end
    let(:id) { lettings_log.id }
    let(:delete_request) { delete "/lettings-logs/#{id}", headers: }

    before do
      allow(user).to receive(:need_two_factor_authentication?).and_return(false)
      sign_in user
    end

    context "when delete permitted" do
      it "redirects to lettings logs and shows message" do
        delete_request
        expect(response).to redirect_to(lettings_logs_path)
        follow_redirect!
        expect(page).to have_content("Log #{id} has been deleted.")
      end

      xit "marks the log as deleted" do
        expect { delete_request }.to change { lettings_log.reload.status }.from("completed").to("deleted")
      end
    end

    context "when log does not exist" do
      let(:id) { -1 }

      it "returns 404" do
        delete_request
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when user not authorised" do
      let(:user) { create(:user) }

      it "returns 401" do
        delete_request
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET delete-confirmation" do
    let(:headers) { { "Accept" => "text/html" } }
    let(:page) { Capybara::Node::Simple.new(response.body) }
    let(:user) { create(:user, :support) }
    let!(:lettings_log) do
      create(:lettings_log, :completed)
    end
    let(:id) { lettings_log.id }
    let(:request) { get "/lettings-logs/#{id}/delete-confirmation", headers: }

    before do
      allow(user).to receive(:need_two_factor_authentication?).and_return(false)
      sign_in user
    end

    context "when delete permitted" do
      it "renders page" do
        request
        expect(response).to have_http_status(:ok)

        expect(page).to have_content("Are you sure you want to delete this log?")
        expect(page).to have_button(text: "Delete this log")
        expect(page).to have_link(text: "Cancel", href: lettings_log_path(id))
      end
    end

    context "when log does not exist" do
      let(:id) { -1 }

      it "returns 404" do
        request
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when user not authorised" do
      let(:user) { create(:user) }

      it "returns 404" do
        request
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET csv-download" do
    let(:page) { Capybara::Node::Simple.new(response.body) }
    let(:user) { FactoryBot.create(:user) }
    let(:headers) { { "Accept" => "text/html" } }

    before do
      allow(user).to receive(:need_two_factor_authentication?).and_return(false)
      sign_in user
    end

    it "renders a page with the correct header" do
      get "/lettings-logs/csv-download?codes_only=false", headers:, params: {}
      header = page.find_css("h1")
      expect(header.text).to include("Download CSV")
    end

    it "renders a form with the correct target containing a button with the correct text" do
      get "/lettings-logs/csv-download?codes_only=false", headers:, params: {}
      form = page.find("form.button_to")
      expect(form[:method]).to eq("post")
      expect(form[:action]).to eq("/lettings-logs/email-csv")
      expect(form).to have_button("Send email")
    end

    it "when query string contains search parameter, form contains hidden field with correct value" do
      search_term = "blam"
      get "/lettings-logs/csv-download?codes_only=false&search=#{search_term}", headers:, params: {}
      hidden_field = page.find("form.button_to").find_field("search", type: "hidden")
      expect(hidden_field.value).to eq(search_term)
    end

    context "when the user is a data coordinator" do
      let(:user) { FactoryBot.create(:user, :data_coordinator) }

      it "when codes_only query parameter is false, form contains hidden field with correct value" do
        codes_only = false
        get "/lettings-logs/csv-download?codes_only=#{codes_only}", headers:, params: {}
        hidden_field = page.find("form.button_to").find_field("codes_only", type: "hidden")
        expect(hidden_field.value).to eq(codes_only.to_s)
      end

      it "when codes_only query parameter is true, user is not authorized" do
        codes_only = true
        get "/lettings-logs/csv-download?codes_only=#{codes_only}", headers:, params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when the user is a data provider" do
      it "when codes_only query parameter is false, form contains hidden field with correct value" do
        codes_only = false
        get "/lettings-logs/csv-download?codes_only=#{codes_only}", headers:, params: {}
        hidden_field = page.find("form.button_to").find_field("codes_only", type: "hidden")
        expect(hidden_field.value).to eq(codes_only.to_s)
      end

      it "when codes_only query parameter is true, user is not authorized" do
        codes_only = true
        get "/lettings-logs/csv-download?codes_only=#{codes_only}", headers:, params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when the user is a support user" do
      let(:user) { FactoryBot.create(:user, :support) }

      it "when codes_only query parameter is false, form contains hidden field with correct value" do
        codes_only = false
        get "/lettings-logs/csv-download?codes_only=#{codes_only}", headers:, params: {}
        hidden_field = page.find("form.button_to").find_field("codes_only", type: "hidden")
        expect(hidden_field.value).to eq(codes_only.to_s)
      end

      it "when codes_only query parameter is true, form contains hidden field with correct value" do
        codes_only = true
        get "/lettings-logs/csv-download?codes_only=#{codes_only}", headers:, params: {}
        hidden_field = page.find("form.button_to").find_field("codes_only", type: "hidden")
        expect(hidden_field.value).to eq(codes_only.to_s)
      end
    end
  end

  describe "POST email-csv" do
    let(:other_organisation) { FactoryBot.create(:organisation) }
    let(:user) { FactoryBot.create(:user, :support) }

    context "when a log exists" do
      let!(:lettings_log) do
        FactoryBot.create(
          :lettings_log,
          assigned_to: user,
          ecstat1: 1,
        )
      end

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        FactoryBot.create(:lettings_log)
        FactoryBot.create(:lettings_log,
                          :completed,
                          owning_organisation:,
                          managing_organisation: owning_organisation,
                          assigned_to: user)
      end

      it "creates an E-mail job" do
        expect {
          post "/lettings-logs/email-csv?codes_only=true", headers:, params: {}
        }.to enqueue_job(EmailCsvJob).with(user, nil, {}, false, nil, true)
      end

      it "redirects to the confirmation page" do
        post "/lettings-logs/email-csv?codes_only=true", headers:, params: {}
        expect(response).to redirect_to(csv_confirmation_lettings_logs_path)
      end

      it "passes the search term" do
        expect {
          post "/lettings-logs/email-csv?search=#{lettings_log.id}&codes_only=false", headers:, params: {}
        }.to enqueue_job(EmailCsvJob).with(user, lettings_log.id.to_s, {}, false, nil, false)
      end

      it "passes filter parameters" do
        expect {
          post "/lettings-logs/email-csv?status[]=completed&codes_only=true", headers:, params: {}
        }.to enqueue_job(EmailCsvJob).with(user, nil, { "status" => %w[completed] }, false, nil, true)
      end

      it "passes export type flag" do
        expect {
          post "/lettings-logs/email-csv?codes_only=true", headers:, params: {}
        }.to enqueue_job(EmailCsvJob).with(user, nil, {}, false, nil, true)
        expect {
          post "/lettings-logs/email-csv?codes_only=false", headers:, params: {}
        }.to enqueue_job(EmailCsvJob).with(user, nil, {}, false, nil, false)
      end

      it "passes a combination of search term, export type and filter parameters" do
        postcode = "XX1 1TG"

        expect {
          post "/lettings-logs/email-csv?status[]=completed&search=#{postcode}&codes_only=false", headers:, params: {}
        }.to enqueue_job(EmailCsvJob).with(user, postcode, { "status" => %w[completed] }, false, nil, false)
      end

      context "when the user is not a support user" do
        let(:user) { FactoryBot.create(:user, :data_coordinator) }

        it "has permission to download human readable csv" do
          codes_only_export = false
          expect {
            post "/lettings-logs/email-csv?codes_only=#{codes_only_export}", headers:, params: {}
          }.to enqueue_job(EmailCsvJob).with(user, nil, {}, false, nil, false)
        end

        it "is not authorized to download codes only csv" do
          codes_only_export = true
          post "/lettings-logs/email-csv?codes_only=#{codes_only_export}", headers:, params: {}
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end
