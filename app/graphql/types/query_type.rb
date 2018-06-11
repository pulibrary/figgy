# frozen_string_literal: true
class Types::QueryType < Types::BaseObject
  description "The query root of this schema"

  # First describe the field signature:
  field :scanned_resource, Types::ScannedResourceType, null: true do
    description "Find a Scanned Resource by ID"
    argument :id, ID, required: true
  end

  # Then provide an implementation:
  def scanned_resource(id:)
    query_service.find_by(id: id)
  end

  def metadata_adapter
    Valkyrie::MetadataAdapter.find(:indexing_persister)
  end

  def query_service
    metadata_adapter.query_service
  end
end
