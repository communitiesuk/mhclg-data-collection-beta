FactoryBot.define do
  factory :scheme do
    code { Faker::Name.initials(number: 4) }
    service_name { Faker::Name.name_with_middle }
    sensitive { Faker::Number.within(range: 0..1) }
    registered_under_care_act { Faker::Number.within(range: 0..1) }
    support_type { Faker::Number.within(range: 0..6) }
    scheme_type { 0 }
    total_units { Faker::Number.number(digits: 2) }
    intended_stay { %w[M P S V X].sample }
    primary_client_group { %w[O H M L A G F B D E I S N R Q P X].sample }
    secondary_client_group { %w[O H M L A G F B D E I S N R Q P X].sample }
    organisation
    created_at { Time.zone.now }
  end
end
