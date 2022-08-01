# frozen_string_literal: true
FactoryBot.define do
  factory :numismatic_issue, class: Numismatics::Issue do
    denomination { ["$1"] }
    rights_statement { RightsStatements.no_known_copyright }
    read_groups { "public" }
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
    transient do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    end
    after(:build) do |resource, evaluator|
      if evaluator.visibility.present?
        change_set = Numismatics::IssueChangeSet.new(resource)
        change_set.validate(visibility: Array(evaluator.visibility).first)
        change_set.sync
        resource = change_set.model
      end
      resource
    end
    factory :open_numismatic_issue do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    end
    factory :private_numismatic_issue do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
    end
    factory :campus_only_numismatic_issue do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
    end
    factory :complete_open_numismatic_issue do
      state { "complete" }
    end
  end
end
