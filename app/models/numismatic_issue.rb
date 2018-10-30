# frozen_string_literal: true
class NumismaticIssue < Resource
  include Valkyrie::Resource::AccessControls
  attribute :member_ids, Valkyrie::Types::Array
  attribute :member_of_collection_ids

  # descriptive metadata
  attribute :artist
  attribute :color
  attribute :date_range
  attribute :denomination
  attribute :department
  attribute :description
  attribute :edge
  attribute :era
  attribute :figure
  attribute :geographic_origin
  attribute :master
  attribute :metal
  attribute :note
  attribute :object_type
  attribute :obverse_attributes
  attribute :obverse_legend, Valkyrie::Types::SingleValuedString
  attribute :obverse_type, Valkyrie::Types::SingleValuedString
  attribute :orientation
  attribute :part
  attribute :place
  attribute :references
  attribute :reverse_attributes
  attribute :reverse_legend, Valkyrie::Types::SingleValuedString
  attribute :reverse_type, Valkyrie::Types::SingleValuedString
  attribute :ruler
  attribute :series
  attribute :shape
  attribute :subject
  attribute :symbol
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

  # Placeholder title.
  # TODO: Add more descriptive title when we have more information.
  def title
    ["Issue: #{id}"]
  end
end
