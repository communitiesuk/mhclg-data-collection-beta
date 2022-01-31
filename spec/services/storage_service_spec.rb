require "rails_helper"

RSpec.describe StorageService do
  let(:instance_name) { "instance_1" }
  let(:bucket_name) { "bucket_1" }
  let(:vcap_services) do
    <<-JSON
        {"aws-s3-bucket": [
          {
            "instance_name": "#{instance_name}",
            "credentials": {
              "aws_access_key_id": "key_id",
              "aws_region": "eu-west-2",
              "aws_secret_access_key": "secret",
              "bucket_name": "#{bucket_name}"
            }
          }
        ]}
    JSON
  end

  context "when we create an S3 Service with no PaaS Configuration present" do
    subject { described_class.new(PaasConfigurationService.new, "random_instance") }
    it "raises an exception" do
      expect { subject }.to raise_error(RuntimeError, /No PaaS configuration present/)
    end
  end

  context "when we create an S3 Service with an unknown instance name" do
    subject { described_class.new(PaasConfigurationService.new, "random_instance") }
    before do
      allow(ENV).to receive(:[]).with("VCAP_SERVICES").and_return("{}")
    end

    it "raises an exception" do
      expect { subject }.to raise_error(RuntimeError, /instance name could not be found/)
    end
  end

  context "when we create an storage service with a valid instance name" do
    subject { described_class.new(PaasConfigurationService.new, instance_name) }

    before do
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with("VCAP_SERVICES").and_return(vcap_services)
    end

    it "creates a Storage Configuration" do
      expect(subject.configuration).to be_an(StorageConfiguration)
    end

    it "sets the expected parameters in the configuration" do
      expected_configuration = StorageConfiguration.new(
        {
          aws_access_key_id: "key_id",
          aws_region: "eu-west-2",
          aws_secret_access_key: "secret",
          bucket_name: bucket_name,
        },
      )
      expect(subject.configuration).to eq(expected_configuration)
    end
  end

  context "when we create an storage service and write a stubbed object" do
    subject { described_class.new(PaasConfigurationService.new, instance_name) }
    let(:filename) { "my_file" }
    let(:content) { "content" }
    let(:s3_client_stub) { Aws::S3::Client.new(stub_responses: true) }

    before do
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with("VCAP_SERVICES").and_return(vcap_services)
      allow(Aws::S3::Client).to receive(:new).and_return(s3_client_stub)
    end

    it "retrieves the previously written object successfully if it exists" do
      s3_client_stub.stub_responses(:get_object, { body: content })

      data = subject.get_file_io(filename)
      expect(data.string).to eq(content)
    end

    it "fails when the object does not exist" do
      s3_client_stub.stub_responses(:get_object, "NoSuchKey")

      expect { subject.get_file_io("fake_filename") }
        .to raise_error(Aws::S3::Errors::NoSuchKey)
    end

    it "writes to the storage with the expected parameters" do
      expect(s3_client_stub).to receive(:put_object).with(body: content,
                                                          bucket: bucket_name,
                                                          key: filename)
      subject.write_file(filename, content)
    end
  end
end
