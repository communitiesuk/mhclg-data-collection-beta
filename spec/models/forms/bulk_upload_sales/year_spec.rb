require "rails_helper"

RSpec.describe Forms::BulkUploadSales::Year do
  subject(:form) { described_class.new }

  around do |example|
    Timecop.freeze(Time.zone.now) do
      example.run
    end
  end

  describe "#options" do
    it "returns correct years" do
      expect(form.options.map(&:id)).to eql([2023, 2022])
      expect(form.options.map(&:name)).to eql(%w[2023/2024 2022/2023])
    end
  end
end
