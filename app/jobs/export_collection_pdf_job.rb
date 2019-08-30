# frozen_string_literal: true
class ExportCollectionPDFJob < ApplicationJob
  def perform(resource_id, logger: Logger.new(STDOUT))
    query_service = Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
    collection = query_service.find_by(id: resource_id)
    logger.info "Exporting #{collection.title.first} to disk as PDFs"

    collection.decorate.members.each do |member|
      unless member.source_metadata_identifier&.first
        logger.info "Skipping #{member.id} (no source_metadata_identifier)"
        next
      end

      filename = "#{member.source_metadata_identifier.first.gsub(/.*_/, '')}.pdf"
      logger.info "Exporting #{member.id} as #{filename}"
      ExportService.export_pdf(member, filename: filename)
    end
  end
end
