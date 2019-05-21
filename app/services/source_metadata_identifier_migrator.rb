# frozen_string_literal: true
class SourceMetadataIdentifierMigrator
  def self.call
    ids.each_slice(100) do |slice|
      adapter.persister.buffer_into_index do |buf|
        slice.each do |id|
          r = query_service.find_by(id: id)
          next unless r.source_metadata_identifier.first.match?(/\//)

          r.source_metadata_identifier = [r.source_metadata_identifier.first.tr("/", "_")]
          buf.persister.save(resource: r)
        end
      end
    end
  end

  def self.ids
    query_service.custom_queries.find_ids_with_property_not_empty(property: :source_metadata_identifier)
  end

  def self.adapter
    Valkyrie::MetadataAdapter.find(:indexing_persister)
  end

  def self.query_service
    adapter.query_service
  end
end
