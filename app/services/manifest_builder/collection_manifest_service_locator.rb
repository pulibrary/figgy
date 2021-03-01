# frozen_string_literal: true
class ManifestBuilder
  # Collections have fewer builders (notably the thumbnail builder) to improve
  # performance.
  class CollectionManifestServiceLocator < ManifestBuilder::ManifestServiceLocator
    class << self
      # Builder for a manifest which is a sub-item in a collection.
      # @note This is the same as in ManifestServiceLocator, but there's no
      #   thumbnail builder, to improve render time.
      def real_child_manifest_builder
        IIIFManifest::ManifestServiceLocator::InjectedFactory.new(
          IIIFManifest::ManifestBuilder,
          builders:
          composite_builder_factory.new(
            child_record_property_builder,
            composite_builder: composite_builder
          ),
          top_record_factory: iiif_manifest_factory
        )
      end
    end
  end
end
