require "rails_helper"

RSpec.describe Form::Sales::Pages::PersonWorkingSituation, type: :model do
  subject(:page) { described_class.new(page_id, page_definition, subsection, person_index:) }

  let(:page_definition) { nil }
  let(:subsection) { instance_double(Form::Subsection, form: instance_double(Form, start_date: Time.zone.local(2023, 4, 1))) }
  let(:person_index) { 2 }

  let(:page_id) { "person_2_working_situation" }

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
    let(:person_index) { 2 }
    let(:page_id) { "person_2_working_situation" }

    it "has correct questions" do
      expect(page.questions.map(&:id)).to eq(%w[ecstat2])
    end

    it "has the correct id" do
      expect(page.id).to eq("person_2_working_situation")
    end

    it "has correct depends_on" do
      expect(page.depends_on).to eq([{ "age2" => { "operand" => 15, "operator" => ">" }, "details_known_2" => 1 }, { "age2" => nil, "details_known_2" => 1 }])
    end
  end

  context "with person 3" do
    let(:person_index) { 3 }
    let(:page_id) { "person_3_working_situation" }

    it "has correct questions" do
      expect(page.questions.map(&:id)).to eq(%w[ecstat3])
    end

    it "has the correct id" do
      expect(page.id).to eq("person_3_working_situation")
    end

    it "has correct depends_on" do
      expect(page.depends_on).to eq([{ "age3" => { "operand" => 15, "operator" => ">" }, "details_known_3" => 1 }, { "age3" => nil, "details_known_3" => 1 }])
    end
  end

  context "with person 4" do
    let(:person_index) { 4 }
    let(:page_id) { "person_4_working_situation" }

    it "has correct questions" do
      expect(page.questions.map(&:id)).to eq(%w[ecstat4])
    end

    it "has the correct id" do
      expect(page.id).to eq("person_4_working_situation")
    end

    it "has correct depends_on" do
      expect(page.depends_on).to eq([{ "age4" => { "operand" => 15, "operator" => ">" }, "details_known_4" => 1 }, { "age4" => nil, "details_known_4" => 1 }])
    end
  end

  context "with person 5" do
    let(:person_index) { 5 }
    let(:page_id) { "person_5_working_situation" }

    it "has correct questions" do
      expect(page.questions.map(&:id)).to eq(%w[ecstat5])
    end

    it "has the correct id" do
      expect(page.id).to eq("person_5_working_situation")
    end

    it "has correct depends_on" do
      expect(page.depends_on).to eq([{ "age5" => { "operand" => 15, "operator" => ">" }, "details_known_5" => 1 }, { "age5" => nil, "details_known_5" => 1 }])
    end
  end
end
