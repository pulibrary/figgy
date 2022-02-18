# frozen_string_literal: true

class TrackIndexer
  delegate :query_service, to: :metadata_adapter
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless resource.is_a?(ScannedResource) && resource.change_set == "recording"
    {
      "tracks_tesim" => tracks.map(&:title).to_a
    }
  end

  private

    def tracks
      @tracks ||= query_service.find_members(resource: resource)
    end

    def metadata_adapter
      Valkyrie.config.metadata_adapter
    end
end
