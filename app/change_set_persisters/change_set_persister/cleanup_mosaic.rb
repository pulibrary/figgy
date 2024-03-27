# frozen_string_literal: true
class ChangeSetPersister
  class CleanupMosaic
    attr_reader :resource, :change_set
    def initialize(change_set_persister: nil, change_set:, post_save_resource: nil)
      @change_set = change_set
      @resource = change_set.resource
    end

    def run
      return unless mosaic? && published?
      DeleteMosaicJob.perform_later(resource_id: resource.id.to_s)
    end

    private

      def published?
        published_states = change_set.resource.decorate.workflow_class.ark_mint_states
        published_states.include?(change_set.state.to_s)
      end

      def mosaic?
        wayfinder = Wayfinder.for(resource)
        file_count = wayfinder.try(:mosaic_file_count)
        return false unless file_count&.positive?
        if resource.is_a?(ScannedMap) && wayfinder.scanned_maps_count > 1
          true
        elsif resource.is_a?(RasterResource) && wayfinder.raster_resources_count > 1
          true
        else
          false
        end
      end
  end
end
