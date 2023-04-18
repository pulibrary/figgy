# frozen_string_literal: true
FactoryBot.define do
  factory :event do
    type { "Test type" }
    status { "SUCCESS" }
    message { "Test message" }
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end

    factory :cloud_fixity_event do
      type { :cloud_fixity }
    end

    factory :local_fixity_success do
      type { :local_fixity }
      status { "SUCCESS" }
      current { true }
      to_create do |instance|
        Valkyrie.config.metadata_adapter.persister.save(resource: instance)
      end
    end

    factory :local_fixity_failure do
      type { :local_fixity }
      status { "FAILURE" }
      current { true }
      to_create do |instance|
        Valkyrie.config.metadata_adapter.persister.save(resource: instance)
      end
    end

    factory :local_fixity_repairing do
      type { :local_fixity }
      status { "REPAIRING" }
      current { true }
      to_create do |instance|
        Valkyrie.config.metadata_adapter.persister.save(resource: instance)
      end
    end
  end
end
