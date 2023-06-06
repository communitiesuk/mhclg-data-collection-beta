require "rails_helper"

RSpec.describe "organisations/data_sharing_agreement.html.erb", :aggregate_failures do
  before do
    Timecop.freeze(Time.zone.local(2023, 1, 10))
    allow(view).to receive(:current_user).and_return(user)
    assign(:organisation, organisation)
    assign(:data_sharing_agreement, data_sharing_agreement)
  end

  after do
    Timecop.return
  end

  let(:fragment) { Capybara::Node::Simple.new(rendered) }
  let(:organisation) { user.organisation }
  let(:data_sharing_agreement) { nil }

  context "when dpo" do
    let(:user) { create(:user, is_dpo: true) }

    it "renders dynamic content" do
      render
      # current date
      expect(fragment).to have_content("10th day of January 2023")
      # dpo name
      expect(fragment).to have_content("Name: #{user.name}")
      # org details
      expect(fragment).to have_content("#{organisation.name} of #{organisation.address_row} (“CORE Data Provider”)")
      # header
      expect(fragment).to have_css("h2", text: "#{organisation.name} and Department for Levelling Up, Housing and Communities")
      # action buttons
      expect(fragment).to have_button(text: "Accept this agreement")
      expect(fragment).to have_link(text: "Cancel", href: "/organisations/#{organisation.id}/details")
      # Shows DPO and org details in 12.2
      expect(fragment).to have_content("12.2. For #{organisation.name}: Name: #{user.name}, Postal Address: #{organisation.address_row}, E-mail address: #{user.email}, Telephone number: #{organisation.phone}")
    end

    context "when accepted" do
      let(:data_sharing_agreement) do
        create(
          :data_sharing_agreement,
          organisation:,
          signed_at: Time.zone.now - 1.day,
        )
      end

      it "renders dynamic content" do
        render

        # dpo name
        expect(fragment).to have_content("Name: #{data_sharing_agreement.dpo_name}")

        # org details
        expect(fragment).to have_content("#{data_sharing_agreement.organisation_name} of #{data_sharing_agreement.organisation_address} (“CORE Data Provider”)")
        # header
        expect(fragment).to have_css("h2", text: "#{data_sharing_agreement.organisation_name} and Department for Levelling Up, Housing and Communities")
        # does not show action buttons
        expect(fragment).not_to have_button(text: "Accept this agreement")
        expect(fragment).not_to have_link(text: "Cancel", href: "/organisations/#{organisation.id}/details")
        # sees signed_at date
        expect(fragment).to have_content("9th day of January 2023")
        # Shows DPO and org details in 12.2
        expect(fragment).to have_content("12.2. For #{data_sharing_agreement.organisation_name}: Name: #{data_sharing_agreement.dpo_name}, Postal Address: #{data_sharing_agreement.organisation_address}, E-mail address: #{data_sharing_agreement.dpo_email}, Telephone number: #{data_sharing_agreement.organisation_phone_number}")
      end
    end
  end

  context "when not dpo" do
    let(:user) { create(:user) }

    it "renders dynamic content" do
      render
      # placeholder date
      expect(fragment).to have_content("This agreement is made the [XX] day of [XX] 20[XX]")
      # dpo name placedholder
      expect(fragment).to have_content("Name: [DPO name]")
      # org details
      expect(fragment).to have_content("#{organisation.name} of #{organisation.address_row} (“CORE Data Provider”)")
      # header
      expect(fragment).to have_css("h2", text: "#{organisation.name} and Department for Levelling Up, Housing and Communities")
      # does not show action buttons
      expect(fragment).not_to have_button(text: "Accept this agreement")
      expect(fragment).not_to have_link(text: "Cancel", href: "/organisations/#{organisation.id}/details")
      # Shows placeholder details in 12.2
      expect(fragment).to have_content("12.2. For #{organisation.name}: Name: [DPO name], Postal Address: #{organisation.address_row}, E-mail address: [DPO email], Telephone number: #{organisation.phone}")
    end

    context "when accepted" do
      let(:data_sharing_agreement) do
        create(
          :data_sharing_agreement,
          organisation:,
          signed_at: Time.zone.now - 1.day,
        )
      end

      it "renders dynamic content" do
        render
        # sees signed_at date
        expect(fragment).to have_content("9th day of January 2023")
        # dpo name placedholder
        expect(fragment).to have_content("Name: #{data_sharing_agreement.dpo_name}")
        # org details
        expect(fragment).to have_content("#{data_sharing_agreement.organisation_name} of #{data_sharing_agreement.organisation_address} (“CORE Data Provider”)")
        # header
        expect(fragment).to have_css("h2", text: "#{data_sharing_agreement.organisation_name} and Department for Levelling Up, Housing and Communities")
        # does not show action buttons
        expect(fragment).not_to have_button(text: "Accept this agreement")
        expect(fragment).not_to have_link(text: "Cancel", href: "/organisations/#{organisation.id}/details")
        # Shows filled in details in 12.2
        expect(fragment).to have_content("12.2. For #{data_sharing_agreement.organisation_name}: Name: #{data_sharing_agreement.dpo_name}, Postal Address: #{data_sharing_agreement.organisation_address}, E-mail address: #{data_sharing_agreement.dpo_email}, Telephone number: #{data_sharing_agreement.organisation_phone_number}")
      end
    end
  end
end
