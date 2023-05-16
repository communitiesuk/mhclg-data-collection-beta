module Forms
  module BulkUploadLettingsSoftValidationsCheck
    class Confirm
      include ActiveModel::Model
      include ActiveModel::Attributes
      include Rails.application.routes.url_helpers

      attribute :bulk_upload

      def view_path
        "bulk_upload_lettings_soft_validations_check/confirm"
      end

      def back_path
        page_bulk_upload_lettings_soft_validations_check_path(bulk_upload, page: "confirm-soft-errors")
      end

      def next_path
        lettings_logs_path
      end

      def save!
        processor = BulkUpload::Processor.new(bulk_upload:)
        processor.approve_and_confirm_soft_validations

        true
      end
    end
  end
end
