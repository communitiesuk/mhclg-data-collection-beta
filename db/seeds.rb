# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# rubocop:disable Rails/Output
org = Organisation.find_or_create_by!(
  name: "DLUHC",
  address_line1: "2 Marsham Street",
  address_line2: "London",
  postcode: "SW1P 4DF",
  holds_own_stock: false,
  other_stock_owners: "None",
  managing_agents: "None",
  provider_type: "LA",
) do
  info = "Seeded DLUHC Organisation"
  if Rails.env.development?
    pp info
  else
    Rails.logger.info info
  end
end

if Rails.env.development? && User.count.zero?
  User.create!(
    email: "provider@example.com",
    password: "password",
    organisation: org,
    role: "data_provider",
  )

  User.create!(
    email: "coordinator@example.com",
    password: "password",
    organisation: org,
    role: "data_coordinator",
  )

  User.create!(
    email: "support@example.com",
    password: "password",
    organisation: org,
    role: "support",
  )

  pp "Seeded 3 dummy users"
end

if LaRentRange.count.zero? && !Rails.env.test?
  Dir.glob("config/rent_range_data/*.csv").each do |path|
    start_year = File.basename(path, ".csv")
    Rake::Task["data_import:rent_ranges"].invoke(start_year, path)
  end
end
# rubocop:enable Rails/Output
