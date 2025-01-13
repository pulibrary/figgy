# frozen_string_literal: true
class Preserver
  # Encapsulate logic for converting a binary node to a preservation node.
  class PreservationChecker
    # @return [Array<Metadata | Binary>]
    def self.for(resource:, preservation_object:, skip_metadata_checksum: false)
      binaries_for(resource: resource, preservation_object: preservation_object) + metadata_for(resource: resource, preservation_object: preservation_object, skip_checksum: skip_metadata_checksum)
    end

    def self.metadata_for(resource:, preservation_object:, skip_checksum: false)
      [
        Metadata.new(resource: resource, preservation_object: preservation_object, skip_checksum: skip_checksum)
      ]
    end

    def self.binaries_for(resource:, preservation_object:)
      (resource.try(:preservation_targets) || []).map { |file_metadata| Binary.new(file_metadata: file_metadata, preservation_object: preservation_object) }
    end

    class Metadata
      attr_reader :resource, :preservation_object, :skip_checksum
      def initialize(resource:, preservation_object:, skip_checksum:)
        @resource = resource
        @preservation_object = preservation_object
        @skip_checksum = skip_checksum
      end

      def preservation_file_exists?
        preservation_file.present?
      rescue Valkyrie::StorageAdapter::FileNotFound
        false
      end

      def preserved?
        preservation_object.preserved_object_id == resource.id && resource.optimistic_lock_token.first&.token == preservation_object.metadata_version
      end

      def preserved_file_checksums_match?
        return true if skip_checksum
        compact_local_md5 == preservation_file.io.file.data[:file].md5
      end

      def compact_local_md5
        local_checksum = preservation_object&.metadata_node&.checksum&.first&.md5
        Base64.strict_encode64([local_checksum].pack("H*"))
      end

      def preservation_file
        @preservation_file ||=
          FiggyUtils.with_rescue([OpenSSL::SSL::SSLError], retries: 5) do
            Valkyrie::StorageAdapter.find_by(id: preservation_node.file_identifiers.first)
          end
      end

      def preservation_node
        @preservation_node ||=
          preservation_object.metadata_node
      end
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

      def preserved_file_checksums_match?
        preservation_file.io.file.data[:file].md5 == compact_local_md5
      end

      def compact_local_md5
        Base64.strict_encode64([file_metadata.checksum.first.md5].pack("H*"))
      end

      def preservation_file
        @preservation_file ||=
          FiggyUtils.with_rescue([OpenSSL::SSL::SSLError], retries: 5) do
            Valkyrie::StorageAdapter.find_by(id: preservation_node.file_identifiers.first)
          end
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
