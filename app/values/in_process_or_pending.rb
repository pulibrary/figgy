# frozen_string_literal: true
class InProcessOrPending
  def self.for(resource)
    new(resource).call
  end

  attr_reader :resource
  def initialize(resource)
    @resource = resource
  end

  def call
    in_process? || pending_uploads?
  end

  def in_process?
    return false unless resource.id
    in_process_file_sets.count.positive?
  end

  def in_process_file_sets
    @in_process_file_sets ||= query_service.custom_queries.find_deep_children_with_property(
      resource: resource,
      model: "FileSet",
      property: :processing_status,
      value: "in process"
    )
  end

  def pending_uploads?
    resource.try(:pending_uploads).present?
  end

  def query_service
    ChangeSetPersister.default.query_service
  end
end
