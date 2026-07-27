class PulfalightReportGenerator
  def self.json_report(collection:)
    new(collection: collection).records.to_json
  end

  attr_reader :collection
  def initialize(collection:)
    @collection = collection
  end

  def records
    pulfalight_resources.each_with_object({}) do |resource, hsh|
      next unless resource.public_readable?
      hsh[resource.component_id] ||= []
      hsh[resource.component_id] << resource.to_hash
    end
  end

  private

    def pulfalight_resources
      ChangeSetPersister.default.query_service.custom_queries.pulfalight_resources(
        collection: collection,
        fields: ReportResource.resource_fields
      ).map { |resource| ReportResource.new(resource) }
    end
end
