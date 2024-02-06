module Forms
  module BulkUploadSales
    class PrepareYourFile
      include ActiveModel::Model
      include ActiveModel::Attributes
      include Rails.application.routes.url_helpers

      attribute :year, :integer

      def view_path
        case year
        when 2023
          "bulk_upload_sales_logs/forms/prepare_your_file_2023"
        when 2024
          "bulk_upload_sales_logs/forms/prepare_your_file_2024"
        end
      end

      def back_path
        if in_crossover_period?
          Rails.application.routes.url_helpers.bulk_upload_sales_log_path(id: "year", form: { year: })
        else
          Rails.application.routes.url_helpers.sales_logs_path
        end
      end

      def next_path
        bulk_upload_sales_log_path(id: "upload-your-file", form: { year: })
      end

      def legacy_template_path
        case year
        when 2023
          "/files/bulk-upload-sales-legacy-template-2023-24.xlsx"
        when 2024
          "/files/bulk-upload-sales-legacy-template-2024-25.xlsx"
        end
      end

      def template_path
        case year
        when 2023
          "/files/bulk-upload-sales-template-2023-24.xlsx"
        when 2024
          "/files/bulk-upload-sales-template-2024-25.xlsx"
        end
      end

      def specification_path
        case year
        when 2023
          "/files/bulk-upload-sales-specification-2023-24.xlsx"
        when 2024
          "/files/bulk-upload-sales-specification-2024-25.xlsx"
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

        FormHandler.instance.sales_in_crossover_period?
      end
    end
  end
end
