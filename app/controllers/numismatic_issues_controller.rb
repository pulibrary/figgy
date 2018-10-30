# frozen_string_literal: true
class NumismaticIssuesController < BaseResourceController
  self.change_set_class = DynamicChangeSet
  self.resource_class = NumismaticIssue
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
end
