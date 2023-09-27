require "rails_helper"

RSpec.describe CollectionResourcesHelper do
  let(:current_user) { create(:user, :data_coordinator) }
  let(:user) { create(:user, :data_coordinator) }

  describe "when displaying file metadata" do
    context "with pages" do
      it "returns correct metadata" do
        expect(file_type_size_and_pages("2023_24_lettings_paper_form.pdf", number_of_pages: 8)).to eq("PDF, 285 KB, 8 pages")
      end
    end

    context "without pages" do
      it "returns correct metadata" do
        expect(file_type_size_and_pages("bulk-upload-lettings-template-2023-24.xlsx")).to eq("Microsoft Excel, 15 KB")
      end
    end
  end
end
