# frozen_string_literal: true

# Controlled Digital Lending
module CDL
  class UnavailableForCharge < StandardError; end
  class ChargeManager
    attr_reader :resource_id, :eligible_item_service, :change_set_persister
    # TODO: default eligible_item_service from #4033
    def initialize(resource_id:, eligible_item_service:, change_set_persister:)
      @resource_id = resource_id
      @eligible_item_service = eligible_item_service
      @change_set_persister = change_set_persister
      clear_expired_charges
    end

    def clear_expired_charges
      resource_charge_list.charged_items = resource_charge_list.charged_items.reject(&:expired?)
    end

    def available_for_charge?
      return false unless item_ids.present?
      resource_charge_list.charged_items.count < item_ids.count
    end

    def create_charge(netid:)
      raise CDL::UnavailableForCharge unless available_for_charge?
      charge = CDL::ChargedItem.new(item_id: available_item_id, netid: netid, expiration_time: Time.current + 3.hours)
      change_set = CDL::ResourceChargeListChangeSet.new(resource_charge_list)
      change_set.validate(charged_items: resource_charge_list.charged_items + [charge])
      change_set_persister.save(change_set: change_set)
      charge
    end

    def available_item_id
      (item_ids - resource_charge_list.charged_items.map(&:item_id)).first
    end

    def item_ids
      eligible_item_service.item_ids(source_metadata_identifier: resource.source_metadata_identifier&.first)
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
