module Imports
  class ImportService
    attr_accessor :allow_updates

  private

    def initialize(storage_service, logger = Rails.logger, allow_updates: false)
      @storage_service = storage_service
      @logger = logger
      @logs_with_discrepancies = []
      @allow_updates = allow_updates
    end

    def import_from(folder, create_method)
      filenames = @storage_service.list_files(folder)
      filenames.each do |filename|
        file_io = @storage_service.get_file_io(filename)
        xml_document = Nokogiri::XML(file_io)
        send(create_method, xml_document)
      rescue StandardError => e
        @logger.error "#{e.class} in #{filename}: #{e.message}. Caller: #{e.backtrace.first}"
      end
    end

    def field_value(xml_document, namespace, field, *args)
      xml_document.at_xpath("//#{namespace}:#{field}", *args)&.text
    end

    def meta_field_value(xml_document, field)
      field_value(xml_document, "meta", field, { "meta" => "http://data.gov.uk/core/metadata" })
    end

    def overridden?(xml_document, namespace, field)
      xml_document.at_xpath("//#{namespace}:#{field}").attributes["override-field"].value
    end

    def to_boolean(input_string)
      input_string == "true"
    end
  end
end
