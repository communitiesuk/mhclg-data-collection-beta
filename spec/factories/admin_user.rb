FactoryBot.define do
  factory :admin_user do
    sequence(:email) { |i| "admin#{i}@example.com" }
    password { "pAssword1" }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
  end
end
