require "rails_helper"
RSpec.describe "User Features" do
  let!(:user) { FactoryBot.create(:user) }
  context "A user navigating to case logs" do
    it " is required to log in" do
      visit("/case_logs")
      expect(page).to have_current_path("/users/sign_in")
    end

    it " is redirected to case logs after signing in" do
      visit("/case_logs")
      fill_in("user_email", with: user.email)
      fill_in("user_password", with: "pAssword1")
      click_button("Sign in")
      expect(page).to have_current_path("/case_logs")
    end
  end

  context "A user who has forgotten their password" do
    it " is redirected to the reset password page when they click the reset password link" do
      visit("/case_logs")
      click_link("reset your password")
      expect(page).to have_current_path("/users/password/new")
    end

    it " is redirected to check your email page after submitting an email on the reset password page" do
      visit("/users/password/new")
      fill_in("user_email", with: user.email)
      click_button("Send email")
      expect(page).to have_content("Check your email")
    end

    it " is shown their email on the password reset confirmation page" do
      visit("/users/password/new")
      fill_in("user_email", with: user.email)
      click_button("Send email")
      expect(page).to have_content(user.email)
    end

    it " is shown the reset password confirmation page even if their email doesn't exist in the system" do
      visit("/users/password/new")
      fill_in("user_email", with: "idontexist@example.com")
      click_button("Send email")
      expect(page).to have_current_path("/confirmations/reset?email=idontexist%40example.com")
    end

    it " is sent a reset password email" do
      visit("/users/password/new")
      fill_in("user_email", with: user.email)
      expect { click_button("Send email") }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end
end
