# frozen_string_literal: true
class ExportCollectionPDFJob < ApplicationJob
  def perform(resource_id, logger: Logger.new(STDOUT))
    collection = query_service.find_by(id: resource_id)
    logger.info "Exporting #{collection.title.first} to disk as PDFs"

    collection.decorate.members.each do |member|
      unless member.source_metadata_identifier&.first
        logger.info "Skipping #{member.id} (no source_metadata_identifier)"
        next
      end

      fn = member.source_metadata_identifier.first.gsub(/.*_/, "")
      member.decorate.volumes.empty? ? export_file(member, fn) : export_volumes(member, fn)
    end
  end

  def export_volumes(resource, filename)
    resource.decorate.volumes.each_with_index do |vol, index|
      export_file(vol, "#{filename}_#{index}")
    end
  end

  def export_file(resource, filename)
    logger.info "Exporting #{resource.id} as #{filename}.pdf"
    ExportService.export_pdf(resource, filename: "#{filename}.pdf")
  end

  def query_service
    Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
  end
end
