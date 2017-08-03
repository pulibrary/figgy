# frozen_string_literal: true
class ManifestBuilder
  attr_reader :resource
  def initialize(resource)
    @resource = RootNode.new(resource)
  end

  def build
    JSON.parse(IIIFManifest::ManifestFactory.new(resource).to_h.to_json, symbolize_keys: true)
  end

  class RootNode
    attr_reader :resource
    delegate :query_service, to: :metadata_adapter
    def initialize(resource)
      @resource = resource
    end

    delegate :description, to: :resource

    def to_s
      resource.decorate.header
    end

    def work_presenters
      []
    end

    def file_set_presenters
      @file_set_presenters ||= leaf_nodes.map do |node|
        LeafNode.new(node)
      end
    end

    def ranges
      logical_structure.map do |top_structure|
        TopStructure.new(top_structure)
      end
    end

    def manifest_url
      helper.polymorphic_url([:manifest, resource])
    end

    def viewing_hint
      Array(resource.viewing_hint).first
    end

    private

      def helper
        @helper ||= ManifestHelper.new
      end

      def members
        @members ||= query_service.find_members(resource: resource).to_a
      end

      def leaf_nodes
        @leaf_nodes ||= members.select { |x| x.instance_of?(FileSet) }
      end

      def metadata_adapter
        Valkyrie.config.metadata_adapter
      end

      def logical_structure
        resource.logical_structure || []
      end
  end

  class TopStructure
    attr_reader :structure
    def initialize(structure)
      @structure = structure
    end

    def label
      structure.label.to_sentence
    end

    def ranges
      @ranges ||= structure.nodes.select { |x| x.proxy.blank? }.map do |node|
        TopStructure.new(node)
      end
    end

    def file_set_presenters
      @file_set_presenters ||= structure.nodes.select { |x| x.proxy.present? }.map do |node|
        LeafStructureNode.new(node)
      end
    end
  end

  class LeafStructureNode
    attr_reader :structure
    def initialize(structure)
      @structure = structure
    end

    def id
      structure.proxy.first.to_s
    end
  end

  class LeafNode
    attr_reader :resource
    delegate :query_service, to: :metadata_adapter
    def initialize(resource)
      @resource = resource
    end

    delegate :id, to: :resource

    def to_s
      resource.decorate.header
    end

    def derivative_id
      derivative_metadata_node.id
    end

    def display_image
      IIIFManifest::DisplayImage.new(id,
                                     width: width,
                                     height: height,
                                     format: "image/jpeg",
                                     iiif_endpoint: endpoint)
    end

    private

      def derivative_metadata_node
        members.find { |x| x.use.include?(Valkyrie::Vocab::PCDMUse.ServiceFile) }
      end

      def width
        file.width.first
      end

      def height
        file.height.first
      end

      def file
        @file ||= members.find { |x| x.use.include?(Valkyrie::Vocab::PCDMUse.OriginalFile) }
      end

      def members
        @members ||= query_service.find_members(resource: resource).to_a
      end

      def endpoint
        IIIFManifest::IIIFEndpoint.new(helper.manifest_image_path(derivative_id),
                                       profile: "http://iiif.io/api/image/2/level2.json")
      end

      def metadata_adapter
        Valkyrie.config.metadata_adapter
      end

      def helper
        @helper ||= ManifestHelper.new
      end
  end

  class ManifestHelper
    include ActionDispatch::Routing::PolymorphicRoutes
    include Rails.application.routes.url_helpers

    def default_url_options
      Figgy.default_url_options
    end

    def manifest_image_path(id)
      RiiifHelper.new.base_url(id)
    end

    def manifest_image_thumbnail_path(id)
      "#{manifest_image_path(id)}/full/!200,150/0/default.jpg"
    end
  end

  class RiiifHelper
    include ActionDispatch::Routing::PolymorphicRoutes
    include Riiif::Engine.routes.url_helpers

    def default_url_options
      Figgy.default_url_options
    end
  end
end
