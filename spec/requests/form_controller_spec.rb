require "rails_helper"

RSpec.describe FormController, type: :request do
  let(:page) { Capybara::Node::Simple.new(response.body) }
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
  let(:setup_complete_case_log) do
    FactoryBot.create(
      :case_log,
      :about_completed,
      status: 1,
      startdate: Time.zone.local(2021, 10, 10),
      owning_organisation: organisation,
      managing_organisation: organisation,
    )
  end
  let(:completed_case_log) do
    FactoryBot.create(
      :case_log,
      :completed,
      owning_organisation: organisation,
      managing_organisation: organisation,
    )
  end
  let(:case_log_2022) do
    FactoryBot.create(
      :case_log,
      startdate: Time.zone.local(2022, 12, 1),
      owning_organisation: organisation,
      managing_organisation: organisation,
    )
  end
  let(:headers) { { "Accept" => "text/html" } }

  context "when a user is not signed in" do
    describe "GET" do
      it "does not let you get case logs pages you don't have access to" do
        get "/logs/#{case_log.id}/person-1-age", headers: headers, params: {}
        expect(response).to redirect_to("/account/sign-in")
      end

      it "does not let you get case log check answer pages you don't have access to" do
        get "/logs/#{case_log.id}/household-characteristics/check-answers", headers: headers, params: {}
        expect(response).to redirect_to("/account/sign-in")
      end
    end

    describe "POST" do
      it "does not let you post form answers to case logs you don't have access to" do
        post "/logs/#{case_log.id}/form", params: {}
        expect(response).to redirect_to("/account/sign-in")
      end
    end
  end

  context "when a user is signed in" do
    before do
      sign_in user
    end

    describe "GET" do
      context "with form pages" do
        context "when forms exist for multiple years" do
          let(:case_log_year_1) { FactoryBot.create(:case_log, startdate: Time.zone.local(2021, 5, 1), owning_organisation: organisation) }
          let(:case_log_year_2) { FactoryBot.create(:case_log, :about_completed, startdate: Time.zone.local(2022, 5, 1), owning_organisation: organisation) }

          it "displays the correct question details for each case log based on form year" do
            get "/logs/#{case_log_year_1.id}/tenant-code-test", headers: headers, params: {}
            expect(response.body).to include("What is the tenant code?")
            get "/logs/#{case_log_year_2.id}/tenant-code-test", headers: headers, params: {}
            expect(response.body).to match("Different question header text for this year - 2023")
          end
        end

        context "when case logs are not owned or managed by your organisation" do
          it "does not show form pages for case logs you don't have access to" do
            get "/logs/#{unauthorized_case_log.id}/person-1-age", headers: headers, params: {}
            expect(response).to have_http_status(:not_found)
          end
        end

        context "with a form page that has custom guidance" do
          it "displays the correct partial" do
            get "/logs/#{case_log.id}/net-income", headers: headers, params: {}
            expect(response.body).to match("What counts as income?")
          end
        end
      end

      context "when displaying check answers pages" do
        context "when case logs are not owned or managed by your organisation" do
          it "does not show a check answers for case logs you don't have access to" do
            get "/logs/#{unauthorized_case_log.id}/household-characteristics/check-answers", headers: headers, params: {}
            expect(response).to have_http_status(:not_found)
          end
        end

        context "when no other sections are enabled" do
          before do
            get "/logs/#{case_log_2022.id}/setup/check-answers", headers: headers, params: {}
          end

          it "does not show Save and go to next incomplete section button" do
            expect(page).not_to have_content("Save and go to next incomplete section")
          end
        end
      end

      context "with a question in a section that isn't enabled yet" do
        it "routes back to the tasklist page" do
          get "/logs/#{case_log.id}/declaration", headers: headers, params: {}
          expect(response).to redirect_to("/logs/#{case_log.id}")
        end
      end

      context "with a question that isn't enabled yet" do
        it "routes back to the tasklist page" do
          get "/logs/#{case_log.id}/conditional-question-no-second-page", headers: headers, params: {}
          expect(response).to redirect_to("/logs/#{case_log.id}")
        end
      end

      context "when visiting the review page" do
        it "renders the review page for the case log" do
          get "/logs/#{setup_complete_case_log.id}/review", headers: headers, params: {}
          expect(response.body).to match("Review lettings log")
        end
      end
    end

    describe "Submit Form" do
      context "with a form page" do
        let(:user) { FactoryBot.create(:user) }
        let(:organisation) { user.organisation }
        let(:case_log) do
          FactoryBot.create(
            :case_log,
            owning_organisation: organisation,
            managing_organisation: organisation,
          )
        end
        let(:page_id) { "person_1_age" }
        let(:params) do
          {
            id: case_log.id,
            case_log: {
              page: page_id,
              age1: answer,
            },
          }
        end
        let(:valid_params) do
          {
            id: case_log.id,
            case_log: {
              page: page_id,
              age1: valid_answer,
            },
          }
        end

        context "with invalid answers" do
          let(:page) { Capybara::Node::Simple.new(response.body) }
          let(:answer) { 2000 }
          let(:valid_answer) { 20 }

          before do
            allow(Rails.logger).to receive(:info)
          end

          it "re-renders the same page with errors if validation fails" do
            post "/logs/#{case_log.id}/form", params: params
            expect(response).to redirect_to("/logs/#{case_log.id}/#{page_id.dasherize}")
            follow_redirect!
            expect(page).to have_content("There is a problem")
          end

          it "resets errors when fixed" do
            post "/logs/#{case_log.id}/form", params: params
            post "/logs/#{case_log.id}/form", params: valid_params
            get "/logs/#{case_log.id}/#{page_id.dasherize}"
            expect(page).not_to have_content("There is a problem")
          end

          it "logs that validation was triggered" do
            expect(Rails.logger).to receive(:info).with("User triggered validation(s) on: age1").once
            post "/logs/#{case_log.id}/form", params: params
          end
        end

        context "with valid answers" do
          let(:answer) { 20 }
          let(:params) do
            {
              id: case_log.id,
              case_log: {
                page: page_id,
                age1: answer,
                age2: 2000,
              },
            }
          end

          before do
            post "/logs/#{case_log.id}/form", params:
          end

          it "re-renders the same page with errors if validation fails" do
            expect(response).to have_http_status(:redirect)
          end

          it "only updates answers that apply to the page being submitted" do
            case_log.reload
            expect(case_log.age1).to eq(answer)
            expect(case_log.age2).to be nil
          end

          it "tracks who updated the record" do
            case_log.reload
            whodunnit_actor = case_log.versions.last.actor
            expect(whodunnit_actor).to be_a(User)
            expect(whodunnit_actor.id).to eq(user.id)
          end
        end
      end

      context "with checkbox questions" do
        let(:case_log_form_params) do
          {
            id: case_log.id,
            case_log: {
              page: "accessibility_requirements",
              accessibility_requirements:
                                     %w[housingneeds_b],
            },
          }
        end

        let(:new_case_log_form_params) do
          {
            id: case_log.id,
            case_log: {
              page: "accessibility_requirements",
              accessibility_requirements: %w[housingneeds_c],
            },
          }
        end

        it "sets checked items to true" do
          post "/logs/#{case_log.id}/form", params: case_log_form_params
          case_log.reload

          expect(case_log.housingneeds_b).to eq(1)
        end

        it "sets previously submitted items to false when resubmitted with new values" do
          post "/logs/#{case_log.id}/form", params: new_case_log_form_params
          case_log.reload

          expect(case_log.housingneeds_b).to eq(0)
          expect(case_log.housingneeds_c).to eq(1)
        end

        context "with a page having checkbox and non-checkbox questions" do
          let(:tenant_code) { "BZ355" }
          let(:case_log_form_params) do
            {
              id: case_log.id,
              case_log: {
                page: "accessibility_requirements",
                accessibility_requirements:
                                       %w[ housingneeds_a
                                           housingneeds_f],
                tenancycode: tenant_code,
              },
            }
          end
          let(:questions_for_page) do
            [
              Form::Question.new(
                "accessibility_requirements",
                {
                  "type" => "checkbox",
                  "answer_options" =>
                  { "housingneeds_a" => "Fully wheelchair accessible housing",
                    "housingneeds_b" => "Wheelchair access to essential rooms",
                    "housingneeds_c" => "Level access housing",
                    "housingneeds_f" => "Other disability requirements",
                    "housingneeds_g" => "No disability requirements",
                    "divider_a" => true,
                    "housingneeds_h" => "Don’t know" },
                }, nil
              ),
              Form::Question.new("tenancycode", { "type" => "text" }, nil),
            ]
          end
          let(:page) { case_log.form.get_page("accessibility_requirements") }

          it "updates both question fields" do
            allow(page).to receive(:questions).and_return(questions_for_page)
            post "/logs/#{case_log.id}/form", params: case_log_form_params
            case_log.reload

            expect(case_log.housingneeds_a).to eq(1)
            expect(case_log.housingneeds_f).to eq(1)
            expect(case_log.tenancycode).to eq(tenant_code)
          end
        end
      end

      context "with conditional routing" do
        let(:validator) { case_log._validators[nil].first }
        let(:case_log_form_conditional_question_yes_params) do
          {
            id: case_log.id,
            case_log: {
              page: "conditional_question",
              preg_occ: 1,
            },
          }
        end
        let(:case_log_form_conditional_question_no_params) do
          {
            id: case_log.id,
            case_log: {
              page: "conditional_question",
              preg_occ: 2,
            },
          }
        end
        let(:case_log_form_conditional_question_wchair_yes_params) do
          {
            id: case_log.id,
            case_log: {
              page: "property_wheelchair_accessible",
              wchair: 1,
            },
          }
        end

        before do
          allow(validator).to receive(:validate_pregnancy).and_return(true)
        end

        it "routes to the appropriate conditional page based on the question answer of the current page" do
          post "/logs/#{case_log.id}/form", params: case_log_form_conditional_question_yes_params
          expect(response).to redirect_to("/logs/#{case_log.id}/conditional-question-yes-page")

          post "/logs/#{case_log.id}/form", params: case_log_form_conditional_question_no_params
          expect(response).to redirect_to("/logs/#{case_log.id}/conditional-question-no-page")
        end

        it "routes to the page if at least one of the condition sets is met" do
          post "/logs/#{case_log.id}/form", params: case_log_form_conditional_question_wchair_yes_params
          post "/logs/#{case_log.id}/form", params: case_log_form_conditional_question_no_params
          expect(response).to redirect_to("/logs/#{case_log.id}/conditional-question-yes-page")
        end
      end

      context "when coming from check answers page" do
        context "and navigating to an interruption screen" do
          let(:interrupt_params) do
            {
              id: completed_case_log.id,
              case_log: {
                page: "net_income_value_check",
                net_income_value_check: value,
              },
            }
          end
          let(:referrer) { "/logs/#{completed_case_log.id}/net-income-value-check?referrer=check_answers" }

          before do
            completed_case_log.update!(ecstat1: 1, earnings: 130, hhmemb: 1) # we're not routing to that page, so it gets cleared?§
            allow(completed_case_log).to receive(:net_income_soft_validation_triggered?).and_return(true)
            post "/logs/#{completed_case_log.id}/form", params: interrupt_params, headers: headers.merge({ "HTTP_REFERER" => referrer })
          end

          context "when yes is answered" do
            let(:value) { 0 }

            it "redirects back to check answers if 'yes' is selected" do
              expect(response).to redirect_to("/logs/#{completed_case_log.id}/income-and-benefits/check-answers")
            end
          end

          context "when no is answered" do
            let(:value) { 1 }

            it "redirects to the previous question if 'no' is selected" do
              expect(response).to redirect_to("/logs/#{completed_case_log.id}/net-income?referrer=check_answers")
            end
          end
        end
      end

      context "with case logs that are not owned or managed by your organisation" do
        let(:answer) { 25 }
        let(:other_organisation) { FactoryBot.create(:organisation) }
        let(:unauthorized_case_log) do
          FactoryBot.create(
            :case_log,
            owning_organisation: other_organisation,
            managing_organisation: other_organisation,
          )
        end

        before do
          post "/logs/#{unauthorized_case_log.id}/form", params: {}
        end

        it "does not let you post form answers to case logs you don't have access to" do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
