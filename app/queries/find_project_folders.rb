# frozen_string_literal: true

class FindProjectFolders
  def self.queries
    [:find_project_folders]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_project_folders(resource:)
    query_service.find_members(resource: resource).flat_map do |child|
      if child.is_a?(EphemeraBox)
        query_service.find_members(resource: child, model: EphemeraFolder)
      elsif child.is_a?(EphemeraFolder)
        child
      end
    end.to_a.compact
  end
end
