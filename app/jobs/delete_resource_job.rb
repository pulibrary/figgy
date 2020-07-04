# frozen_string_literal: true
class DeleteResourceJob < ApplicationJob
  def perform(id)
    resource = metadata_adapter.query_service.find_by(id: Valkyrie::ID.new(id))
    indexing_adapter.persister.delete(resource: resource)
    change_set_persister.delete(change_set: ChangeSet.for(resource))
  end

  def indexing_adapter
    Valkyrie::MetadataAdapter.find(:index_solr)
  end

  def metadata_adapter
    Valkyrie::MetadataAdapter.find(:postgres)
  end

  def change_set_persister
    ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter)
  end
end
