# frozen_string_literal: true
class ManifestBuilder
  attr_reader :resource, :services

  ##
  # @param [Resource] resource the Resource subject
  def initialize(resource)
    @resource = RootNode.new(resource)
  end

  ##
  # Build the JSON-serialized Manifest instance
  # @return [JSON]
  def build
    JSON.parse(manifest.to_json, symbolize_keys: true)
  end

  ##
  # Presenter modeling the Resource subjects as root nodes
  class RootNode
    attr_reader :resource
    delegate :query_service, to: :metadata_adapter
    delegate :decorate, :source_metadata_identifier, :to_model, :id, to: :resource

    ##
    # @param [Resource] resource the Resource being modeled as the root
    def initialize(resource)
      @resource = resource
    end

    delegate :description, to: :resource

    ##
    # Stringify the Resource by delegating to the header within the Decorator
    # @return [String]
    def to_s
      resource.decorate.header
    end

    ##
    # Retrieves the presenters for each member Work as a separate root
    # @return [RootNode]
    def work_presenters
      @work_presenters ||= (members - leaf_nodes).map do |node|
        RootNode.new(node)
      end
    end

    ##
    # Retrieves the presenters for each member FileSet as a leaf
    # @return [LeafNode]
    def file_set_presenters
      @file_set_presenters ||= leaf_nodes.map do |node|
        LeafNode.new(node, self)
      end
    end

    ##
    # Retrieves the presenter for each Range (sc:Range) instance
    # @return [TopStructure]
    def ranges
      logical_structure.map do |top_structure|
        TopStructure.new(top_structure)
      end
    end

    ##
    # Helper method for generating the URL to the resource manifest
    # @return [String]
    def manifest_url
      helper.polymorphic_url([:manifest, resource])
    end

    ##
    # Retrieves the first viewing hint from the resource metadata
    # @return [String]
    def viewing_hint
      Array(resource.viewing_hint).first
    end

    private

      ##
      # Retrieve an instance of the ManifestHelper
      # @return [ManifestHelper]
      def helper
        @helper ||= ManifestHelper.new
      end

      ##
      # Retrieve the child members for the subject resource of the Manifest
      # @return [Resource]
      def members
        @members ||= query_service.find_members(resource: resource).to_a
      end

      ##
      # Retrieve the leaf nodes for the Manifest
      # @return [FileSet]
      def leaf_nodes
        @leaf_nodes ||= members.select { |x| x.instance_of?(FileSet) }
      end

      ##
      # Retrieve the metadata adapter instance for the Valkyrie engine
      # @return [String]
      def metadata_adapter
        Valkyrie.config.metadata_adapter
      end

      ##
      # Retrieve the TopStructure for the resource manifest
      # @param [TopStructure]
      def logical_structure
        resource.logical_structure || []
      end
  end

  ##
  # Presenter modeling the top node of nested structure resource trees
  class TopStructure
    attr_reader :structure

    ##
    # @param [Hash] structure the top structure node
    def initialize(structure)
      @structure = structure
    end

    ##
    # Retrieve the label for the Structure
    # @return [String]
    def label
      structure.label.to_sentence
    end

    ##
    # Retrieve the ranges (sc:Range) for this structure
    # @return [TopStructure]
    def ranges
      @ranges ||= structure.nodes.select { |x| x.proxy.blank? }.map do |node|
        TopStructure.new(node)
      end
    end

    # Retrieve the IIIF Manifest nodes for FileSet resources
    # @return [LeafStructureNode]
    def file_set_presenters
      @file_set_presenters ||= structure.nodes.select { |x| x.proxy.present? }.map do |node|
        LeafStructureNode.new(node)
      end
    end
  end

  ##
  # Class modeling the terminal nodes of IIIF Manifest structures
  class LeafStructureNode
    attr_reader :structure
    ##
    # @param [Hash] structure the structure terminal node
    def initialize(structure)
      @structure = structure
    end

    ##
    # Retrieve the ID for the node from the first proxy in the structure
    # @return [String]
    def id
      structure.proxy.first.to_s
    end
  end

  ##
  # Presenter for Resource instances (usually FileSets) modeled as leaf nodes
  class LeafNode
    attr_reader :resource, :parent_node
    delegate :query_service, to: :metadata_adapter
    ##
    # @param [Resource] resource a FileSet resource featured in the IIIF Manifest
    # @param [RootNode] parent_node the node for the parent Work for the FileSet
    def initialize(resource, parent_node)
      @resource = resource
      @parent_node = parent_node
    end

    delegate :id, to: :resource

    ##
    # Stringify the image using the decorator
    # @return [String]
    def to_s
      resource.decorate.header
    end

    ##
    # Retrieve the ID for the resource
    # @return [String]
    def derivative_id
      resource.id
    end

    ##
    # Retrieve an instance of the IIIFManifest::DisplayImage for the image
    # @return [IIIFManifest::DisplayImage]
    def display_image
      IIIFManifest::DisplayImage.new(id,
                                     width: width,
                                     height: height,
                                     format: "image/jpeg",
                                     iiif_endpoint: endpoint)
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
        resource.original_file
      end

      ##
      # Retrieve an instance of the IIIFManifest::IIIFEndpoint for the service endpoint
      # @return [IIIFManifest::IIIFEndpoint]
      def endpoint
        IIIFManifest::IIIFEndpoint.new(helper.manifest_image_path(derivative_id),
                                       profile: "http://iiif.io/api/image/2/level2.json")
      end

      ##
      # Retrieve an instance of the ManifestHelper
      # @return [ManifestHelper]
      def helper
        @helper ||= ManifestHelper.new
      end
  end

  ##
  # Class providing helper methods for the IIIF::Presentation::Manifest
  class ManifestHelper
    include ActionDispatch::Routing::PolymorphicRoutes
    include Rails.application.routes.url_helpers

    ##
    # Retrieve the default options for URL's
    # @return [Hash]
    def default_url_options
      Figgy.default_url_options
    end

    ##
    # Retrieve the base URL for Riiif
    # @param [String] id identifier for the image resource
    # @return [String]
    def manifest_image_path(id)
      RiiifHelper.new.base_url(id)
    end

    ##
    # Retrieve the URL path for an image served over the Riiif
    # @param [String] id identifier for the image resource
    # @return [String]
    def manifest_image_thumbnail_path(id)
      "#{manifest_image_path(id)}/full/!200,150/0/default.jpg"
    end
  end

  ##
  # Class providing helper methods for the Riiif Gem
  class RiiifHelper
    include ActionDispatch::Routing::PolymorphicRoutes
    include Riiif::Engine.routes.url_helpers

    ##
    # Retrieve the default options for URL's
    # @return [Hash]
    def default_url_options
      Figgy.default_url_options
    end
  end

  private

    ##
    # Instantiate the Manifest
    # @return [IIIFManifest]
    def manifest
      @manifest || @manifest = IIIFManifest::ManifestFactory.new(@resource, manifest_service_locator: ManifestServiceLocator).to_h
    end
end
