# frozen_string_literal: true

class TombstoneChangeSet < ChangeSet
  property :file_set_id
  property :file_set_title
  property :file_set_original_filename
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
