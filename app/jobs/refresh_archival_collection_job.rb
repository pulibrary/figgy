# frozen_string_literal: true
class RefreshArchivalCollectionJob < ApplicationJob
  queue_as :low
  delegate :query_service, to: :metadata_adapter

  def perform(collection_code:)
    ids = query_service.custom_queries.find_by_property(property: :archival_collection_code, value: collection_code).map { |r| r.id.to_s }
    ids.each { |id| RefreshRemoteMetadataJob.perform_later(id: id) }
  end

  private

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end
end
