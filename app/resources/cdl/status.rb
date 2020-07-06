# frozen_string_literal: true

module CDL
  class Status
    attr_reader :resource, :user
    def initialize(resource:, user:)
      @resource = resource
      @user = user
    end

    def as_json(*_args)
      return no_user if user.blank?
      {
        "charged": charged_item.present?,
        "available": available_status
      }.merge(expired_hash)
    end

    def no_user
      {
        "charged": false,
        "available": false
      }
    end

    def expired_hash
      return {} unless charged_item.present?
      {
        expires_at: charged_item.expiration_time.to_i
      }
    end

    def charged_item
      @charged_item ||= charge_manager.charged_items.find do |charged_item|
        charged_item.netid == user.uid
      end
    end

    def available_status
      charge_manager.available_for_charge?
    end

    def charge_manager
      @charge_manager ||= CDL::ChargeManager.new(
        resource_id: resource.id,
        eligible_item_service: CDL::EligibleItemService,
        change_set_persister: change_set_persister
      )
    end

    def change_set_persister
      ChangeSetPersister.new(
        metadata_adapter: Valkyrie.config.metadata_adapter,
        storage_adapter: Valkyrie.config.storage_adapter
      )
    end
  end
end
