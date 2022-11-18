# frozen_string_literal: true
class ChangeSetPersister
  class GenerateMosaic
    attr_reader :change_set_persister, :change_set, :post_save_resource
    def initialize(change_set_persister:, change_set:, post_save_resource:)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @post_save_resource = post_save_resource
    end

    def run
      return unless mosaic?(post_save_resource)
      return unless published?(change_set)
      MosaicJob.perform_later(post_save_resource.id.to_s)
      change_set
    end

    private

      def published?(change_set)
        published_states = change_set.resource.decorate.workflow_class.ark_mint_states
        change_set.changed?(:state) && published_states.include?(change_set.state.to_s)
      end

      def mosaic?(resource)
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
