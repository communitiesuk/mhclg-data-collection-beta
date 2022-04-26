require "rails_helper"
require_relative "helpers"

RSpec.describe "Accessible Automcomplete" do
  include Helpers
  let(:user) { FactoryBot.create(:user) }
  let(:case_log) do
    FactoryBot.create(
      :case_log,
      :in_progress,
      previous_la_known: 1,
      prevloc: "E09000033",
      is_la_inferred: false,
      owning_organisation: user.organisation,
      managing_organisation: user.organisation,
    )
  end

  before do
    sign_in user
  end

  it "allows type ahead filtering", js: true do
    visit("/logs/#{case_log.id}/accessible-select")
    find("#case-log-prevloc-field").click.native.send_keys("T", "h", "a", "n", :down, :enter)
    expect(find("#case-log-prevloc-field").value).to eq("Thanet")
  end

  it "maintains enhancement state across back navigation", js: true do
    visit("/logs/#{case_log.id}/accessible-select")
    find("#case-log-prevloc-field").click.native.send_keys("T", "h", "a", "n", :down, :enter)
    click_button("Save and continue")
    click_link(text: "Back")
    expect(page).to have_selector("input", class: "autocomplete__input", count: 1)
  end

  it "has a disabled null option" do
    visit("/logs/#{case_log.id}/accessible-select")
    expect(page).to have_select("case-log-prevloc-field", disabled_options: ["Select an option"])
  end

  it "has the correct option selected if one has been saved" do
    case_log.update!(postcode_known: 0, previous_la_known: 1, prevloc: "E07000178")
    visit("/logs/#{case_log.id}/accessible-select")
    expect(page).to have_select("case-log-prevloc-field", selected: %w[Oxford])
  end
end
