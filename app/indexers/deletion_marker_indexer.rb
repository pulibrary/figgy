# frozen_string_literal: true
class DeletionMarkerIndexer
  delegate :query_service, to: :metadata_adapter
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless resource.is_a?(::DeletionMarker) && suppress?
    {
      suppressed_bsi: "true"
    }
  end

  private

    # Suppress marker from search results if it has a parent that does not exist
    # in the database. This means that the marker is child of another marker
    # resource and will be restored when the parent marker is restored.
    def suppress?
      return false if resource.parent_id.blank?
      query_service.find_by(id: resource.parent_id)

      false
    rescue Valkyrie::Persistence::ObjectNotFoundError
      true
    end

    def metadata_adapter
      Valkyrie.config.metadata_adapter
    end
end
