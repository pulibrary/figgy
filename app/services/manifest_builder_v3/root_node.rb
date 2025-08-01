# frozen_string_literal: true
class ManifestBuilderV3
  # Presenter modeling the Resource subjects as root nodes
  class RootNode
    def self.multi_volume_recording?(resource)
      decorated = resource.decorate
      return unless decorated.respond_to?(:volumes) && !decorated.volumes.empty?

      volumes = decorated.volumes
      volume_file_sets = volumes.map(&:file_sets)
      volume_file_sets.flatten!
      av_file_sets = volume_file_sets.select(&:av?)
      !av_file_sets.empty?
    end

    def self.for(resource, auth_token = nil, current_ability = nil, downloadable = nil)
      case resource
      when Collection
        case ChangeSet.for(resource)
        when ArchivalMediaCollectionChangeSet
          ArchivalMediaCollectionNode.new(resource, auth_token, current_ability, downloadable)
        end
      when ScannedMap
        ScannedMapNode.new(resource, auth_token, current_ability, downloadable)
      when Playlist
        PlaylistNode.new(resource, auth_token, current_ability, downloadable)
      else
        case ChangeSet.for(resource)
        when RecordingChangeSet
          if multi_volume_recording?(resource)
            MultiVolumeRecordingNode.new(resource, auth_token, current_ability, downloadable)
          else
            RecordingNode.new(resource, auth_token, current_ability, downloadable)
          end
        else
          new(resource, auth_token, current_ability, downloadable)
        end
      end
    end
    attr_reader :resource, :auth_token, :current_ability, :downloadable
    attr_accessor :child_of
    delegate :decorate, :to_model, :id, to: :resource

    def source_metadata_identifier
      resource.try(:source_metadata_identifier)
    end

    ##
    # @param [Resource] resource the Resource being modeled as the root
    def initialize(resource, auth_token = nil, current_ability = nil, downloadable = nil)
      @resource = resource
      @auth_token = auth_token
      @current_ability = current_ability
      @downloadable = downloadable || resource.decorate.try(:downloadable?)
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
        RootNode.for(node, nil, nil, downloadable)
      end
    end

    ##
    # Retrieves the presenters for each member FileSet as a leaf
    # @return [LeafNode]
    def file_set_presenters
      @file_set_presenters ||= leaf_nodes.map do |node|
        LeafNode.new(node, self, downloadable)
      end
    end

    ##
    # Retrieves the presenter for each Range (sc:Range) instance
    # @return [TopStructure]
    def ranges
      return av_ranges if av_manifest?
      logical_structure.map do |top_structure|
        TopStructure.new(top_structure)
      end
    end

    def av_manifest?
      work_presenter_nodes = Array.wrap(work_presenters)
      work_presenters = work_presenter_nodes.select(&:av_manifest?)

      !av_file_sets.empty? || !work_presenters.empty?
    end

    def av_file_sets
      @av_file_sets ||= file_set_presenters.select do |fs_presenter|
        fs_presenter.display_content.present?
      end
    end

    def av_ranges
      return default_av_ranges if logical_structure.blank? || logical_structure.flat_map(&:nodes).blank?
      logical_structure.flat_map do |top_structure|
        top_structure.nodes.map do |node|
          TopStructure.new(wrap_proxies(node))
        end
      end
    end

    def wrap_proxies(node)
      # If it's a folder for the canvas, then make it a structure node and wrap
      # its children.
      if node.proxy.blank?
        StructureNode.new(
          id: node.id,
          label: node.label,
          nodes: node.nodes.map { |x| wrap_proxies(x) }
        )
      else
        # If it's a node for a canvas, create a structure node to wrap it so it
        # shows up in the table of contents.
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

    def default_av_ranges
      file_set_presenters.map do |file_set|
        TopStructure.new(
          Structure.new(
            label: file_set.label,
            nodes: StructureNode.new(
              label: file_set.label,
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
      return [] if av_manifest?
      [
        {
          "@id" => helper.pdf_url(resource),
          "type" => "Text",
          "label": { "en": ["Download as PDF"] },
          "format" => "application/pdf"
        }
      ]
    end

    # Retrieve the child members for the subject resource of the Manifest
    # @return [Resource]
    def members
      @members ||=
        Wayfinder.for(@resource).members.to_a.select do |member|
          !current_ability || current_ability.can?(:read, member)
        end
    end

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
      # Retrieve the TopStructure for the resource manifest
      def logical_structure
        resource.try(:logical_structure) || []
      end
  end

  class ArchivalMediaCollectionNode < RootNode
    def members
      return @members unless @members.nil?

      member_nodes = super
      nodes = member_nodes
      nodes += member_nodes.map { |child| child.decorate.members }.flatten
      @members = nodes
    end

    def file_sets
      return @file_sets unless @file_sets.nil?

      leaves = members.map { |child| child.decorate.members }.flatten
      @file_sets = leaves.select { |x| x.instance_of?(FileSet) && !x.image? }
    end

    ##
    # Retrieve the leaf nodes for the Manifest
    # @return [FileSet]
    def leaf_nodes
      @leaf_nodes ||= file_sets.select { |x| leaf_node_mime_type?(x.mime_type) }
    end
  end

  class MultiVolumeRecordingNode < RootNode
    def child_members
      @child_members ||= members.map { |child| child.decorate.members }.flatten
    end

    def file_sets
      @file_sets ||= child_members.select { |x| x.instance_of?(FileSet) && !x.image? }
    end

    def leaf_nodes
      @leaf_nodes ||= file_sets.select { |x| leaf_node_mime_type?(x.mime_type) }
    end

    def default_av_ranges
      members.map do |member|
        av_file_sets = member.decorate.file_sets.select(&:av?)
        nodes = av_file_sets.map do |file_set|
          Structure.new(
            label: file_set.title,
            nodes: [
              StructureNode.new(
                label: IIIFManifest::V3::ManifestBuilder.language_map(file_set.title),
                proxy: file_set.id
              )
            ]
          )
        end

        TopStructure.new(
          Structure.new(
            label: member.title,
            nodes: nodes
          )
        )
      end
    end
  end

  class RecordingNode < RootNode
    def leaf_nodes
      @leaf_nodes ||= super.select(&:av?)
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
        next unless node.decorate.av?

        LeafNode.new(node, self, downloadable)
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
end
