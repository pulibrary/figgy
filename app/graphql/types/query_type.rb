# frozen_string_literal: true
class Types::QueryType < Types::BaseObject
  description "The query root of this schema"

  field :resource, Types::Resource, null: true do
    description "Find a resource by ID"
    argument :id, ID, required: true
  end

  field :resources_by_ark, [Types::Resource], null: true do
    description "Find a resource by ark"
    argument :ark, String, required: true
  end

  field :resources_by_bibid, [Types::Resource], null: true do
    description "Find a resource by BibID"
    argument :bib_id, String, required: true
  end

  field :resources_by_bibids, [Types::Resource], null: true do
    description "Find resources by BibIDs"
    argument :bib_ids, [String], required: true
  end

  def resource(id:)
    resource = query_service.find_by(id: id)
    return unless ability.can? :read, resource
    resource
  rescue Valkyrie::Persistence::ObjectNotFoundError
    Valkyrie.logger.error("Failed to retrieve the resource #{id} for a GraphQL query")
    nil
  end

  def resources_by_ark(ark:)
    resources = query_service.custom_queries.find_by_property(property: :identifier, value: ark).select { |resource| ability.can? :read, resource }.to_a
    resources.select { |r| type_defined?(r) }
  end

  def resources_by_bibid(bib_id:)
    resources = query_service.custom_queries.find_by_property(property: :source_metadata_identifier, value: bib_id).select { |resource| ability.can? :read, resource }.to_a
    resources.select { |r| type_defined?(r) }
  end

  def resources_by_bibids(bib_ids:)
    resources = query_service.custom_queries.find_many_by_string_property(property: :source_metadata_identifier, values: bib_ids)
    readable_resources = resources.select { |resource| ability.can? :read, resource }
    readable_resources.select { |r| type_defined?(r) }.to_a
  end

  def ability
    context[:ability]
  end

  def type_defined?(resource)
    "Types::#{resource.class}Type".constantize
  rescue NameError
    false
  end

  def change_set_persister
    context[:change_set_persister]
  end

  delegate :metadata_adapter, to: :change_set_persister
  delegate :query_service, to: :metadata_adapter
end
