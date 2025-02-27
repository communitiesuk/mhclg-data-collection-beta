require "rails_helper"

RSpec.describe Csv::SalesLogCsvService do
  subject(:task) { Rake::Task["data_import:add_variable_definitions"] }

  let(:form_handler_mock) { instance_double(FormHandler) }
  let(:organisation) { create(:organisation, name: "MHCLG") }
  let(:fixed_time) { now }
  let(:now) { Time.zone.now }
  let(:user) { create(:user, :support, email: "billyboy@eyeKLAUD.com") }
  let(:log) do
    create(
      :sales_log,
      :completed,
      assigned_to: user,
      saledate: fixed_time,
      created_at: fixed_time,
      updated_at: now,
      owning_organisation: organisation,
      managing_organisation: organisation,
      purchid: nil,
      hholdcount: 3,
      age1: 30,
      sex1: "X",
      age2: 35,
      sex2: "X",
      sex3: "X",
      age4_known: 1,
      sex4: "X",
      details_known_5: 2,
      age6_known: nil,
      age6: nil,
      ecstat6: nil,
      relat6: nil,
      sex6: nil,
      town_or_city: "Town or city",
      address_line1_as_entered: "address line 1 as entered",
      address_line2_as_entered: "address line 2 as entered",
      town_or_city_as_entered: "town or city as entered",
      county_as_entered: "county as entered",
      postcode_full_as_entered: "AB1 2CD",
      la_as_entered: "la as entered",
      hhregres: 1,
      hhregresstill: 4,
    )
  end
  let(:service) { described_class.new(user:, export_type: "labels", year:) }
  let(:csv) { CSV.parse(service.prepare_csv(SalesLog.all)) }
  let(:year) { 2024 }
  let(:definition_line) { csv.first }
  let(:attribute_line) { csv.second }
  let(:content_line) { csv.third }

  before do
    Timecop.freeze(now)
    Singleton.__init__(FormHandler)
    log
    Rake.application.rake_require("tasks/log_variable_definitions")
    Rake::Task.define_task(:environment)
    task.reenable
    task.invoke("spec/fixtures/variable_definitions")
  end

  after do
    Timecop.return
  end

  it "returns a string" do
    result = service.prepare_csv(SalesLog.all)
    expect(result).to be_a String
  end

  it "returns a csv with definition headers on first line" do
    expect(definition_line.first).to eq "Log ID"
  end

  it "returns a csv with attribute headers on second line" do
    expect(attribute_line.first).to eq "ID"
  end

  context "when stubbing :ordered_questions_for_year" do
    let(:sales_form) do
      FormFactory.new(year: 1936, type: "sales")
                 .with_sections([build(:section, :with_questions, question_ids:, questions:)])
                 .build
    end
    let(:question_ids) { [] }
    let(:questions) { nil }
    let(:year) { 1936 }

    before do
      allow(FormHandler).to receive(:instance).and_return(form_handler_mock)
      allow(form_handler_mock).to receive(:form_name_from_start_year)
      allow(form_handler_mock).to receive(:get_form).and_return(sales_form)
      allow(form_handler_mock).to receive(:ordered_questions_for_year).and_return(sales_form.questions)
    end

    it "calls the form handler to get all questions in order when initialized" do
      allow(FormHandler).to receive(:instance).and_return(form_handler_mock)
      allow(form_handler_mock).to receive(:ordered_questions_for_year).and_return([])
      service
      expect(form_handler_mock).to have_received(:ordered_questions_for_year).with(1936, "sales")
    end

    context "when it returns questions with particular ids" do
      let(:question_ids) { %w[type age1 buy1livein exdate] }

      it "includes log attributes related to questions to the headers" do
        attribute_line_before_2023 = csv.first
        expect(attribute_line_before_2023).to include(*%w[TYPE AGE1 LIVEINBUYER1])
      end

      it "removes some log attributes related to questions from the headers and replaces them with their derived values in the correct order" do
        attribute_line_before_2023 = csv.first
        expect(attribute_line_before_2023).not_to include "EXDATE"
        expect(attribute_line_before_2023.last(4)).to eq %w[LIVEINBUYER1 EXDAY EXMONTH EXYEAR]
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
        attribute_line_before_2023 = csv.first
        expect(attribute_line_before_2023).not_to include "attribute_value_check"
        expect(attribute_line_before_2023).not_to include "something_or_other_known"
        expect(attribute_line_before_2023).not_to include "whatchamacallit_asked"
      end

      it "does not add the id of checkbox questions, but adds the related attributes of the log in the correct order" do
        attribute_line_before_2023 = csv.first
        expect(attribute_line_before_2023.last(4)).to eq %w[OWNERSHIP PREGYRHA PREGOTHER TYPE]
      end
    end
  end

  it "includes attributes not related to questions to the headers" do
    expect(attribute_line).to include(*%w[ID STATUS CREATEDDATE UPLOADDATE])
  end

  it "returns a csv with the correct number of logs" do
    create_list(:sales_log, 15)
    log_count = SalesLog.count
    expected_row_count_with_headers = log_count + 2
    expect(csv.size).to be expected_row_count_with_headers
  end

  context "when exporting with human readable labels" do
    let(:year) { 2023 }
    let(:fixed_time) { Time.zone.local(2023, 12, 8) }
    let(:now) { fixed_time }

    it "gives answers to radio questions as their labels" do
      national_column_index = attribute_line.index("NATIONAL")
      national_value = content_line[national_column_index]
      expect(national_value).to eq "United Kingdom"
      relat2_column_index = attribute_line.index("RELAT2")
      relat2_value = content_line[relat2_column_index]
      expect(relat2_value).to eq "Partner"
    end

    it "gives answers to free input questions as the user input" do
      age1_column_index = attribute_line.index("AGE1")
      age1_value = content_line[age1_column_index]
      expect(age1_value).to eq 30.to_s
      postcode_part1, postcode_part2 = log.postcode_full.split
      postcode_part1_column_index = attribute_line.index("PCODE1")
      postcode_part1_value = content_line[postcode_part1_column_index]
      expect(postcode_part1_value).to eq postcode_part1
      postcode_part2_column_index = attribute_line.index("PCODE2")
      postcode_part2_value = content_line[postcode_part2_column_index]
      expect(postcode_part2_value).to eq postcode_part2
    end

    it "exports the code for the local authority under the heading 'la'" do
      la_column_index = attribute_line.index("LA")
      la_value = content_line[la_column_index]
      expect(la_value).to eq "E09000033"
    end

    it "exports the label for the local authority under the heading 'la_label'" do
      la_label_column_index = attribute_line.index("LANAME")
      la_label_value = content_line[la_label_column_index]
      expect(la_label_value).to eq "Westminster"
    end

    context "when the requested form is 2024" do
      let(:now) { Time.zone.local(2024, 5, 1) }
      let(:year) { 2024 }
      let(:fixed_time) { Time.zone.local(2024, 5, 1) }

      before do
        log.update!(nationality_all: 36, manual_address_entry_selected: false, uprn: "1", uprn_known: 1)
      end

      it "exports the CSV with the 2024 ordering and all values correct" do
        expected_content = CSV.read("spec/fixtures/files/sales_logs_csv_export_labels_24.csv")
        values_to_delete = %w[ID]
        values_to_delete.each do |attribute|
          index = attribute_line.index(attribute)
          content_line[index] = nil
        end
        expect(csv).to eq expected_content
      end
    end

    context "when the requested form is 2023" do
      let(:now) { Time.zone.local(2024, 1, 1) }
      let(:year) { 2023 }

      it "exports the CSV with the 2023 ordering and all values correct" do
        expected_content = CSV.read("spec/fixtures/files/sales_logs_csv_export_labels_23.csv")
        values_to_delete = %w[ID]
        values_to_delete.each do |attribute|
          index = attribute_line.index(attribute)
          content_line[index] = nil
        end
        expect(csv).to eq expected_content
      end
    end

    context "when the log has a duplicate log reference" do
      before do
        log.update!(duplicate_set_id: 12_312)
      end

      it "exports the id for under the heading 'duplicate_set_id'" do
        duplicate_set_id_column_index = attribute_line.index("DUPLICATESET")
        duplicate_set_id_value = content_line[duplicate_set_id_column_index]
        expect(duplicate_set_id_value).to eq "12312"
      end
    end
  end

  context "when exporting values as codes" do
    let(:service) { described_class.new(user:, export_type: "codes", year:) }
    let(:year) { 2023 }
    let(:fixed_time) { Time.zone.local(2023, 12, 8) }
    let(:now) { fixed_time }

    it "gives answers to radio questions as their codes" do
      national_column_index = attribute_line.index("NATIONAL")
      national_value = content_line[national_column_index]
      expect(national_value).to eq 18.to_s
      relat2_column_index = attribute_line.index("RELAT2")
      relat2_value = content_line[relat2_column_index]
      expect(relat2_value).to eq "P"
    end

    it "gives answers to free input questions as the user input" do
      age1_column_index = attribute_line.index("AGE1")
      age1_value = content_line[age1_column_index]
      expect(age1_value).to eq 30.to_s
      postcode_part1, postcode_part2 = log.postcode_full.split
      postcode_part1_column_index = attribute_line.index("PCODE1")
      postcode_part1_value = content_line[postcode_part1_column_index]
      expect(postcode_part1_value).to eq postcode_part1
      postcode_part2_column_index = attribute_line.index("PCODE2")
      postcode_part2_value = content_line[postcode_part2_column_index]
      expect(postcode_part2_value).to eq postcode_part2
    end

    it "exports the code for the local authority under the heading 'la'" do
      la_column_index = attribute_line.index("LA")
      la_value = content_line[la_column_index]
      expect(la_value).to eq "E09000033"
    end

    it "exports the label for the local authority under the heading 'la_label'" do
      la_label_column_index = attribute_line.index("LANAME")
      la_label_value = content_line[la_label_column_index]
      expect(la_label_value).to eq "Westminster"
    end

    context "when the requested form is 2024" do
      let(:now) { Time.zone.local(2024, 5, 1) }
      let(:fixed_time) { Time.zone.local(2024, 5, 1) }
      let(:year) { 2024 }

      before do
        log.update!(manual_address_entry_selected: false, uprn: "1", uprn_known: 1)
      end

      it "exports the CSV with all values correct" do
        expected_content = CSV.read("spec/fixtures/files/sales_logs_csv_export_codes_24.csv")
        values_to_delete = %w[ID]
        values_to_delete.each do |attribute|
          index = attribute_line.index(attribute)
          content_line[index] = nil
        end
        expect(csv).to eq expected_content
      end
    end

    context "when the requested form is 2023" do
      let(:now) { Time.zone.local(2024, 1, 1) }
      let(:year) { 2023 }

      it "exports the CSV with all values correct" do
        expected_content = CSV.read("spec/fixtures/files/sales_logs_csv_export_codes_23.csv")
        values_to_delete = %w[ID]
        values_to_delete.each do |attribute|
          index = attribute_line.index(attribute)
          content_line[index] = nil
        end
        expect(csv).to eq expected_content
      end
    end

    context "when the log has a duplicate log reference" do
      before do
        log.update!(duplicate_set_id: 12_312)
      end

      it "exports the id for under the heading 'duplicate_set_id'" do
        duplicate_set_id_column_index = attribute_line.index("DUPLICATESET")
        duplicate_set_id_value = content_line[duplicate_set_id_column_index]
        expect(duplicate_set_id_value).to eq "12312"
      end
    end
  end

  context "when the user is not a support user" do
    let(:user) { create(:user, email: "billyboy@eyeklaud.com") }

    it "does not include certain attributes in the headers" do
      expect(attribute_line).not_to include(*%w[address_line1_as_entered address_line2_as_entered town_or_city_as_entered county_as_entered postcode_full_as_entered la_as_entered created_by value_value_check monthly_charges_value_check])
    end

    context "and the requested form is 2024" do
      let(:year) { 2024 }
      let(:now) { Time.zone.local(2024, 5, 1) }
      let(:fixed_time) { Time.zone.local(2024, 5, 1) }

      before do
        log.update!(nationality_all: 36, manual_address_entry_selected: false, uprn: "1", uprn_known: 1)
      end

      context "and exporting with labels" do
        let(:export_type) { "labels" }

        it "exports the CSV with all values correct" do
          expected_content = CSV.read("spec/fixtures/files/sales_logs_csv_export_non_support_labels_24.csv")
          values_to_delete = %w[id]
          values_to_delete.each do |attribute|
            index = attribute_line.index(attribute)
            content_line[index] = nil
          end
          expect(csv).to eq expected_content
        end
      end
    end
  end
end
