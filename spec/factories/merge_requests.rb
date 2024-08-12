FactoryBot.define do
  factory :merge_request do
    status { "Incomplete" }
    merge_date { nil }
    helpdesk_ticket { "MSD-99999" }
    association :requesting_organisation, factory: :organisation
  end
end
