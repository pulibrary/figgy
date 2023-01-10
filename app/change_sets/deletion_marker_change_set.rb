# frozen_string_literal: true

class DeletionMarkerChangeSet < ChangeSet
  property :resource_id
  property :resource_title
  property :original_filename
  property :preservation_object
  property :parent_id
  property :optimistic_lock_token,
            multiple: true,
            required: true,
            type: Valkyrie::Types::Set.of(Valkyrie::Types::OptimisticLockToken)

  def preserve?
    false
  end
end
