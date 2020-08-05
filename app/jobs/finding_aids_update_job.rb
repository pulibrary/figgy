# frozen_string_literal: true

class FindingAidsUpdateJob < ApplicationJob
  # Update given resource with finding aids metadata
  # @param id <String>
  def perform(id:)
    resource = query_service.find_by(id: id)
    change_set = ChangeSet.for(resource)
    change_set.validate(refresh_remote_metadata: "1")
    persister.save(change_set: change_set)
  end

  private

    def persister
      @persister ||= ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter)
    end

    def metadata_adapter
      @metadata_adapter ||= Valkyrie.config.metadata_adapter
    end

    def query_service
      @query_service ||= metadata_adapter.query_service
    end
end
