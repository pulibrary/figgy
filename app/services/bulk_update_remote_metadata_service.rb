# frozen_string_literal: true
class BulkUpdateRemoteMetadataService
  def self.call(batch_size: 50)
    metadata_adapter.query_service.custom_queries.find_ids_with_property_not_empty(property: :source_metadata_identifier).each_slice(batch_size) do |slice|
      CatalogUpdateJob.perform_later(slice.map(&:to_s))
    end
  end

  def self.metadata_adapter
    Valkyrie::MetadataAdapter.find(:postgres)
  end
end
