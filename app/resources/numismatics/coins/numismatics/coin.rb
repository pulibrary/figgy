# frozen_string_literal: true
# A physical coin in our collections, modeling things that are unique to the physical item, such as its
# weight, purchase/acquisition, where it was found, etc.
module Numismatics
  class Coin < Resource
    include Valkyrie::Resource::AccessControls

    # resources linked by ID
    attribute :member_ids, Valkyrie::Types::Array
    attribute :member_of_collection_ids
    attribute :numismatic_accession_id
    attribute :find_place_id

    # nested resources
    attribute :numismatic_citation, Valkyrie::Types::Array.of(Numismatics::Citation).meta(ordered: true)
    attribute :loan, Valkyrie::Types::Array.of(Numismatics::Loan).meta(ordered: true)
    attribute :provenance, Valkyrie::Types::Array.of(Numismatics::Provenance).meta(ordered: true)

    # descriptive metadata
    attribute :coin_number, Valkyrie::Types::Anything
    attribute :number_in_accession, Valkyrie::Types::Integer
    attribute :counter_stamp
    attribute :analysis
    attribute :public_note
    attribute :private_note
    attribute :find_date
    attribute :find_feature
    attribute :find_locus
    attribute :find_description
    attribute :die_axis
    attribute :append_id
    attribute :size
    attribute :technique
    attribute :weight
    attribute :find_number
    attribute :numismatic_collection
    attribute :rights_statement

    # administrative metadata
    attribute :depositor
    attribute :replaces
    attribute :state
    attribute :thumbnail_id
    attribute :title
    attribute :visibility
    attribute :workflow_note, Valkyrie::Types::Array.of(WorkflowNote).optional
    attribute :pending_uploads, Valkyrie::Types::Array.of(PendingUpload)
    attribute :pdf_type
    attribute :file_metadata, Valkyrie::Types::Set.of(FileMetadata.optional)
    attribute :identifier
    attribute :claimed_by, Valkyrie::Types::String
    attribute :cached_parent_id, Valkyrie::Types::ID

    # manifest metadata
    attribute :start_canvas
    attribute :viewing_direction
    attribute :viewing_hint
    attribute :downloadable

    def self.can_have_manifests?
      true
    end

    # Determines whether or not the "Save and Duplicate Metadata" is supported for this Resource
    # @return [Boolean]
    def self.supports_save_and_duplicate?
      true
    end

    # Placeholder title.
    # TODO: Add more descriptive title when we have more information.
    def title
      ["Coin: #{coin_number}"]
    end

    def pdf_file
      file_metadata.find do |file|
        file.mime_type == ["application/pdf"]
      end
    end
  end
end
