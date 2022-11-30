module SchemesHelpers
  def fill_in_number_question(lettings_log_id, question, value, path)
    visit("/lettings-logs/#{lettings_log_id}/#{path}")
    fill_in("lettings-log-#{question.to_s.dasherize}-field", with: value)
    click_button("Save and continue")
  end

  def answer_all_questions_in_income_subsection(lettings_log)
    visit("/lettings-logs/#{lettings_log.id}/net-income")
    fill_in("lettings-log-earnings-field", with: 18_000)
    choose("lettings-log-incfreq-2-field")
    click_button("Save and continue")
    choose("lettings-log-benefits-0-field")
    click_button("Save and continue")
    choose("lettings-log-hb-1-field")
    click_button("Save and continue")
  end

  def sign_in(user)
    visit("/lettings-logs")
    fill_in("user[email]", with: user.email)
    fill_in("user[password]", with: user.password)
    click_button("Sign in")
  end

  def fill_in_and_save_scheme_details(answers = {})
    fill_in "Scheme name", with: "FooBar"
    check "This scheme contains confidential information"
    choose "Direct access hostel"
    choose "Yes – registered care home providing nursing care"
    select organisation_name, from: "scheme-owning-organisation-id-field"
    choose answers["housing_stock_owners"].presence || "The same organisation that owns the housing stock"
    click_button "Save and continue"
  end

  def fill_in_and_save_primary_client_group
    choose "Homeless families with support needs"
    click_button "Save and continue"
  end

  def fill_in_and_save_secondary_client_group_confirmation
    choose "Yes"
    click_button "Save and continue"
  end

  def fill_in_and_save_secondary_client_group
    choose "Offenders and people at risk of offending"
    click_button "Save and continue"
  end

  def fill_in_and_save_support
    choose "Low level"
    choose "Very short stay"
    click_button "Save and continue"
  end

  def fill_in_and_save_location
    fill_in_and_save_postcode
    fill_in_and_save_local_authority
    fill_in_and_save_name
    fill_in_and_save_units
    fill_in_and_save_type_of_unit
    fill_in_and_save_mobility_standards
    fill_in_and_save_availability
  end

  def fill_in_and_save_postcode
    fill_in with: "AA11AA"
    click_button "Save and continue"
  end

  def fill_in_and_save_local_authority
    fill_in with: "Adur"
  end

  def fill_in_and_save_name
    fill_in with: "Some name"
    click_button "Save and continue"
  end

  def fill_in_and_save_units
    fill_in with: 5
    click_button "Save and continue"
  end

  def fill_in_and_save_type_of_unit
    choose "Self-contained house"
    click_button "Save and continue"
  end

  def fill_in_and_save_mobility_standards
    choose "location-mobility-type-none-field"
    click_button "Save and continue"
  end

  def fill_in_and_save_availability
    fill_in "Day", with: 2
    fill_in "Month", with: 2
    fill_in "Year", with: 2022
    click_button "Save and continue"
  end

  def fill_in_and_save_second_location
    fill_in "Postcode", with: "AA12AA"
    fill_in "Location name (optional)", with: "Other name"
    fill_in "Total number of units at this location", with: 2
    choose "Self-contained house"
    choose "location-add-another-location-no-field"
    choose "location-mobility-type-none-field"
    click_button "Save and continue"
  end

  def create_and_save_a_scheme
    fill_in_and_save_scheme_details
    fill_in_and_save_primary_client_group
    fill_in_and_save_secondary_client_group_confirmation
    fill_in_and_save_secondary_client_group
    fill_in_and_save_support
  end
end
