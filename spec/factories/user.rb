FactoryBot.define do
  factory :user do
    sequence(:email) { "test#{SecureRandom.hex}@example.com" }
    name { "Danny Rojas" }
    password { "pAssword1" }
    organisation { association :organisation }
    role { "data_provider" }
    phone { "1234512345123" }
    trait :data_provider do
      role { "data_provider" }
    end
    trait :data_coordinator do
      role { "data_coordinator" }
    end
    trait :data_protection_officer do
      is_dpo { true }
    end
    trait :support do
      role { "support" }
    end
    sign_in_count { 5 }
    confirmed_at { Time.zone.now }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }

    transient do
      old_user_id { SecureRandom.uuid }
    end

    after(:create) do |user, evaluator|
      FactoryBot.create(:legacy_user, old_user_id: evaluator.old_user_id, user:)

      user.reload
    end
  end
end
