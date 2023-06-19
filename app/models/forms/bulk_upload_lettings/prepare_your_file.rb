module Forms
  module BulkUploadLettings
    class PrepareYourFile
      include ActiveModel::Model
      include ActiveModel::Attributes
      include Rails.application.routes.url_helpers

      attribute :year, :integer
      attribute :needstype, :integer

      def view_path
        case year
        when 2022
          "bulk_upload_lettings_logs/forms/prepare_your_file_2022"
        else
          "bulk_upload_lettings_logs/forms/prepare_your_file_2023"
        end
      end

      def back_path
        if in_crossover_period?
          Rails.application.routes.url_helpers.bulk_upload_lettings_log_path(id: "year", form: { year: })
        else
          Rails.application.routes.url_helpers.lettings_logs_path
        end
      end

      def next_path
        page_id = year == 2022 ? "needstype" : "upload-your-file"
        bulk_upload_lettings_log_path(id: page_id, form: { year:, needstype: })
      end

      def legacy_template_path
        case year
        when 2022
          "/files/bulk-upload-lettings-template-2022-23.xlsx"
        else
          "/files/bulk-upload-lettings-legacy-template-2023-24.xlsx"
        end
      end

      def template_path
        case year
        when 2022
          "/files/bulk-upload-lettings-template-2022-23.xlsx"
        else
          "/files/bulk-upload-lettings-template-2023-24.xlsx"
        end
      end

      def specification_path
        case year
        when 2022
          "/files/bulk-upload-lettings-specification-2022-23.xlsx"
        else
          "/files/bulk-upload-lettings-specification-2023-24.xlsx"
        end
      end

      def year_combo
        "#{year}/#{year + 1 - 2000}"
      end

      def save!
        true
      end

    private

      def in_crossover_period?
        return true if FeatureToggle.force_crossover?

        FormHandler.instance.lettings_in_crossover_period?
      end
    end
  end
end
