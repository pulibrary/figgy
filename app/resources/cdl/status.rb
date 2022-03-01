# frozen_string_literal: true

module CDL
  class Status
    attr_reader :charge_manager, :user
    def initialize(charge_manager:, user:)
      @charge_manager = charge_manager
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
      return {} if charged_item.blank?
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
      charge_manager.available_for_charge?(netid: user.uid)
    end
  end
end
