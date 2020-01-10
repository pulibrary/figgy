# frozen_string_literal: true
# An abstraction of coins that were minted at the same time, similar to an edition of a book.  Includes
# metadata about properties that are shared between all coins that are minted together, such as their place
# of origin, denomination, composition, design, creator, etc.
module Numismatics
  class Issue < Resource
    include Valkyrie::Resource::AccessControls

    # resources linked by ID
    attribute :member_ids, Valkyrie::Types::Array
    attribute :member_of_collection_ids
    attribute :numismatic_monogram_ids
    attribute :numismatic_place_id
    attribute :ruler_id
    attribute :master_id

    # nested resources
    attribute :numismatic_artist, Valkyrie::Types::Array.of(Numismatics::Artist).meta(ordered: true)
    attribute :numismatic_citation, Valkyrie::Types::Array.of(Numismatics::Citation).meta(ordered: true)
    attribute :numismatic_note, Valkyrie::Types::Array.of(Numismatics::Note).meta(ordered: true)
    attribute :numismatic_subject, Valkyrie::Types::Array.of(Numismatics::Subject).meta(ordered: true)
    attribute :obverse_attribute, Valkyrie::Types::Array.of(Numismatics::Attribute).meta(ordered: true)
    attribute :reverse_attribute, Valkyrie::Types::Array.of(Numismatics::Attribute).meta(ordered: true)

    # descriptive metadata
    attribute :ce1
    attribute :ce2
    attribute :color
    attribute :denomination
    attribute :edge
    attribute :era
    attribute :issue_number, Valkyrie::Types::Anything
    attribute :metal
    attribute :object_date
    attribute :object_type
    attribute :obverse_figure
    attribute :obverse_figure_description
    attribute :obverse_figure_relationship
    attribute :obverse_legend
    attribute :obverse_orientation
    attribute :obverse_part
    attribute :obverse_symbol
    attribute :reverse_figure
    attribute :reverse_figure_description
    attribute :reverse_figure_relationship
    attribute :reverse_legend
    attribute :reverse_orientation
    attribute :reverse_part
    attribute :reverse_symbol
    attribute :series
    attribute :shape
    attribute :workshop

    # adminstrative metadata
    attribute :depositor
    attribute :identifier
    attribute :replaces
    attribute :rights_statement
    attribute :rights_note, Valkyrie::Types::Set
    attribute :state
    attribute :thumbnail_id
    attribute :visibility
    attribute :workflow_note, Valkyrie::Types::Array.of(WorkflowNote).optional
    attribute :pending_uploads, Valkyrie::Types::Array.of(PendingUpload)

    # manifest metadata
    attribute :start_canvas
    attribute :viewing_direction
    attribute :viewing_hint
    attribute :downloadable

    def self.can_have_manifests?
      true
    end

    def title
      ["Issue: #{issue_number}"]
    end

    def title_display
      title&.join
    end
  end
end
