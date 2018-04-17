# frozen_string_literal: true
module ResourceRelations
  extend ActiveSupport::Concern

  included do
    def load_attachable_resources!
      load_scanned_maps! if [ScannedMap, RasterResource].include? resource.class
      load_raster_resources! if [RasterResource, VectorResource].include? resource.class
      load_vector_resources! if [VectorResource].include? resource.class
    end

    def load_parent_resources!
      load_parent_scanned_maps if [RasterResource, VectorResource].include? resource.class
      load_parent_raster_resources if [VectorResource].include? resource.class
    end

    private

      def load_unattached_resources(id:, model:)
        resources = query_service.custom_queries.find_unrelated(id: id, model: model.to_s)
        resources.map(&:decorate).map(&:form_input_values)
      end

      def load_unrelated_parent_resources(id:, model:)
        resources = query_service.custom_queries.find_unrelated_parents(id: id, model: model.to_s)
        resources.map(&:decorate).map(&:form_input_values)
      end

      def resource_id
        params[:id]
      end

      def load_scanned_maps!
        @unattached_scanned_maps = load_unattached_resources(id: resource_id, model: ScannedMap)
      end

      def load_raster_resources!
        @unattached_raster_resources = load_unattached_resources(id: resource_id, model: RasterResource)
      end

      def load_vector_resources!
        @unattached_vector_resources = load_unattached_resources(id: resource_id, model: VectorResource)
      end

      def load_parent_scanned_maps!
        @unrelated_parent_scanned_maps = load_unrelated_parent_resources(id: resource_id, model: ScannedMap)
      end

      def load_parent_raster_resources!
        @unrelated_parent_raster_resources = load_unrelated_parent_resources(id: resource_id, model: RasterResource)
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

      def load_attachable_resources!
        load_scanned_maps! if attaches_scanned_maps?
        load_raster_resources! if attaches_raster_resources?
        load_vector_resources! if attaches_vector_resources?
      end

      def relates_to_parent_scanned_maps?
        [RasterResource, VectorResource].include? resource.class
      end

      def relates_to_parent_raster_resources?
        [VectorResource].include? resource.class
      end

      def load_relatable_resources!
        load_parent_scanned_maps! if relates_to_parent_scanned_maps?
        load_parent_raster_resources! if relates_to_parent_raster_resources?
      end
  end
end
