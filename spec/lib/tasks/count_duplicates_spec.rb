require "rails_helper"
require "rake"

RSpec.describe "count_duplicates" do
  describe "count_duplicates:scheme_duplicates_per_org", type: :task do
    subject(:task) { Rake::Task["count_duplicates:scheme_duplicates_per_org"] }

    let(:storage_service) { instance_double(Storage::S3Service) }
    let(:test_url) { "test_url" }

    before do
      Rake.application.rake_require("tasks/count_duplicates")
      Rake::Task.define_task(:environment)
      task.reenable
      allow(Storage::S3Service).to receive(:new).and_return(storage_service)
      allow(storage_service).to receive(:write_file)
      allow(storage_service).to receive(:get_presigned_url).and_return(test_url)
    end

    context "when the rake task is run" do
      context "and there are no duplicate schemes" do
        let!(:organisation) { create(:organisation) }

        it "creates a csv with headers only" do
          expect(storage_service).to receive(:write_file).with(/scheme-duplicates-.*\.csv/, "\uFEFFOrganisation id,Number of duplicate sets,Total duplicate schemes\n")
          expect(Rails.logger).to receive(:info).with("Download URL: #{test_url}")
          task.invoke
        end
      end

      context "and there are duplicate schemes" do
        let(:organisation) { create(:organisation) }
        let(:organisation2) { create(:organisation) }

        before do
          create_list(:scheme, 2, :duplicate, owning_organisation: organisation)
          create_list(:scheme, 3, :duplicate, primary_client_group: "I", owning_organisation: organisation)
          create_list(:scheme, 5, :duplicate, owning_organisation: organisation2)
        end

        it "creates a csv with correct duplicate numbers" do
          expect(storage_service).to receive(:write_file).with(/scheme-duplicates-.*\.csv/, "\uFEFFOrganisation id,Number of duplicate sets,Total duplicate schemes\n#{organisation.id},2,5\n#{organisation2.id},1,5\n")
          expect(Rails.logger).to receive(:info).with("Download URL: #{test_url}")
          task.invoke
        end
      end
    end
  end
end
