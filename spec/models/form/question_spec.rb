require "rails_helper"

RSpec.describe Form::Question, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page) }

  let(:lettings_log) { FactoryBot.build(:lettings_log) }
  let(:type) { "numeric" }
  let(:readonly) { nil }
  let(:prefix) { nil }
  let(:suffix) { nil }
  let(:depends_on_met) { nil }
  let(:conditional_question_conditions) { nil }
  let(:form_questions) { nil }
  let(:answer_options) { { "1" => { "value" => "Weekly" }, "2" => { "value" => "Monthly" } } }
  let(:inferred_check_answers_value) { [{ "condition" => { "postcode_known" => 0 }, "value" => "Weekly" }] }

  let(:form) { instance_double(Form, depends_on_met:, conditional_question_conditions:, type: "form-type", start_date: Time.utc(2024, 12, 25)) }
  let(:subsection) { instance_double(Form::Subsection, form:, id: "subsection-id", copy_key: "subsection-copy-key") }
  let(:page) { instance_double(Form::Page, subsection:, routed_to?: true, questions: form_questions) }
  let(:question_id) { "earnings" }
  let(:question_definition) do
    { "header" => "What is the tenant’s /and partner’s combined income after tax?",
      "check_answer_label" => "Income",
      "type" => type,
      "min" => 0,
      "step" => 1,
      "answer_options" => answer_options,
      "readonly" => readonly,
      "result-field" => "tcharge",
      "fields-to-add" => %w[brent scharge pscharge supcharg],
      "inferred_check_answers_value" => inferred_check_answers_value,
      "suffix" => suffix,
      "prefix" => prefix,
      "hidden_in_check_answers" => {} }
  end

  it "has an id" do
    expect(question.id).to eq(question_id)
  end

  it "sets copy_key in the default style" do
    expect(question.copy_key).to eq("#{form.type}.#{subsection.copy_key}.#{question_id}")
  end

  context "when copy is not provided" do
    let(:question_definition) do
      {
        "type" => type,
        "min" => 0,
        "step" => 1,
        "answer_options" => answer_options,
        "readonly" => readonly,
        "result-field" => "tcharge",
        "fields-to-add" => %w[brent scharge pscharge supcharg],
        "inferred_check_answers_value" => inferred_check_answers_value,
        "suffix" => suffix,
        "prefix" => prefix,
        "hidden_in_check_answers" => {},
      }
    end

    context "and translations are present" do
      before do
        allow(I18n).to receive(:t).with("forms.#{form.start_date.year}.#{question.copy_key}.question_text", { default: "" }).and_return("header copy")
        allow(I18n).to receive(:t).with("forms.#{form.start_date.year}.#{question.copy_key}.check_answer_label", { default: "" }).and_return("check answer label copy")
        allow(I18n).to receive(:t).with("forms.#{form.start_date.year}.#{question.copy_key}.hint_text", { default: "" }).and_return("hint text copy")
        allow(I18n).to receive(:exists?).and_return(true)
      end

      it "uses header from translations" do
        expect(question.header).to eq("header copy")
      end

      it "uses check answer label from translations" do
        expect(question.check_answer_label).to eq("check answer label copy")
      end

      it "uses hint text from translations" do
        expect(question.hint_text).to eq("hint text copy")
      end
    end

    context "and translations are not present" do
      before do
        allow(I18n).to receive(:exists?).and_return(false)
      end

      it "uses empty header" do
        expect(question.header).to eq("")
      end

      it "uses empty check answer label" do
        expect(question.check_answer_label).to eq("")
      end

      it "uses empty hint text" do
        expect(question.hint_text).to eq("")
      end
    end
  end

  it "has a header" do
    expect(question.header).to eq("What is the tenant’s /and partner’s combined income after tax?")
  end

  it "has a check answers label" do
    expect(question.check_answer_label).to eq("Income")
  end

  it "has a question type" do
    expect(question.type).to eq("numeric")
  end

  it "belongs to a page" do
    expect(question.page).to eq(page)
  end

  it "belongs to a subsection" do
    expect(question.subsection).to eq(subsection)
  end

  it "has a read only helper" do
    expect(question.read_only?).to be false
  end

  it "has a yes value helper" do
    expect(question).to be_value_is_yes("Yes")
    expect(question).to be_value_is_yes("YES")
    expect(question).not_to be_value_is_yes("random")
  end

  it "has a check answer prompt" do
    question_definition["check_answer_prompt"] = "Enter total income"
    expect(question.check_answer_prompt).to eq("Enter total income")
  end

  context "when type is numeric" do
    it "has a min value" do
      expect(question.min).to eq(0)
    end

    it "has a step value" do
      expect(question.step).to eq(1)
    end

    it "does not map value from label" do
      expect(question.value_from_label("5")).to eq("5")
    end

    it "has generates a default check answer prompt" do
      expect(question.check_answer_prompt).to eq("Enter income")
    end
  end

  context "when type is radio" do
    let(:type) { "radio" }

    it "has answer options" do
      expected_answer_options = { "1" => { "value" => "Weekly" }, "2" => { "value" => "Monthly" } }
      expect(question.answer_options).to eq(expected_answer_options)
    end

    it "can map value from label" do
      expect(question.value_from_label("Monthly")).to eq("2")
    end

    it "can map label from value" do
      expect(question.label_from_value(1)).to eq("Weekly")
    end

    it "has generates a default check answer prompt" do
      expect(question.check_answer_prompt).to eq("Select income")
    end

    context "when answer options include yes, no, prefer not to say" do
      let(:question_id) { "illness" }

      it "maps those options" do
        expect(question).to be_value_is_yes(1)
        expect(question).not_to be_value_is_refused(1)
        expect(question).to be_value_is_dont_know(3)
      end
    end

    context "when answer options includes don’t know" do
      let(:question_id) { "layear" }

      it "maps those options" do
        expect(question).not_to be_value_is_yes(7)
        expect(question).not_to be_value_is_refused(7)
        expect(question).to be_value_is_dont_know(7)
      end
    end

    context "when answer options do not include derived options" do
      it "displays all answer options" do
        expect(question.displayed_answer_options(lettings_log)).to match(question.answer_options)
      end
    end

    context "when answer options include derived options" do
      let(:answer_options) { { "0" => { "value" => "Other" }, "9" => { "value" => "This", "depends_on" => [false] } } }
      let(:depends_on_met) { false }
      let(:expected_answer_options) do
        {
          "0" => { "value" => "Other" },
        }
      end

      it "does not include those options in the displayed options" do
        expect(question.displayed_answer_options(lettings_log)).to match(expected_answer_options)
      end

      it "can still map the value label" do
        expect(question.label_from_value(9)).to eq("This")
      end
    end

    context "when the saved answer is not in the value map" do
      it "displays the saved answer umapped" do
        expect(question.label_from_value(9999)).to eq("9999")
      end
    end
  end

  context "when type is select" do
    let(:type) { "select" }
    let(:answer_options) { { "E08000003" => "Manchester", "E09000033" => "Westminster" } }

    it "can map value from label" do
      expect(question.value_from_label("Manchester")).to eq("E08000003")
    end

    it "can map label from value" do
      expect(question.label_from_value("E09000033")).to eq("Westminster")
    end

    it "has generates a default check answer prompt" do
      expect(question.check_answer_prompt).to eq("Select income")
    end

    context "when the saved answer is not in the value map" do
      it "displays the saved answer umapped" do
        expect(question.label_from_value(9999)).to eq("9999")
      end
    end
  end

  context "when type is checkbox" do
    let(:type) { "checkbox" }
    let(:page_id) { "illness" }
    let(:answer_options) { { "illness_type_1" => { "value" => "Vision - such as blindness or partial sight" }, "illness_type_2" => { "value" => "Hearing - such as deafness or partial hearing" } } }

    it "has generates a default check answer prompt" do
      expect(question.check_answer_prompt).to eq("Select income")
    end

    it "has answer options" do
      expected_answer_options = {
        "illness_type_1" => { "value" => "Vision - such as blindness or partial sight" },
        "illness_type_2" => { "value" => "Hearing - such as deafness or partial hearing" },
      }
      expect(question.answer_options).to eq(expected_answer_options)
    end

    it "can map yes values" do
      expect(question).to be_value_is_yes(1)
      expect(question).not_to be_value_is_yes(0)
    end
  end

  context "when the question is read only" do
    let(:readonly) { true }

    it "has a read only helper" do
      expect(question.read_only?).to be true
    end

    context "when the answer is part of a sum" do
      let(:question_id) { "pscharge" }

      it "has a result_field" do
        expect(question.result_field).to eq("tcharge")
      end

      it "has fields to sum" do
        expected_fields_to_sum = %w[brent scharge pscharge supcharg]
        expect(question.fields_to_add).to eq(expected_fields_to_sum)
      end
    end
  end

  context "with a lettings log" do
    let(:lettings_log) { FactoryBot.build(:lettings_log, :in_progress) }
    let(:question_id) { "incfreq" }
    let(:type) { "radio" }
    let(:answer_options) { { "1" => { "value" => "Weekly" }, "2" => { "value" => "Monthly" }, "3" => { "value" => "Yearly", "depends_on" => true } } }

    it "has an answer label" do
      lettings_log.incfreq = 1
      expect(question.answer_label(lettings_log)).to eq("Weekly")
    end

    it "has an update answer link text helper" do
      lettings_log["incfreq"] = 0
      expect(question.action_text(lettings_log)).to match(/Change/)
    end

    context "when the question has an inferred answer" do
      let(:lettings_log) { FactoryBot.build(:lettings_log, :in_progress, postcode_known: 0, postcode_full: nil) }
      let(:question_id) { "incfreq" }
      let(:type) { "radio" }

      it "displays 'change' in the check answers link text" do
        expect(question.action_text(lettings_log)).to match(/Change/)
      end
    end

    context "when the answer option is a derived answer option" do
      let(:lettings_log) { FactoryBot.build(:lettings_log, :in_progress, incfreq: 3, postcode_full: nil) }
      let(:depends_on_met) { true }

      it "knows it has an inferred value or is derived for check answers" do
        expect(question.is_derived_or_has_inferred_check_answers_value?(lettings_log)).to be true
      end
    end

    context "when type is date" do
      let(:question_id) { "mrcdate" }
      let(:type) { "date" }

      it "displays a formatted answer label" do
        lettings_log.mrcdate = Time.zone.local(2021, 10, 11)
        expect(question.answer_label(lettings_log)).to eq("11 October 2021")
      end

      it "can handle nils" do
        lettings_log.mrcdate = nil
        expect(question.answer_label(lettings_log)).to eq("")
      end

      it "has generates a default check answer prompt" do
        expect(question.check_answer_prompt).to eq("Set income")
      end
    end

    context "when type is checkbox" do
      let(:question_id) { "housingneeds_type" }
      let(:type) { "checkbox" }
      let(:answer_options) do
        {
          "housingneeds_a" => { "value" => "Fully wheelchair accessible housing" },
          "housingneeds_b" => { "value" => "Wheelchair access to essential rooms" },
          "housingneeds_c" => { "value" => "Level access housing" },
        }
      end

      it "has a joined answers label" do
        lettings_log.housingneeds_a = 1
        lettings_log.housingneeds_c = 1
        expected_answer_label = "Fully wheelchair accessible housing, Level access housing"
        expect(question.answer_label(lettings_log)).to eq(expected_answer_label)
      end
    end

    context "when a condition is present" do
      let(:question_id) { "conditional_question" }
      let(:conditional_question_conditions) { [{ to: question_id, from: "hb", cond: [0] }] }
      let(:form_questions) { [OpenStruct.new(id: "hb", type: "radio")] }

      it "knows whether it is enabled or not for unmet conditions" do
        expect(question.enabled?(lettings_log)).to be false
      end

      it "knows whether it is enabled or not for met conditions" do
        lettings_log.hb = "Housing benefit"
        expect(question.enabled?(lettings_log)).to be true
      end

      context "when the condition type hasn't been implemented yet" do
        let(:form_questions) { [OpenStruct.new(id: "hb", type: "unkown")] }

        it "raises an exception" do
          expect { question.enabled?(lettings_log) }.to raise_error("Not implemented yet")
        end
      end
    end

    context "when answers have a suffix dependent on another answer" do
      let(:question_id) { "earnings" }
      let(:type) { "numeric" }
      let(:suffix) do
        [
          { "label" => " every week", "depends_on" => { "incfreq" => 1 } },
          { "label" => " every month", "depends_on" => { "incfreq" => 2 } },
          { "label" => " every year", "depends_on" => { "incfreq" => 3 } },
        ]
      end
      let(:prefix) { "£" }

      it "displays the correct label for given suffix and answer the suffix depends on" do
        lettings_log.incfreq = 1
        lettings_log.earnings = 500
        expect(question.answer_label(lettings_log)).to eq("£500.00 every week")
        lettings_log.incfreq = 2
        expect(question.answer_label(lettings_log)).to eq("£500.00 every month")
        lettings_log.incfreq = 3
        expect(question.answer_label(lettings_log)).to eq("£500.00 every year")
      end
    end

    context "with inferred_check_answers_value" do
      context "when Lettings form" do
        let(:question_id) { "armedforces" }
        let(:inferred_check_answers_value) { [{ "condition" => { "armedforces" => 3 }, "value" => "Prefers not to say" }] }

        it "returns the inferred label value" do
          lettings_log.armedforces = 3
          expect(question.answer_label(lettings_log)).to eq("Prefers not to say")
        end
      end

      context "when Sales form" do
        let(:question_id) { "national" }
        let(:sales_log) { FactoryBot.build(:sales_log, :completed, national: 13) }
        let(:inferred_check_answers_value) { [{ "condition" => { "national" => 13 }, "value" => "Prefers not to say" }] }

        it "returns the inferred label value" do
          expect(question.answer_label(sales_log)).to eq("Prefers not to say")
        end
      end
    end
  end

  describe ".completed?" do
    context "when the question has inferred value only for check answers display" do
      it "returns true" do
        lettings_log["postcode_known"] = 0
        expect(question.completed?(lettings_log)).to be(true)
      end
    end
  end

  context "when the question has a hidden in check answers attribute with dependencies" do
    let(:lettings_log) { FactoryBot.build(:lettings_log, :in_progress) }

    context "when it's hidden in check answers" do
      let(:depends_on_met) { true }

      it "can work out if the question will be shown in check answers" do
        expect(question.hidden_in_check_answers?(lettings_log, nil)).to be(true)
      end
    end

    context "when it's not hidden in check answers" do
      let(:depends_on_met) { false }

      it "can work out if the question will be shown in check answers" do
        expect(question.hidden_in_check_answers?(lettings_log, nil)).to be(false)
      end
    end
  end

  describe "#error_display_label" do
    let(:question_with_error_label_no_punctuation) { described_class.new("address_line1_input", { "header" => "address line 1", "error_label" => "address line 1" }, page) }
    let(:question_with_error_label_with_full_stop) { described_class.new("address_line1_input", { "header" => "address line 1", "error_label" => "address line 1." }, page) }
    let(:question_with_error_label_with_question_mark) { described_class.new("address_line1_input", { "header" => "address line 1", "error_label" => "address line 1?" }, page) }
    let(:question_with_error_label_with_brackets) { described_class.new("address_line1_input", { "header" => "address line 1", "error_label" => "(address line 1)" }, page) }
    let(:question_with_error_label_with_percentage) { described_class.new("address_line1_input", { "header" => "address line 1", "error_label" => "address line 1%" }, page) }

    let(:question_with_check_answer_label_no_punctuation) { described_class.new("address_line1_input", { "header" => "address line 1", "check_answer_label" => "address line 1" }, page) }
    let(:question_with_check_answer_label_with_full_stop) { described_class.new("address_line1_input", { "header" => "address line 1", "check_answer_label" => "address line 1." }, page) }
    let(:question_with_check_answer_label_with_question_mark) { described_class.new("address_line1_input", { "header" => "address line 1", "check_answer_label" => "address line 1?" }, page) }
    let(:question_with_check_answer_label_with_brackets) { described_class.new("address_line1_input", { "header" => "address line 1", "check_answer_label" => "(address line 1)" }, page) }
    let(:question_with_check_answer_label_with_percentage) { described_class.new("address_line1_input", { "header" => "address line 1", "check_answer_label" => "address line 1%" }, page) }

    let(:question_with_header_no_punctuation) { described_class.new("address_line1_input", { "header" => "address line 1" }, page) }
    let(:question_with_header_with_full_stop) { described_class.new("address_line1_input", { "header" => "address line 1." }, page) }
    let(:question_with_header_with_question_mark) { described_class.new("address_line1_input", { "header" => "address line 1?" }, page) }
    let(:question_with_header_with_brackets) { described_class.new("address_line1_input", { "header" => "(address line 1)" }, page) }
    let(:question_with_header_with_percentage) { described_class.new("address_line1_input", { "header" => "address line 1%" }, page) }

    let(:question_with_id_only_no_punctuation) { described_class.new("address_line1_input", {}, page) }

    context "when the error label should stay the same" do
      it "returns the error label unchanged with full stop" do
        expect(question_with_error_label_with_full_stop.error_display_label).to eq("address line 1.")
      end

      it "returns the error label unchanged with question mark" do
        expect(question_with_error_label_with_question_mark.error_display_label).to eq("address line 1?")
      end

      it "returns the check answer label unchanged with full stop" do
        expect(question_with_check_answer_label_with_full_stop.error_display_label).to eq("address line 1.")
      end

      it "returns the check answer label unchanged with question mark" do
        expect(question_with_check_answer_label_with_question_mark.error_display_label).to eq("address line 1?")
      end

      it "returns the header unchanged with full stop" do
        expect(question_with_header_with_full_stop.error_display_label).to eq("address line 1.")
      end

      it "returns the header unchanged with question mark" do
        expect(question_with_header_with_question_mark.error_display_label).to eq("address line 1?")
      end
    end

    context "when the error label should have a full stop added" do
      it "returns the error label with no punctuation changed to with a full stop" do
        expect(question_with_error_label_no_punctuation.error_display_label).to eq("address line 1.")
      end

      it "returns the error label with brackets changed to with a full stop" do
        expect(question_with_error_label_with_brackets.error_display_label).to eq("(address line 1).")
      end

      it "returns the error label with percentage changed to with a full stop" do
        expect(question_with_error_label_with_percentage.error_display_label).to eq("address line 1%.")
      end

      it "returns the check answer label with no punctuation changed with a full stop" do
        expect(question_with_check_answer_label_no_punctuation.error_display_label).to eq("address line 1.")
      end

      it "returns the check answer label with brackets changed with a full stop" do
        expect(question_with_check_answer_label_with_brackets.error_display_label).to eq("(address line 1).")
      end

      it "returns the check answer label with percentage changed with a full stop" do
        expect(question_with_check_answer_label_with_percentage.error_display_label).to eq("address line 1%.")
      end

      it "returns the header with no punctuation changed with a full stop" do
        expect(question_with_header_no_punctuation.error_display_label).to eq("address line 1.")
      end

      it "returns the header with brackets changed with a full stop" do
        expect(question_with_header_with_brackets.error_display_label).to eq("(address line 1).")
      end

      it "returns the header with percentage changed with a full stop" do
        expect(question_with_header_with_percentage.error_display_label).to eq("address line 1%.")
      end

      it "returns the id with no punctuation changed with a full stop" do
        expect(question_with_id_only_no_punctuation.error_display_label).to eq("address line1 input.")
      end
    end
  end
end
