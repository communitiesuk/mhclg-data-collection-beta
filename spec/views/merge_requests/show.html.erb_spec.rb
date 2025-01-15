require "rails_helper"

RSpec.describe "merge_requests/show.html.erb", type: :view do
  let(:absorbing_organisation) { create(:organisation, name: "Absorbing Org", with_dsa: false) }
  let(:dpo_user) { create(:user, name: "DPO User", is_dpo: true, organisation: absorbing_organisation) }
  let(:merge_request) { create(:merge_request, absorbing_organisation_id: absorbing_organisation.id, signed_dsa: false) }

  before do
    assign(:merge_request, merge_request)
    render
  end

  it "displays the correct title" do
    expect(rendered).to have_selector("h1.govuk-heading-l") do |h1|
      expect(h1).to have_selector("span.govuk-caption-l", text: "Merge request")
      expect(h1).to have_content("Absorbing Org")
    end
  end

  it "displays the notification banner when DSA is not signed" do
    expect(rendered).to have_selector(".govuk-notification-banner")
    expect(rendered).to have_content("The absorbing organisation must accept the Data Sharing Agreement before merging.")
  end

  it "displays the requester details" do
    expect(rendered).to have_selector("dt", text: "Requester")
    expect(rendered).to have_selector("dd", text: merge_request.requester&.name || "No answer provided")
  end

  it "displays the helpdesk ticket details" do
    expect(rendered).to have_selector("dt", text: "Helpdesk ticket")
    if merge_request.helpdesk_ticket.present?
      expect(rendered).to have_link(merge_request.helpdesk_ticket, href: "https://mhclgdigital.atlassian.net/browse/#{merge_request.helpdesk_ticket}")
    else
      expect(rendered).to have_selector("dd", text: "No answer provided")
    end
  end

  it "displays the status details" do
    expect(rendered).to have_selector("dt", text: "Status")
    expect(rendered).to have_selector("dd", text: "Incomplete")
  end

  it "displays the absorbing organisation details" do
    expect(rendered).to have_selector("dt", text: "Absorbing organisation")
    expect(rendered).to have_selector("dd", text: merge_request.absorbing_organisation_name)
  end

  it "displays the merge date details" do
    expect(rendered).to have_selector("dt", text: "Merge date")
    expect(rendered).to have_selector("dd", text: merge_request.merge_date || "No answer provided")
  end

  context "when the merge request is complete" do
    before do
      merge_request.update!(request_merged: true, signed_dsa: true, total_users: 10, total_schemes: 5, total_lettings_logs: 20, total_sales_logs: 30, total_stock_owners: 40, total_managing_agents: 50)
      assign(:merge_request, merge_request)
      render
    end

    it "has status of 'Merged'" do
      expect(rendered).to have_selector("dd", text: "Merged")
    end

    it "displays the total users after merge details" do
      expect(rendered).to have_selector("dt", text: "Total users after merge")
      expect(rendered).to have_selector("dd", text: merge_request.total_users)
    end

    it "displays the total schemes after merge details" do
      expect(rendered).to have_selector("dt", text: "Total schemes after merge")
      expect(rendered).to have_selector("dd", text: merge_request.total_schemes)
    end

    it "displays the total logs after merge details" do
      expect(rendered).to have_selector("dt", text: "Total logs after merge")
      if merge_request.total_lettings_logs.present? || merge_request.total_sales_logs.present?
        combined_text = []
        combined_text << "#{merge_request.total_lettings_logs} lettings logs" if merge_request.total_lettings_logs.present?
        combined_text << "#{merge_request.total_sales_logs} sales logs" if merge_request.total_sales_logs.present?
        expect(rendered).to have_selector("dd", text: combined_text.join(""))
      end
    end

    it "displays the total stock owners & managing agents after merge details" do
      expect(rendered).to have_selector("dt", text: "Total stock owners & managing agents after merge")
      combined_text = []
      combined_text << "#{merge_request.total_stock_owners} stock owners" if merge_request.total_stock_owners.present?
      combined_text << "#{merge_request.total_managing_agents} managing agents" if merge_request.total_managing_agents.present?
      expect(rendered).to have_selector("dd", text: combined_text.join("\n"))
    end
  end
end
