require "rails_helper"

RSpec.describe ConditionalQuestionsHelper do
  let(:form) { Form.new(2021, 2022) }
  let(:page_key) { "armed_forces" }
  let(:page) { form.all_pages[page_key] }

  describe "conditional questions for page" do
    let(:conditional_pages) { %w[armed_forces_active armed_forces_injured] }

    it "returns the question keys of all conditional questions on the given page" do
      expect(conditional_questions_for_page(page)).to eq(conditional_pages)
    end
  end

  describe "display question key div" do
    let(:question_key) { "armed_forces" }
    let(:conditional_question_key) { "armed_forces_injured" }

    it "returns a non visible div for conditional questions" do
      expect(display_question_key_div(page, conditional_question_key)).to match("style='display:none;'")
    end

    it "returns a visible div for conditional questions" do
      expect(display_question_key_div(page, question_key)).not_to match("style='display:none;'")
    end
  end
end
