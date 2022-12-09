# frozen_string_literal: true
class EventChangeSet < ChangeSet
  property :type, multiple: false, required: true
  property :status, multiple: false, required: true
  property :resource_id, multiple: false, type: Valkyrie::Types::ID
  property :child_property, multiple: false
  property :child_id, multiple: false, type: Valkyrie::Types::ID
  property :message, multiple: false, required: true
  property :optimistic_lock_token,
            multiple: true,
            required: true,
            type: Valkyrie::Types::Set.of(Valkyrie::Types::OptimisticLockToken)

  def preserve?
    false
  end
end
