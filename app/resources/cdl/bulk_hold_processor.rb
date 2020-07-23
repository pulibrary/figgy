# frozen_string_literal: true

module CDL
  class BulkHoldProcessor
    def self.process!
      change_set_persister.buffer_into_index do |buffered_change_set_persister|
        new(change_set_persister: buffered_change_set_persister).process!
      end
    end

    def self.change_set_persister
      ::ChangeSetPersister.new(
        metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
        storage_adapter: Valkyrie.config.storage_adapter
      )
    end

    attr_reader :change_set_persister
    delegate :metadata_adapter, to: :change_set_persister
    delegate :query_service, to: :metadata_adapter
    def initialize(change_set_persister:)
      @change_set_persister = change_set_persister
    end

    def process!
      held_resources.each do |held_resource|
        charge_manager_for(resource_charge_list: held_resource).activate_holds!
      end
    end

    private

      def charge_manager_for(resource_charge_list:)
        CDL::ChargeManager.new(
          resource_id: resource_charge_list.resource_id,
          eligible_item_service: EligibleItemService,
          change_set_persister: change_set_persister
        )
      end

      def held_resources
        @held_resources ||= query_service.custom_queries.find_by_property(property: :hold_queue, value: [{}], model: CDL::ResourceChargeList)
      end
  end
end
