# frozen_string_literal: true
class ExtractArchivalCollectionCodeJob < ApplicationJob
  def perform(logger: Logger.new(STDOUT))
    query_service.find_all_of_model(model: ScannedResource).each do |sr|
      next unless sr.source_metadata_identifier.present?
      next if PulMetadataServices::Client.bibdata?(sr.source_metadata_identifier.first)
      next if sr.archival_collection_code

      sr.archival_collection_code = ChangeSetPersister::ExtractArchivalCollectionCode.extract_collection_code(sr.source_metadata_identifier.first)

      logger.info "extracting archival collection code for #{sr.id}"
      metadata_adapter.persister.save(resource: sr)
    end
  end

  def metadata_adapter
    Valkyrie::MetadataAdapter.find(:indexing_persister)
  end
  delegate :query_service, to: :metadata_adapter
end
