# frozen_string_literal: true

module CDL
  class ResourceChargeListChangeSet < Valkyrie::ChangeSet
    property :charged_items
    property :hold_queue
  end
end
