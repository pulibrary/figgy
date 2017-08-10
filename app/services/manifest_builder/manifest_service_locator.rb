# frozen_string_literal: true
class ManifestBuilder
  ##
  # Class for the IIIF Manifest Service Locator
  class ManifestServiceLocator < IIIFManifest::ManifestServiceLocator
    class << self
      ##
      # Class accessor for the metadata builder
      # @return [Class]
      def metadata_manifest_builder
        ManifestBuilder::MetadataBuilder
      end

      ##
      # Class accessor for the "see also" builder
      # @return [Class]
      def see_also_builder
        ManifestBuilder::SeeAlsoBuilder
      end

      ##
      # Class accessor for the license builder
      # @return [Class]
      def license_builder
        ManifestBuilder::LicenseBuilder
      end

      ##
      # Override the Class method for instantiating a CompositeBuilder
      # Insert the metadata manifest builder
      # @return [IIIFManifest::ManifestBuilder::CompositeBuilder]
      def manifest_builders
        composite_builder_factory.new(
          record_property_builder,
          sequence_builder,
          structure_builder,
          metadata_manifest_builder,
          see_also_builder,
          license_builder,
          composite_builder: composite_builder
        )
      end
    end
  end
end
