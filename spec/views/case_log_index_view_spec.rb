require "rails_helper"
require_relative "../request_helper"

RSpec.describe "case_logs/index" do
  before do
    RequestHelper.stub_http_requests
  end

  let(:in_progress_log) { FactoryBot.create(:case_log, :in_progress) }
  let(:completed_log) { FactoryBot.create(:case_log, :completed) }

  context "with an in progress log list" do
    before do
      assign(:in_progress_case_logs, [in_progress_log])
      assign(:completed_case_logs, [])
      render
    end

    it "renders a table for in progress logs only" do
      expect(rendered).to match(/<table class="govuk-table">/)
      expect(rendered).to match(/Logs you need to complete/)
      expect(rendered).not_to match(/Logs you’ve submitted/)
      expect(rendered).to match(in_progress_log.tenant_code)
      expect(rendered).to match(in_progress_log.property_postcode)
    end
  end

  context "with a completed log list" do
    before do
      assign(:in_progress_case_logs, [])
      assign(:completed_case_logs, [completed_log])
      render
    end

    it "renders a table for in progress logs only" do
      expect(rendered).to match(/<table class="govuk-table">/)
      expect(rendered).to match(/Logs you’ve submitted/)
      expect(rendered).not_to match(/Logs you need to complete/)
      expect(rendered).to match(completed_log.tenant_code)
      expect(rendered).to match(completed_log.property_postcode)
    end
  end

  context "with a completed log list and an in_progress log list" do
    before do
      assign(:in_progress_case_logs, [in_progress_log])
      assign(:completed_case_logs, [completed_log])
      render
    end

    it "renders two tables, one for each status" do
      expect(rendered).to match(/<table class="govuk-table">/)
      expect(rendered).to match(/Logs you’ve submitted/)
      expect(rendered).to match(/Logs you need to complete/)
    end
  end
end
