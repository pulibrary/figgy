# frozen_string_literal: true
class Preserver
  # Encapsulate logic for converting a binary node to a preservation node.
  class PreservationIntermediaryNode
    attr_reader :binary_node, :preservation_object
    delegate :file_identifiers, to: :binary_node
    # @param binary_node [FileMetadata] Node to convert to a preservation
    #   node.
    # @param preservation_object [PreservationObject] Object the preservation
    #   node will be appended to. Used to check if already preserved.
    def initialize(binary_node:, preservation_object:)
      @binary_node = binary_node
      @preservation_object = preservation_object
    end

    def uploaded_content?
      binary_node.file_identifiers.present?
    end

    def preserved?
      preservation_object.binary_nodes.find { |x| x.preservation_copy_of_id == binary_node.id }
    end

    def preservation_node
      FileMetadata.new(
        label: preservation_label,
        use: Valkyrie::Vocab::PCDMUse.PreservationCopy,
        mime_type: binary_node.mime_type,
        checksum: binary_node.checksum,
        preservation_copy_of_id: binary_node.id
      )
    end

    # Creates the binary name for a preserved copy of a file by setting the
    # label before the ID and extension of the file.
    # @example Get a label
    #   x.binary_node.label # => "bla.tif"
    #   x.binary_node.id # => "123"
    #   x.preservation_label # => "bla-123.tif"
    def preservation_label
      label, splitter, extension = binary_node.label.first.to_s.rpartition(".")
      "#{label}-#{binary_node.id}#{splitter}#{extension}"
    end
  end
end
