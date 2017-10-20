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

      def child_manifest_builder
        ConditionalCollectionManifest.new(manifest_builder: real_child_manifest_builder, collection_builder: child_collection_builder)
      end

      ##
      # Builder for a manifest which is a sub-item in a collection.
      def real_child_manifest_builder
        IIIFManifest::ManifestServiceLocator::InjectedFactory.new(
          IIIFManifest::ManifestBuilder,
          builders: child_record_property_builder,
          top_record_factory: iiif_manifest_factory
        )
      end

      ##
      # Builder for record properties to be applied when rendering as a
      # "manifest" sub-item in a collection.
      def child_record_property_builder
        ManifestBuilder::ChildRecordPropertyBuilder
      end

      ##
      # Builder for collections which are sub-collections.
      def child_collection_builder
        IIIFManifest::ManifestServiceLocator::InjectedFactory.new(
          CollectionManifestBuilder,
          builders:
          composite_builder_factory.new(
            record_property_builder,
            metadata_manifest_builder,
            see_also_builder,
            composite_builder: composite_builder
          ),
          top_record_factory: iiif_collection_factory
        )
      end

      # Provides the builders injected into the factory for manifests of collections
      # @see IIIFManifest::ManifestServiceLocator#collection_manifest_builder
      # @return [IIIFManifest::ManifestBuilder::CompositeBuilderFactory] the factory of multiple builders
      def collection_manifest_builders
        composite_builder_factory.new(
          record_property_builder,
          child_manifest_builder_factory,
          metadata_manifest_builder,
          see_also_builder,
          composite_builder: composite_builder
        )
      end

      class CollectionManifestBuilder < IIIFManifest::ManifestBuilder
        def apply(collection)
          collection['collections'] ||= []
          collection['collections'] << to_h
          collection
        end
      end

      class ConditionalCollectionManifest
        attr_reader :manifest_builder, :collection_builder
        def initialize(manifest_builder:, collection_builder:)
          @manifest_builder = manifest_builder
          @collection_builder = collection_builder
        end

        def new(work)
          if work.is_a?(ManifestBuilder::CollectionNode)
            collection_builder.new(work)
          else
            manifest_builder.new(work)
          end
        end
      end

      def iiif_manifest_factory
        ::ManifestBuilder::FasterIIIFManifest
      end

      def iiif_service_factory
        ::ManifestBuilder::Service
      end

      def sequence_factory
        ::ManifestBuilder::FasterIIIFManifest::Sequence
      end

      def iiif_canvas_factory
        ::ManifestBuilder::FasterIIIFManifest::Canvas
      end

      def iiif_annotation_factory
        ::ManifestBuilder::FasterIIIFManifest::Annotation
      end

      def iiif_resource_factory
        ::ManifestBuilder::FasterIIIFManifest::Resource
      end

      def iiif_range_factory
        ::ManifestBuilder::FasterIIIFManifest::Range
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
