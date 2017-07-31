# frozen_string_literal: true
class ScannedResourceDecorator < Valkyrie::ResourceDecorator
  self.display_attributes = [:author, :internal_resource, :created_at, :updated_at, :member_of_collections]
  delegate :query_service, to: :metadata_adapter

  def member_of_collections
    @member_of_collections ||=
      begin
        member_of_collection_ids.map do |id|
          query_service.find_by(id: id).decorate
        end.map(&:title)
      end
  end

  def member_of_collection_ids
    super || []
  end

  def metadata_adapter
    Valkyrie.config.metadata_adapter
  end
end
