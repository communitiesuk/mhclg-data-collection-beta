require "securerandom"

FactoryBot.define do
  include CollectionTimeHelper

  factory :bulk_upload do
    user
    log_type { BulkUpload.log_types.values.sample }
    year { current_collection_start_year }
    identifier { SecureRandom.uuid }
    sequence(:filename) { |n| "bulk-upload-#{n}.csv" }
    needstype { 1 }
    noint_fix_status { BulkUpload.noint_fix_statuses.values.sample }

    trait(:sales) do
      log_type { BulkUpload.log_types[:sales] }
    end

    trait(:lettings) do
      log_type { BulkUpload.log_types[:lettings] }
    end
  end
end
