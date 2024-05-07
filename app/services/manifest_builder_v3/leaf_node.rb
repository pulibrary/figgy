# frozen_string_literal: true
class ManifestBuilderV3
  # Presenter for Resource instances (usually FileSets) modeled as leaf nodes
  class LeafNode
    attr_reader :resource, :parent_node
    ##
    # @param [Resource] resource a FileSet resource featured in the IIIF Manifest
    # @param [RootNode] parent_node the node for the parent Work for the FileSet
    def initialize(resource, parent_node)
      @resource = resource
      @parent_node = parent_node
    end

    delegate :local_identifier, :viewing_hint, :ocr_content, :to_model, to: :resource

    def id
      resource.id.to_s
    end

    ##
    # Stringify the image using the decorator
    # @return [String]
    def to_s
      Valkyrie::ResourceDecorator.new(resource).header
    end

    ##
    # Retrieve an instance of the IIIFManifest::DisplayImage for the image
    # @return [IIIFManifest::DisplayImage]
    def display_image
      @display_image ||= IIIFManifest::DisplayImage.new(display_image_url,
                                                        width: width.to_i,
                                                        height: height.to_i,
                                                        format: "image/jpeg",
                                                        iiif_endpoint: endpoint)
    end

    def display_image_url
      helper.manifest_image_medium_path(resource)
    rescue
      ""
    end

    private

      ##
      # Retrieve the width for the image resource
      # @return [String]
      def width
        file.width.first
      end

      ##
      # Retrieve the height for the image resource
      # @return [String]
      def height
        file.height.first
      end

      ##
      # Retrieve the File related to the image resource
      # @return [File]
      def file
        resource.primary_file
      end

      ##
      # Retrieve an instance of the IIIFManifest::IIIFEndpoint for the service endpoint
      # @return [IIIFManifest::IIIFEndpoint]
      def endpoint
        return unless resource.derivative_file
        IIIFManifest::IIIFEndpoint.new(helper.manifest_image_path(resource),
                                       profile: "http://iiif.io/api/image/2/level2.json")
      end

      ##
      # Retrieve an instance of the ManifestHelper
      # @return [ManifestHelper]
      def helper
        @helper ||= ManifestHelper.new
      end
  end
end
