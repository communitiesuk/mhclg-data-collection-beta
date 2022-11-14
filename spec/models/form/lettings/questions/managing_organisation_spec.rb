require "rails_helper"

RSpec.describe Form::Lettings::Questions::ManagingOrganisation, type: :model do
  subject(:question) { described_class.new(question_id, question_definition, page) }

  let(:question_id) { nil }
  let(:question_definition) { nil }
  let(:page) { instance_double(Form::Page) }
  let(:subsection) { instance_double(Form::Subsection) }
  let(:form) { instance_double(Form) }

  it "has correct page" do
    expect(question.page).to eq(page)
  end

  it "has the correct id" do
    expect(question.id).to eq("managing_organisation_id")
  end

  it "has the correct header" do
    expect(question.header).to eq("Which organisation manages this letting?")
  end

  it "has the correct check_answer_label" do
    expect(question.check_answer_label).to eq("Managing agent")
  end

  it "has the correct type" do
    expect(question.type).to eq("select")
  end

  it "has the correct hint_text" do
    expect(question.hint_text).to be_nil
  end

  describe "#displayed_answer_options" do
    let(:options) { { "" => "Select an option" } }

    context "when current_user nil" do
      let(:log) { create(:lettings_log) }

      it "shows default options" do
        expect(question.displayed_answer_options(log, nil)).to eq(options)
      end
    end

    context "when log nil" do
      let(:user) { create(:user) }

      it "shows default options" do
        expect(question.displayed_answer_options(nil, user)).to eq(options)
      end
    end

    context "when user not support and owns own stock" do
      let(:user) { create(:user, :data_coordinator, organisation: create(:organisation, holds_own_stock: true)) }

      let(:log) { create(:lettings_log) }
      let!(:org_rel1) { create(:organisation_relationship, :managing, parent_organisation: user.organisation) }
      let!(:org_rel2) { create(:organisation_relationship, :managing, parent_organisation: user.organisation) }

      let(:options) do
        {
          "" => "Select an option",
          user.organisation.id => "#{user.organisation.name} (Your organisation)",
          org_rel1.child_organisation.id => org_rel1.child_organisation.name,
          org_rel2.child_organisation.id => org_rel2.child_organisation.name,
        }
      end

      it "shows managing agents with own org at the top" do
        expect(question.displayed_answer_options(log, user)).to eq(options)
      end
    end

    context "when support user and org does not own own stock" do
      let(:user) { create(:user, :support) }
      let(:log_owning_org) { create(:organisation, holds_own_stock: false) }
      let(:log) { create(:lettings_log, owning_organisation: log_owning_org) }
      let!(:org_rel1) { create(:organisation_relationship, :managing, parent_organisation: log_owning_org) }
      let!(:org_rel2) { create(:organisation_relationship, :managing, parent_organisation: log_owning_org) }

      let(:options) do
        {
          "" => "Select an option",
          org_rel1.child_organisation.id => org_rel1.child_organisation.name,
          org_rel2.child_organisation.id => org_rel2.child_organisation.name,
        }
      end

      it "shows owning org managing agents with hint" do
        expect(question.displayed_answer_options(log, user)).to eq(options)
      end
    end

    context "when support user and org does own stock" do
      let(:user) { create(:user, :support) }
      let(:log_owning_org) { create(:organisation, holds_own_stock: true) }
      let(:log) { create(:lettings_log, owning_organisation: log_owning_org) }
      let!(:org_rel1) { create(:organisation_relationship, :managing, parent_organisation: log_owning_org) }
      let!(:org_rel2) { create(:organisation_relationship, :managing, parent_organisation: log_owning_org) }

      let(:options) do
        {
          "" => "Select an option",
          log_owning_org.id => "#{log_owning_org.name} (Owning organisation)",
          org_rel1.child_organisation.id => org_rel1.child_organisation.name,
          org_rel2.child_organisation.id => org_rel2.child_organisation.name,
        }
      end

      it "shows owning org managing agents
      " do
        expect(question.displayed_answer_options(log, user)).to eq(options)
      end
    end
  end

  it "is marked as derived" do
    expect(question.derived?).to be true
  end

  describe "#hidden_in_check_answers?" do
    let(:user) { create(:user) }

    context "when managing agents >= 2" do
      it "is shown in check answers" do
        expect(question.hidden_in_check_answers?(nil, user)).to be true
      end
    end

    context "when managing agents < 2" do
      before do
        create(:organisation_relationship, :managing, parent_organisation: user.organisation)
        create(:organisation_relationship, :managing, parent_organisation: user.organisation)
      end

      it "is not shown in check answers" do
        expect(question.hidden_in_check_answers?(nil, user)).to be false
      end
    end
  end
end
