# frozen_string_literal: true
class CollectionIndexer
  delegate :query_service, to: :metadata_adapter
  attr_reader :resource
  def initialize(resource:)
    @resource = if resource.is_a?(DeletionMarker)
                  resource.deleted_object
                else
                  resource
                end
  end

  # Adds a collection title index entry to a resource's index document for each collection that resource belongs to
  def to_solr
    return {} unless collection_titles.any?
    {
      "member_of_collection_titles_ssim" => collection_titles,
      "member_of_collection_titles_tesim" => collection_titles
    }
  end

  def collection_titles
    @collection_titles ||=
      ephemera_collection_titles.any? ? ephemera_collection_titles : collections.map(&:title)
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
    @collections ||= resource.member_of_collection_ids.map do |id|
      query_service.find_by(id: id)&.decorate
                     rescue Valkyrie::Persistence::ObjectNotFoundError
                       nil
    end.compact
  end

  def metadata_adapter
    Valkyrie.config.metadata_adapter
  end
end
