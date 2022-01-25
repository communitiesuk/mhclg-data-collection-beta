require "rails_helper"

RSpec.describe Form::Subsection, type: :model do
  let(:case_log) { FactoryBot.build(:case_log) }
  let(:form) { case_log.form }
  let(:section_id) { "household" }
  let(:section_definition) { form.form_definition["sections"][section_id] }
  let(:section) { Form::Section.new(section_id, section_definition, form) }
  let(:subsection_id) { "household_characteristics" }
  let(:subsection_definition) { section_definition["subsections"][subsection_id] }
  subject { Form::Subsection.new(subsection_id, subsection_definition, section) }

  it "has an id" do
    expect(subject.id).to eq(subsection_id)
  end

  it "has a label" do
    expect(subject.label).to eq("Household characteristics")
  end

  it "has pages" do
    expected_pages = %w[tenant_code person_1_age person_1_gender household_number_of_other_members]
    expect(subject.pages.map(&:id)).to eq(expected_pages)
  end

  it "has questions" do
    expected_questions = %w[tenant_code age1 sex1 other_hhmemb relat2 age2 sex2 ecstat2]
    expect(subject.questions.map(&:id)).to eq(expected_questions)
  end

  context "for a given in progress case log" do
    let(:case_log) { FactoryBot.build(:case_log, :in_progress) }

    it "has a status" do
      expect(subject.status(case_log)).to eq(:in_progress)
    end

    it "has a completed status for completed subsection" do
      subsection_definition = section_definition["subsections"]["household_needs"]
      subject = Form::Subsection.new("household_needs", subsection_definition, section)
      case_log.armedforces = "No"
      case_log.illness = "No"
      case_log.housingneeds_a = "Yes"
      case_log.la = "York"
      case_log.illness_type_1 = "Yes"
      expect(subject.status(case_log)).to eq(:completed)
    end

    it "has status helpers" do
      expect(subject.is_incomplete?(case_log)).to be(true)
      expect(subject.is_started?(case_log)).to be(true)
    end

    it "has question helpers for the number of applicable questions" do
      expected_questions = %w[tenant_code age1 sex1 other_hhmemb]
      expect(subject.applicable_questions(case_log).map(&:id)).to eq(expected_questions)
      expect(subject.applicable_questions_count(case_log)).to eq(4)
    end

    it "has question helpers for the number of answered questions" do
      subsection_definition = section_definition["subsections"]["household_needs"]
      subject = Form::Subsection.new("household_needs", subsection_definition, section)
      expected_questions = %w[armedforces illness accessibility_requirements la condition_effects]
      case_log.armedforces = "No"
      case_log.illness = "No"
      case_log.housingneeds_a = "Yes"
      case_log.la = "York"
      case_log.illness_type_1 = "Yes"
      expect(subject.answered_questions(case_log).map(&:id)).to eq(expected_questions)
      expect(subject.answered_questions_count(case_log)).to eq(5)
    end

    it "has a question helpers for the unanswered questions" do
      expected_questions = %w[sex1 other_hhmemb]
      expect(subject.unanswered_questions(case_log).map(&:id)).to eq(expected_questions)
    end
  end

  context "the privacy notice has not been shown" do
    let(:section_id) { "about_this_log" }
    let(:subsection_id) { "about_this_log" }
    let(:case_log) { FactoryBot.build(:case_log, :about_completed, gdpr_acceptance: "No") }

    it "does not mark the section as completed" do
      expect(subject.status(case_log)).to eq(:in_progress)
    end
  end

  context "for a given completed case log" do
    let(:case_log) { FactoryBot.build(:case_log, :completed) }

    it "has a status" do
      expect(subject.status(case_log)).to eq(:completed)
    end

    it "has status helpers" do
      expect(subject.is_incomplete?(case_log)).to be(false)
      expect(subject.is_started?(case_log)).to be(true)
    end
  end
end
