# frozen_string_literal: true
class Types::QueryType < Types::BaseObject
  description "The query root of this schema"

  field :resource, Types::Resource, null: true do
    description "Find a resource by ID"
    argument :id, ID, required: true
  end

  field :resources_by_bibid, [Types::Resource], null: true do
    description "Find a resource by BibID"
    argument :bib_id, String, required: true
  end

  def resource(id:)
    resource = query_service.find_by(id: id)
    return unless ability.can? :read, resource
    resource
  end

  def resources_by_bibid(bib_id:)
    resources = query_service.custom_queries.find_by_string_property(property: :source_metadata_identifier, value: bib_id).select { |resource| ability.can? :read, resource }.to_a
    resources
  end

  def ability
    context[:ability]
  end

  def change_set_persister
    context[:change_set_persister]
  end

  delegate :metadata_adapter, to: :change_set_persister
  delegate :query_service, to: :metadata_adapter
end
