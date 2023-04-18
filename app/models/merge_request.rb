class MergeRequest < ApplicationRecord
  belongs_to :requesting_organisation, class_name: "Organisation"
  has_many :merge_request_organisations
  has_many :merging_organisations, through: :merge_request_organisations, source: :merging_organisation
  scope :unsubmitted, -> { where.not(status: "unsubmitted") }

  STATUS = {
    "unsubmitted" => 0,
    "submitted" => 1,
  }.freeze
  enum status: STATUS
end
