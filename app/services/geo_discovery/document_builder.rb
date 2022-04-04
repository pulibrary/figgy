# frozen_string_literal: true
module GeoDiscovery
  class DocumentBuilder
    class_attribute :services, :root_path_class

    # Array of document builder services.
    # - BasicMetadataBuilder: builds fields such as id, subject, and publisher.
    # - SpatialBuilder: builds spatial fields such as bounding box and solr geometry.
    # - DateBuilder: builds date fields such as layer year and modified date.
    # - ReferencesBuilder: builds service reference fields such as thumbnail and download url.
    # - LayerInfoBuilder: builds fields about the geospatial file such as geometry and format.
    # - SlugBuilder: builds the Geoblacklight slug field.
    # - IIIFBuilder: builds the iiif manifest url for references.
    # - RelationshipBuilder: builds fields concerning parent child relationships between docs.
    self.services = [
      BasicMetadataBuilder,
      SpatialBuilder,
      DateBuilder,
      ReferencesBuilder,
      LayerInfoBuilder,
      SlugBuilder,
      IIIFBuilder,
      RelationshipBuilder,
      RightsBuilder
    ]

    # Class used to generate urls for links in the document.
    self.root_path_class = DocumentPath

    def initialize(record, document)
      @resource_decorator = GeoblacklightMetadataDecorator.new(record.decorate)
      @document = document
      builders.build(document)
    end

    attr_reader :resource_decorator, :document
    delegate :to_json, :to_xml, :to_hash, to: :document

    private

      # Instantiates a CompositeBuilder object with an array of
      # builder instances that are used to create the document.
      # @return [CompositeBuilder] composite builder for document
      def builders
        @builders ||= CompositeBuilder.new(
          services.map { |service| service.new(resource_decorator) }
        )
      end
  end
end
