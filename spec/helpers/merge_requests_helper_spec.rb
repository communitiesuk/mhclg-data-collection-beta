require "rails_helper"

RSpec.describe MergeRequestsHelper do
  describe "#merging_organisations_without_users_text" do
    context "with 1 organisation" do
      let(:organisation) { build(:organisation, name: "Org 1") }

      it "returns the correct text" do
        expect(merging_organisations_without_users_text([organisation])).to eq("Org 1 has no users.")
      end
    end

    context "with 2 organisations" do
      let(:organisation) { build(:organisation, name: "Org 1") }
      let(:organisation_2) { build(:organisation, name: "Org 2") }

      it "returns the correct text" do
        expect(merging_organisations_without_users_text([organisation, organisation_2])).to eq("Org 1 and Org 2 have no users.")
      end
    end

    context "with 3 organisations" do
      let(:organisation) { build(:organisation, name: "Org 1") }
      let(:organisation_2) { build(:organisation, name: "Org 2") }
      let(:organisation_3) { build(:organisation, name: "Org 3") }

      it "returns the correct text" do
        expect(merging_organisations_without_users_text([organisation, organisation_2, organisation_3])).to eq("Org 1, Org 2, and Org 3 have no users.")
      end
    end
  end

  describe "#link_to_merging_organisation_users" do
    context "with 1 organisation user" do
      let(:organisation) { create(:organisation, name: "Org 1") }

      it "returns the correct link" do
        expect(link_to_merging_organisation_users(organisation)).to include("View 1 Org 1 user (opens in a new tab)")
        expect(link_to_merging_organisation_users(organisation)).to include(users_organisation_path(organisation))
      end
    end

    context "with multiple organisation users" do
      let(:organisation) { create(:organisation, name: "Org 1") }

      before do
        create(:user, organisation:)
      end

      it "returns the correct link" do
        expect(link_to_merging_organisation_users(organisation)).to include("View all 2 Org 1 users (opens in a new tab)")
        expect(link_to_merging_organisation_users(organisation)).to include(users_organisation_path(organisation))
      end
    end
  end

  describe "#merging_organisations_without_schemes_text" do
    context "with 1 organisation" do
      let(:organisation) { build(:organisation, name: "Org 1") }

      it "returns the correct text" do
        expect(merging_organisations_without_schemes_text([organisation])).to eq("Org 1 has no schemes.")
      end
    end

    context "with 2 organisations" do
      let(:organisation) { build(:organisation, name: "Org 1") }
      let(:organisation_2) { build(:organisation, name: "Org 2") }

      it "returns the correct text" do
        expect(merging_organisations_without_schemes_text([organisation, organisation_2])).to eq("Org 1 and Org 2 have no schemes.")
      end
    end

    context "with 3 organisations" do
      let(:organisation) { build(:organisation, name: "Org 1") }
      let(:organisation_2) { build(:organisation, name: "Org 2") }
      let(:organisation_3) { build(:organisation, name: "Org 3") }

      it "returns the correct text" do
        expect(merging_organisations_without_schemes_text([organisation, organisation_2, organisation_3])).to eq("Org 1, Org 2, and Org 3 have no schemes.")
      end
    end
  end

  describe "#link_to_merging_organisation_schemes" do
    context "with 1 organisation scheme" do
      let(:organisation) { create(:organisation, name: "Org 1") }

      before do
        create(:scheme, owning_organisation: organisation)
      end

      it "returns the correct link" do
        expect(link_to_merging_organisation_schemes(organisation)).to include("View 1 Org 1 scheme (opens in a new tab)")
        expect(link_to_merging_organisation_schemes(organisation)).to include(schemes_organisation_path(organisation))
      end
    end

    context "with multiple organisation schemes" do
      let(:organisation) { create(:organisation, name: "Org 1") }

      before do
        create_list(:scheme, 2, owning_organisation: organisation)
      end

      it "returns the correct link" do
        expect(link_to_merging_organisation_schemes(organisation)).to include("View all 2 Org 1 schemes (opens in a new tab)")
        expect(link_to_merging_organisation_schemes(organisation)).to include(schemes_organisation_path(organisation))
      end
    end
  end

  describe "when creating relationship outcomes content" do
    let(:stock_owner1) { create(:organisation, name: "Stock owner 1") }
    let(:stock_owner2) { create(:organisation, name: "Stock owner 2") }
    let(:managing_agent1) { create(:organisation, name: "Managing agent 1") }
    let(:managing_agent2) { create(:organisation, name: "Managing agent 2") }
    let(:absorbing_organisation) { create(:organisation, name: "Absorbing Org") }
    let(:merging_organisations) { create_list(:organisation, 2) { |org, i| org.name = "Dummy Org #{i + 1}" } }
    let(:merge_request) { create(:merge_request, absorbing_organisation:, merging_organisations:) }

    context "when there are no relationships" do
      it "returns text stating there are no stock owners" do
        expect(stock_owners_text(merge_request)).to eq("Absorbing Org, Dummy Org 1, and Dummy Org 2 have no stock owners.<br><br>")
      end

      it "returns text stating there are no managing agents" do
        expect(managing_agent_text(merge_request)).to eq("Absorbing Org, Dummy Org 1, and Dummy Org 2 have no managing agents.<br><br>")
      end
    end

    context "when there are stock owners" do
      before do
        create(:organisation_relationship, child_organisation: absorbing_organisation, parent_organisation: stock_owner1)
        create(:organisation_relationship, child_organisation: merging_organisations.first, parent_organisation: stock_owner2)
        create(:organisation_relationship, child_organisation: merging_organisations.first, parent_organisation: stock_owner1)
      end

      it "returns text stating the relationships" do
        expect(stock_owners_text(merge_request)).to include("Some of the organisations merging have common stock owners.")
        expect(stock_owners_text(merge_request)).to include("Dummy Org 2 has no stock owners.")
        expect(stock_owners_text(merge_request)).to include("<a class=\"govuk-link\" target=\"_blank\" href=\"/organisations/#{merging_organisations.first.id}/stock-owners\">View all 2 Dummy Org 1 stock owners (opens in a new tab)</a>")
      end
    end

    context "when there are managing agents" do
      before do
        create(:organisation_relationship, parent_organisation: absorbing_organisation, child_organisation: managing_agent1)
        create(:organisation_relationship, parent_organisation: absorbing_organisation, child_organisation: managing_agent2)
        create(:organisation_relationship, parent_organisation: merging_organisations.first, child_organisation: managing_agent2)
      end

      it "returns text stating the relationships" do
        expect(managing_agent_text(merge_request)).to include("Some of the organisations merging have common managing agents.")
        expect(managing_agent_text(merge_request)).to include("Dummy Org 2 has no managing agents.")
        expect(managing_agent_text(merge_request)).to include("<a class=\"govuk-link\" target=\"_blank\" href=\"/organisations/#{merging_organisations.first.id}/managing-agents\">View the 1 Dummy Org 1 managing agent (opens in a new tab)</a>")
      end
    end
  end

  describe "logs outcomes summary" do
    let(:organisation) { create(:organisation, name: "Org 1") }
    let(:merging_organisation) { create(:organisation, name: "Org 2") }
    let(:merging_organisation_2) { create(:organisation, name: "Org 3") }
    let(:merge_request) { create(:merge_request, absorbing_organisation: organisation, merge_date: Time.zone.today) }

    before do
      create(:merge_request_organisation, merge_request:, merging_organisation:)
    end

    context "when merging organisations don't have logs" do
      it "returns the correct merging_organisations_lettings_logs_outcomes_text text" do
        outcome_text = merging_organisations_lettings_logs_outcomes_text(merge_request)
        expect(outcome_text).not_to include("Org 1 users will have access to all lettings logs owned or managed by the merging organisation after the merge.")
        expect(outcome_text).not_to include("Lettings logs that are owned or managed by the merging organisation and have a tenancy start date after the merge date will have their owning or managing organisation changed to Org 1.")
        expect(outcome_text).not_to include("Some logs are owned and managed by different organisations in this merge. They appear in the list for both the owning and the managing organisation.")
        expect(outcome_text).to include("Org 1 and Org 2 have no lettings logs.")
      end

      it "returns correct lettings_logs_outcomes_header_text" do
        expect(lettings_logs_outcomes_header_text(merge_request)).to eq("0 lettings logs after merge")
      end

      it "returns the correct merging_organisations_sales_logs_outcomes_text text" do
        outcome_text = merging_organisations_sales_logs_outcomes_text(merge_request)
        expect(outcome_text).not_to include("Org 1 users will have access to all sales logs owned or reported by the merging organisation after the merge.")
        expect(outcome_text).not_to include("Sales logs that are owned or reported by the merging organisation and have a sale completion date after the merge date will have their owning or managing organisation changed to Org 1.")
        expect(outcome_text).not_to include("Some logs are owned and reported by different organisation in this merge. They appear in the list for both the owning and the managing organisation.")
        expect(outcome_text).to include("Org 1 and Org 2 have no sales logs.")
      end

      it "returns correct sales_logs_outcomes_header_text" do
        expect(sales_logs_outcomes_header_text(merge_request)).to eq("0 sales logs after merge")
      end
    end

    context "when merging organisations have logs" do
      before do
        create(:lettings_log, owning_organisation: organisation)
        create(:lettings_log, owning_organisation: merging_organisation, startdate: Time.zone.tomorrow)
        create(:lettings_log, owning_organisation: merging_organisation, startdate: Time.zone.yesterday)
        create(:sales_log, owning_organisation: organisation)
        create(:sales_log, owning_organisation: merging_organisation, saledate: Time.zone.tomorrow)
        create(:sales_log, owning_organisation: merging_organisation, saledate: Time.zone.yesterday)
      end

      it "returns the correct merging_organisations_lettings_logs_outcomes_text text" do
        outcome_text = merging_organisations_lettings_logs_outcomes_text(merge_request)
        expect(outcome_text).to include("Org 1 users will have access to all lettings logs owned or managed by the merging organisation after the merge.")
        expect(outcome_text).to include("Lettings logs that are owned or managed by the merging organisation and have a tenancy start date after the merge date will have their owning or managing organisation changed to Org 1.")
        expect(outcome_text).not_to include("Some logs are owned and managed by different organisations in this merge. They appear in the list for both the owning and the managing organisation.")
        expect(outcome_text).not_to include("Org 2 has no lettings logs.")
        expect(outcome_text).to include("View all 2 Org 2 lettings logs (opens in a new tab)")
      end

      it "returns correct lettings_logs_outcomes_header_text" do
        expect(lettings_logs_outcomes_header_text(merge_request)).to eq("3 lettings logs after merge")
      end

      it "returns the correct merging_organisations_sales_logs_outcomes_text text" do
        outcome_text = merging_organisations_sales_logs_outcomes_text(merge_request)
        expect(outcome_text).to include("Org 1 users will have access to all sales logs owned or reported by the merging organisation after the merge.")
        expect(outcome_text).to include("Sales logs that are owned or reported by the merging organisation and have a sale completion date after the merge date will have their owning or managing organisation changed to Org 1.")
        expect(outcome_text).not_to include("Some logs are owned and reported by different organisations in this merge. They appear in the list for both the owning and the managing organisation.")
        expect(outcome_text).not_to include("Org 2 has no sales logs.")
        expect(outcome_text).to include("View all 2 Org 2 sales logs (opens in a new tab)")
      end

      it "returns correct sales_logs_outcomes_header_text" do
        expect(sales_logs_outcomes_header_text(merge_request)).to eq("3 sales logs after merge")
      end

      context "when logs are owned and managed by organisations in the same merge" do
        before do
          create(:organisation_relationship, parent_organisation: merging_organisation_2, child_organisation: merging_organisation)
          create(:merge_request_organisation, merge_request:, merging_organisation: merging_organisation_2)
          create(:lettings_log, assigned_to: merging_organisation_2.users.first, owning_organisation: merging_organisation_2, managing_organisation: merging_organisation, startdate: Time.zone.yesterday)
          create(:sales_log, assigned_to: merging_organisation_2.users.first, owning_organisation: merging_organisation_2, managing_organisation: merging_organisation, saledate: Time.zone.yesterday)
        end

        it "returns the correct merging_organisations_lettings_logs_outcomes_text text" do
          outcome_text = merging_organisations_lettings_logs_outcomes_text(merge_request)
          expect(outcome_text).to include("Org 1 users will have access to all lettings logs owned or managed by the merging organisations after the merge.")
          expect(outcome_text).to include("Lettings logs that are owned or managed by the merging organisations and have a tenancy start date after the merge date will have their owning or managing organisation changed to Org 1.")
          expect(outcome_text).to include("Some logs are owned and managed by different organisations in this merge. They appear in the list for both the owning and the managing organisation.")
          expect(outcome_text).not_to include("Org 2 has no lettings logs.")
          expect(outcome_text).to include("View all 3 Org 2 lettings logs (opens in a new tab)")
          expect(outcome_text).to include("View 1 Org 3 lettings log (opens in a new tab)")
        end

        it "returns correct lettings_logs_outcomes_header_text" do
          expect(lettings_logs_outcomes_header_text(merge_request)).to eq("4 lettings logs after merge")
        end

        it "returns the correct merging_organisations_sales_logs_outcomes_text text" do
          outcome_text = merging_organisations_sales_logs_outcomes_text(merge_request)
          expect(outcome_text).to include("Org 1 users will have access to all sales logs owned or reported by the merging organisations after the merge.")
          expect(outcome_text).to include("Sales logs that are owned or reported by the merging organisations and have a sale completion date after the merge date will have their owning or managing organisation changed to Org 1.")
          expect(outcome_text).to include("Some logs are owned and reported by different organisations in this merge. They appear in the list for both the owning and the managing organisation.")
          expect(outcome_text).not_to include("Org 2 has no sales logs.")
          expect(outcome_text).to include("View all 3 Org 2 sales logs (opens in a new tab)")
          expect(outcome_text).to include("View 1 Org 3 sales log (opens in a new tab)")
        end

        it "returns correct sales_logs_outcomes_header_text" do
          expect(sales_logs_outcomes_header_text(merge_request)).to eq("4 sales logs after merge")
        end
      end
    end
  end

  describe "#merge_request_details_prompt" do
    it "returns the correct message for existing_absorbing_organisation" do
      expect(helper.merge_request_details_prompt("existing_absorbing_organisation")).to eq("Tell us if absorbing organisation is already active")
    end

    it "returns the correct message for helpdesk_ticket" do
      expect(helper.merge_request_details_prompt("helpdesk_ticket")).to eq("Enter helpdesk ticket number")
    end

    it "returns the correct message for merging_organisations" do
      expect(helper.merge_request_details_prompt("merging_organisations")).to eq("Add merging organisations")
    end

    it "returns the correct message for merge_date" do
      expect(helper.merge_request_details_prompt("merge_date")).to eq("Set merge date")
    end

    it "returns a default message for an unknown page" do
      expect(helper.merge_request_details_prompt("unknown_page")).to eq("Enter unknown page")
    end
  end
end
