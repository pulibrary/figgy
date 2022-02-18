# frozen_string_literal: true

class ManifestBuilder
  class StartCanvasBuilder
    attr_reader :resource, :canvas_builder

    # @param [Resource] resource the Resource being viewed
    def initialize(resource, canvas_builder:)
      @resource = resource
      @canvas_builder = canvas_builder
    end

    def apply(manifest)
      return manifest unless start_canvas_id && file_set
      manifest["startCanvas"] = path
      manifest
    end

    private

      def path
        canvas_builder.new(file_set, resource).path
      end

      def file_set
        @file_set ||= query_service.find_by(id: start_canvas_id)
      rescue Valkyrie::Persistence::ObjectNotFoundError
        nil
      end

      def query_service
        Valkyrie.config.metadata_adapter.query_service
      end

      def start_canvas_id
        Array.wrap(resource.resource.try(:start_canvas)).first
      end
  end
end
