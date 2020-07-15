# frozen_string_literal: true

# Controlled Digital Lending
module CDL
  class ResourceChargeList < Valkyrie::Resource
    attribute :resource_id, Valkyrie::Types::ID
    attribute :charged_items, Valkyrie::Types::Set.of(CDL::ChargedItem)
    attribute :hold_queue, Valkyrie::Types::Set.of(CDL::Hold)

    def pending_or_active_holds
      hold_queue.reject do |hold|
        hold.active? && hold.expired?
      end
    end
  end
end
