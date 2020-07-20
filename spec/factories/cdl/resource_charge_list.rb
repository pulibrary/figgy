# frozen_string_literal: true
FactoryBot.define do
  factory :resource_charge_list, class: CDL::ResourceChargeList do
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
    transient do
      expired_hold_netids []
      active_hold_netids []
      inactive_hold_netids []
    end
    after(:build) do |resource, evaluator|
      if evaluator.expired_hold_netids.present?
        resource.hold_queue += evaluator.expired_hold_netids.map do |netid|
          CDL::Hold.new(netid: netid, expiration_time: Time.current - 1.hour)
        end
      end
      if evaluator.active_hold_netids.present?
        resource.hold_queue += evaluator.active_hold_netids.map do |netid|
          CDL::Hold.new(netid: netid, expiration_time: Time.current + 1.hour)
        end
      end
      if evaluator.inactive_hold_netids.present?
        resource.hold_queue += evaluator.inactive_hold_netids.map do |netid|
          CDL::Hold.new(netid: netid)
        end
      end
    end
  end
end
