Given("there are multiple users in the same organization") do
  @users = create_list :user, 5, organisation: @user.organisation
end

Given("I visit the users page") do
  click_link("Users")
end

Then("I see information about those users") do
  @users.each do |user|
    expect(page.body).to have_content user.name
    expect(page.body).to have_content user.email
  end
end

Then("the user navigation bar is highlighted") do
  expect(page).to have_css('[aria-current="page"]', text: "Users")
end

When("I visit the About your organisation page") do
  click_link("About your organisation")
end

Then("I see information about your organisation") do
  expect(page.body).to have_content @user.organisation.name
  expect(page.body).to have_content @user.organisation.address_line1
  expect(page.body).to have_content @user.organisation.postcode
end

Then("the about your organisation navigation bar is highlighted") do
  expect(page).to have_css('[aria-current="page"]', text: "About your organisation")
end

When("I visit the your account page") do
  click_link("Your account")
end

When("I visit the about your organisation page") do
  click_link("About your organisation")
end

Then("I see information about my account") do
  expect(page.body).to have_content @user.name
  expect(page.body).to have_content @user.email
  expect(page.body).to have_content @user.organisation.name
end

Then("the no links in navigation bar are highlighted") do
  expect(page).not_to have_css('[aria-current="page"]', text: "Users")
  expect(page).not_to have_css('[aria-current="page"]', text: "About your organisation")
end

When("I click to change my password") do
  find('[data-qa="change-password"]').click
end

When("I fill in new password and confirmation") do
  fill_in("user[password]", with: "Password123!")
  fill_in("user[password_confirmation]", with: "Password123!")
end

When("I click to update my password") do
  click_button("Update")
end

Then("my password should be updated") do
  expect(page).to have_current_path("/account")
  expect(User.find(@user.id).valid_password?("Password123!")).to be true
end
