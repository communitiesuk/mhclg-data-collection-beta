module Forms
  module BulkUploadForm
    class PrepareYourFile
      include ActiveModel::Model
      include ActiveModel::Attributes
      include Rails.application.routes.url_helpers

      attribute :log_type
      attribute :year, :integer
      attribute :organisation_id, :integer

      def view_path
        case year
        when 2024
          "bulk_upload_#{log_type}_logs/forms/prepare_your_file_2024"
        when 2025
          "bulk_upload_#{log_type}_logs/forms/prepare_your_file_2025"
        end
      end

      def back_path
        if have_choice_of_year?
          Rails.application.routes.url_helpers.send("bulk_upload_#{log_type}_log_path", id: "year", form: { year: }.compact)
        elsif organisation_id.present?
          send("#{log_type}_logs_organisation_path", organisation_id)
        else
          Rails.application.routes.url_helpers.send("#{log_type}_logs_path")
        end
      end

      def next_path
        send("bulk_upload_#{log_type}_log_path", id: "upload-your-file", form: { year:, organisation_id: }.compact)
      end

      def template_path
        download_mandatory_collection_resource_path(year:, log_type:, resource_type: "bulk_upload_template")
      end

      def specification_path
        download_mandatory_collection_resource_path(year:, log_type:, resource_type: "bulk_upload_specification")
      end

      def year_combo
        "#{year} to #{year + 1}"
      end

      def save!
        true
      end

    private

      def have_choice_of_year?
        return true if FeatureToggle.allow_future_form_use?

        FormHandler.instance.send("#{log_type}_in_crossover_period?")
      end
    end
  end
end
