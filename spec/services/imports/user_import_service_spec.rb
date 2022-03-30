require "rails_helper"

RSpec.describe Imports::UserImportService do
  let(:fixture_directory) { "spec/fixtures/softwire_imports/users" }
  let(:old_user_id) { "fc7625a02b24ae16162aa63ae7cb33feeec0c373" }
  let(:old_org_id) { "7c5bd5fb549c09a2c55d7cb90d7ba84927e64618" }
  let(:user_file) { File.open("#{fixture_directory}/#{old_user_id}.xml") }
  let(:storage_service) { instance_double(StorageService) }

  context "when importing users" do
    subject(:import_service) { described_class.new(storage_service) }

    before do
      allow(storage_service).to receive(:list_files)
                                  .and_return(["user_directory/#{old_user_id}.xml"])
      allow(storage_service).to receive(:get_file_io)
                                  .with("user_directory/#{old_user_id}.xml")
                                  .and_return(user_file)
    end

    it "successfully create a user with the expected data" do
      FactoryBot.create(:organisation, old_org_id:)
      import_service.create_users("user_directory")

      user = User.find_by(old_user_id:)
      expect(user.name).to eq("John Doe")
      expect(user.email).to eq("john.doe@gov.uk")
      expect(user.encrypted_password).not_to be_nil
      expect(user.phone).to eq("02012345678")
      expect(user).to be_data_provider
      expect(user.organisation.old_org_id).to eq(old_org_id)
      expect(user.is_key_contact?).to be false
    end

    it "refuses to create a user belonging to a non existing organisation" do
      expect { import_service.create_users("user_directory") }
        .to raise_error(ActiveRecord::RecordInvalid, /Organisation must exist/)
    end

    context "when the user is a data coordinator" do
      let(:old_user_id) { "d4729b1a5dfb68bb1e01c08445830c0add40907c" }

      it "sets their role correctly" do
        FactoryBot.create(:organisation, old_org_id:)
        import_service.create_users("user_directory")
        expect(User.find_by(old_user_id:)).to be_data_coordinator
      end
    end

    context "when the user is a data accessor" do
      let(:old_user_id) { "b7829b1a5dfb68bb1e01c08445830c0add40907c" }

      it "sets their role correctly" do
        FactoryBot.create(:organisation, old_org_id:)
        import_service.create_users("user_directory")
        expect(User.find_by(old_user_id:)).to be_data_accessor
      end
    end

    context "when the user was a 'Key Performance Contact' in the old system" do
      let(:old_user_id) { "d4729b1a5dfb68bb1e01c08445830c0add40907c" }

      it "marks them as a key contact" do
        FactoryBot.create(:organisation, old_org_id:)
        import_service.create_users("user_directory")

        user = User.find_by(old_user_id:)
        expect(user.is_key_contact?).to be true
      end
    end

    context "when the user was a 'eCORE Contact' in the old system" do
      let(:old_user_id) { "d6717836154cd9a58f9e2f1d3077e3ab81e07613" }

      it "marks them as a key contact" do
        FactoryBot.create(:organisation, old_org_id:)
        import_service.create_users("user_directory")

        user = User.find_by(old_user_id:)
        expect(user.is_key_contact?).to be true
      end
    end

    context "when the user has already been imported previously" do
      before do
        org = FactoryBot.create(:organisation, old_org_id:)
        FactoryBot.create(:user, old_user_id:, organisation: org)
      end

      it "logs that the user already exists" do
        expect(Rails.logger).to receive(:warn)
        import_service.create_users("user_directory")
      end
    end
  end
end
