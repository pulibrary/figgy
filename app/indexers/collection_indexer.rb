# frozen_string_literal: true
class CollectionIndexer
  delegate :query_service, to: :metadata_adapter
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless collection_titles.any?
    {
      "member_of_collection_titles_ssim" => collection_titles,
      "member_of_collection_titles_tesim" => collection_titles
    }
  end

  def collection_titles
    @collection_titles ||=
      ephemera_collection_titles.any? ? ephemera_collection_titles : collections.map(&:title).to_a
  end

  def decorated_resource
    @decorated_resource ||= resource.decorate
  end

  def ephemera_collection_titles
    return [] unless resource.is_a?(EphemeraFolder) && decorated_resource.ephemera_box
    decorated_resource.ephemera_box.member_of_collections.map(&:title)
  end

  def collections
    return [] unless resource.respond_to?(:member_of_collection_ids) && resource.member_of_collection_ids
    @collections ||=
      begin
        query_service.find_references_by(resource: resource, property: :member_of_collection_ids).to_a.map(&:decorate)
      end
  end

  def metadata_adapter
    Valkyrie.config.metadata_adapter
  end
end
