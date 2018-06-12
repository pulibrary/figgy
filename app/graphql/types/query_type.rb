# frozen_string_literal: true
class Types::QueryType < Types::BaseObject
  description "The query root of this schema"

  field :resource, Types::Resource, null: true do
    description "Find a resource by ID"
    argument :id, ID, required: true
  end

  def resource(id:)
    query_service.find_by(id: id)
  end

  def metadata_adapter
    Valkyrie::MetadataAdapter.find(:indexing_persister)
  end

  delegate :query_service, to: :metadata_adapter
end
