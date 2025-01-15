require "rails_helper"
require_relative "schemes_helpers"

RSpec.describe "Schemes scheme Features" do
  include SchemesHelpers
  context "when viewing list of schemes" do
    context "when I am signed as a coordinator user and there are schemes in the database" do
      let(:organisation) { FactoryBot.create(:organisation, name: "MHCLG") }
      let!(:user) { FactoryBot.create(:user, :data_coordinator, organisation:, last_sign_in_at: Time.zone.now) }
      let!(:schemes) { FactoryBot.create_list(:scheme, 5, owning_organisation: organisation) }
      let!(:scheme_to_search) { FactoryBot.create(:scheme, owning_organisation: organisation) }

      before do
        Timecop.freeze(Time.zone.local(2024, 3, 1))
        visit("/lettings-logs")
        fill_in("user[email]", with: user.email)
        fill_in("user[password]", with: user.password)
        click_button("Sign in")
      end

      after do
        Timecop.return
      end

      it "displays the link to the schemes" do
        expect(page).to have_link("Schemes", href: "/schemes")
      end

      context "when I click schemes" do
        before do
          click_link "Schemes", href: "/schemes"
        end

        it "shows list of schemes" do
          schemes.each do |scheme|
            expect(page).to have_content(scheme.id)
          end
        end

        context "when I search for a specific scheme" do
          it "there is a search bar with a message and search button for schemes" do
            expect(page).to have_field("search")
            expect(page).to have_content("Search by postcode, scheme name, scheme code or location name")
            expect(page).to have_button("Search")
          end

          context "when I fill in search information and press the search button" do
            before do
              fill_in("search", with: scheme_to_search.id_to_display)
              click_button("Search")
            end

            it "displays scheme matching the scheme code" do
              expect(page).to have_content(scheme_to_search.id_to_display)
            end

            context "when I want to clear results" do
              it "there is link to clear the search results" do
                expect(page).to have_link("Clear search")
              end

              it "displays all schemes after I clear the search results" do
                click_link("Clear search")
                expect(page).to have_content(scheme_to_search.id)
                schemes.each do |scheme|
                  expect(page).to have_content(scheme.id)
                end
              end
            end
          end
        end

        context "when filtering schemes" do
          context "when no filters are selected" do
            it "displays the filters component with no clear button" do
              expect(page).to have_content("No filters applied")
              expect(page).not_to have_link("Clear", href: "/clear-filters?filter_type=schemes")
            end
          end

          context "when I have selected filters" do
            before do
              check("Active")
              check("Incomplete")
              click_button("Apply filters")
            end

            it "displays the filters component with a correct count and clear button" do
              expect(page).to have_content("2 filters applied")
              expect(page).to have_link("Clear", href: /clear-filters\?.*filter_type=schemes/)
            end

            context "when clearing the filters" do
              before do
                click_link("Clear")
              end

              it "clears the filters and displays the filter component as before" do
                expect(page).to have_content("No filters applied")
                expect(page).not_to have_link("Clear", href: "/clear-filters?filter_type=schemes")
              end
            end

            context "when on the scheme question page" do
              let(:lettings_log) { FactoryBot.create(:lettings_log, assigned_to: user, needstype: 2) }

              it "open from guidance page with filters cleared" do
                expect(page).to have_text("2 filters applied")
                visit("/lettings-logs/#{lettings_log.id}/scheme")
                find(".govuk-details__summary").click
                expect(page).to have_link("View your organisation’s schemes")
                click_link "View your organisation’s schemes"
                expect(page).to have_current_path("/organisations/#{user.organisation.id}/schemes")
                expect(page).to have_text("No filters applied")
              end
            end
          end
        end
      end
    end
  end

  context "when I am signed as a support user and there are schemes in the database" do
    let(:user) { FactoryBot.create(:user, :support, last_sign_in_at: Time.zone.now) }
    let!(:schemes) { FactoryBot.create_list(:scheme, 5) }
    let!(:scheme_to_search) { FactoryBot.create(:scheme) }
    let(:notify_client) { instance_double(Notifications::Client) }
    let(:confirmation_token) { "MCDH5y6Km-U7CFPgAMVS" }
    let(:devise_notify_mailer) { DeviseNotifyMailer.new }
    let(:otp) { "999111" }

    before do
      allow(DeviseNotifyMailer).to receive(:new).and_return(devise_notify_mailer)
      allow(devise_notify_mailer).to receive(:notify_client).and_return(notify_client)
      allow(Devise).to receive(:friendly_token).and_return(confirmation_token)
      allow(notify_client).to receive(:send_email).and_return(true)
      allow(SecureRandom).to receive(:random_number).and_return(otp)
      visit("/lettings-logs")
      fill_in("user[email]", with: user.email)
      fill_in("user[password]", with: user.password)
      click_button("Sign in")
      fill_in("code", with: otp)
      click_button("Submit")
    end

    it "allows navigating to the schemes from the home page" do
      expect(page).to have_link("Schemes", href: "/schemes")
    end

    context "when viewing list of schemes" do
      before do
        click_link "Schemes", href: "/schemes"
      end

      it "shows a list of schemes" do
        schemes.each do |scheme|
          expect(page).to have_link(scheme.service_name)
          expect(page).to have_content(scheme.id_to_display)
          expect(page).to have_content(scheme.locations&.count)
        end
      end

      it "displays a search bar" do
        expect(page).to have_field("search")
        expect(page).to have_content("Search by postcode, scheme name, scheme code or location name")
        expect(page).to have_button("Search")
      end

      it "allows searching the schemes by scheme code" do
        fill_in("search", with: scheme_to_search.id_to_display)
        click_button("Search")
        expect(page).to have_content(scheme_to_search.id_to_display)
      end

      it "returns results with no location" do
        scheme_without_location = FactoryBot.create(:scheme)
        visit "/schemes"
        fill_in("search", with: scheme_without_location.id_to_display)
        click_button("Search")
        expect(page).to have_content(scheme_without_location.id_to_display)
      end

      it "allows clearing the search results" do
        fill_in("search", with: scheme_to_search.id_to_display)
        click_button("Search")
        click_link("Clear search")
        expect(page).to have_content(scheme_to_search.id_to_display)
        schemes.each do |scheme|
          expect(page).to have_content(scheme.id_to_display)
        end
      end
    end

    context "when viewing individual scheme" do
      let!(:schemes) { FactoryBot.create_list(:scheme, 5) }
      let!(:same_organisation_schemes) { FactoryBot.create_list(:scheme, 5, owning_organisation: user.organisation) }

      context "when I visit schemes page" do
        before do
          visit("schemes")
        end

        context "when I click to see individual scheme" do
          let(:scheme) { same_organisation_schemes.first }

          before do
            click_link(scheme.service_name)
          end

          it "shows me details about the selected scheme" do
            expect(page).to have_content(scheme.id_to_display)
            expect(page).to have_content(scheme.service_name)
            expect(page).to have_content(scheme.sensitive)
            expect(page).to have_content(scheme.scheme_type)
            expect(page).to have_content(scheme.registered_under_care_act)
            expect(page).to have_content(scheme.primary_client_group)
            expect(page).to have_content(scheme.secondary_client_group)
            expect(page).to have_content(scheme.support_type)
            expect(page).to have_content(scheme.intended_stay)
          end

          context "when I click to go back" do
            before do
              visit("schemes")
              click_link(scheme.service_name)
            end

            it "shows list of links to the organisation's schemes" do
              click_on("Schemes (#{user.organisation.name})")
              same_organisation_schemes.each do |scheme|
                expect(page).to have_link(scheme.service_name)
                expect(page).to have_content(scheme.id_to_display)
                expect(page).to have_content(scheme.locations&.count)
              end
            end
          end

          context "when there are locations that belong to the selected scheme" do
            let!(:schemes) { FactoryBot.create_list(:scheme, 5) }
            let(:scheme)     { schemes.first }
            let!(:locations) { FactoryBot.create_list(:location, 3, scheme:, postcode: "XX11XX", startdate: Time.utc(2022, 1, 1)) }

            before do
              visit("schemes")
              click_link(scheme.service_name)
            end

            it "shows service and locations tab" do
              expect(page).to have_link("Scheme")
              expect(page).to have_link("Locations")
            end

            context "when I click locations link and the new locations layout feature toggle is enabled" do
              before do
                click_link("Locations")
              end

              it "shows details of those locations" do
                locations.each do |location|
                  expect(page).to have_content(location.id)
                  expect(page).to have_content(location.postcode)
                  expect(page).to have_content(location.name)
                  expect(page).to have_content("Active")
                end
              end
            end

            context "when I search for a specific location" do
              before do
                click_link("Locations")
              end

              it "there is a search bar with a message and search button for locations" do
                expect(page).to have_field("search")
                expect(page).to have_content("Search by location name or postcode")
                expect(page).to have_button("Search")
              end

              context "when I fill in search information and press the search button" do
                let(:postcode_to_search) { "NW38RR" }
                let(:location_name_to_search) { "search name location" }
                let(:location_to_search) { FactoryBot.create(:location, postcode: postcode_to_search, name: location_name_to_search, scheme:) }

                before do
                  fill_in("search", with: location_to_search.name)
                  click_button("Search")
                end

                it "displays scheme matching the location name" do
                  expect(page).to have_content(location_name_to_search)
                end

                context "when I want to clear results" do
                  it "there is link to clear the search results" do
                    expect(page).to have_link("Clear search")
                  end

                  it "displays all schemes after I clear the search results" do
                    click_link("Clear search")
                    Location.all.each do |location|
                      expect(page).to have_content(location.name)
                    end
                  end
                end
              end
            end

            context "when filtering locations" do
              before do
                click_link("Locations")
              end

              context "when no filters are selected" do
                it "displays the filters component with no clear button" do
                  expect(page).to have_content("No filters applied")
                  expect(page).not_to have_link("Clear", href: /\/clear-filters\?filter_type=scheme_locations/)
                end
              end

              context "when I have selected filters" do
                before do
                  check("Active")
                  check("Incomplete")
                  click_button("Apply filters")
                end

                it "displays the filters component with a correct count and clear button" do
                  expect(page).to have_content("2 filters applied")
                  expect(page).to have_link("Clear", href: /\/clear-filters\?.*filter_type=scheme_locations/)
                end

                context "when clearing the filters" do
                  before do
                    click_link("Clear")
                  end

                  it "clears the filters and displays the filter component as before" do
                    expect(page).to have_content("No filters applied")
                    expect(page).not_to have_link("Clear", href: /\/clear-filters\?filter_type=scheme_locations/)
                  end
                end
              end
            end

            context "when the user clicks add location" do
              before do
                click_link("Locations")
                click_button("Add a location")
              end

              it "shows the new location form" do
                expect(page).to have_content("Add a location to #{scheme.service_name}")
              end

              context "when the user completes the new location form" do
                let(:location_name) { "Area 42" }

                before do
                  fill_in with: "XX12XX"
                  click_button "Save and continue"
                  select "Adur"
                  click_button "Save and continue"
                  fill_in with: location_name
                  click_button "Save and continue"
                  fill_in with: 1
                  click_button "Save and continue"
                  choose "Self-contained house"
                  click_button "Save and continue"
                  choose "location-mobility-type-none-field"
                  click_button "Save and continue"
                  fill_in "location_startdate", with: "2/2/2022"
                  click_button "Save and continue"
                end

                it "shows the location check answers page" do
                  expect(page.current_url.split("/").last).to eq("check-answers")
                  expect(page).to have_content(location_name)
                end

                it "has the correct action button text" do
                  expect(page).to have_button("Save and return to locations")
                end

                it "allows you to edit the newly added location" do
                  expect(page).to have_link(href: /postcode/)
                end

                context "when you click save" do
                  before do
                    click_button "Save and return to locations"
                  end

                  it "displays a updated banner" do
                    expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
                    expect(page).to have_content("has been added")
                  end

                  it "lets you edit the saved location" do
                    click_link "XX12XX"
                    expect(page).to have_link("Change", href: /postcode/)
                  end
                end

                context "when you click to view the scheme details" do
                  before do
                    click_button "Save and return to locations"
                    click_link("Scheme")
                  end

                  it "does not let you change details other than the name, confidential information and housing stock owner" do
                    assert_selector "a", text: "Change", count: 11
                  end
                end
              end
            end
          end
        end
      end
    end

    context "when creating a new scheme" do
      let(:organisation_name) { "FooBar" }
      let(:scheme) { Scheme.first }
      let(:location) { Location.first }

      before do
        FactoryBot.create(:organisation, name: organisation_name)
        Scheme.destroy_all
        click_link "Schemes", href: "/schemes"
      end

      it "displays the link to create a new scheme" do
        expect(page).to have_current_path("/schemes")
        expect(page).to have_link("Create a new supported housing scheme")
      end

      context "when I press create a new scheme" do
        before do
          allow(FormHandler.instance).to receive(:lettings_in_crossover_period?).and_return(true)
          click_link "Create a new supported housing scheme"
        end

        it "lets me fill in the scheme details" do
          expect(page).to have_current_path("/schemes/new")
          expect(page).to have_content "Scheme name"
          expect(page).to have_content "This scheme contains confidential information"
          expect(page).to have_content "Which organisation owns the housing stock for this scheme?"
          expect(page).to have_content "What is this type of scheme?"
          expect(page).to have_content "Is this scheme registered under the Care Standards Act 2000?"
          expect(page).to have_content "Who provides the support services used by this scheme?"
        end

        it "lets me fill in the primary client group" do
          fill_in_and_save_scheme_details
          expect(page).to have_content "What client group is this scheme intended for?"
        end

        it "allows to navigate back and fill in the scheme details" do
          fill_in_and_save_scheme_details
          click_link "Back"
          expect(page).to have_current_path("/schemes/#{scheme.id}/details")
          expect(page).to have_content "Scheme name"
          expect(page).to have_content "This scheme contains confidential information"
          expect(page).to have_content "What is this type of scheme?"
          expect(page).to have_content "Who provides the support services used by this scheme?"
          expect(page).to have_content "Is this scheme registered under the Care Standards Act 2000?"
        end

        it "returns to the primary client group question after amending scheme details" do
          fill_in_and_save_scheme_details
          click_link "Back"
          click_button "Save and continue"
          expect(page).to have_current_path("/schemes/#{scheme.id}/primary-client-group")
        end

        it "allows confirming if the scheme provides for secondary group details" do
          fill_in_and_save_scheme_details
          fill_in_and_save_primary_client_group
          expect(page).to have_content "Does this scheme provide for another client group?"
        end

        it "allows amending primary client group after navigating back from secondary client group confirmation question" do
          fill_in_and_save_scheme_details
          fill_in_and_save_primary_client_group
          click_link "Back"
          expect(page).to have_current_path("/schemes/#{scheme.id}/primary-client-group")
          expect(page).to have_content "What client group is this scheme intended for?"
        end

        it "returns to the secondary group details confirmation question after amending primary client group" do
          fill_in_and_save_scheme_details
          fill_in_and_save_primary_client_group
          click_link "Back"
          click_button "Save and continue"
          expect(page).to have_current_path("/schemes/#{scheme.id}/confirm-secondary-client-group")
        end

        it "allows selecting secondary client group if the scheme provides for it" do
          fill_in_and_save_scheme_details
          fill_in_and_save_primary_client_group
          fill_in_and_save_secondary_client_group_confirmation_yes
          expect(page).to have_content "What is the other client group?"
        end

        it "allows amending secondary client group confirmation question after navigating from secondary client group question" do
          fill_in_and_save_scheme_details
          fill_in_and_save_primary_client_group
          fill_in_and_save_secondary_client_group_confirmation_yes
          click_link "Back"
          expect(page).to have_current_path("/schemes/#{scheme.id}/confirm-secondary-client-group")
          expect(page).to have_content "Does this scheme provide for another client group?"
        end

        it "returns to the secondary group details question after amending secondary group details confirmation" do
          fill_in_and_save_scheme_details
          fill_in_and_save_primary_client_group
          fill_in_and_save_secondary_client_group_confirmation_yes
          click_link "Back"
          click_button "Save and continue"
          expect(page).to have_current_path("/schemes/#{scheme.id}/secondary-client-group")
        end

        it "allows selecting the level of support" do
          fill_in_and_save_scheme_details
          fill_in_and_save_primary_client_group
          fill_in_and_save_secondary_client_group_confirmation_yes
          fill_in_and_save_secondary_client_group
          expect(page).to have_content "What support does this scheme provide?"
        end

        it "allows amending secondary client group question after navigating from level of support" do
          fill_in_and_save_scheme_details
          fill_in_and_save_primary_client_group
          fill_in_and_save_secondary_client_group_confirmation_yes
          fill_in_and_save_secondary_client_group
          click_link "Back"
          expect(page).to have_current_path("/schemes/#{scheme.id}/secondary-client-group")
          expect(page).to have_content "What is the other client group?"
        end

        it "returns to the level of support question after amending secondary group details" do
          fill_in_and_save_scheme_details
          fill_in_and_save_primary_client_group
          fill_in_and_save_secondary_client_group_confirmation_yes
          fill_in_and_save_secondary_client_group
          click_link "Back"
          click_button "Save and continue"
          expect(page).to have_current_path("/schemes/#{scheme.id}/support")
        end

        context "when adding a location" do
          before do
            create_and_save_a_scheme
            click_button "Create scheme"
          end

          it "lets me add location" do
            click_link "Locations"
            expect(page).to have_content "Add a location"
          end

          it "lets me check my answers after adding a location" do
            fill_in_and_save_location
            expect(page).to have_current_path("/schemes/#{scheme.id}/locations/#{location.id}/check-answers")
            expect(page).to have_content "Check your answers"
          end

          it "lets me check my answers after adding a second location" do
            fill_in_and_save_location
            click_button "Save and return to locations"
            fill_in_and_save_second_location
            expect(page).to have_content "Check your answers"
          end

          it "dispays correct text for unanswered questions" do
            fill_in_and_save_location
            location.update!(location_code: nil)
            visit "/schemes/#{scheme.id}/locations/#{location.id}/check-answers"
            expect(page).to have_content "You didn’t answer this question"
          end
        end

        context "when viewing locations" do
          before do
            create_and_save_a_scheme
            click_button "Create scheme"
            fill_in_and_save_location
            click_button "Save and return to locations"
            click_link "Locations"
          end

          it "displays information about a single location" do
            expect(page).to have_content "Locations"
            expect(page).to have_content "#{scheme.locations.count} total location"
          end

          it "displays information about the first created location" do
            expect(page).to have_content "XX11XX"
            expect(page).to have_content "Some name"
            expect(page).to have_content "Active"
          end

          it "displays information about another location" do
            fill_in_and_save_second_location
            click_button "Save and return to locations"
            expect(page).to have_content "Locations"
            expect(page).to have_content "#{scheme.locations.count} total location"
          end

          it "displays information about newly created location" do
            fill_in_and_save_second_location
            expect(page).to have_content "XX12XX"
            expect(page).to have_content "Other name"
            expect(page).to have_content "Self-contained house"
          end
        end

        context "when changing location details" do
          before do
            create_and_save_a_scheme
            click_button "Create scheme"
            fill_in_and_save_second_location
            click_button "Save and return to locations"
          end

          it "displays changed location" do
            click_link "XX12XX"
            click_link("Change", href: "/schemes/#{scheme.id}/locations/#{location.id}/name?referrer=details", match: :first)
            fill_in with: "new name"
            click_button "Save changes"
            expect(page).to have_content "XX12XX"
            expect(page).to have_content "new name"
          end
        end

        context "when changing scheme answers" do
          before do
            create_and_save_a_scheme_no_secondary_client_group
          end

          it "displays change links" do
            assert_selector "a", text: "Change", count: 10
          end

          it "allows changing details questions" do
            click_link("Change", href: "/schemes/#{scheme.id}/details?referrer=check-answers", match: :first)
            expect(page).to have_current_path("/schemes/#{scheme.id}/details?referrer=check-answers")

            fill_in "Scheme name", with: "Example"
            click_button "Save changes"

            expect(page).to have_current_path("/schemes/#{scheme.id}/check-answers")
            expect(page).to have_content "Example"
          end

          it "lets me select the support answers after navigating back" do
            click_link("Change", href: "/schemes/#{scheme.id}/details?referrer=check-answers", match: :first)
            click_link "Back"
            expect(page).to have_current_path("/schemes/#{scheme.id}/check-answers")
            expect(page).to have_content "Check your changes before creating this scheme"
          end

          it "indicates if the scheme is not complete" do
            click_link("Change", href: "/schemes/#{scheme.id}/confirm-secondary-client-group?referrer=check-answers", match: :first)
            choose "Yes"
            click_button "Save changes"
            visit("/schemes/#{scheme.id}/check-answers")
            expect(page).to have_content("You didn’t answer this question")
          end
        end

        context "when selecting 'create a scheme'" do
          before do
            create_and_save_a_scheme
            click_button "Create scheme"
          end

          it "adds scheme to the list of schemes" do
            expect(page).to have_content "#{scheme.service_name} has been created."
            click_link "Schemes"
            expect(page).to have_content "Supported housing schemes"
            expect(page).to have_content scheme.id_to_display
            expect(page).to have_content scheme.service_name
            expect(page).to have_content scheme.owning_organisation.name
          end
        end

        context "when I fill in scheme details indicating that supported services provided by a different organisation and I press save I see primary client group section" do
          let(:scheme) { Scheme.first }

          before do
            fill_in_and_save_scheme_details({ "housing_stock_owners" => "Another registered stock owner" })
          end

          it "lets the primary client group to be selected" do
            expect(page).to have_content "What client group is this scheme intended for?"
          end

          context "when changing scheme answers" do
            before do
              fill_in_and_save_primary_client_group
              fill_in_and_save_secondary_client_group_confirmation_yes
              fill_in_and_save_secondary_client_group
              fill_in_and_save_support
            end

            it "displays change links" do
              assert_selector "a", text: "Change", count: 11
            end

            it "allows changing details questions" do
              click_link("Change", href: "/schemes/#{scheme.id}/details?referrer=check-answers", match: :first)
              expect(page).to have_current_path("/schemes/#{scheme.id}/details?referrer=check-answers")

              fill_in "Scheme name", with: "Example"
              click_button "Save changes"

              expect(page).to have_current_path("/schemes/#{scheme.id}/check-answers")
              expect(page).to have_content "Example"
            end

            it "lets me select the support answers after navigating back" do
              click_link("Change", href: "/schemes/#{scheme.id}/details?referrer=check-answers", match: :first)
              click_link "Back"
              expect(page).to have_current_path("/schemes/#{scheme.id}/check-answers")
              expect(page).to have_content "Check your changes before creating this scheme"
            end

            it "does not display the answer if it's changed to the same support provider" do
              click_link("Change", href: "/schemes/#{scheme.id}/details?referrer=check-answers", match: :first)
              choose "The same organisation that owns the housing stock"
              click_button "Save changes"
              expect(page).not_to have_content("Organisation providing support")
            end
          end
        end
      end
    end

    context "when editing a scheme" do
      context "when I visit schemes page" do
        before do
          visit("schemes")
        end

        it "shows list of links to schemes" do
          schemes.each do |scheme|
            expect(page).to have_link(scheme.service_name)
            expect(page).to have_content(scheme.id_to_display)
            expect(page).to have_content(scheme.locations&.count)
          end
        end

        context "when I click to see individual scheme" do
          let(:scheme) { schemes.first }
          let!(:location) { FactoryBot.create(:location, startdate: Time.zone.local(2022, 4, 4), scheme:) }
          let!(:deactivated_location) { FactoryBot.create(:location, startdate: Time.zone.local(2022, 4, 4), scheme:) }

          before do
            Timecop.freeze(Time.zone.local(2023, 10, 10))
            Singleton.__init__(FormHandler)
            FactoryBot.create(:location_deactivation_period, deactivation_date: Time.zone.local(2022, 6, 4), location: deactivated_location)
            Timecop.unfreeze
            Singleton.__init__(FormHandler)
            click_link(scheme.service_name)
          end

          it "shows me details about the selected scheme" do
            expect(page).to have_content(schemes.first.id_to_display)
            expect(page).to have_content(schemes.first.service_name)
            expect(page).to have_content(schemes.first.sensitive)
            expect(page).to have_content(schemes.first.scheme_type)
            expect(page).to have_content(schemes.first.registered_under_care_act)
            expect(page).to have_content(schemes.first.primary_client_group)
            expect(page).to have_content(schemes.first.secondary_client_group)
            expect(page).to have_content(schemes.first.support_type)
            expect(page).to have_content(schemes.first.intended_stay)
          end

          context "when I click to change scheme name" do
            before do
              click_link("Change", href: "/schemes/#{scheme.id}/details?referrer=check-answers", match: :first)
            end

            it "shows available fields to edit" do
              expect(page).to have_current_path("/schemes/#{scheme.id}/details?referrer=check-answers")
              expect(page).to have_content "Scheme details"
            end

            context "when I edit details" do
              before do
                fill_in "Scheme name", with: "FooBar"
                check "This scheme contains confidential information"
                click_button "Save changes"
              end

              it "lets me see amended details on the details page" do
                expect(page).to have_content "FooBar"
                expect(page).to have_current_path("/schemes/#{scheme.id}")
                assert_selector "a", text: "Change", count: 11
                expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
                expect(page).to have_content("has been updated")
              end
            end
          end

          context "when I click to see locations" do
            before do
              click_link "Locations"
            end

            it "I see location details" do
              expect(page).to have_content scheme.locations.first.id
              expect(page).to have_current_path("/schemes/#{scheme.id}/locations")
            end

            context "when location is inactive" do
              context "and I click to view the location" do
                before do
                  click_link(deactivated_location.postcode)
                end

                it "displays details about the selected location" do
                  expect(page).to have_current_path("/schemes/#{scheme.id}/locations/#{deactivated_location.id}")
                  expect(page).to have_content(deactivated_location.postcode)
                  expect(page).to have_content(deactivated_location.location_admin_district)
                  expect(page).to have_content(deactivated_location.name)
                  expect(page).to have_content(deactivated_location.units)
                  expect(page).to have_content(deactivated_location.type_of_unit)
                  expect(page).to have_content(deactivated_location.mobility_type)
                  expect(page).to have_content(deactivated_location.id)
                  expect(page).to have_content("Active from 4 April 2022 to 3 June 2022 Deactivated on 4 June 2022")
                  expect(page).to have_content("Deactivated")
                end

                xit "allows to reactivate a location" do
                  click_link("Reactivate this location")
                  expect(page).to have_current_path("/schemes/#{scheme.id}/locations/#{deactivated_location.id}/new-reactivation")
                  expect(page).to have_content("Reactivate #{deactivated_location.name}")
                  expect(page).to have_content("You’ll be able to add logs with this location if their tenancy start date is on or after the date you enter.")
                  expect(page).to have_content("If the date is before 1 April 2022, select ‘From the start of the open collection period’ because the previous period has now closed.")
                end

                context "when I press the back button" do
                  before do
                    click_link "Back"
                  end

                  it "I see location details" do
                    expect(page).to have_content scheme.locations.first.id
                    expect(page).to have_current_path("/schemes/#{scheme.id}/locations")
                  end
                end
              end
            end

            context "when I click to change location name" do
              before do
                click_link(location.postcode)
              end

              it "displays details about the selected location" do
                expect(page).to have_current_path("/schemes/#{scheme.id}/locations/#{location.id}")
                expect(page).to have_content(location.postcode)
                expect(page).to have_content(location.location_admin_district)
                expect(page).to have_content(location.name)
                expect(page).to have_content(location.units)
                expect(page).to have_content(location.type_of_unit)
                expect(page).to have_content(location.mobility_type)
                expect(page).to have_content(location.id)
                expect(page).to have_content("Active from 4 April 2022")
                expect(page).to have_content("Active")
              end

              it "only allows to edit the location name, postcode, unit, unit type and mobility standards" do
                assert_selector "a", text: "Change", count: 5

                click_link("Change", href: "/schemes/#{scheme.id}/locations/#{location.id}/name?referrer=details", match: :first)
                expect(page).to have_content "What is the name of this location?"
              end

              it "allows to deactivate a location" do
                click_link("Deactivate this location")
                expect(page).to have_current_path("/schemes/#{scheme.id}/locations/#{location.id}/new-deactivation")
              end

              context "when I press the back button" do
                before do
                  click_link "Back"
                end

                it "I see location details" do
                  expect(page).to have_content scheme.locations.first.id
                  expect(page).to have_current_path("/schemes/#{scheme.id}/locations")
                end
              end

              context "and I change the location name" do
                before do
                  click_link("Change", href: "/schemes/#{scheme.id}/locations/#{location.id}/name?referrer=details", match: :first)
                end

                it "returns to locations check your answers page and shows the new name" do
                  fill_in "location-name-field", with: "NewName"
                  click_button "Save changes"
                  expect(page).to have_content location.postcode
                  expect(page).to have_content "NewName"
                  expect(page).to have_current_path("/schemes/#{scheme.id}/locations/#{location.id}")
                end

                context "when I press the back button" do
                  before do
                    click_link "Back"
                  end

                  it "I see location details" do
                    expect(page).to have_content location.name
                    expect(page).to have_current_path("/schemes/#{scheme.id}/locations/#{location.id}")
                  end
                end
              end
            end

            context "when I search for a specific location" do
              before do
                click_link("Locations")
              end

              it "there is a search bar with a message and search button for locations" do
                expect(page).to have_field("search")
                expect(page).to have_content("Search by location name or postcode")
                expect(page).to have_button("Search")
              end

              context "when I fill in search information and press the search button" do
                let(:postcode_to_search) { "NW38RR" }
                let(:location_name_to_search) { "search name location" }
                let(:location_to_search) { FactoryBot.create(:location, postcode: postcode_to_search, name: location_name_to_search, scheme:) }

                before do
                  fill_in("search", with: location_to_search.name)
                  click_button("Search")
                end

                it "displays scheme matching the location name" do
                  expect(page).to have_content(location_name_to_search)
                end

                context "when I want to clear results" do
                  it "there is link to clear the search results" do
                    expect(page).to have_link("Clear search")
                  end

                  it "displays all schemes after I clear the search results" do
                    click_link("Clear search")
                    Location.all.each do |location|
                      expect(page).to have_content(location.name)
                    end
                  end
                end
              end
            end

            context "when the user clicks add location" do
              before do
                click_link("Locations")
                click_button("Add a location")
              end

              it "shows the new location form" do
                expect(page).to have_content("Add a location to #{scheme.service_name}")
              end

              context "when the user completes the new location form" do
                let(:location_name) { "Area 42" }

                before do
                  fill_in with: "XX12XX"
                  click_button "Save and continue"
                  select "Adur"
                  click_button "Save and continue"
                  fill_in with: location_name
                  click_button "Save and continue"
                  fill_in with: 1
                  click_button "Save and continue"
                  choose "Self-contained house"
                  click_button "Save and continue"
                  choose "location-mobility-type-none-field"
                  click_button "Save and continue"
                  fill_in "location_startdate", with: "2/2/2022"
                  click_button "Save and continue"
                end

                it "shows the location check answers page" do
                  expect(page.current_url.split("/").last).to eq("check-answers")
                  expect(page).to have_content(location_name)
                end

                it "has the correct action button text" do
                  expect(page).to have_button("Save and return to locations")
                end

                it "allows you to edit the newly added location" do
                  expect(page).to have_link(href: /postcode/)
                end

                context "when you click save" do
                  before do
                    click_button "Save and return to locations"
                  end

                  it "displays a updated banner" do
                    expect(page).to have_css(".govuk-notification-banner.govuk-notification-banner--success")
                    expect(page).to have_content("has been added")
                  end

                  it "lets you edit the saved location" do
                    click_link "XX12XX"
                    expect(page).to have_link("Change", href: /postcode/)
                  end
                end

                context "when you click to view the scheme details" do
                  before do
                    click_button "Save and return to locations"
                    click_link("Scheme")
                  end

                  it "does not let you change details other than the name, confidential information and housing stock owner" do
                    assert_selector "a", text: "Change", count: 11
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  context "when I am signed in as a data coordinator" do
    let(:user) { FactoryBot.create(:user, :data_coordinator, last_sign_in_at: Time.zone.now) }
    let!(:schemes) { FactoryBot.create_list(:scheme, 5, owning_organisation_id: user.organisation_id) }

    before do
      visit("/lettings-logs")
      fill_in("user[email]", with: user.email)
      fill_in("user[password]", with: user.password)
      click_button("Sign in")
    end

    context "when editing a scheme" do
      context "when I visit schemes page" do
        before do
          visit("schemes")
        end

        context "when I click to see individual scheme" do
          let(:scheme) { schemes.first }

          before do
            FactoryBot.create(:location, scheme:)
            click_link(scheme.service_name)
          end

          context "when I click to change scheme name" do
            before do
              click_link("Change", href: "/schemes/#{scheme.id}/edit-name", match: :first)
            end

            context "when I edit details" do
              before do
                fill_in "Scheme name", with: "FooBar"
                check "This scheme contains confidential information"
                click_button "Save changes"
              end

              it "lets me see amended details on the details page" do
                expect(page).to have_content "FooBar"
                expect(page).to have_current_path("/schemes/#{scheme.id}")
                expect(page).to have_link("Change", href:  /schemes\/#{scheme.id}\/edit-name/, count: 3)
              end
            end
          end
        end
      end
    end
  end

  context "when selecting a scheme" do
    let!(:user) { FactoryBot.create(:user, :data_coordinator, last_sign_in_at: Time.zone.now) }
    let!(:schemes) { FactoryBot.create_list(:scheme, 5, owning_organisation: user.organisation, arrangement_type: "The same organisation that owns the housing stock") }
    let(:location) { FactoryBot.create(:location, scheme: schemes[2]) }
    let!(:lettings_log) { FactoryBot.create(:lettings_log, assigned_to: user, needstype: 2) }

    before do
      Timecop.freeze(Time.utc(2022, 6, 3))
      location.update!(startdate: nil)
      FactoryBot.create(:location, scheme: schemes[0], startdate: nil)
      FactoryBot.create(:location, scheme: schemes[1], startdate: nil)
      FactoryBot.create(:location, scheme: schemes[1], startdate: nil)
      FactoryBot.create(:location, scheme: schemes[1], startdate: Time.utc(2023, 6, 3))
      visit("/lettings-logs")
      fill_in("user[email]", with: user.email)
      fill_in("user[password]", with: user.password)
      click_button("Sign in")
    end

    after do
      Timecop.unfreeze
    end

    it "does not display the schemes without a location" do
      visit("/lettings-logs/#{lettings_log.id}/scheme")
      expect(find("#lettings-log-scheme-id-field").all("option").count).to eq(4)
    end

    it "does not display the schemes with a location with a startdate in the future" do
      location.update!(startdate: Time.utc(2022, 7, 4))
      visit("/lettings-logs/#{lettings_log.id}/scheme")
      expect(find("#lettings-log-scheme-id-field").all("option").count).to eq(3)
    end

    it "does display the schemes with a location with a startdate in the past" do
      location.update!(startdate: Time.utc(2022, 5, 2))
      visit("/lettings-logs/#{lettings_log.id}/scheme")
      expect(find("#lettings-log-scheme-id-field").all("option").count).to eq(4)
    end

    it "does display the schemes with a location with a startdate being today" do
      location.update!(startdate: Time.utc(2022, 6, 3))
      visit("/lettings-logs/#{lettings_log.id}/scheme")
      expect(find("#lettings-log-scheme-id-field").all("option").count).to eq(4)
    end

    it "does display the schemes that are not completed" do
      schemes[2].update!(confirmed: false)
      visit("/lettings-logs/#{lettings_log.id}/scheme")
      expect(find("#lettings-log-scheme-id-field").all("option").count).to eq(3)
    end
  end
end
