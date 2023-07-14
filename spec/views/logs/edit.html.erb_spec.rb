require "rails_helper"

RSpec.describe "logs/edit.html.erb" do
  before do
    assign(:log, log)
    sign_in create(:user, :support)
  end

  context "when log is in progress" do
    let(:log) { create(:lettings_log, :in_progress) }

    it "there is no link back to log type root" do
      render

      fragment = Capybara::Node::Simple.new(rendered)

      expect(fragment).not_to have_link(text: "Back to lettings logs", href: "/lettings-logs")
    end

    it "has link 'Delete log'" do
      render

      fragment = Capybara::Node::Simple.new(rendered)

      expect(fragment).to have_link(text: "Delete log", href: "/lettings-logs/#{log.id}/delete-confirmation")
    end
  end

  context "when log is completed" do
    context "when showing a lettings log" do
      let(:log) { create(:lettings_log, :completed) }

      it "has link 'Back to lettings logs'" do
        render

        fragment = Capybara::Node::Simple.new(rendered)

        expect(fragment).to have_link(text: "Back to lettings logs", href: "/lettings-logs")
      end

      it "has link 'Delete log'" do
        render

        fragment = Capybara::Node::Simple.new(rendered)

        expect(fragment).to have_link(text: "Delete log", href: "/lettings-logs/#{log.id}/delete-confirmation")
      end
    end

    context "when showing a sales log" do
      let(:log) { create(:sales_log, :completed) }

      it "has link 'Back to sales logs'" do
        render

        fragment = Capybara::Node::Simple.new(rendered)

        expect(fragment).to have_link(text: "Back to sales logs", href: "/sales-logs")
      end

      it "has link 'Delete log'" do
        render

        fragment = Capybara::Node::Simple.new(rendered)

        expect(fragment).to have_link(text: "Delete log", href: "/sales-logs/#{log.id}/delete-confirmation")
      end
    end

    context "when lettings log is bulk uploaded" do
      let(:bulk_upload) { create(:bulk_upload, :lettings) }
      let(:log) { create(:lettings_log, :completed, bulk_upload:, creation_method: "bulk upload") }

      it "has link 'Back to uploaded logs'" do
        render

        fragment = Capybara::Node::Simple.new(rendered)

        expect(fragment).to have_link(text: "Back to uploaded logs", href: "/lettings-logs/bulk-upload-results/#{bulk_upload.id}/resume")
      end

      it "has link 'Delete log'" do
        render

        fragment = Capybara::Node::Simple.new(rendered)

        expect(fragment).to have_link(text: "Delete log", href: "/lettings-logs/#{log.id}/delete-confirmation")
      end
    end

    context "when sales log is bulk uploaded" do
      let(:bulk_upload) { create(:bulk_upload, :sales) }
      let(:log) { create(:sales_log, :completed, bulk_upload:, creation_method: "bulk upload") }

      it "has link 'Back to uploaded logs'" do
        render

        fragment = Capybara::Node::Simple.new(rendered)

        expect(fragment).to have_link(text: "Back to uploaded logs", href: "/sales-logs/bulk-upload-results/#{bulk_upload.id}/resume")
      end

      it "has link 'Delete log'" do
        render

        fragment = Capybara::Node::Simple.new(rendered)

        expect(fragment).to have_link(text: "Delete log", href: "/sales-logs/#{log.id}/delete-confirmation")
      end
    end
  end
end
