FactoryBot.define do
  factory :organisation do
    name { "DLUHC" }
    address_line1 { "2 Marsham Street" }
    address_line2 { "London" }
    provider_type { "LA" }
    housing_registration_no { "1234" }
    postcode { "SW1P 4DF" }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
    holds_own_stock { true }

    transient do
      with_dsa { true }
    end

    after(:create) do |org, evaluator|
      if evaluator.with_dsa
        create(
          :data_protection_confirmation,
          organisation: org,
          data_protection_officer: org.users.any? ? org.users.first : create(:user, :data_protection_officer, organisation: org),
        )
      end
    end

    trait :with_old_visible_id do
      old_visible_id { rand(9_999_999).to_s }
    end

    trait :prp do
      provider_type { "PRP" }
    end

    trait :does_not_own_stock do
      holds_own_stock { false }
    end

    trait :without_dpc do
      transient do
        with_dsa { false }
      end

      data_protection_confirmation { nil }
    end
  end

  factory :organisation_rent_period do
    organisation
    rent_period { 2 }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
  end
end
