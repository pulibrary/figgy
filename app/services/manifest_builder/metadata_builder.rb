# frozen_string_literal: true
class ManifestBuilder
  class MetadataBuilder
    attr_reader :resource

    ##
    # @param [Valhalla::Resource] resource the Resource being viewed
    def initialize(resource, metadata_object_class: MetadataObject)
      @resource = RootNode.new(resource)
      @metadata_object_class = metadata_object_class
    end

    ##
    # Append the metadata to the IIIF Manifest
    # @param [IIIF::Presentation::Manifest] manifest the IIIF manifest being
    # @return [IIIF::Presentation::Manifest]
    def apply(manifest)
      manifest.metadata = transformed_metadata
      manifest
    end

    class MetadataObject
      def initialize(attribute, value)
        @attribute = attribute
        @value = value
      end

      def pdf_type_label
        'PDF Type'
      end

      def label
        if respond_to?("#{@attribute}_label".to_sym)
          send("#{@attribute}_label".to_sym)
        else
          @attribute.to_s.titleize
        end
      end

      def date_value
        @value.map do |date|
          date.split("/").map do |d|
            if year_only(date.split("/"))
              Date.parse(d).strftime("%Y")
            else
              Date.parse(d).strftime("%m/%d/%Y")
            end
          end.join("-")
        end
      rescue => e
        Rails.logger.warn e.message
        @value
      end

      alias created_value date_value
      alias imported_created_value created_value
      alias updated_value date_value
      alias imported_updated_value updated_value
      private :date_value

      def identifier_value
        @value.map do |id|
          if id =~ /^https?\:\/\//
            "<a href='#{id}' alt='#{label}'>#{id}</a>"
          else
            id
          end
        end
      end

      alias imported_identifier_value identifier_value

      def value
        Array.wrap(
          if respond_to?("#{@attribute}_value".to_sym)
            send("#{@attribute}_value".to_sym)
          else
            @value
          end
        )
      end

      def to_h
        { label: label, value: value }
      end

      private

        def year_only(dates)
          dates.length == 2 && dates.first.end_with?("-01-01T00:00:00Z") && dates.last.end_with?("-12-31T23:59:59Z")
        end
    end

    private

      def transformed_metadata
        @resource.decorate.iiif_manifest_attributes.select { |_, value| value.present? }.map do |u, v|
          @metadata_object_class.new(u, v).to_h
        end
      end
  end
end
