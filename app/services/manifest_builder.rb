# frozen_string_literal: true
class ManifestBuilder
  attr_reader :resource, :services

  ##
  # @param [Resource] resource the Resource subject
  def initialize(resource, auth_token = nil)
    @resource = RootNode.for(resource, auth_token)
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
    def self.for(resource, auth_token = nil)
      case resource
      when Collection
        CollectionNode.new(resource)
      when EphemeraProject
        EphemeraProjectNode.new(resource)
      when IndexCollection
        IndexCollectionNode.new(resource)
      when ScannedMap
        ScannedMapNode.new(resource)
      when Numismatics::Issue
        Numismatics::IssueNode.new(resource)
      when Playlist
        PlaylistNode.new(resource, auth_token)
      else
        case DynamicChangeSet.new(resource)
        when RecordingChangeSet
          RecordingNode.new(resource)
        else
          new(resource, auth_token)
        end
      end
    end
    attr_reader :resource, :auth_token
    delegate :query_service, to: :metadata_adapter
    delegate :decorate, :to_model, :id, to: :resource

    def source_metadata_identifier
      resource.try(:source_metadata_identifier)
    end

    ##
    # @param [Resource] resource the Resource being modeled as the root
    def initialize(resource, auth_token = nil)
      @resource = resource
      @auth_token = auth_token
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
      return audio_ranges if audio_manifest?
      logical_structure.map do |top_structure|
        TopStructure.new(top_structure)
      end
    end

    def audio_manifest?
      file_set_presenters.find do |fs_presenter|
        fs_presenter.display_content.present?
      end.present?
    end

    def audio_ranges
      return default_audio_ranges if logical_structure.blank? || logical_structure.flat_map(&:nodes).blank?
      logical_structure.flat_map do |top_structure|
        top_structure.nodes.map do |node|
          TopStructure.new(wrap_proxies(node))
        end
      end
    end

    def wrap_proxies(node)
      if !node.proxy.present?
        StructureNode.new(
          id: node.id,
          label: node.label,
          nodes: node.nodes.map { |x| wrap_proxies(x) }
        )
      else
        StructureNode.new(
          id: node.id,
          label: label(node),
          nodes: [
            StructureNode.new(
              proxy: node.proxy
            )
          ]
        )
      end
    end

    def default_audio_ranges
      file_set_presenters.map do |file_set|
        TopStructure.new(
          Structure.new(
            label: file_set&.display_content&.label,
            nodes: StructureNode.new(
              label: file_set&.display_content&.label,
              proxy: file_set.id
            )
          )
        )
      end
    end

    def label(structure_node)
      proxy_id = structure_node.proxy.first
      file_set_presenter = file_set_presenters.find { |x| x.resource.id == proxy_id }
      file_set_presenter&.display_content&.label
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
      return [] if audio_manifest?
      [
        {
          "@id" => helper.pdf_url(resource),
          label: "Download as PDF",
          format: "application/pdf"
        }
      ]
    end

    ##
    # Retrieve the child members for the subject resource of the Manifest
    # @return [Resource]
    def members
      @members ||= decorate.members.to_a
    end

    ##
    # Retrieve the leaf nodes for the Manifest
    # @return [FileSet]
    def leaf_nodes
      @leaf_nodes ||= members.select { |x| x.instance_of?(FileSet) && leaf_node_mime_type?(x.mime_type) }
    end

    private

      ##
      # Retrieve an instance of the ManifestHelper
      # @return [ManifestHelper]
      def helper
        @helper ||= ManifestHelper.new
      end

      ##
      # Checks a mime_type against a blacklist
      # @return [TrueClass, FalseClass]
      def leaf_node_mime_type?(mime_type)
        blacklist = ["application/xml; schema=mets", "application/xml"]
        (blacklist & Array.wrap(mime_type)).empty?
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
        resource.try(:logical_structure) || []
      end
  end

  # Wraps a Collection Resource for building Manifests
  class CollectionNode < RootNode
    # Collections should not have FileSets as members
    # @return [Array]
    def file_set_presenters
      []
    end

    # Attempt to delegate the description to the CollectionDecorator
    # @return [String]
    def description
      decorate.try(:description)
    end

    # Collections should not have viewing hints
    # @return [nil]
    def viewing_hint; end
  end

  class EphemeraProjectNode < CollectionNode
    def members
      @members ||= query_service.custom_queries.find_project_folders(resource: resource).to_a
    end
  end

  class IndexCollectionNode < CollectionNode
    def members
      @members ||= query_service.find_all_of_model(model: Collection).to_a + query_service.find_all_of_model(model: EphemeraProject).to_a
    end

    def manifest_url
      helper.index_manifest_url
    end

    def to_s
      "Figgy Collections"
    end

    def description
      "All collections which are a part of Figgy."
    end

    def id
      nil
    end
  end

  class ScannedMapNode < RootNode
    def manifestable_members
      @manifestable ||= decorate.members.reject { |x| x.is_a?(RasterResource) }
    end

    def members
      @members ||= begin
        manifestable_members.map do |member|
          decorator = member.decorate
          if decorator.respond_to?(:scanned_map_members) && decorator.scanned_map_members.empty?
            member.decorate.geo_members.first
          else
            member
          end
        end.compact
      end
    end

    def leaf_nodes
      @leaf_nodes ||= members.select { |x| x.instance_of?(FileSet) && geo_image?(x) }
    end

    private

      def geo_image?(member)
        ControlledVocabulary.for(:geo_image_format).include?(member.mime_type.first)
      end
  end

  class Numismatics::IssueNode < CollectionNode
    # Only include coins which have file sets;
    # otherwise there is no image for the viewer.
    def members
      @members ||= super.select { |coin| coin.member_ids.present? }
    end
  end

  class RecordingNode < RootNode
    def leaf_nodes
      @leaf_nodes ||= super.select { |x| x.mime_type.first.include?("audio/") }
    end

    def sequence_rendering
      []
    end

    ##
    # Retrieves the presenters for each member FileSet as a leaf
    # @return [LeafNode]
    def file_set_presenters
      return @file_set_presenters unless @file_set_presenters.nil?

      values = leaf_nodes.map do |node|
        next unless node.decorate.audio?

        LeafNode.new(node, self)
      end
      @file_set_presenters = values.compact
    end
  end

  class PlaylistNode < RootNode
    # Get all FileSets for a playlist, but decorate the label so that it's the
    # proxy's label instead.
    def leaf_nodes
      @leaf_nodes ||= wayfinder.file_sets.map do |member|
        ProxiedMember.new(member)
      end
    end

    def wayfinder
      @wayfinder ||= Wayfinder.for(resource)
    end

    class ProxiedMember < SimpleDelegator
      def id
        loaded[:proxy_parent].id
      end

      def proxied_object_id
        __getobj__.id
      end

      def title
        loaded[:proxy_parent].label
      end
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
      return if file.mime_type.first.include?("audio")
      @display_image ||= IIIFManifest::DisplayImage.new(display_image_url,
                                                        width: width.to_i,
                                                        height: height.to_i,
                                                        format: "image/jpeg",
                                                        iiif_endpoint: endpoint)
    end

    def download_url
      return if derivative.nil?
      if helper.token_authorizable?(parent_node.resource)
        helper.download_url(resource.try(:proxied_object_id) || resource.id, derivative.id, auth_token: parent_node.resource.auth_token)
      else
        helper.download_url(resource.try(:proxied_object_id) || resource.id, derivative.id)
      end
    end

    def display_content
      return unless file.mime_type.first.include?("audio")

      @display_content ||= IIIFManifest::V3::DisplayContent.new(
        download_url,
        format: "application/vnd.apple.mpegurl",
        label: resource.title.first,
        duration: file.duration.first.to_f,
        type: "Audio" # required for the viewer to play audio correctly
      )
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
        resource.original_file || resource.intermediate_files.first
      end

      def derivative
        resource.derivative_file
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
      case resource
      when Collection
        "#{protocol}://#{host}/collections/#{resource.id}/manifest"
      when FileSet
        ""
      else
        "#{protocol}://#{host}/concern/#{resource.model_name.plural}/#{resource.id}/manifest"
      end
    end

    def token_authorizable?(resource)
      resource.respond_to?(:auth_token) && !resource.auth_token.nil?
    end

    def pdf_url(resource)
      url = manifest_url(resource).gsub("manifest", "pdf")
      return url + "?auth_token=#{resource.auth_token}" if token_authorizable?(resource)
      url
    end

    def show_url(resource)
      "#{protocol}://#{host}/catalog/#{resource.id}"
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
      if Rails.env.development? || Rails.env.test?
        RiiifHelper.new.base_url(resource.id)
      else
        CantaloupeHelper.new.base_url(resource)
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

  class CantaloupeHelper
    def base_url(file_set)
      file_metadata = file_set.derivative_file
      raise Valkyrie::Persistence::ObjectNotFoundError, file_set.id if file_metadata.nil?
      begin
        file = file_metadata.file_identifiers[0].to_s.gsub("disk://", "")
        id = file.gsub(Figgy.config["derivative_path"], "").gsub(/^\//, "")
        Pathname.new(Figgy.config["cantaloupe_url"]).join(
          CGI.escape(id.to_s)
        ).to_s
      rescue
        Rails.logger.warn("Unable to find derivative path for #{file_set.id}")
        nil
      end
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
      @manifest ||= begin
        if audio_files(resource.try(:leaf_nodes)).empty?
          IIIFManifest::ManifestFactory.new(@resource, manifest_service_locator: ManifestServiceLocator).to_h
        else
          # note this assumes audio resources use flat modeling
          IIIFManifest::V3::ManifestFactory.new(@resource, manifest_service_locator: ManifestServiceLocatorV3).to_h
        end
      end
    end

    def audio_files(file_sets)
      return [] unless file_sets
      file_sets.select do |fs|
        fs.mime_type.any? { |str| str.starts_with? "audio" }
      end
    end
end
