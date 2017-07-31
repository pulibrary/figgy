# frozen_string_literal: true
class CollectionIndexer
  delegate :query_service, to: :metadata_adapter
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless resource.respond_to?(:member_of_collection_ids)
    {
      "member_of_collection_titles_ssim" => collections.map(&:title).to_a
    }
  end

  def collections
    return [] if resource.member_of_collection_ids.blank?
    @collections ||=
      begin
        query_service.find_references_by(resource: resource, property: :member_of_collection_ids).map(&:decorate)
      end
  end

  def metadata_adapter
    Valkyrie.config.metadata_adapter
  end
end
