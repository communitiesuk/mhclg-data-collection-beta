require "rails_helper"

RSpec.describe BulkUpload::LettingsValidator do
  subject(:validator) { described_class.new(path:) }

  let(:path) { file.path }
  let(:file) { Tempfile.new }

  describe "validations" do
    context "when file is empty" do
      it "is not valid" do
        expect(validator).not_to be_valid
      end
    end

    context "when file has too many columns" do
      before do
        file.write("a," * 136)
        file.write("\n")
        file.rewind
      end

      it "is not valid" do
        expect(validator).not_to be_valid
      end
    end

    context "incorrect headers"
  end

  context do
    let(:path) { file_fixture("2021_22_lettings_bulk_upload.csv") }

    it do
      validator.call
    end
  end
end
