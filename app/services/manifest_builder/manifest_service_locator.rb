# frozen_string_literal: true
class ManifestBuilder
  ##
  # Class for the IIIF Manifest Service Locator
  class ManifestServiceLocator < IIIFManifest::ManifestServiceLocator
    class << self
      ##
      # Override the Class method for instantiating a CompositeBuilder
      # Insert see_also_builder, license_builder, thumbnail_builder, rendering_builder
      # @return [IIIFManifest::ManifestBuilder::CompositeBuilder]
      def manifest_builders
        composite_builder_factory.new(
          record_property_builder,
          sequence_builder,
          structure_builder,
          see_also_builder,
          license_builder,
          thumbnail_builder,
          rendering_builder,
          logo_builder,
          iiif_search_builder,
          media_sequence_builder,
          composite_builder: composite_builder
        )
      end

      # Provides the builders injected into the factory for manifests of collections
      # @see IIIFManifest::ManifestServiceLocator#collection_manifest_builder
      # @return [IIIFManifest::ManifestBuilder::CompositeBuilderFactory] the factory of multiple builders
      def collection_manifest_builders
        composite_builder_factory.new(
          record_property_builder,
          child_manifest_builder_factory,
          see_also_builder,
          license_builder,
          thumbnail_builder,
          rendering_builder,
          composite_builder: composite_builder
        )
      end

      # Provides the builders injected into the factory for manifests of sammelbands
      # @see IIIFManifest::ManifestServiceLocator#sammelband_manifest_builders
      # @return [IIIFManifest::ManifestBuilder::CompositeBuilderFactory] the factory of multiple builders
      def sammelband_manifest_builders
        composite_builder_factory.new(
          record_property_builder,
          sammelband_sequence_builder,
          structure_builder,
          see_also_builder,
          license_builder,
          thumbnail_builder,
          rendering_builder,
          composite_builder: composite_builder
        )
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
      # Class accessor for the rendering builder
      # @return [Class]
      def rendering_builder
        ManifestBuilder::RenderingBuilder
      end

      ##
      # Class accessor for the logo builder
      # @return [Class]
      def logo_builder
        ManifestBuilder::LogoBuilder
      end

      def iiif_search_builder
        ManifestBuilder::IiifSearchBuilder
      end

      def media_sequence_builder
        ManifestBuilder::MediaSequenceBuilder
      end

      ##
      # Overridden to support setting viewing_direction.
      def record_property_builder
        IIIFManifest::ManifestServiceLocator::InjectedFactory.new(
          ManifestBuilder::RecordPropertyBuilder,
          iiif_search_service_factory: IIIFManifest::ManifestBuilder::IIIFManifest::SearchService,
          iiif_autocomplete_service_factory: IIIFManifest::ManifestBuilder::IIIFManifest::AutocompleteService
        )
      end

      def start_canvas_builder
        IIIFManifest::ManifestServiceLocator::InjectedFactory.new(
          ::ManifestBuilder::StartCanvasBuilder,
          canvas_builder: canvas_builder
        )
      end

      ##
      # Objects are either in 'manifests' or 'collections' depending on if the
      # child resource is a IIIF::Manifest or a IIIF::Collection. This special
      # class will pick the builder which puts it in the right place. Replace
      # when we put everything in `members` per IIIF 2.1.
      def child_manifest_builder
        ConditionalCollectionManifest.new(manifest_builder: real_child_manifest_builder, collection_builder: child_collection_builder)
      end

      ##
      # Builder to add thumbnails to manifests.
      def thumbnail_builder
        ::ManifestBuilder::ThumbnailBuilder
      end

      ##
      # Overridden to allow adding local_identifier to canvas.
      def canvas_builder
        IIIFManifest::ManifestServiceLocator::InjectedFactory.new(
          ::ManifestBuilder::CanvasBuilder,
          iiif_canvas_factory: iiif_canvas_factory,
          image_builder: image_builder
        )
      end

      def image_builder
        IIIFManifest::ManifestServiceLocator::InjectedFactory.new(
          ::ManifestBuilder::ImageBuilder,
          iiif_annotation_factory: iiif_annotation_factory,
          resource_builder_factory: resource_builder_factory
        )
      end

      ##
      # Override sequence builder to support adding viewingHint.
      def sequence_builder
        IIIFManifest::ManifestServiceLocator::InjectedFactory.new(
          ::ManifestBuilder::SequenceBuilder, # This whole method is overridden just for this constant.
          canvas_builder_factory: canvas_builder_factory,
          sequence_factory: sequence_factory,
          start_canvas_builder: start_canvas_builder
        )
      end

      ##
      # Builder for a manifest which is a sub-item in a collection.
      def real_child_manifest_builder
        IIIFManifest::ManifestServiceLocator::InjectedFactory.new(
          IIIFManifest::ManifestBuilder,
          builders:
          composite_builder_factory.new(
            child_record_property_builder,
            thumbnail_builder,
            composite_builder: composite_builder
          ),
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
            see_also_builder,
            license_builder,
            rendering_builder,
            composite_builder: composite_builder
          ),
          top_record_factory: iiif_collection_factory
        )
      end

      class CollectionManifestBuilder < IIIFManifest::ManifestBuilder
        def apply(collection)
          collection["collections"] ||= []
          collection["collections"] << to_h
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
    end
  end
end
