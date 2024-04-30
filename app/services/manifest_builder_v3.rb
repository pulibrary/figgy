# frozen_string_literal: true
class ManifestBuilderV3
  attr_reader :resource, :services

  ##
  # @param [Resource] resource the Resource subject
  def initialize(resource, auth_token = nil, current_ability = nil)
    @resource = RootNode.for(resource, auth_token, current_ability)
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
    def self.for(resource, _auth_token = nil, _current_ability = nil)
      case resource
      when ScannedMap
        ScannedMapNode.new(resource)
      else
        case ChangeSet.for(resource)
        when RecordingChangeSet
          # if multi_volume_recording?(resource)
          #   MultiVolumeRecordingNode.new(resource)
          # else
            RecordingNode.new(resource)
        #   end
        else
          new(resource, auth_token)
        end


      end
    end
    attr_reader :resource, :auth_token, :current_ability
    delegate :decorate, :to_model, :id, to: :resource

    def source_metadata_identifier
      resource.try(:source_metadata_identifier)
    end

    ##
    # @param [Resource] resource the Resource being modeled as the root
    def initialize(resource, auth_token = nil, current_ability = nil)
      @resource = resource
      @auth_token = auth_token
      @current_ability = current_ability
    end

    ##
    # Returns representation of the object as an array of strings - often the
    #   title.
    # @return [Array<String>]
    def to_s
      resource.title.map(&:to_s)
    end

    def search_enabled?
      resource.try(:ocr_language).present?
    end

    def description
      if resource.respond_to?(:primary_imported_metadata) && resource.primary_imported_metadata.description.present?
        resource.primary_imported_metadata.description
      else
        decorate.try(:description)
      end
    end

    def thumbnail_id
      resource.try(:thumbnail_id)
    end

    ##
    # Retrieves the presenters for each member Work as a separate root
    # @return [RootNode]
    def work_presenters
      @work_presenters ||= (members - leaf_nodes).map do |node|
        RootNode.for(node)
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
      helper.manifest_url(resource)
    end

    # Generate the IIIF Manifest metadata using the resource decorator
    # @return [Hash] the manifest metadata
    def manifest_metadata
      resource.decorate.iiif_metadata
    end

    ##
    # Retrieves the first viewing hint from the resource metadata
    # Returns multi-part if it's a Multi-Volume Work.
    # @return [String]
    def viewing_hint
      if !work_presenters.empty?
        "multi-part"
      else
        resource.respond_to?(:viewing_hint) ? Array(resource.viewing_hint).first : []
      end
    end

    ##
    # Retrieves the first viewing direction from the resource metadata
    # read by method in record_property_builder
    # @return [String]
    def viewing_direction
      return if viewing_hint == "multi-part"
      resource.respond_to?(:viewing_direction) ? Array(resource.viewing_direction).first : []
    end

    def sequence_rendering
      [
        {
          "@id" => helper.pdf_url(resource),
          "type" => "Text",
          "label": { "en": ["Download as PDF"] },
          "format" => "application/pdf"
        }
      ]
    end

    private

      ##
      # Retrieve an instance of the ManifestHelper
      # @return [ManifestHelper]
      def helper
        @helper ||= ManifestHelper.new
      end
  end

  class ScannedMapNode < RootNode
    def manifestable_members
      @manifestable ||= Wayfinder.for(resource).members.reject { |x| x.is_a?(RasterResource) }
    end

    def members
      @members ||= manifestable_members.map do |member|
        wayfinder = Wayfinder.for(member)
        if wayfinder.respond_to?(:decorated_scanned_maps) && wayfinder.decorated_scanned_maps.empty?
          wayfinder.geo_members.first
        else
          member
        end
      end.compact
    end

    def leaf_nodes
      @leaf_nodes ||= members.select { |x| x.instance_of?(FileSet) && geo_image?(x) }
    end

    def logical_structure
      value = resource.try(:logical_structure) || []

      # Return an empty structure if the structure contains empty nodes.
      nodes = value.first.nodes.reject { |n| n.nodes.empty? }
      return [] if nodes.empty?
      value
    end

    private

      def geo_image?(member)
        ControlledVocabulary.for(:geo_image_format).include?(member.mime_type.first)
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

    def manifest_url(resource)
      "#{protocol}://#{host}/concern/#{resource.model_name.collection}/#{resource.id}/manifest"
    end

    def token_authorizable?(resource)
      resource.respond_to?(:auth_token) && !resource.auth_token.nil?
    end

    def pdf_url(resource)
      url = manifest_url(resource).gsub("manifest", "pdf")
      return url + "?auth_token=#{resource.auth_token}" if token_authorizable?(resource)
      url
    end

    def host
      default_url_options[:host]
    end

    def protocol
      default_url_options[:protocol] || "http"
    end

    ##
    # Retrieve the base URL for Riiif
    # @param [String] id identifier for the image resource
    # @return [String]
    def manifest_image_path(resource)
      if (Rails.env.development? && Figgy.config["pyramidals_bucket"].blank?) || Rails.env.test?
        ManifestBuilder::RiiifHelper.new.base_url(resource.id)
      else
        ManifestBuilder::PyramidalHelper.new.base_url(resource)
      end
    end

    ##
    # Retrieve the URL path for an image served over the Riiif
    # @param [FileSet] resource A FileSet to generate a
    #   thumbnail URL from.
    # @return [String]
    def manifest_image_thumbnail_path(resource)
      "#{manifest_image_path(resource)}/full/!200,150/0/default.jpg"
    end

    def manifest_image_medium_path(resource)
      "#{manifest_image_path(resource)}/full/1000,/0/default.jpg"
    end
  end

  private

    ##
    # Instantiate the Manifest
    # @return [IIIFManifest]
    def manifest
      @manifest ||= IIIFManifest::V3::ManifestFactory.new(@resource, manifest_service_locator: ManifestServiceLocator).to_h
    end
end
