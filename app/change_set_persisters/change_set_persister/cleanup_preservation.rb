# frozen_string_literal: true

class ChangeSetPersister
  class CleanupPreservation
    attr_reader :resource
    def initialize(change_set:, change_set_persister: nil, post_save_resource: nil)
      @resource = change_set.resource
    end

    def run
      return unless resource.is_a?(PreservationObject)
      CleanupFilesJob.perform_later(file_identifiers: identifiers_to_remove)
    end

    private

      def identifiers_to_remove
        metadata_node_identifiers + binary_node_identifiers
      end

      def metadata_node_identifiers
        resource.metadata_node&.file_identifiers&.map(&:to_s) || []
      end

      def binary_node_identifiers
        resource.binary_nodes.flat_map(&:file_identifiers).compact.map(&:to_s)
      end
  end
end
