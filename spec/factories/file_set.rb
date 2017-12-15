# frozen_string_literal: true
FactoryBot.define do
  factory :file_set do
    sequence(:title) { |x| "File Set #{x}" }
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
    transient do
      user nil
    end
    after(:build) do |resource, evaluator|
      resource.depositor = evaluator.user.uid if evaluator.user.present?
    end
  end
end
