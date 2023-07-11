require "rails_helper"

RSpec.describe SalesLogsController, type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:owning_organisation) { user.organisation }
  let(:api_username) { "test_user" }
  let(:api_password) { "test_password" }
  let(:basic_credentials) do
    ActionController::HttpAuthentication::Basic
      .encode_credentials(api_username, api_password)
  end

  let(:params) do
    {
      "owning_organisation_id": owning_organisation.id,
      "created_by_id": user.id,
    }
  end

  let(:headers) do
    {
      "Content-Type" => "application/json",
      "Accept" => "application/json",
      "Authorization" => basic_credentials,
    }
  end

  before do
    allow(ENV).to receive(:[])
    allow(ENV).to receive(:[]).with("API_USER").and_return(api_username)
    allow(ENV).to receive(:[]).with("API_KEY").and_return(api_password)
  end

  describe "POST #create" do
    context "when API" do
      before do
        post "/sales-logs", headers:, params: params.to_json
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "returns a serialized sales log" do
        json_response = JSON.parse(response.body)
        expect(json_response.keys).to match_array(SalesLog.new.attributes.keys)
      end

      it "creates a sales log with the values passed" do
        json_response = JSON.parse(response.body)
        expect(json_response["owning_organisation_id"]).to eq(owning_organisation.id)
        expect(json_response["created_by_id"]).to eq(user.id)
      end

      context "with a request containing invalid credentials" do
        let(:basic_credentials) do
          ActionController::HttpAuthentication::Basic.encode_credentials(api_username, "Oops")
        end

        it "returns 401" do
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "with a request containing invalid json parameters" do
        let(:params) do
          {
            "saledate": Time.zone.today,
            "purchid": "1",
            "ownershipsch": 1,
            "type": 2,
            "jointpur": 1,
            "jointmore": 1,
            "beds": 2,
            "proptype": 2,
          }
        end

        before do
          post "/sales-logs", headers:, params: params.to_json
        end

        it "validates sales log parameters" do
          json_response = JSON.parse(response.body)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response["errors"]).to match_array([["beds", ["Number of bedrooms must be 1 if the property is a bedsit"]], ["proptype", ["Answer cannot be 'Bedsit' if the property has 2 or more bedrooms"]]])
        end
      end
    end

    context "when UI" do
      let(:user) { FactoryBot.create(:user) }
      let(:headers) { { "Accept" => "text/html" } }

      before do
        RequestHelper.stub_http_requests
        sign_in user
        post "/sales-logs", headers:
      end

      it "tracks who created the record" do
        created_id = response.location.match(/[0-9]+/)[0]
        whodunnit_actor = SalesLog.find_by(id: created_id).versions.last.actor
        expect(whodunnit_actor).to be_a(User)
        expect(whodunnit_actor.id).to eq(user.id)
      end
    end
  end

  describe "GET" do
    let(:page) { Capybara::Node::Simple.new(response.body) }
    let(:user) { FactoryBot.create(:user) }
    let(:organisation) { user.organisation }
    let(:other_organisation) { FactoryBot.create(:organisation) }
    let(:purchaser_code) { "coop123" }
    let!(:sales_log) do
      FactoryBot.create(
        :sales_log,
        purchid: purchaser_code,
        owning_organisation: organisation,
      )
    end
    let!(:unauthorized_sales_log) do
      FactoryBot.create(
        :sales_log,
        owning_organisation: other_organisation,
      )
    end

    context "when displaying a collection of logs" do
      let(:headers) { { "Accept" => "text/html" } }

      context "when the user is a customer support user" do
        let(:user) { FactoryBot.create(:user, :support) }

        before do
          allow(user).to receive(:need_two_factor_authentication?).and_return(false)
          sign_in user
        end

        it "does have organisation values" do
          get "/sales-logs", headers: headers, params: {}
          expect(page).to have_content("Owned by")
          expect(page).not_to have_content("Managed by")
        end

        it "shows sales logs for all organisations" do
          get "/sales-logs", headers: headers, params: {}
          expect(page).to have_content(organisation.name)
          expect(page).to have_content(other_organisation.name)
        end

        it "shows a link for labelled CSV download of logs" do
          get "/sales-logs", headers: headers, params: {}
          expect(page).to have_link("Download (CSV)", href: "/sales-logs/csv-download?codes_only=false")
        end

        it "shows a link for codes only CSV download of logs" do
          get "/sales-logs", headers: headers, params: {}
          expect(page).to have_link("Download (CSV, codes only)", href: "/sales-logs/csv-download?codes_only=true")
        end

        context "when there are no logs in the database" do
          before do
            SalesLog.destroy_all
          end

          it "page has correct title" do
            get "/sales-logs", headers: headers, params: {}
            expect(page).to have_title("Logs - Submit social housing lettings and sales data (CORE) - GOV.UK")
          end

          it "does not show CSV download links" do
            get "/sales-logs", headers: headers, params: {}
            expect(page).not_to have_link("Download (CSV)")
            expect(page).not_to have_link("Download (CSV, codes only)")
          end
        end

        context "and the state of filters and search is such that display_delete_logs returns true" do
          before do
            allow_any_instance_of(LogListHelper).to receive(:display_delete_logs?).and_return(true) # rubocop:disable RSpec/AnyInstance
          end

          it "displays the delete logs button with the correct path if there are logs visibile" do
            get sales_logs_path(search: purchaser_code)
            expect(page).to have_link "Delete logs", href: delete_logs_sales_logs_path(search: purchaser_code)
          end

          it "does not display the delete logs button if there are no logs displayed" do
            SalesLog.destroy_all
            get sales_logs_path(search: "gibberish_e9o87tvbyc4875g")
            expect(page).not_to have_selector "article.app-log-summary"
            expect(page).not_to have_link "Delete logs"
          end
        end

        context "and the state of filters and search is such that display_delete_logs returns false" do
          before do
            allow_any_instance_of(LogListHelper).to receive(:display_delete_logs?).and_return(false) # rubocop:disable RSpec/AnyInstance
          end

          it "does not display the delete logs button even if there are logs displayed" do
            get sales_logs_path
            expect(page).to have_selector "article.app-log-summary"
            expect(page).not_to have_link "Delete logs"
          end
        end

        context "when there is a pending log" do
          let!(:invisible_log) do
            FactoryBot.create(
              :sales_log,
              owning_organisation: organisation,
              status: "pending",
              skip_update_status: true,
            )
          end

          it "does not render pending logs" do
            get "/sales-logs", headers: headers, params: {}
            expect(page).not_to have_link(invisible_log.id, href: "sales-logs/#{invisible_log.id}")
          end
        end

        context "when filtering" do
          context "with status filter" do
            let(:organisation_2) { FactoryBot.create(:organisation) }
            let(:user_2) { FactoryBot.create(:user, organisation: organisation_2) }
            let!(:not_started_sales_log) do
              FactoryBot.create(:sales_log,
                                owning_organisation: organisation,
                                created_by: user)
            end
            let!(:completed_sales_log) do
              FactoryBot.create(:sales_log, :completed,
                                owning_organisation: organisation_2,
                                created_by: user_2)
            end

            it "shows sales logs for multiple selected statuses" do
              get "/sales-logs?status[]=not_started&status[]=completed", headers: headers, params: {}
              expect(page).to have_link(not_started_sales_log.id.to_s)
              expect(page).to have_link(completed_sales_log.id.to_s)
            end

            it "shows sales logs for one selected status" do
              get "/sales-logs?status[]=not_started", headers: headers, params: {}
              expect(page).to have_link(not_started_sales_log.id.to_s)
              expect(page).not_to have_link(completed_sales_log.id.to_s)
            end

            it "filters on organisation" do
              get "/sales-logs?organisation[]=#{organisation_2.id}", headers: headers, params: {}
              expect(page).to have_link(completed_sales_log.id.to_s)
              expect(page).not_to have_link(not_started_sales_log.id.to_s)
            end

            it "does not reset the filters" do
              get "/sales-logs?status[]=not_started", headers: headers, params: {}
              expect(page).to have_link(not_started_sales_log.id.to_s)
              expect(page).not_to have_link(completed_sales_log.id.to_s)

              get "/sales-logs", headers: headers, params: {}
              expect(page).to have_link(not_started_sales_log.id.to_s)
              expect(page).not_to have_link(completed_sales_log.id.to_s)
            end
          end

          context "with year filter" do
            around do |example|
              Timecop.freeze(2022, 12, 1) do
                example.run
              end
              Timecop.return
            end

            before do
              Timecop.freeze(2022, 4, 1)
              sales_log_2022.update!(saledate: Time.zone.local(2022, 4, 1))
              Timecop.freeze(2023, 1, 1)
              sales_log_2022.update!(saledate: Time.zone.local(2023, 1, 1))
            end

            after do
              Timecop.unfreeze
            end

            let!(:sales_log_2022) do
              FactoryBot.create(:sales_log, :completed,
                                owning_organisation: organisation,
                                created_by: user,
                                saledate: Time.zone.today)
            end
            let!(:sales_log_2023) do
              FactoryBot.create(:sales_log,
                                owning_organisation: organisation,
                                created_by: user,
                                saledate: Time.zone.today)
            end

            it "shows sales logs for multiple selected years" do
              get "/sales-logs?years[]=2021&years[]=2022", headers: headers, params: {}
              expect(page).to have_link(sales_log_2022.id.to_s)
              expect(page).to have_link(sales_log_2023.id.to_s)
            end

            it "shows sales logs for one selected year" do
              get "/sales-logs?years[]=2022", headers: headers, params: {}
              expect(page).to have_link(sales_log_2022.id.to_s)
              expect(page).to have_link(sales_log_2023.id.to_s)
            end
          end

          context "with year and status filter" do
            around do |example|
              Timecop.freeze(2022, 12, 1) do
                example.run
              end
              Timecop.return
            end

            before do
              Timecop.freeze(2022, 4, 1)
              sales_log_2022.update!(saledate: Time.zone.local(2022, 4, 1))
              Timecop.freeze(2023, 1, 1)
              sales_log_2022.update!(saledate: Time.zone.local(2023, 1, 1))
            end

            after do
              Timecop.unfreeze
            end

            let!(:sales_log_2022) do
              FactoryBot.create(:sales_log, :completed,
                                owning_organisation: organisation,
                                created_by: user,
                                saledate: Time.zone.today)
            end
            let!(:sales_log_2023) do
              FactoryBot.create(:sales_log,
                                owning_organisation: organisation,
                                created_by: user,
                                saledate: Time.zone.today)
            end

            it "shows sales logs for multiple selected statuses and years" do
              get "/sales-logs?years[]=2021&years[]=2022&status[]=in_progress&status[]=completed", headers: headers, params: {}
              expect(page).to have_link(sales_log_2022.id.to_s)
              expect(page).to have_link(sales_log_2023.id.to_s)
            end
          end
        end
      end

      context "when the user is not a customer support user" do
        before do
          sign_in user
        end

        it "does not have organisation columns" do
          get "/sales-logs", headers: headers, params: {}
          expect(page).not_to have_content("Owning organisation")
          expect(page).not_to have_content("Managing organisation")
        end

        it "displays standard CSV download link only, with the correct path" do
          get "/sales-logs", headers:, params: {}
          expect(page).to have_link("Download (CSV)", href: "/sales-logs/csv-download?codes_only=false")
          expect(page).not_to have_link("Download (CSV, codes only)")
        end

        it "does not display CSV download links if there are no logs" do
          SalesLog.destroy_all
          get "/sales-logs", headers:, params: {}
          expect(page).not_to have_link("Download (CSV)")
          expect(page).not_to have_link("Download (CSV, codes only)")
        end

        context "when using a search query" do
          let(:logs) { FactoryBot.create_list(:sales_log, 3, :completed, owning_organisation: user.organisation, created_by: user) }
          let(:log_to_search) { FactoryBot.create(:sales_log, :completed, owning_organisation: user.organisation, created_by: user) }
          let(:log_total_count) { SalesLog.where(owning_organisation: user.organisation).count }

          it "has search results in the title" do
            get "/sales-logs?search=#{log_to_search.id}", headers: headers, params: {}
            expect(page).to have_title("Logs (1 logs matching ‘#{log_to_search.id}’) - Submit social housing lettings and sales data (CORE) - GOV.UK")
          end

          it "shows sales logs matching the id" do
            get "/sales-logs?search=#{log_to_search.id}", headers: headers, params: {}
            expect(page).to have_link(log_to_search.id.to_s)
            logs.each do |log|
              expect(page).not_to have_link(log.id.to_s)
            end
          end

          it "displays the labelled CSV download link, with the search included in the query params" do
            get "/sales-logs?search=#{log_to_search.id}", headers:, params: {}
            download_link = page.find_link("Download (CSV)")
            download_link_params = CGI.parse(URI.parse(download_link[:href]).query)
            expect(download_link_params).to include("search" => [log_to_search.id.to_s])
          end

          context "when search query doesn't match any logs" do
            it "doesn't display any logs" do
              get "/sales-logs?search=foobar", headers:, params: {}
              logs.each do |log|
                expect(page).not_to have_link(log.id.to_s)
              end
              expect(page).not_to have_link(log_to_search.id.to_s)
            end
          end

          context "when search query is empty" do
            it "doesn't display any logs" do
              get "/sales-logs?search=", headers:, params: {}
              logs.each do |log|
                expect(page).not_to have_link(log.id.to_s)
              end
              expect(page).not_to have_link(log_to_search.id.to_s)
            end
          end

          context "when search and filter is present" do
            let(:matching_status) { "completed" }
            let!(:log_matching_filter_and_search) { FactoryBot.create(:sales_log, :completed, owning_organisation: user.organisation, created_by: user) }
            let(:matching_id) { log_matching_filter_and_search.id }

            it "shows only logs matching both search and filters" do
              get "/sales-logs?search=#{matching_id}&status[]=#{matching_status}", headers: headers, params: {}
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
            get "/sales-logs", headers:, params: {}
          end

          it "shows a table of logs" do
            expect(CGI.unescape_html(response.body)).to match(/<article class="app-log-summary">/)
            expect(CGI.unescape_html(response.body)).to match(/logs/)
          end

          it "only shows sales logs for your organisation" do
            expected_case_row_log = "<span class=\"govuk-visually-hidden\">Log </span>#{sales_log.id}"
            unauthorized_case_row_log = "<span class=\"govuk-visually-hidden\">Log </span>#{unauthorized_sales_log.id}"
            expect(CGI.unescape_html(response.body)).to include(expected_case_row_log)
            expect(CGI.unescape_html(response.body)).not_to include(unauthorized_case_row_log)
          end

          it "shows the formatted created at date for each log" do
            formatted_date = sales_log.created_at.to_formatted_s(:govuk_date)
            expect(CGI.unescape_html(response.body)).to include(formatted_date)
          end

          it "shows the log's status" do
            expect(CGI.unescape_html(response.body)).to include(sales_log.status.humanize)
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
            expect(page).to have_title("Logs - Submit social housing lettings and sales data (CORE) - GOV.UK")
          end

          it "does not show the organisation filter" do
            expect(page).not_to have_field("organisation-field")
          end
        end

        context "when there are more than 20 logs" do
          before do
            FactoryBot.create_list(:sales_log, 25, owning_organisation: organisation)
          end

          context "when on the first page" do
            before do
              get "/sales-logs", headers:, params: {}
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
              expect(page).to have_title("Logs (page 1 of 2) - Submit social housing lettings and sales data (CORE) - GOV.UK")
            end
          end

          context "when on the second page" do
            before do
              get "/sales-logs?page=2", headers:, params: {}
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
              expect(page).to have_title("Logs (page 2 of 2) - Submit social housing lettings and sales data (CORE) - GOV.UK")
            end
          end
        end
      end
    end

    context "when you visit the index page" do
      let(:headers) { { "Accept" => "text/html" } }
      let(:user) { FactoryBot.create(:user, :support) }

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
      end

      it "does not have a button for creating lettings logs" do
        get "/sales-logs", headers:, params: {}
        page.assert_selector(".govuk-button", text: "Create a new sales log", count: 1)
        page.assert_selector(".govuk-button", text: "Create a new lettings log", count: 0)
      end
    end

    context "when viewing a sales log" do
      let(:headers) { { "Accept" => "text/html" } }
      let(:completed_sales_log) { FactoryBot.create(:sales_log, :completed, owning_organisation: user.organisation, created_by: user) }

      before do
        sign_in user
        Timecop.freeze(2021, 4, 1)
        Singleton.__init__(FormHandler)
        completed_sales_log.update!(saledate: Time.zone.local(2021, 4, 1))
        completed_sales_log.reload
      end

      context "with sales logs that are owned by your organisation" do
        before do
          get "/sales-logs/#{completed_sales_log.id}", headers:, params: {}
        end

        after do
          Timecop.return
          Singleton.__init__(FormHandler)
        end

        it "shows the tasklist for sales logs you have access to" do
          expect(response.body).to match("Log")
          expect(response.body).to match(completed_sales_log.id.to_s)
        end

        it "displays a link to update the log for currently editable logs" do
          completed_sales_log.update!(saledate: Time.zone.local(2021, 4, 1))
          completed_sales_log.reload

          get "/sales-logs/#{completed_sales_log.id}", headers:, params: {}
          expect(completed_sales_log.form.new_logs_end_date).to eq(Time.zone.local(2022, 12, 31))
          expect(completed_sales_log.status).to eq("completed")
          expect(page).to have_link("review and make changes to this log", href: "/sales-logs/#{completed_sales_log.id}/review?sales_log=true")
        end
      end

      context "with sales logs from a closed collection period before the previous collection" do
        before do
          sign_in user
          Timecop.return
          Singleton.__init__(FormHandler)
          get "/sales-logs/#{completed_sales_log.id}", headers:, params: {}
        end

        it "redirects to review page" do
          expect(response).to redirect_to("/sales-logs/#{completed_sales_log.id}/review?sales_log=true")
        end
      end

      context "with sales logs from a closed previous collection period" do
        before do
          sign_in user
          Timecop.freeze(2023, 2, 1)
          Singleton.__init__(FormHandler)
          get "/sales-logs/#{completed_sales_log.id}", headers:, params: {}
        end

        after do
          Timecop.return
          Singleton.__init__(FormHandler)
        end

        it "redirects to review page" do
          expect(response).to redirect_to("/sales-logs/#{completed_sales_log.id}/review?sales_log=true")
        end

        it "displays a closed collection window message for previous collection year logs" do
          get "/sales-logs/#{completed_sales_log.id}", headers:, params: {}
          expect(completed_sales_log.form.new_logs_end_date).to eq(Time.zone.local(2022, 12, 31))
          expect(completed_sales_log.status).to eq("completed")
          follow_redirect!
          expect(page).to have_content("This log is from the 2021/2022 collection window, which is now closed.")
        end
      end
    end

    context "when requesting CSV download" do
      let(:headers) { { "Accept" => "text/html" } }
      let(:search_term) { "foot" }
      let(:codes_only) { false }

      before do
        allow(user).to receive(:need_two_factor_authentication?).and_return(false)
        sign_in user
        get "/sales-logs/csv-download?search=#{search_term}&codes_only=#{codes_only}", headers:
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "shows a confirmation button" do
        expect(page).to have_button("Send email")
      end

      it "has a hidden field with the search term" do
        expect(page).to have_field("search", type: "hidden", with: search_term)
      end

      context "when user is not support" do
        context "and export type is not codes only" do
          it "has a hidden field with the export type" do
            expect(page).to have_field("codes_only", type: "hidden", with: codes_only)
          end
        end

        context "and export type is codes only" do
          let(:codes_only) { true }

          it "the user is not authorised" do
            expect(response).to have_http_status(:unauthorized)
          end
        end
      end

      context "when user is support" do
        let(:user) { FactoryBot.create(:user, :support) }

        context "and export type is not codes only" do
          it "has a hidden field with the export type" do
            expect(page).to have_field("codes_only", type: "hidden", with: codes_only)
          end
        end

        context "and export type is codes only" do
          let(:codes_only) { true }

          it "has a hidden field with the export type" do
            expect(page).to have_field("codes_only", type: "hidden", with: codes_only)
          end
        end
      end
    end

    context "when confirming the CSV email" do
      let(:headers) { { "Accept" => "text/html" } }

      it "confirms that the user will receive an email with the requested CSV" do
        sign_in user
        get "/sales-logs/csv-confirmation"
        expect(CGI.unescape_html(response.body)).to include("We’re sending you an email")
      end
    end
  end

  describe "POST #email-csv" do
    let(:other_organisation) { FactoryBot.create(:organisation) }
    let(:user) { FactoryBot.create(:user, :support) }
    let!(:sales_log) do
      FactoryBot.create(
        :sales_log,
        created_by: user,
      )
    end

    before do
      allow(user).to receive(:need_two_factor_authentication?).and_return(false)
      sign_in user
      FactoryBot.create(:sales_log)
      FactoryBot.create(:sales_log,
                        :completed,
                        owning_organisation:,
                        created_by: user)
    end

    it "creates an E-mail job with the correct log type" do
      expect {
        post "/sales-logs/email-csv?codes_only=true", headers:, params: {}
      }.to enqueue_job(EmailCsvJob).with(user, nil, {}, false, nil, true, "sales")
    end

    it "redirects to the confirmation page" do
      post "/sales-logs/email-csv?codes_only=true", headers:, params: {}
      expect(response).to redirect_to(csv_confirmation_sales_logs_path)
    end

    it "passes the search term" do
      expect {
        post "/sales-logs/email-csv?search=#{sales_log.id}&codes_only=false", headers:, params: {}
      }.to enqueue_job(EmailCsvJob).with(user, sales_log.id.to_s, {}, false, nil, false, "sales")
    end

    it "passes filter parameters" do
      expect {
        post "/sales-logs/email-csv?status[]=completed&codes_only=true", headers:, params: {}
      }.to enqueue_job(EmailCsvJob).with(user, nil, { "status" => %w[completed] }, false, nil, true, "sales")
    end

    it "passes export type flag" do
      expect {
        post "/sales-logs/email-csv?codes_only=true", headers:, params: {}
      }.to enqueue_job(EmailCsvJob).with(user, nil, {}, false, nil, true, "sales")
      expect {
        post "/sales-logs/email-csv?codes_only=false", headers:, params: {}
      }.to enqueue_job(EmailCsvJob).with(user, nil, {}, false, nil, false, "sales")
    end

    it "passes a combination of search term, export type and filter parameters" do
      postcode = "XX1 1TG"

      expect {
        post "/sales-logs/email-csv?status[]=completed&search=#{postcode}&codes_only=false", headers:, params: {}
      }.to enqueue_job(EmailCsvJob).with(user, postcode, { "status" => %w[completed] }, false, nil, false, "sales")
    end

    context "when the user is not a support user" do
      let(:user) { FactoryBot.create(:user, :data_coordinator) }

      it "has permission to download human readable csv" do
        codes_only_export = false
        expect {
          post "/sales-logs/email-csv?codes_only=#{codes_only_export}", headers:, params: {}
        }.to enqueue_job(EmailCsvJob).with(user, nil, {}, false, nil, false, "sales")
      end

      it "is not authorized to download codes only csv" do
        codes_only_export = true
        post "/sales-logs/email-csv?codes_only=#{codes_only_export}", headers:, params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE" do
    let(:headers) { { "Accept" => "text/html" } }
    let(:page) { Capybara::Node::Simple.new(response.body) }
    let(:user) { create(:user, :support) }
    let!(:sales_log) do
      create(:sales_log, :completed)
    end
    let(:id) { sales_log.id }
    let(:delete_request) { delete "/sales-logs/#{id}", headers: }

    before do
      allow(user).to receive(:need_two_factor_authentication?).and_return(false)
      sign_in user
    end

    context "when delete permitted" do
      it "redirects to sales logs and shows message" do
        delete_request
        expect(response).to redirect_to(sales_logs_path)
        follow_redirect!
        expect(page).to have_content("Log #{id} has been deleted")
      end

      it "marks the log as deleted" do
        expect { delete_request }.to change { sales_log.reload.status }.from("completed").to("deleted")
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

      it "returns 404" do
        delete_request
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET delete-confirmation" do
    let(:headers) { { "Accept" => "text/html" } }
    let(:page) { Capybara::Node::Simple.new(response.body) }
    let(:user) { create(:user, :support) }
    let!(:sales_log) do
      create(:sales_log, :completed)
    end
    let(:id) { sales_log.id }
    let(:request) { get "/sales-logs/#{id}/delete-confirmation", headers: }

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
        expect(page).to have_link(text: "Cancel", href: sales_log_path(id))
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
end
