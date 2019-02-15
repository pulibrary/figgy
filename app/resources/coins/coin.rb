# frozen_string_literal: true
# A physical coin in our collections, modeling things that are unique to the physical item, such as its
# weight, purchase/acquisition, where it was found, etc.
class Coin < Resource
  include Valkyrie::Resource::AccessControls
  attribute :member_ids, Valkyrie::Types::Array
  attribute :member_of_collection_ids
  attribute :numismatic_citation_ids, Valkyrie::Types::Array

  # descriptive metadata
  attribute :coin_number, Valkyrie::Types::Anything
  attribute :number_in_accession, Valkyrie::Types::Integer
  attribute :holding_location
  attribute :counter_stamp
  attribute :analysis
  attribute :public_note
  attribute :private_note
  attribute :find_date
  attribute :find_feature
  attribute :find_locus
  attribute :find_description
  attribute :accession_number
  attribute :provenance
  attribute :die_axis
  attribute :append_id
  attribute :loan
  attribute :size
  attribute :technique
  attribute :weight
  attribute :find_number
  attribute :find_place
  attribute :numismatic_collection

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
