# frozen_string_literal: true
class ScannedResourceChangeSet < ChangeSet
  apply_workflow(BookWorkflow)
  enable_claiming
  delegate :human_readable_type, to: :model

  include VisibilityProperty
  include RemoteMetadataProperty
  property :title, multiple: true, required: true, default: []
  property :source_metadata_identifier, required: true, multiple: false
  property :downloadable, multiple: false, require: true, default: "public"
  property :rights_statement, multiple: false, required: true, default: RightsStatements.no_known_copyright, type: ::Types::URI
  property :rights_note, multiple: false, required: false
  property :viewing_hint, multiple: false, required: false, default: "individuals"
  property :pdf_type, multiple: false, required: false, default: "color"
  property :holding_location, multiple: false, required: false, type: ::Types::URI
  property :location, multiple: true, required: false, default: []
  property :viewing_direction, multiple: false, required: false
  property :portion_note, multiple: false, required: false
  property :nav_date, multiple: false, required: false
  property :local_identifier, multiple: true, required: false, default: []
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
  property :thumbnail_id, multiple: false, required: false, type: Valkyrie::Types::ID.optional
  property :start_canvas, multiple: false, type: Valkyrie::Types::ID.optional
  property :member_of_collection_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
  property :append_collection_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID), virtual: true
  property :logical_structure, multiple: true, required: false, type: Types::Strict::Array.of(Structure), default: [Structure.new(label: "Logical", nodes: [])]
  property :read_groups, multiple: true, required: false
  property :file_metadata, multiple: true, required: false, default: []
  property :depositor, multiple: false, require: false
  property :ocr_language, multiple: true, require: false, default: []
  property :replaces, multiple: true, require: false
  property :identifier, multiple: false, require: false
  property :series, multiple: true, required: false
  property :embargo_date, multiple: false, required: false, type: Valkyrie::Types::String.optional

  # MARCRelator attributes
  Schema::MARCRelators.attributes.each { |field| property field }

  # Virtual Attributes
  property :files, virtual: true, multiple: true, required: false
  property :pending_uploads, multiple: true, required: false
  property :tombstone_restore_ids, virtual: true, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID), default: []

  validates_with StateValidator
  validates_with ViewingDirectionValidator
  validates_with ViewingHintValidator
  validates_with SourceMetadataIdentifierValidator
  validates_with SourceMetadataIdentifierOrTitleValidator
  validates_with MemberValidator
  validates_with CollectionValidator
  validates_with RightsStatementValidator
  validates_with EmbargoDateValidator
  validates :visibility, presence: true

  # filters out structure nodes that proxy deleted resources
  def logical_structure
    logical_order = (Array(fields["logical_structure"] || resource.logical_structure).first || Structure.new)
    members = Wayfinder.for(resource).members_with_parents
    structure_with_proxies = WithProxyForObject.new(logical_order, members)
    logical_order.nodes = recursive_structure_node_delete(structure_with_proxies.nodes)
    Array(logical_order)
  end

  def primary_terms
    [
      :title,
      :source_metadata_identifier,
      :member_of_collection_ids,
      :rights_statement,
      :rights_note,
      :local_identifier,
      :holding_location,
      :pdf_type,
      :downloadable,
      :ocr_language,
      :portion_note,
      :nav_date,
      :append_id,
      :embargo_date
    ]
  end

  private

    def recursive_structure_node_delete(nodes)
      nodes.map do |node|
        if node.proxy.present? && node.proxy_for_object.nil?
          nil
        elsif node.nodes.present?
          node.nodes = recursive_structure_node_delete(node.nodes)
          node
        else
          node
        end
      end.compact
    end
end
