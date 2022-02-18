# frozen_string_literal: true

module CDL
  class ResourceChargeListChangeSet < Valkyrie::ChangeSet
    property :charged_items
    property :hold_queue
    property :optimistic_lock_token,
      multiple: true,
      required: true,
      type: Valkyrie::Types::Set.of(Valkyrie::Types::OptimisticLockToken)
  end
end
