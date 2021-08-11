# frozen_string_literal: true

# Controlled Digital Lending
module CDL
  class UnavailableForCharge < StandardError; end
  class HoldExists < StandardError; end
  class NotCharged < StandardError; end
  class ChargeManager
    include ActionView::Helpers::DateHelper
    attr_reader :resource_id, :eligible_item_service, :change_set_persister
    attr_writer :resource_charge_list
    delegate :charged_items, :pending_or_active_holds, :active_hold?, :hold?, :expired_holds, to: :resource_charge_list
    # TODO: default eligible_item_service from #4033
    def initialize(resource_id:, eligible_item_service:, change_set_persister:)
      @resource_id = resource_id
      @eligible_item_service = eligible_item_service
      @change_set_persister = change_set_persister
      resource_charge_list.clear_expired_charges!
    end

    def eligible?
      @eligible ||= item_ids.present?
    end

    def available_for_charge?(netid: nil)
      return false unless eligible?
      return true if available_charge_slot? && active_hold?(netid: netid)
      (charged_items.count + pending_or_active_holds.count) < item_ids.count
    end

    def available_charge_slot?
      charged_items.count < item_ids.count
    end

    def hold_index(netid:)
      pending_or_active_holds.index do |hold|
        hold.netid == netid
      end
    end

    def create_charge(netid:)
      raise CDL::UnavailableForCharge unless available_for_charge?(netid: netid)
      charge = CDL::ChargedItem.new(item_id: available_item_ids.first, netid: netid, expiration_time: Time.current + 3.hours)
      change_set = CDL::ResourceChargeListChangeSet.new(resource_charge_list)
      updated_hold_queue = resource_charge_list.hold_queue.reject do |hold|
        hold.netid == netid
      end
      change_set.validate(charged_items: resource_charge_list.charged_items + [charge], hold_queue: updated_hold_queue)
      change_set_persister.save(change_set: change_set)
      if change_set.changed["hold_queue"]
        CDL::EventLogging.google_hold_charged_event(netid: netid, source_metadata_identifier: source_metadata_identifier)
      else
        CDL::EventLogging.google_charge_event(netid: netid, source_metadata_identifier: source_metadata_identifier)
      end
      charge
    end

    def return(netid:)
      raise CDL::NotCharged unless resource_charge_list.active_charge?(netid: netid)
      change_set = CDL::ResourceChargeListChangeSet.new(resource_charge_list)
      new_charged_items = resource_charge_list.charged_items.reject { |i| i.netid == netid }
      change_set.validate(charged_items: new_charged_items)
      change_set_persister.save(change_set: change_set)
      true
    end

    def source_metadata_identifier
      resource.try(:source_metadata_identifier)&.first
    end

    def create_hold(netid:)
      raise CDL::HoldExists if hold?(netid: netid)
      return create_charge(netid: netid) if available_for_charge?(netid: netid)
      hold = CDL::Hold.new(netid: netid)
      change_set = CDL::ResourceChargeListChangeSet.new(resource_charge_list)
      change_set.validate(hold_queue: resource_charge_list.hold_queue + [hold])
      change_set_persister.save(change_set: change_set).tap do |list|
        CDL::EventLogging.google_hold_event(netid: netid, source_metadata_identifier: source_metadata_identifier, hold_queue_size: list.pending_or_active_holds.size)
      end
    end

    def activate_holds!
      expire_holds!
      return unless available_charge_slot? && resource_charge_list.pending_or_active_holds.present?
      return if holds_to_activate.empty?
      activated_holds = holds_to_activate.map do |hold|
        hold.expiration_time = 1.hour.from_now
        hold
      end
      change_set = ChangeSet.for(resource_charge_list)
      change_set.validate(hold_queue: resource_charge_list.hold_queue)
      change_set_persister.save(change_set: change_set)
      activated_holds.each do |hold|
        notify_hold_active(hold: hold)
      end
    end

    def holds_to_activate
      resource_charge_list.pending_holds.first(available_item_ids.size - resource_charge_list.active_holds.size)
    end

    def expire_holds!
      return resource_charge_list if expired_holds.empty?
      expired_holds.each do |expired_hold|
        notify_hold_expired(hold: expired_hold)
      end
      change_set = ChangeSet.for(resource_charge_list)
      change_set.validate(hold_queue: resource_charge_list.hold_queue - expired_holds)
      self.resource_charge_list = change_set_persister.save(change_set: change_set)
    end

    def notify_hold_active(hold:)
      CDL::HoldMailer.with(user: User.where(uid: hold.netid).first!, resource_id: resource_id.to_s).hold_activated.deliver_now
    end

    def notify_hold_expired(hold:)
      CDL::EventLogging.google_hold_expired_event(source_metadata_identifier: source_metadata_identifier, netid: hold.netid)
      CDL::HoldMailer.with(user: User.where(uid: hold.netid).first!, resource_id: resource_id.to_s).hold_expired.deliver_later
    end

    def available_item_ids
      item_ids - resource_charge_list.charged_items.map(&:item_id)
    end

    def item_ids
      @item_ids ||= eligible_item_service.item_ids(source_metadata_identifier: resource.try(:source_metadata_identifier)&.first)
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
