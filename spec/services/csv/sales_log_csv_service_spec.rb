require "rails_helper"

RSpec.describe Csv::SalesLogCsvService do
  let(:form_handler_mock) { instance_double(FormHandler) }
  let(:organisation) { create(:organisation) }
  let(:fixed_time) { Time.zone.local(2023, 2, 8) }
  let(:user) { create(:user, email: "billyboy@eyeKLAUD.com") }
  let(:log) do
    create(
      :sales_log,
      :completed,
      created_by: user,
      saledate: fixed_time,
      created_at: fixed_time,
      updated_at: fixed_time,
      owning_organisation: organisation,
      purchid: nil,
    )
  end
  let(:service) { described_class.new(export_type: "labels") }
  let(:csv) { CSV.parse(service.prepare_csv(SalesLog.all)) }

  before do
    allow(Time).to receive(:now).and_return(fixed_time)
    Singleton.__init__(FormHandler)
    log
  end

  it "calls the form handler to get all questions in order when initialized" do
    allow(FormHandler).to receive(:instance).and_return(form_handler_mock)
    allow(form_handler_mock).to receive(:ordered_sales_questions_for_all_years).and_return([])
    service
    expect(form_handler_mock).to have_received(:ordered_sales_questions_for_all_years)
  end

  it "returns a string" do
    result = service.prepare_csv(SalesLog.all)
    expect(result).to be_a String
  end

  it "returns a csv with headers" do
    expect(csv.first.first).to eq "id"
  end

  context "when stubbing :ordered_sales_questions_for_all_years" do
    let(:sales_form) do
      FormFactory.new(year: 1936, type: "sales")
                 .with_sections([build(:section, :with_questions, question_ids:, questions:)])
                 .build
    end
    let(:question_ids) { nil }
    let(:questions) { nil }

    before do
      allow(FormHandler).to receive(:instance).and_return(form_handler_mock)
      allow(form_handler_mock).to receive(:form_name_from_start_year)
      allow(form_handler_mock).to receive(:get_form).and_return(sales_form)
      allow(form_handler_mock).to receive(:ordered_sales_questions_for_all_years).and_return(sales_form.questions)
    end

    context "when it returns questions with particular ids" do
      let(:question_ids) { %w[type age1 buy1livein exdate] }

      it "includes log attributes related to questions to the headers" do
        headers = csv.first
        expect(headers).to include(*question_ids.first(3))
      end

      it "removes some log attributes related to questions from the headers and replaces them with their derived values in the correct order" do
        headers = csv.first
        expect(headers).not_to include "exdate"
        expect(headers.last(4)).to eq %w[buy1livein exday exmonth exyear]
      end
    end

    context "when it returns questions with particular features" do
      let(:questions) do
        [
          build(:question, id: "attribute_value_check", type: "interruption_screen"),
          build(:question, id: "something_or_other_known", type: "radio"),
          build(:question, id: "whatchamacallit_asked", type: "radio"),
          build(:question, id: "ownershipsch"),
          build(:question, id: "checkbox_question", type: "checkbox", answer_options: { "pregyrha" => {}, "pregother" => {} }),
          build(:question, id: "type"),
        ]
      end

      it "does not add questions for checks, whether some other attribute is known or whether something else was asked" do
        headers = csv.first
        expect(headers).not_to include "attribute_value_check"
        expect(headers).not_to include "something_or_other_known"
        expect(headers).not_to include "whatchamacallit_asked"
      end

      it "does not add the id of checkbox questions, but adds the related attributes of the log in the correct order" do
        headers = csv.first
        expect(headers.last(4)).to eq %w[ownershipsch pregyrha pregother type]
      end
    end
  end

  it "includes attributes not related to questions to the headers" do
    headers = csv.first
    expect(headers).to include(*%w[id status created_at updated_at old_form_id])
  end

  it "returns a csv with the correct number of logs" do
    create_list(:sales_log, 15)
    log_count = SalesLog.count
    expected_row_count_with_headers = log_count + 1
    expect(csv.size).to be expected_row_count_with_headers
  end

  context "when exporting with human readable labels" do
    it "gives answers to radio questions as their labels" do
      national_column_index = csv.first.index("national")
      national_value = csv.second[national_column_index]
      expect(national_value).to eq "United Kingdom"
      relat2_column_index = csv.first.index("relat2")
      relat2_value = csv.second[relat2_column_index]
      expect(relat2_value).to eq "Partner"
    end

    it "gives answers to free input questions as the user input" do
      age1_column_index = csv.first.index("age1")
      age1_value = csv.second[age1_column_index]
      expect(age1_value).to eq 30.to_s
      postcode_part1, postcode_part2 = log.postcode_full.split
      postcode_part1_column_index = csv.first.index("pcode1")
      postcode_part1_value = csv.second[postcode_part1_column_index]
      expect(postcode_part1_value).to eq postcode_part1
      postcode_part2_column_index = csv.first.index("pcode2")
      postcode_part2_value = csv.second[postcode_part2_column_index]
      expect(postcode_part2_value).to eq postcode_part2
    end

    it "exports the code for the local authority under the heading 'la'" do
      la_column_index = csv.first.index("la")
      la_value = csv.second[la_column_index]
      expect(la_value).to eq "E09000003"
    end

    it "exports the label for the local authority under the heading 'la_label'" do
      la_label_column_index = csv.first.index("la_label")
      la_label_value = csv.second[la_label_column_index]
      expect(la_label_value).to eq "Barnet"
    end

    it "exports the CSV with all values correct" do
      expected_content = CSV.read("spec/fixtures/files/sales_logs_csv_export_labels.csv")
      values_to_delete = %w[id]
      values_to_delete.each do |attribute|
        index = csv.first.index(attribute)
        csv.second[index] = nil
      end
      expect(csv).to eq expected_content
    end
  end

  context "when exporting values as codes" do
    let(:service) { described_class.new(export_type: "codes") }

    it "gives answers to radio questions as their codes" do
      national_column_index = csv.first.index("national")
      national_value = csv.second[national_column_index]
      expect(national_value).to eq 18.to_s
      relat2_column_index = csv.first.index("relat2")
      relat2_value = csv.second[relat2_column_index]
      expect(relat2_value).to eq "P"
    end

    it "gives answers to free input questions as the user input" do
      age1_column_index = csv.first.index("age1")
      age1_value = csv.second[age1_column_index]
      expect(age1_value).to eq 30.to_s
      postcode_part1, postcode_part2 = log.postcode_full.split
      postcode_part1_column_index = csv.first.index("pcode1")
      postcode_part1_value = csv.second[postcode_part1_column_index]
      expect(postcode_part1_value).to eq postcode_part1
      postcode_part2_column_index = csv.first.index("pcode2")
      postcode_part2_value = csv.second[postcode_part2_column_index]
      expect(postcode_part2_value).to eq postcode_part2
    end

    it "exports the code for the local authority under the heading 'la'" do
      la_column_index = csv.first.index("la")
      la_value = csv.second[la_column_index]
      expect(la_value).to eq "E09000003"
    end

    it "exports the label for the local authority under the heading 'la_label'" do
      la_label_column_index = csv.first.index("la_label")
      la_label_value = csv.second[la_label_column_index]
      expect(la_label_value).to eq "Barnet"
    end

    it "exports the CSV with all values correct" do
      expected_content = CSV.read("spec/fixtures/files/sales_logs_csv_export_codes.csv")
      values_to_delete = %w[id]
      values_to_delete.each do |attribute|
        index = csv.first.index(attribute)
        csv.second[index] = nil
      end
      expect(csv).to eq expected_content
    end
  end
end
