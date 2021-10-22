# frozen_string_literal: true
class ManifestBuilderV3
  ##
  # Class for the IIIF Manifest Service Locator
  class ManifestServiceLocator < IIIFManifest::V3::ManifestServiceLocator
    class << self
      ##
      # Override the Class method for instantiating a CompositeBuilder
      # Insert see_also_builder, license_builder, thumbnail_builder, rendering_builder
      # @return [IIIFManifest::ManifestBuilder::CompositeBuilder]
      def manifest_builders
        composite_builder_factory.new(
          record_property_builder,
          structure_builder,
          see_also_builder,
          rights_builder,
          logo_builder,
          thumbnail_builder,
          rendering_builder,
          iiif_search_builder,
          nav_place_builder,
          composite_builder: composite_builder
        )
      end

      def structure_builder
        IIIFManifest::ManifestServiceLocator::InjectedFactory.new(
          ManifestBuilderV3::StructureBuilder,
          canvas_builder_factory: canvas_builder,
          iiif_range_factory: iiif_range_factory
        )
      end

      ##
      # Class accessor for the "see also" builder
      # @return [Class]
      def see_also_builder
        ManifestBuilderV3::SeeAlsoBuilder
      end

      ##
      # Class accessor for the rights builder
      # @return [Class]
      def rights_builder
        ManifestBuilderV3::RightsBuilder
      end

      ##
      # Class accessor for the logo builder
      # @return [Class]
      def logo_builder
        ManifestBuilder::LogoBuilder
      end

      ##
      # Overridden to support setting viewing_direction.
      def record_property_builder
        IIIFManifest::ManifestServiceLocator::InjectedFactory.new(
          ManifestBuilderV3::RecordPropertyBuilder,
          iiif_search_service_factory: IIIFManifest::ManifestBuilder::IIIFManifest::SearchService,
          iiif_autocomplete_service_factory: IIIFManifest::ManifestBuilder::IIIFManifest::AutocompleteService,
          canvas_builder_factory: canvas_builder_factory
        )
      end

      ##
      # Overridden to allow adding local_identifier to canvas.
      def canvas_builder
        IIIFManifest::ManifestServiceLocator::InjectedFactory.new(
          ::ManifestBuilderV3::CanvasBuilder,
          iiif_canvas_factory: iiif_canvas_factory,
          content_builder: content_builder,
          choice_builder: choice_builder,
          iiif_annotation_page_factory: iiif_annotation_page_factory
        )
      end

      ##
      # Builder to add thumbnails to manifests.
      def thumbnail_builder
        ::ManifestBuilderV3::ThumbnailBuilder
      end

      def iiif_search_builder
        ManifestBuilderV3::IIIFSearchBuilder
      end

      ##
      # Class accessor for the rendering builder
      # @return [Class]
      def rendering_builder
        ManifestBuilderV3::RenderingBuilder
      end

      ##
      # Class accessor for the navPlace builder
      # @return [Class]
      def nav_place_builder
        ManifestBuilderV3::NavPlaceBuilder
      end
    end
  end
end
