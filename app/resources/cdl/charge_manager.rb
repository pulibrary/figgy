# frozen_string_literal: true

# Controlled Digital Lending
module CDL
  class UnavailableForCharge < StandardError; end
  class ChargeManager
    include ActionView::Helpers::DateHelper
    attr_reader :resource_id, :eligible_item_service, :change_set_persister
    delegate :charged_items, to: :resource_charge_list
    # TODO: default eligible_item_service from #4033
    def initialize(resource_id:, eligible_item_service:, change_set_persister:)
      @resource_id = resource_id
      @eligible_item_service = eligible_item_service
      @change_set_persister = change_set_persister
      clear_expired_charges
    end

    def eligible?
      item_ids.present?
    end

    def clear_expired_charges
      resource_charge_list.charged_items = resource_charge_list.charged_items.reject(&:expired?)
    end

    def available_for_charge?(netid: nil)
      return false unless eligible?
      return true if charged_item_count < item_ids.count && active_hold?(netid: netid)
      (charged_item_count + held_item_count) < item_ids.count
    end

    def active_hold?(netid:)
      resource_charge_list.hold_queue.find do |hold|
        hold.active? && !hold.expired? && hold.netid == netid
      end.present?
    end

    def charged_item_count
      resource_charge_list.charged_items.count
    end

    def held_item_count
      resource_charge_list.pending_or_active_holds.count
    end

    def estimated_wait_time
      return if available_for_charge?
      earliest = charged_items.flat_map(&:expiration_time).sort.first
      distance_of_time_in_words(Time.current - earliest)
    end

    def create_charge(netid:)
      raise CDL::UnavailableForCharge unless available_for_charge?(netid: netid)
      charge = CDL::ChargedItem.new(item_id: available_item_id, netid: netid, expiration_time: Time.current + 3.hours)
      change_set = CDL::ResourceChargeListChangeSet.new(resource_charge_list)
      updated_hold_queue = resource_charge_list.hold_queue.reject do |hold|
        hold.netid == netid
      end
      change_set.validate(charged_items: resource_charge_list.charged_items + [charge], hold_queue: updated_hold_queue)
      change_set_persister.save(change_set: change_set)
      CDL::EventLogging.google_charge_event(netid: netid, source_metadata_identifier: resource.try(:source_metadata_identifier)&.first)
      charge
    end

    def available_item_id
      (item_ids - resource_charge_list.charged_items.map(&:item_id)).first
    end

    def item_ids
      eligible_item_service.item_ids(source_metadata_identifier: resource.try(:source_metadata_identifier)&.first)
    end

    def resource_charge_list
      @resource_charge_list ||= Wayfinder.for(resource).resource_charge_list || build_resource_charge
    end

    def build_resource_charge
      CDL::ResourceChargeList.new(
        resource_id: resource.id
      )
    end

    def resource
      @resource ||= query_service.find_by(id: resource_id)
    end

    def query_service
      change_set_persister.metadata_adapter.query_service
    end
  end
end
