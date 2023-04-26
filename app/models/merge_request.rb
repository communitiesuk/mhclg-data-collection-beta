class MergeRequest < ApplicationRecord
  belongs_to :requesting_organisation, class_name: "Organisation"
  has_many :merge_request_organisations
  belongs_to :absorbing_organisation, class_name: "Organisation", optional: true
  has_many :merging_organisations, through: :merge_request_organisations, source: :merging_organisation

  STATUS = {
    "unsubmitted" => 0,
    "submitted" => 1,
  }.freeze
  enum status: STATUS
end
