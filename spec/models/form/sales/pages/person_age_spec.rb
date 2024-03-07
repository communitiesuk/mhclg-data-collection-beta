require "rails_helper"

RSpec.describe Form::Sales::Pages::PersonAge, type: :model do
  subject(:page) { described_class.new(page_id, page_definition, subsection, person_index:) }

  let(:page_id) { "person_1_age" }
  let(:page_definition) { nil }
  let(:subsection) { instance_double(Form::Subsection, form: instance_double(Form, start_date: Time.zone.local(2023, 4, 1))) }
  let(:person_index) { 1 }

  it "has correct subsection" do
    expect(page.subsection).to eq(subsection)
  end

  it "has the correct header" do
    expect(page.header).to be_nil
  end

  it "has the correct description" do
    expect(page.description).to be_nil
  end

  context "with person 2" do
    let(:page_id) { "person_2_age" }
    let(:person_index) { 2 }

    it "has correct questions" do
      expect(page.questions.map(&:id)).to eq(%w[age2_known age2])
    end

    it "has the correct id" do
      expect(page.id).to eq("person_2_age")
    end

    it "has correct depends_on" do
      expect(page.depends_on).to eq(
        [{ "details_known_2" => 1 }],
      )
    end
  end

  context "with person 3" do
    let(:page_id) { "person_3_age" }
    let(:person_index) { 3 }

    it "has correct questions" do
      expect(page.questions.map(&:id)).to eq(%w[age3_known age3])
    end

    it "has the correct id" do
      expect(page.id).to eq("person_3_age")
    end

    it "has correct depends_on" do
      expect(page.depends_on).to eq(
        [
          { "details_known_3" => 1 },
        ],
      )
    end
  end

  context "with person 4" do
    let(:page_id) { "person_4_age" }
    let(:person_index) { 4 }

    it "has correct questions" do
      expect(page.questions.map(&:id)).to eq(%w[age4_known age4])
    end

    it "has the correct id" do
      expect(page.id).to eq("person_4_age")
    end

    it "has correct depends_on" do
      expect(page.depends_on).to eq(
        [
          { "details_known_4" => 1 },
        ],
      )
    end
  end

  context "with person 5" do
    let(:page_id) { "person_5_age" }
    let(:person_index) { 5 }

    it "has correct questions" do
      expect(page.questions.map(&:id)).to eq(%w[age5_known age5])
    end

    it "has the correct id" do
      expect(page.id).to eq("person_5_age")
    end

    it "has correct depends_on" do
      expect(page.depends_on).to eq(
        [
          { "details_known_5" => 1 },
        ],
      )
    end
  end
end
