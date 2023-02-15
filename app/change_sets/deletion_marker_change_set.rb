# frozen_string_literal: true

class DeletionMarkerChangeSet < ChangeSet
  property :resource_title
  property :resource_type
  property :resource_identifier
  property :resource_source_metadata_identifier
  property :resource_local_identifier
  property :resource_id
  property :original_filename
  property :deleted_object
  property :preservation_object
  property :parent_id
  property :depositor, multiple: false, require: false
  property :optimistic_lock_token,
            multiple: true,
            required: true,
            type: Valkyrie::Types::Set.of(Valkyrie::Types::OptimisticLockToken)

  def preserve?
    false
  end
end
