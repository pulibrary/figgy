# frozen_string_literal: true

class ExportHathiSipJob < ApplicationJob
  def perform(resource_id, destination = Rails.root.join("tmp"), logger = Logger.new($stdout))
    logger.info "Exporting #{resource_id} to Hathi SIP in '#{destination}'"
    query_service = Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
    resource = query_service.find_by(id: resource_id)
    sip = Hathi::SubmissionInformationPackage.new(
      package: Hathi::ContentPackage.new(resource: resource),
      base_path: destination
    )

    sip.export
  end
end
