# frozen_string_literal: true
class ManifestBuilder
  class MediaSequenceBuilder
    attr_reader :resource

    ##
    # @param [Resource] resource the Resource being viewed
    def initialize(resource)
      @resource = resource
    end

    def apply(manifest)
      return manifest unless resource.leaf_nodes&.first&.mime_type == ["application/pdf"]
      return manifest if pdf_node.primary_file.preservation_file?
      manifest["mediaSequences"] = [media_sequence]
      manifest
    end

    private

      def media_sequence
        {
          "@type": "ixif:MediaSequence",
          label: "XSequence 0",
          elements: [
            pdf_element
          ]
        }
      end

      def pdf_element
        id = helper.download_url(pdf_node.id.to_s, pdf_node.primary_file.id.to_s)
        {
          "@id": id,
          "@type": "foaf:Document",
          "format": "application/pdf",
          "label": resource.to_s.first
        }
      end

      def pdf_node
        resource.leaf_nodes.first
      end

      def helper
        @helper ||= ManifestBuilder::ManifestHelper.new
      end
  end
end
