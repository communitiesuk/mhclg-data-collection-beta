require "rails_helper"

RSpec.describe Forms::BulkUploadLettings::Guidance do
  include Rails.application.routes.url_helpers

  subject(:bu_guidance) { described_class.new(year:, referrer:) }

  let(:year) { 2024 }

  describe "#back_path" do
    context "when referrer is prepare-your-file" do
      let(:referrer) { "prepare-your-file" }

      it "returns the prepare your file path" do
        expect(bu_guidance.back_path).to eq bulk_upload_lettings_log_path(id: "prepare-your-file", form: { year: })
      end
    end

    context "when referrer is guidance" do
      let(:referrer) { "guidance" }

      it "returns the main guidance page path" do
        expect(bu_guidance.back_path).to eq guidance_path
      end
    end

    context "when referrer is absent" do
      let(:referrer) { nil }

      it "returns the main guidance page path" do
        expect(bu_guidance.back_path).to eq guidance_path
      end
    end
  end
end
