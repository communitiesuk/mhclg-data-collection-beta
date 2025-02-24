require "rails_helper"

RSpec.describe Form::Lettings::Questions::AddressSearch, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page, subsection: instance_double(Form::Subsection, form: instance_double(Form, start_date:))) }
  let(:start_date) { Time.utc(2024, 4, 1) }

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("uprn")
  end

  it "has the correct type" do
    expect(question.type).to eq("address_search")
  end

  it "has the correct question number" do
    expect(question.question_number).to eq(12)
  end

  context "with 2025/26 form" do
    let(:start_date) { Time.utc(2025, 4, 1) }

    it "has the correct question number" do
      expect(question.question_number).to eq(16)
    end
  end

  describe "get_extra_check_answer_value" do
    context "when address is not present" do
      let(:log) { build(:lettings_log, manual_address_entry_selected: false) }

      it "returns nil" do
        expect(question.get_extra_check_answer_value(log)).to be_nil
      end
    end

    context "when address search is present" do
      let(:log) do
        build(
          :lettings_log,
          :completed,
          address_line1: "19, Charlton Gardens",
          town_or_city: "Bristol",
          postcode_full: "BS10 6LU",
          la: "E06000023",
          uprn_known: 1,
          uprn: 107,
          uprn_confirmed: 1,
        )
      end

      context "when uprn known" do
        it "returns formatted value" do
          expect(question.get_extra_check_answer_value(log)).to eq(
            "\n\n19, Charlton Gardens\nBristol\nBS10 6LU\nBristol, City of",
          )
        end
      end
    end
  end
end
