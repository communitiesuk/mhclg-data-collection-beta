FactoryBot.define do
  factory :user do
    sequence(:email) { "test#{SecureRandom.hex}@example.com" }
    name { "Danny Rojas" }
    password { "pAssword1" }
    organisation { association :organisation, with_dsa: is_dpo ? false : true }
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

    after(:create) do |user, _evaluator|
      unless user.organisation.data_protection_confirmed?
        create(
          :data_protection_confirmation,
          organisation: user.organisation,
          data_protection_officer: user,
        )
      end
    end
  end
end
