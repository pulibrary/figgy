# frozen_string_literal: true
class ManifestBuilder
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
    def self.for(resource, auth_token = nil, current_ability = nil)
      case resource
      when Collection
        case ChangeSet.for(resource)
        when ArchivalMediaCollectionChangeSet
          ManifestBuilderV3::RootNode.for(resource, auth_token, current_ability)
        else
          CollectionNode.new(resource, nil, current_ability)
        end
      when EphemeraProject
        EphemeraProjectNode.new(resource)
      when EphemeraFolder
        EphemeraFolderNode.new(resource)
      when IndexCollection
        IndexCollectionNode.new(resource)
      when ScannedMap
        ScannedMapNode.new(resource)
      when Numismatics::Issue
        Numismatics::IssueNode.new(resource)
      when Playlist
        ManifestBuilderV3::RootNode.for(resource, auth_token, current_ability)
      else
        case ChangeSet.for(resource)
        when RecordingChangeSet
          ManifestBuilderV3::RootNode.for(resource, auth_token, current_ability)
        else
          new(resource, auth_token)
        end
      end
    end
    attr_reader :resource, :auth_token, :current_ability
    delegate :query_service, to: :metadata_adapter
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
      @file_set_presenters ||= leaf_nodes.flat_map do |node|
        LeafNode.for(node, self)
      end
    end

    ##
    # Retrieves the presenter for each Range (sc:Range) instance
    # @return [TopStructure]
    def ranges
      logical_structure.map do |top_structure|
        TopStructure.new(top_structure, resource)
      end
    end

    def collection?
      false
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
          label: "Download as PDF",
          format: "application/pdf"
        }
      ]
    end

    ##
    # Retrieve the child members for the subject resource of the Manifest
    # @return [Resource]
    def members
      @members ||=
        Wayfinder.for(@resource).members.to_a.select do |member|
          !current_ability || current_ability.can?(:read, member)
        end
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
      # Checks a mime_type against an ignore list
      # @return [TrueClass, FalseClass]
      def leaf_node_mime_type?(mime_type)
        ignore_list = [
          "application/xml",
          "application/xml; schema=mets",
          "application/xml; schema=mods",
          "application/xml; schema=pbcore",
          "application/json; charset=ISO-8859-1"
        ]
        (ignore_list & Array.wrap(mime_type)).empty?
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

    def work_presenters
      @work_presenters ||=
        begin
          output = super
          output.presence || FalseEmpty.new
        end
    end

    class FalseEmpty < Array
      def empty?
        false
      end
    end

    # Attempt to delegate the description to the CollectionDecorator
    # @return [String]
    def description
      decorate.try(:description)
    end

    # Collections should not have viewing hints
    # @return [nil]
    def viewing_hint; end

    def collection?
      true
    end
  end

  class EphemeraProjectNode < CollectionNode
    def members
      @members ||= query_service.custom_queries.find_project_folders(resource: resource).to_a
    end
  end

  class EphemeraFolderNode < RootNode
    def to_s
      (resource.title + resource.transliterated_title).map(&:to_s)
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
      @members ||= manifestable_members.map do |member|
        decorator = member.decorate
        if decorator.respond_to?(:decorated_scanned_maps) && decorator.decorated_scanned_maps.empty?
          member.decorate.geo_members.first
        else
          member
        end
      end.compact
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

  ##
  # Presenter modeling the top node of nested structure resource trees
  class TopStructure
    attr_reader :structure, :resource

    ##
    # @param [Hash] structure the top structure node
    def initialize(structure, resource = nil)
      @structure = structure
      @resource = resource
    end

    ##
    # Retrieve the label for the Structure. If it's RTL return it as an RDF
    # Literal
    # @return [String, RDF::Literal]
    def label
      return structure_label unless structure_label.dir == "rtl"
      return structure_label unless resource&.decorate&.imported_attribute(:language)
      RDF::Literal.new(structure_label, language: resource.decorate.imported_attribute(:language).first)
    end

    ##
    # Retrieve the ranges (sc:Range) for this structure
    # @return [TopStructure]
    def ranges
      @ranges ||= structure.nodes.select { |x| x.proxy.blank? }.map do |node|
        TopStructure.new(node, resource)
      end
    end

    # Retrieve the IIIF Manifest nodes for FileSet resources
    # @return [LeafStructureNode]
    def file_set_presenters
      @file_set_presenters ||= structure.nodes.select { |x| x.proxy.present? }.map do |node|
        LeafStructureNode.new(node)
      end
    end

    def structure_label
      structure.label.to_sentence
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
    def self.for(resource, parent_node)
      # If it's a PDF we need to render every page.
      if resource.mime_type&.include?("application/pdf") && resource.derivative_partial_files.present?
        resource.derivative_partial_files.map do |pdf_page|
          new(resource, parent_node, pdf_page)
        end
      else
        new(resource, parent_node, resource.primary_file)
      end
    end

    attr_reader :resource, :parent_node, :file
    delegate :query_service, to: :metadata_adapter
    ##
    # @param [Resource] resource a FileSet resource featured in the IIIF Manifest
    # @param [RootNode] parent_node the node for the parent Work for the FileSet
    def initialize(resource, parent_node, file)
      @resource = resource
      @parent_node = parent_node
      @file = file
    end

    delegate :local_identifier, :viewing_hint, :ocr_content, :to_model, to: :resource

    def id
      resource.id.to_s
    end

    ##
    # Stringify the image using the decorator
    # @return [String]
    def to_s
      if resource.primary_file == file
        Valkyrie::ResourceDecorator.new(resource).header
      else
        file.label.first.to_s
      end
    end

    ##
    # Retrieve an instance of the IIIFManifest::DisplayImage for the image
    # @return [IIIFManifest::DisplayImage]
    def display_image
      return if file.av?
      @display_image ||= IIIFManifest::DisplayImage.new(display_image_url,
                                                        width: width.to_i,
                                                        height: height.to_i,
                                                        format: "image/jpeg",
                                                        iiif_endpoint: endpoint)
    end

    def display_image_url
      helper.manifest_image_medium_path(resource, file)
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
      # Retrieve an instance of the IIIFManifest::IIIFEndpoint for the service endpoint
      # @return [IIIFManifest::IIIFEndpoint]
      def endpoint
        return unless resource.derivative_file || resource.derivative_partial_files.present?
        IIIFManifest::IIIFEndpoint.new(helper.manifest_image_path(resource, file),
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
        "#{protocol}://#{host}/concern/#{resource.model_name.collection}/#{resource.id}/manifest"
      end
    end

    def token_authorizable?(resource)
      resource.respond_to?(:auth_token) && !resource.auth_token.nil?
    end

    def pdf_url(resource)
      url = Rails.application.routes.url_helpers.pdf_url(resource)
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
    def manifest_image_path(resource, file_metadata = nil)
      if (Rails.env.development? && Figgy.config["pyramidals_bucket"].blank?) || Rails.env.test?
        RiiifHelper.new.base_url("#{resource.id}~#{file_metadata&.id || resource.pyramidal_derivative&.id}")
      else
        PyramidalHelper.new.base_url(resource, file_metadata)
      end
    end

    ##
    # Retrieve the URL path for an image served over the Riiif
    # @param [FileSet] resource A FileSet to generate a
    #   thumbnail URL from.
    # @return [String]
    def manifest_image_thumbnail_path(resource, file_metadata = nil)
      "#{manifest_image_path(resource, file_metadata)}/full/!200,150/0/default.jpg"
    end

    def manifest_image_medium_path(resource, file_metadata = nil)
      "#{manifest_image_path(resource, file_metadata)}/full/1000,/0/default.jpg"
    end
  end

  # Returns the URL for pyramidal objects stored in S3.
  class PyramidalHelper
    def base_url(file_set, file_metadata = nil)
      file_metadata ||= file_set.pyramidal_derivative
      raise Valkyrie::Persistence::ObjectNotFoundError, file_set.id if file_metadata.nil?
      begin
        file = file_metadata.file_identifiers[0].to_s.gsub(/^.*:\/\//, "")
        id = file.gsub(Figgy.config["pyramidal_derivative_path"], "").gsub(/^\//, "").gsub(".tif", "")
        Pathname.new(Figgy.config["pyramidal_url"]).join(
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
      @manifest ||= if av_collection? || av?
                      IIIFManifest::V3::ManifestFactory.new(@resource, manifest_service_locator: ManifestBuilderV3::ManifestServiceLocator).to_h
                    # If not multi-part and a collection, it's not a MVW
                    elsif @resource.viewing_hint.blank? && @resource.collection?
                      IIIFManifest::ManifestFactory.new(@resource, manifest_service_locator: CollectionManifestServiceLocator).to_h
                    else
                      # NOTE: this assumes audio resources use flat modeling
                      IIIFManifest::ManifestFactory.new(@resource, manifest_service_locator: ManifestServiceLocator).to_h
                    end
    end

    # resource is a RootNode.
    def av?
      return true if resource.resource.is_a?(Playlist)
      # Skip check if it's a Collection node, for performance.
      return false if resource.try(:collection?)

      file_sets = Array.wrap(resource.try(:leaf_nodes))
      av_file_sets = file_sets.select(&:av?)

      !av_file_sets.empty?
    end

    def av_collection?
      return false unless @resource.resource.respond_to?(:change_set)

      ChangeSet.for(@resource.resource).is_a?(ArchivalMediaCollectionChangeSet)
    end
end
