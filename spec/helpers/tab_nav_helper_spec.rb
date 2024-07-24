require "rails_helper"

RSpec.describe TabNavHelper do
  let(:organisation) { FactoryBot.create(:organisation) }
  let(:current_user) { FactoryBot.build(:user, organisation:) }
  let(:scheme) { FactoryBot.create(:scheme, service_name: "Some name") }
  let(:location) { FactoryBot.create(:location, scheme:) }

  describe "#user_cell" do
    it "returns user link and email separated by a newline character" do
      expected_html = "<a class=\"govuk-link\" href=\"/users\">#{current_user.name}</a>\n<span class=\"govuk-visually-hidden\">User </span><span class=\"govuk-!-font-weight-regular app-!-colour-muted\">#{current_user.email}</span>"
      expect(user_cell(current_user)).to match(expected_html)
    end
  end

  describe "#org_cell" do
    it "returns the users org name and role separated by a newline character" do
      expected_html = "MHCLG\n<span class=\"app-!-colour-muted\">Data provider</span>"
      expect(org_cell(current_user)).to match(expected_html)
    end
  end

  describe "#location_cell" do
    it "returns the location link to the postcode with optional name" do
      link = "/schemes/#{location.scheme.id}/locations/#{location.id}/edit"
      expected_html = "<a class=\"govuk-link\" rel=\"nofollow\" data-method=\"patch\" href=\"/schemes/#{scheme.id}/locations/#{location.id}/edit\">#{location.postcode}</a>\n<span class=\"govuk-visually-hidden\">Location</span>"
      expect(location_cell_postcode(location, link)).to match(expected_html)
    end
  end

  describe "#scheme_cell" do
    it "returns the scheme link service name and primary user group separated by a newline character" do
      expected_html = "<a class=\"govuk-link\" href=\"/schemes/#{scheme.id}\">#{scheme.service_name}</a>\n<span class=\"govuk-visually-hidden\">Scheme</span>"
      expect(scheme_cell(scheme)).to match(expected_html)
    end
  end
end
