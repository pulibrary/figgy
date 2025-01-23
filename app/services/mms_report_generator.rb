# frozen_string_literal: true
class MmsReportGenerator
  def self.json_report
    new.records.to_json
  end

  def records
    mms_resources.each_with_object({}) do |resource, hsh|
      next unless resource.public_readable?
      hsh[resource.mms_id] ||= []
      hsh[resource.mms_id] << resource.to_hash
    end
  end

  private

    def mms_resources
      ChangeSetPersister.default.query_service.custom_queries.all_mms_resources(fields: ReportResource.resource_fields).map { |resource| ReportResource.new(resource) }
    end
end
