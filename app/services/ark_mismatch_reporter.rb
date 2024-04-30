# frozen_string_literal: true

class ArkMismatchReporter
  def self.write(output_path: Rails.root.join("tmp", "ark_mismatch_report.csv"))
    new(output_path: output_path, logger: Logger.new(STDOUT)).write
  end

  attr_reader :output_path, :logger
  def initialize(output_path:, logger:)
    @output_path = output_path
    @logger = logger
  end

  def write
    CSV.open(output_path, "w") do |csv|
      csv << [:id, :title, :mmsid, :ark, :url]
      resources.each do |resource|
        next unless resource.identifier
        target = target(resource)
        next unless findingaid_url?(target)
        csv << [
          resource.id,
          resource.title.first,
          resource.source_metadata_identifier.first,
          resource.identifier.first,
          target
        ]
      end
    end
  end

  private

    def resources
      query_service.custom_queries.all_mms_resources
    end

    def target(resource)
      ark = resource.identifier.first
      Faraday.head("https://n2t.net/#{ark}").headers["location"]
    end

    def findingaid_url?(url)
      !(url =~ /findingaids/).nil?
    end

    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end
end
