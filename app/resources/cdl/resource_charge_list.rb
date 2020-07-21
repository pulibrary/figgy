# frozen_string_literal: true

# Controlled Digital Lending
module CDL
  class ResourceChargeList < Valkyrie::Resource
    attribute :resource_id, Valkyrie::Types::ID
    attribute :charged_items, Valkyrie::Types::Set.of(CDL::ChargedItem)
    attribute :hold_queue, Valkyrie::Types::Set.of(CDL::Hold)

    def clear_expired_charges!
      self.charged_items = charged_items.reject(&:expired?)
    end

    # Hold Queries

    def active_hold?(netid:)
      hold_queue.find do |hold|
        hold.active? && !hold.expired? && hold.netid == netid
      end.present?
    end

    def hold?(netid:)
      hold_queue.find do |hold|
        hold.netid == netid && !hold.expired?
      end.present?
    end

    def pending_or_active_holds
      hold_queue.reject do |hold|
        hold.active? && hold.expired?
      end
    end

    def pending_holds
      hold_queue.select do |hold|
        !hold.active?
      end
    end

    def expired_holds
      hold_queue.select(&:expired?)
    end

    def active_holds
      hold_queue.select do |hold|
        hold.active? && !hold.expired?
      end
    end
  end
end
