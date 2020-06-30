# frozen_string_literal: true
FactoryBot.define do
  factory :resource_charge_list, class: CDL::ResourceChargeList do
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
