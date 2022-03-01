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
      next if resource.source_metadata_identifier.blank?
      next if PulMetadataServices::Client.bibdata?(resource.source_metadata_identifier.first)
      logger.info "Refreshing pulfa metadata for #{resource.id}, #{resource.source_metadata_identifier}"
      FindingAidsUpdateJob.perform_later(id: resource.id.to_s)
    end
  end

  private

    class SvnParser
      # @param [Date] date
      def updated_collection_codes(date)
        svn_config = Rails.application.config_for :svn
        date = date.to_formatted_s(:iso8601)
        stdout, status = Open3.capture2("svn diff --summarize -r {#{date}}:HEAD --username #{svn_config['user']} --password #{svn_config['pass']} #{File.join(svn_config['url'], 'pulfa/trunk/eads')}")
        raise StandardError unless status.success?
        parse_collection_ids(stdout)
      end

      def parse_collection_ids(svn_output)
        svn_output.split("\n").map do |line|
          line.rpartition("/").last.partition(".").first
        end
      end
    end

    def query_service
      @query_service ||= Valkyrie.config.metadata_adapter.query_service
    end
end
