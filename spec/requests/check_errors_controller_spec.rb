require "rails_helper"

RSpec.describe CheckErrorsController, type: :request do
  let(:page) { Capybara::Node::Simple.new(response.body) }
  let(:user) { create(:user, :data_coordinator) }
  let(:lettings_log) { create(:lettings_log, :setup_completed, assigned_to: user) }
  let(:sales_log) { create(:sales_log, :shared_ownership_setup_complete, assigned_to: user) }

  describe "check errors page" do
    context "when user is not signed in" do
      it "redirects to sign in page for lettings" do
        post "/lettings-logs/#{lettings_log.id}/net-income", params: {}
        expect(response).to redirect_to("/account/sign-in")
      end

      it "redirects to sign in page for sales" do
        post "/sales-logs/#{sales_log.id}/buyer-1-income", params: {}
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when the user is from different organisation" do
      let(:other_user) { create(:user) }

      before do
        sign_in other_user
      end

      it "renders page not found for lettings" do
        post "/lettings-logs/#{lettings_log.id}/net-income", params: {}
        expect(response).to have_http_status(:not_found)
      end

      it "renders page not found for sales" do
        post "/sales-logs/#{sales_log.id}/buyer-1-income", params: {}
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when user is signed in" do
      context "with multiple error fields and answered questions for lettings" do
        let(:params) do
          {
            id: lettings_log.id,
            lettings_log: {
              page: "income_amount",
              earnings: "100000",
              incfreq: "1",
            },
            check_errors: "",
          }
        end

        before do
          lettings_log.update!(needstype: 1, declaration: 1, ecstat1: 10, hhmemb: 2, net_income_known: 0, incfreq: nil, earnings: nil)
          sign_in user
          post "/lettings-logs/#{lettings_log.id}/income-amount", params: params
        end

        it "displays correct clear links" do
          expect(page).to have_selector("input[type=submit][value='Clear']", count: 2)
          expect(page).to have_button("Clear all")
        end
      end

      context "with multiple error fields and answered questions for sales" do
        let(:params) do
          {
            id: sales_log.id,
            sales_log: {
              page: "buyer_1_income",
              income1: "100000",
              la: "E09000001",
              ownershipsch: "1",
            },
            check_errors: "",
          }
        end

        before do
          sales_log.update!(income1: 1000, la: "E09000001")
          sign_in user
          post "/sales-logs/#{sales_log.id}/buyer-1-income", params: params
        end

        it "displays correct clear and change links" do
          expect(page.all(:button, value: "Clear").count).to eq(1)
          expect(page).to have_link("Change", count: 1)
          expect(page).to have_button("Clear all")
        end
      end
    end
  end

  describe "confirm clear answer page" do
    context "when user is not signed in" do
      it "redirects to sign in page for lettings" do
        post "/lettings-logs/#{lettings_log.id}/confirm-clear-answer", params: {}
        expect(response).to redirect_to("/account/sign-in")
      end

      it "redirects to sign in page for sales" do
        post "/sales-logs/#{sales_log.id}/confirm-clear-answer", params: {}
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when the user is from different organisation" do
      let(:other_user) { create(:user) }

      before do
        sign_in other_user
      end

      it "renders page not found for lettings" do
        post "/lettings-logs/#{lettings_log.id}/confirm-clear-answer", params: {}
        expect(response).to have_http_status(:not_found)
      end

      it "renders page not found for sales" do
        post "/sales-logs/#{sales_log.id}/confirm-clear-answer", params: {}
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when user is signed in" do
      context "and clearing specific lettings question" do
        let(:params) do
          {
            id: lettings_log.id,
            lettings_log: {
              earnings: "100000",
              incfreq: "1",
              hhmemb: "2",
              page_id: "income_amount",
            },
            hhmemb: "",
          }
        end

        before do
          sign_in user
          post "/lettings-logs/#{lettings_log.id}/confirm-clear-answer", params:
        end

        it "displays correct clear links" do
          expect(page).to have_content("Are you sure you want to clear Number of household members?")
          expect(page).to have_content("Dependent answers related to this question may also get cleared. You will not be able to undo this action.")
          expect(page).to have_link("Cancel")
          expect(page).to have_button("Confirm and continue")
        end
      end

      context "and clearing specific sales question" do
        let(:params) do
          {
            id: sales_log.id,
            sales_log: {
              income1: "100000",
              la: "E09000001",
              ownershipsch: "1",
              page_id: "buyer_1_income",
            },
            income1: "",
          }
        end

        before do
          sign_in user
          post "/sales-logs/#{sales_log.id}/confirm-clear-answer", params:
        end

        it "displays correct clear links" do
          expect(page).to have_content("Are you sure you want to clear Buyer 1’s gross annual income?")
          expect(page).to have_content("Dependent answers related to this question may also get cleared. You will not be able to undo this action.")
          expect(page).to have_link("Cancel")
          expect(page).to have_button("Confirm and continue")
        end
      end
    end
  end

  describe "confirm clear all answers" do
    context "when user is signed in" do
      context "and clearing all lettings questions" do
        let(:params) do
          {
            id: lettings_log.id,
            clear_all: "Clear all",
            lettings_log: {
              earnings: "100000",
              incfreq: "1",
              hhmemb: "2",
              page_id: "income_amount",
            },
          }
        end

        before do
          sign_in user
          post "/lettings-logs/#{lettings_log.id}/confirm-clear-answer", params:
        end

        it "displays correct clear links" do
          expect(page).to have_content("Are you sure you want to clear all")
          expect(page).to have_content("You've selected 5 answers to clear")
          expect(page).to have_content("You will not be able to undo this action")
          expect(page).to have_link("Cancel")
          expect(page).to have_button("Confirm and continue")
        end
      end

      context "and clearing all sales question" do
        let(:params) do
          {
            id: sales_log.id,
            clear_all: "Clear all",
            sales_log: {
              income1: "100000",
              la: "E09000001",
              ownershipsch: "1",
              page_id: "buyer_1_income",
            },
          }
        end

        before do
          sign_in user
          post "/sales-logs/#{sales_log.id}/confirm-clear-answer", params:
        end

        it "displays correct clear links" do
          expect(page).to have_content("Are you sure you want to clear all")
          expect(page).to have_content("You've selected 3 answers to clear")
          expect(page).to have_content("You will not be able to undo this action")
          expect(page).to have_link("Cancel")
          expect(page).to have_button("Confirm and continue")
        end
      end
    end
  end

  describe "clear answer" do
    context "when user is not signed in" do
      it "redirects to sign in page for lettings" do
        post "/lettings-logs/#{lettings_log.id}/income-amount", params: {}
        expect(response).to redirect_to("/account/sign-in")
      end

      it "redirects to sign in page for sales" do
        post "/sales-logs/#{sales_log.id}/buyer-1-income", params: {}
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    context "when the user is from different organisation" do
      let(:other_user) { create(:user) }

      before do
        sign_in other_user
      end

      it "renders page not found for lettings" do
        post "/lettings-logs/#{lettings_log.id}/income-amount", params: {}
        expect(response).to have_http_status(:not_found)
      end

      it "renders page not found for sales" do
        post "/sales-logs/#{lettings_log.id}/buyer-1-income", params: {}
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when user is signed in" do
      context "and clearing specific lettings question" do
        let(:params) do
          {
            id: lettings_log.id,
            lettings_log: {
              earnings: "100000",
              incfreq: "1",
              hhmemb: "2",
              clear_question_ids: "hhmemb",
              page: "income_amount",
            },
            check_errors: "",
          }
        end

        before do
          sign_in user
          post "/lettings-logs/#{lettings_log.id}/income-amount", params:
        end

        it "displays correct clear links" do
          expect(page).to have_content("Make sure these answers are correct")
          expect(page).to have_link(lettings_log.form.get_question("hhmemb", lettings_log).check_answer_prompt, href: "/lettings-logs/#{lettings_log.id}/household-members?referrer=check_answers_new_answer", class: "govuk-link govuk-link--no-visited-state")
          expect(page).to have_link("Answer")
          expect(lettings_log.reload.earnings).to eq(nil)
        end
      end

      context "and clearing ppostcode_full when previous_la_known is yes" do
        let(:params) do
          {
            id: lettings_log.id,
            lettings_log: {
              layear: "1",
              clear_question_ids: "ppostcode_full",
              page: "time_lived_in_local_authority",
            },
            check_errors: "",
          }
        end

        before do
          lettings_log.update!(previous_la_known: 1, ppcodenk: 0, ppostcode_full: "AA11AA")
          sign_in user
          post "/lettings-logs/#{lettings_log.id}/time-lived-in-local-authority", params:
        end

        it "clears related previous location fields" do
          expect(lettings_log.reload.prevloc).to eq(nil)
          expect(lettings_log.reload.previous_la_known).to eq(nil)
          expect(lettings_log.reload.ppostcode_full).to eq(nil)
          expect(lettings_log.reload.ppcodenk).to eq(nil)
        end
      end

      context "and clearing specific sales question" do
        let(:params) do
          {
            id: sales_log.id,
            sales_log: {
              income1: "100000",
              la: "E09000001",
              ownershipsch: "1",
              clear_question_ids: "income1",
              page: "buyer_1_income",
            },
            check_errors: "",
          }
        end

        before do
          sign_in user
          post "/sales-logs/#{sales_log.id}/buyer-1-income", params:
        end

        it "displays correct clear links" do
          expect(page).to have_content("Make sure these answers are correct")
          expect(page).to have_link(sales_log.form.get_question("income1", sales_log).check_answer_prompt, href: "/sales-logs/#{sales_log.id}/buyer-1-income?referrer=check_answers_new_answer", class: "govuk-link govuk-link--no-visited-state")
          expect(page).to have_link("Answer")
          expect(sales_log.reload.income1).to eq(nil)
        end
      end
    end
  end

  describe "answer incomplete question" do
    context "when user is signed in" do
      context "and answering specific lettings question" do
        let(:params) do
          {
            original_page_id: "household_members",
            referrer: "check_errors",
            related_question_ids: %w[hhmemb ecstat1 earnings],
            lettings_log: {
              page: "household_members",
              hhmemb: "2",
            },
          }
        end

        before do
          sign_in user
          post "/lettings-logs/#{lettings_log.id}/household-members", params:
        end

        it "maintains original check_errors data in query params" do
          follow_redirect!
          expect(request.query_parameters["check_errors"]).to eq("true")
          expect(request.query_parameters["related_question_ids"]).to eq(%w[hhmemb ecstat1 earnings])
          expect(page).to have_content("You have successfully updated Number of household members")
          expect(page).to have_link("Confirm and continue", href: "/lettings-logs/#{lettings_log.id}/household-members")
        end
      end

      context "and answering specific sales question" do
        let(:params) do
          {
            original_page_id: "buyer_1_income",
            referrer: "check_errors",
            related_question_ids: %w[income1 la ownershipsch],
            sales_log: {
              page: "buyer_1_income",
              income1: "1000",
              income1nk: "0",
            },
          }
        end

        before do
          sign_in user
          post "/sales-logs/#{sales_log.id}/buyer-1-income", params:
        end

        it "maintains original check_errors data in query params" do
          follow_redirect!
          expect(request.query_parameters["check_errors"]).to eq("true")
          expect(request.query_parameters["related_question_ids"]).to eq(%w[income1 la ownershipsch])
          expect(page).to have_content("You have successfully updated Buyer 1’s gross annual income known and Buyer 1’s gross annual income")
          expect(page).to have_link("Confirm and continue", href: "/sales-logs/#{sales_log.id}/buyer-1-income")
        end
      end
    end
  end

  describe "clear all answers" do
    context "when user is signed in" do
      context "and clearing all lettings question" do
        let(:params) do
          {
            id: lettings_log.id,
            lettings_log: {
              earnings: "100000",
              incfreq: "1",
              hhmemb: "2",
              clear_question_ids: "earnings incfreq hhmemb",
              page: "income_amount",
            },
            check_errors: "",
          }
        end

        before do
          sign_in user
          post "/lettings-logs/#{lettings_log.id}/income-amount", params:
        end

        it "correctly clears the values" do
          expect(page).to have_content("Make sure these answers are correct")
          expect(page).to have_link(lettings_log.form.get_question("hhmemb", lettings_log).check_answer_prompt, href: "/lettings-logs/#{lettings_log.id}/household-members?referrer=check_answers_new_answer", class: "govuk-link govuk-link--no-visited-state")
          expect(page.all(:button, value: "Clear").count).to eq(0)
          expect(lettings_log.reload.earnings).to eq(nil)
          expect(lettings_log.reload.incfreq).to eq(nil)
          expect(lettings_log.reload.hhmemb).to eq(nil)
        end
      end

      context "and clearing all sales question" do
        let(:params) do
          {
            id: sales_log.id,
            sales_log: {
              income1: "100000",
              la: "E09000001",
              ownershipsch: "1",
              clear_question_ids: "income1 la ownershipsch",
              page: "buyer_1_income",
            },
            check_errors: "",
          }
        end

        before do
          sign_in user
          post "/sales-logs/#{sales_log.id}/buyer-1-income", params:
        end

        it "displays correct clear links" do
          expect(page).to have_content("Make sure these answers are correct")
          expect(page).to have_link(sales_log.form.get_question("income1", sales_log).check_answer_prompt, href: "/sales-logs/#{sales_log.id}/buyer-1-income?referrer=check_answers_new_answer", class: "govuk-link govuk-link--no-visited-state")
          expect(page.all(:button, value: "Clear").count).to eq(0)
          expect(sales_log.reload.income1).to eq(nil)
          expect(sales_log.reload.la).to eq(nil)
          expect(sales_log.reload.ownershipsch).not_to eq(nil)
        end
      end
    end
  end
end
