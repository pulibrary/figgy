# frozen_string_literal: true
class UpdateFgdcOnlinkJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  def perform(id)
    @resource = query_service.find_by(id: Valkyrie::ID.new(id)).decorate
    return unless fgdc_file_set && geo_member_file_set
    FgdcUpdateService.new(file_set: fgdc_file_set).insert_onlink(url: download_url)
    # Check fixity since we altered the original file
    CheckFixityJob.set(queue: queue_name).perform_later(fgdc_file_set.id.to_s)
  end

  private

    def document_path_class
      GeoDiscovery::DocumentBuilder::DocumentPath
    end

    def download_url
      document_path_class.new(@resource).file_download
    end

    def fgdc_file_set
      @fgdc_file_set ||= @resource.geo_metadata_members.find { |m| m.mime_type.first == "application/xml; schema=fgdc" }
    end

    def geo_member_file_set
      @geo_member_file_set ||= @resource.geo_members.try(:first)
    end

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end
end
