# frozen_string_literal: true

class FindingAidsUpdater
  attr_accessor :logger
  def initialize(logger:)
    @logger = logger
  end

  def yesterday
    yesterdays_date = Time.zone.yesterday
    SvnParser.new.updated_collection_codes(yesterdays_date).each do |code|
      resources = query_service.custom_queries.find_by_property(property: :archival_collection_code, value: code)
      # there might be multiple resources with the same collection code
      resources.each do |resource|
        logger.info "Refreshing pulfa metadata for #{resource.id}, #{resource.source_metadata_identifier}"
        FindingAidsUpdateJob.perform_later(id: resource.id.to_s)
      end
    end
  end

  def all
    query_service.find_all_of_model(model: ScannedResource).each do |resource|
      next unless resource.source_metadata_identifier.present?
      next if PulMetadataServices::Client.bibdata?(resource.source_metadata_identifier.first)
      logger.info "Refreshing pulfa metadata for #{resource.id}, #{resource.source_metadata_identifier}"
      FindingAidsUpdateJob.perform_later(id: resource.id.to_s)
    end
  end

  private

    def query_service
      @query_service ||= Valkyrie.config.metadata_adapter.query_service
    end
end
