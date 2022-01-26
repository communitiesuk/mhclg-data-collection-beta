require "rails_helper"

RSpec.describe Form, type: :model do
  let(:case_log) { FactoryBot.build(:case_log, :in_progress) }
  let(:form) { case_log.form }
  let(:completed_case_log) { FactoryBot.build(:case_log, :completed) }
  let(:conditional_section_complete_case_log) { FactoryBot.build(:case_log, :conditional_section_complete) }

  describe ".next_page" do
    let(:previous_page) { form.get_page("person_1_age") }

    it "returns the next page given the previous" do
      expect(form.next_page(previous_page, case_log)).to eq("person_1_gender")
    end
  end

  describe "next_page_redirect_path" do
    let(:previous_page) { form.get_page("net_income") }
    let(:last_previous_page) { form.get_page("housing_benefit") }
    let(:previous_conditional_page) { form.get_page("conditional_question") }

    it "returns a correct page path if there is no conditional routing" do
      expect(form.next_page_redirect_path(previous_page, case_log)).to eq("case_log_net_income_uc_proportion_path")
    end

    it "returns a check answers page if previous page is the last page" do
      expect(form.next_page_redirect_path(last_previous_page, case_log)).to eq("case_log_income_and_benefits_check_answers_path")
    end

    it "returns a correct page path if there is conditional routing" do
      case_log["preg_occ"] = "No"
      expect(form.next_page_redirect_path(previous_conditional_page, case_log)).to eq("case_log_conditional_question_no_page_path")
    end
  end

  describe "next_incomplete_section_redirect_path" do
    let(:case_log) { FactoryBot.build(:case_log, :in_progress) }
    let(:subsection) { form.get_subsection("household_characteristics") }
    let(:later_subsection) { form.get_subsection("local_authority") }

    context "when a user is on the check answers page for a subsection" do
      before do
        case_log.tenant_code = "123"
        case_log.age1 = 35
        case_log.sex1 = "Male"
        case_log.other_hhmemb = 0
      end

      it "returns the first page of the next incomplete subsection" do
        expect(form.next_incomplete_section_redirect_path(subsection, case_log)).to eq("armed-forces")
      end

      it "returns the first page of the next incomplete subsection (skipping completed subsections)" do
        case_log.armedforces = "No"
        case_log.illness = "No"
        case_log.housingneeds_a = "Yes"
        case_log.la = "York"
        case_log.illness_type_1 = "Yes"
        expect(form.next_incomplete_section_redirect_path(subsection, case_log)).to eq("tenancy-code")
      end

      it "returns the next incomplete section by cycling back around if next subsections are completed" do
        case_log.layear = "1 to 2 years"
        case_log.lawaitlist = "Less than 1 year"
        case_log.property_postcode = "NW1 5TY"
        case_log.reason = "Permanently decanted from another property owned by this landlord"
        case_log.previous_postcode = "SE2 6RT"
        case_log.mrcdate = Time.zone.parse("03/11/2019")
        expect(form.next_incomplete_section_redirect_path(later_subsection, case_log)).to eq("armed-forces")
      end

      it "returns the declaration section if all sections are complete" do
        expect(form.next_incomplete_section_redirect_path(subsection, completed_case_log)).to eq("declaration")
      end
    end
  end

  describe "invalidated_page_questions" do
    context "when dependencies are not met" do
      let(:expected_invalid) { %w[la_known cbl conditional_question_no_second_question dependent_question declaration] }

      it "returns an array of question keys whose pages conditions are not met" do
        expect(form.invalidated_page_questions(case_log).map(&:id).uniq).to eq(expected_invalid)
      end
    end

    context "with two pages having the same question and only one has dependencies met" do
      let(:expected_invalid) { %w[la_known conditional_question_no_second_question dependent_question declaration] }

      it "returns an array of question keys whose pages conditions are not met" do
        case_log["preg_occ"] = "No"
        expect(form.invalidated_page_questions(case_log).map(&:id).uniq).to eq(expected_invalid)
      end
    end
  end
end
