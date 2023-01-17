# frozen_string_literal: true
class ExportCollectionPDFJob < ApplicationJob
  def perform(resource_id, logger: Logger.new(STDOUT))
    collection = query_service.find_by(id: resource_id)
    logger.info "Exporting #{collection.title.first} to disk as PDFs"

    Wayfinder.for(collection).members.each do |member|
      unless member.source_metadata_identifier&.first
        logger.info "Skipping #{member.id} (no source_metadata_identifier)"
        next
      end

      fn_base = member.source_metadata_identifier.first.gsub(/.*_/, "")
      ExportService.export_resource_or_volumes_pdf(member, filename_base: fn_base)
    end
  end

  def query_service
    Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
  end
end
