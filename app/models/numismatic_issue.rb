# frozen_string_literal: true
class NumismaticIssue < Resource
  include Valkyrie::Resource::AccessControls
  attribute :member_ids, Valkyrie::Types::Array

  # descriptive metadata
  attribute :object_type
  attribute :denomination
  attribute :metal
  attribute :geographic_origin
  attribute :workshop, Valkyrie::Types::SingleValuedString
  attribute :ruler
  attribute :date_range
  attribute :obverse_type, Valkyrie::Types::SingleValuedString
  attribute :obverse_legend, Valkyrie::Types::SingleValuedString
  attribute :obverse_attributes
  attribute :reverse_type, Valkyrie::Types::SingleValuedString
  attribute :reverse_legend, Valkyrie::Types::SingleValuedString
  attribute :reverse_attributes
  attribute :master
  attribute :description
  attribute :references
  attribute :artist
  attribute :color
  attribute :department
  attribute :edge
  attribute :era
  attribute :figure
  attribute :note
  attribute :orientation
  attribute :part
  attribute :place
  attribute :series
  attribute :shape
  attribute :subject
  attribute :symbol

  # adminstrative metadata
  attribute :depositor
  attribute :identifier
  attribute :replaces
  attribute :rights_statement
  attribute :rights_note, Valkyrie::Types::Set
  attribute :state
  attribute :visibility
  attribute :workflow_note, Valkyrie::Types::Array.of(WorkflowNote).optional

  # for ark minting
  def title
    denomination
  end
end
