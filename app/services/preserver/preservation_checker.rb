# frozen_string_literal: true
class Preserver
  # Encapsulate logic for converting a binary node to a preservation node.
  class PreservationChecker
    # @return [Array<Metadata | Binary>]
    def self.for(resource:, preservation_object:)
      binaries_for(resource: resource, preservation_object: preservation_object)
    end

    def self.binaries_for(resource:, preservation_object:)
      (resource.try(:preservation_targets) || []).map { |file_metadata| Binary.new(file_metadata: file_metadata, preservation_object: preservation_object) }
    end

    class Metadata
      def local_files?
        true
      end

      def preserved?; end
    end

    class Binary
      attr_reader :file_metadata, :preservation_object
      delegate :file_identifiers, :checksum, to: :file_metadata
      # @param file_metadata [FileMetadata] Node to convert to a preservation
      #   node.
      # @param preservation_object [PreservationObject] Object the preservation
      #   node will be appended to. Used to check if already preserved.
      def initialize(file_metadata:, preservation_object:)
        @file_metadata = file_metadata
        @preservation_object = preservation_object
      end

      def local_files?
        file_metadata.file_identifiers.present?
      end

      def preservation_file_exists?
        preservation_file.present?
      rescue Valkyrie::StorageAdapter::FileNotFound
        false
      end

      def preservation_file
        @preservation_file ||=
          Valkyrie::StorageAdapter.find_by(id: preservation_node.file_identifiers.first).present?
      end

      def preserved?
        preservation_object.binary_nodes.find { |x| x.preservation_copy_of_id == file_metadata.id } &&
          file_metadata.checksum == preservation_node&.checksum
      end

      def preservation_node
        @preservation_node ||=
          preservation_object.binary_node_for(file_metadata)
      end
    end
  end
end
