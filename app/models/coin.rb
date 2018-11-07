# frozen_string_literal: true
class Coin < Resource
  include Valkyrie::Resource::AccessControls
  attribute :member_ids, Valkyrie::Types::Array
  attribute :numismatic_citation_ids, Valkyrie::Types::Array

  # descriptive metadata
  attribute :accession
  attribute :analysis
  attribute :coin_number, Valkyrie::Types::Anything
  attribute :counter_stamp
  attribute :department
  attribute :die_axis
  attribute :find
  attribute :find_date
  attribute :find_description
  attribute :find_feature
  attribute :find_locus
  attribute :find_number
  attribute :find_place
  attribute :holding_location
  attribute :loan
  attribute :object_type
  attribute :place
  attribute :private_note
  attribute :provenance
  attribute :size
  attribute :technique
  attribute :weight

  # administrative metadata
  attribute :depositor
  attribute :replaces
  attribute :state
  attribute :thumbnail_id
  attribute :title
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
    ["Coin: #{coin_number}"]
  end
end
