require "rails_helper"
require_relative "helpers"

RSpec.describe "Address Search" do
  include Helpers
  let(:user) { FactoryBot.create(:user) }
  let(:sales_log) do
    FactoryBot.create(
      :sales_log,
      :shared_ownership_setup_complete,
      assigned_to: user,
      manual_address_entry_selected: false,
    )
  end

  before do
    sign_in user
  end

  context "when using address search feature" do
    before do
      visit("/sales-logs/#{sales_log.id}/address-search")
    end

    it "allows searching by a UPRN", js: true do
      find("#sales-log-uprn-field").click.native.send_keys("1", "0", "0", "3", "3", "5", "4", "4", "6", "1", "4", :down)
      expect(find("#sales-log-uprn-field").value).to eq("10033544614")
    end

    it "allows searching by address", js: true do
      find("#sales-log-uprn-field").click.native.send_keys("S", "W", "1", "5", :down, :enter)
      expect(find("#sales-log-uprn-field").value).to eq("SW15")
    end

    it "displays the placeholder text", js: true do
      expect(find("#sales-log-uprn-field")["placeholder"]).to eq("Start typing to search")
    end

    it "displays correct bottom guidance text" do
      find("span.govuk-details__summary-text", text: "Can’t find the address you’re looking for?").click
      expect(page).to have_content("Some properties may not be available yet e.g. new builds; you might need to enter them manually instead")
      expect(page).to have_content("For UPRN (Unique Property Reference Number), please enter the full value exactly")
    end
  end
end
