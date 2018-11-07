# frozen_string_literal: true
class NumismaticIssue < Resource
  include Valkyrie::Resource::AccessControls
  attribute :member_ids, Valkyrie::Types::Array
  attribute :member_of_collection_ids

  # descriptive metadata
  attribute :artist
  attribute :color
  attribute :date_object
  attribute :date_range
  attribute :denomination
  attribute :department
  attribute :description
  attribute :edge
  attribute :era
  attribute :geographic_origin
  attribute :issue_number, Valkyrie::Types::Anything
  attribute :master
  attribute :metal
  attribute :note
  attribute :object_type
  attribute :obverse_attributes
  attribute :obverse_figure
  attribute :obverse_figure_description
  attribute :obverse_figure_relationship
  attribute :obverse_legend, Valkyrie::Types::SingleValuedString
  attribute :obverse_orientation
  attribute :obverse_part
  attribute :obverse_symbol
  attribute :place
  attribute :reverse_attributes
  attribute :reverse_figure
  attribute :reverse_figure_description
  attribute :reverse_figure_relationship
  attribute :reverse_legend, Valkyrie::Types::SingleValuedString
  attribute :reverse_orientation
  attribute :reverse_part
  attribute :reverse_symbol
  attribute :ruler
  attribute :series
  attribute :shape
  attribute :subject
  attribute :workshop, Valkyrie::Types::SingleValuedString

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

  def self.can_have_manifests?
    true
  end

  # Placeholder title.
  # TODO: Add more descriptive title when we have more information.
  def title
    ["Issue: #{issue_number}"]
  end
end
