# frozen_string_literal: true
module ResourceRelations
  extend ActiveSupport::Concern

  included do
    def load_attachable_resources!
      load_scanned_maps! if attaches_scanned_maps?
      load_raster_resources! if attaches_raster_resources?
      load_vector_resources! if attaches_vector_resources?
    end

    def load_relatable_resources!
      load_parent_scanned_maps! if relates_to_parent_scanned_maps?
      load_parent_raster_resources! if relates_to_parent_raster_resources?
      load_parent_vector_resources! if relates_to_parent_vector_resources?
    end

    private

      def solr_query_service
        Valkyrie::MetadataAdapter.find(:index_solr)
      end

      def find_unrelated_query
        FindUnrelated.new(query_service: solr_query_service)
      end

      def find_unrelated_parents_query
        FindUnrelatedParents.new(query_service: solr_query_service)
      end

      def load_unattached_resources(model:)
        resources = find_unrelated_query.find_unrelated(resource: resource, model: model)
        resources.map(&:decorate).map(&:form_input_values)
      end

      def load_unrelated_parent_resources(model:)
        resources = find_unrelated_parents_query.find_unrelated_parents(resource: resource, model: model)
        resources.map(&:decorate).map(&:form_input_values)
      end

      def load_scanned_maps!
        @unattached_scanned_maps = load_unattached_resources(model: ScannedMap)
      end

      def load_raster_resources!
        @unattached_raster_resources = load_unattached_resources(model: RasterResource)
      end

      def load_vector_resources!
        @unattached_vector_resources = load_unattached_resources(model: VectorResource)
      end

      def load_parent_scanned_maps!
        @unrelated_parent_scanned_maps = load_unrelated_parent_resources(model: ScannedMap)
      end

      def load_parent_raster_resources!
        @unrelated_parent_raster_resources = load_unrelated_parent_resources(model: RasterResource)
      end

      def load_parent_vector_resources!
        @unrelated_parent_vector_resources = load_unrelated_parent_resources(model: VectorResource)
      end

      def attaches_scanned_maps?
        [ScannedMap].include? resource.class
      end

      def attaches_raster_resources?
        [ScannedMap, RasterResource].include? resource.class
      end

      def attaches_vector_resources?
        [RasterResource, VectorResource].include? resource.class
      end

      def relates_to_parent_scanned_maps?
        [ScannedMap, RasterResource].include? resource.class
      end

      def relates_to_parent_raster_resources?
        [RasterResource, VectorResource].include? resource.class
      end

      def relates_to_parent_vector_resources?
        [VectorResource].include? resource.class
      end
  end
end
