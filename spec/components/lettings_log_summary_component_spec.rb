require "rails_helper"

RSpec.describe LettingsLogSummaryComponent, type: :component do
  let(:support_user) { FactoryBot.create(:user, :support) }
  let(:coordinator_user) { FactoryBot.create(:user) }
  let(:propcode) { "P3647" }
  let(:tenancycode) { "T62863" }
  let(:lettings_log) { FactoryBot.create(:lettings_log, needstype: 1, tenancycode:, propcode:, startdate: Time.zone.today) }

  context "when rendering lettings log for a support user" do
    it "shows the log summary with organisational relationships" do
      result = render_inline(described_class.new(current_user: support_user, log: lettings_log))

      expect(result).to have_link(lettings_log.id.to_s)
      expect(result).to have_text(lettings_log.tenancycode)
      expect(result).to have_text(lettings_log.propcode)
      expect(result).to have_text("General needs")
      expect(result).to have_text("Tenancy starts #{Time.zone.today.strftime('%e %B %Y').strip}")
      expect(result).to have_text("Created #{Time.zone.today.strftime('%e %B %Y').strip}")
      expect(result).to have_text("Assigned to Danny Rojas")
      expect(result).to have_content("Owned by\n              DLUHC")
      expect(result).to have_content("Managed by\n              DLUHC")
    end
  end

  context "when rendering lettings log for a data coordinator user" do
    it "does not show the user who the log is owned and managed by" do
      result = render_inline(described_class.new(current_user: coordinator_user, log: lettings_log))

      expect(result).not_to have_content("Owned by")
      expect(result).not_to have_content("Managed by")
    end
  end
end
