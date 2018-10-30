# frozen_string_literal: true
class Coin < Resource
  include Valkyrie::Resource::AccessControls
  attribute :member_ids, Valkyrie::Types::Array

  # descriptive metadata
  attribute :department
  attribute :size
  attribute :die_axis
  attribute :weight
  attribute :references
  attribute :accession
  attribute :analysis
  attribute :counter_stamp
  attribute :find
  attribute :find_date
  attribute :holding_location
  attribute :loan
  attribute :object_type
  attribute :place
  attribute :private_note
  attribute :provenance
  attribute :technique

  # administrative metadata
  attribute :depositor
  attribute :replaces
  attribute :state
  attribute :visibility
  attribute :workflow_note, Valkyrie::Types::Array.of(WorkflowNote).optional
  attribute :pending_uploads, Valkyrie::Types::Array.of(PendingUpload)
end
