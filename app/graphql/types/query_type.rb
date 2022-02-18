# frozen_string_literal: true

class Types::QueryType < Types::BaseObject
  description "The query root of this schema"

  field :resource, Types::Resource, null: true do
    description "Find a resource by ID"
    argument :id, ID, required: true
  end

  field :resources_by_figgy_ids, [Types::Resource], null: true do
    description "Find resources by IDs"
    argument :ids, [ID], required: true
  end

  field :resources_by_bibid, [Types::Resource], null: true do
    description "Find a resource by BibID"
    argument :bib_id, String, required: true
  end

  field :resources_by_bibids, [Types::Resource], null: true do
    description "Find resources by BibIDs"
    argument :bib_ids, [String], required: true
  end

  field :resources_by_orangelight_id, [Types::Resource], null: true do
    description "Find resources by Orangelight id"
    argument :id, String, required: true
  end

  field :resources_by_orangelight_ids, [Types::Resource], null: true do
    description "Find resources by Orangelight ids"
    argument :ids, [String], required: true
  end

  def resource(id:)
    resource = query_service.find_by(id: id)
    return unless ability.can? :discover, resource
    resource
  rescue Valkyrie::Persistence::ObjectNotFoundError
    Valkyrie.logger.error("Failed to retrieve the resource #{id} for a GraphQL query")
    nil
  end

  def resources_by_figgy_ids(ids:)
    resources = query_service.find_many_by_ids(ids: ids)
    readable_resources = resources.select { |resource| ability.can? :discover, resource }
    readable_resources.select { |r| type_defined?(r) }.to_a
  end

  def resources_by_bibid(bib_id:)
    resources = query_service.custom_queries.find_by_source_metadata_identifier(source_metadata_identifier: bib_id).select { |resource| ability.can? :discover, resource }.to_a
    resources.select { |r| type_defined?(r) }
  end

  def resources_by_bibids(bib_ids:)
    resources = query_service.custom_queries.find_by_source_metadata_identifiers(source_metadata_identifiers: bib_ids)
    readable_resources = resources.select { |resource| ability.can? :discover, resource }
    readable_resources.select { |r| type_defined?(r) }.to_a
  end

  def resources_by_coin_number(coin_number:)
    resources = query_service.custom_queries.find_by_property(property: :coin_number, value: coin_number.to_i).select { |resource| ability.can? :discover, resource }
    resources.select { |r| type_defined?(r) }
  end

  def resources_by_coin_numbers(coin_numbers:)
    numbers = coin_numbers.map(&:to_i)
    resources = query_service.custom_queries.find_many_by_property(property: :coin_number, values: numbers).select { |resource| ability.can? :discover, resource }
    resources.select { |r| type_defined?(r) }
  end

  def resources_by_orangelight_id(id:)
    if coin_id?(id)
      resources_by_coin_number(coin_number: id.gsub("coin-", ""))
    else
      resources_by_bibid(bib_id: id)
    end
  end

  def resources_by_orangelight_ids(ids:)
    coin_ids = ids.select { |id| coin_id?(id) }.map { |id| id.gsub("coin-", "") }
    bib_ids = ids - coin_ids
    coin_resources = coin_ids.empty? ? [] : resources_by_coin_numbers(coin_numbers: coin_ids)
    bib_resources = bib_ids.empty? ? [] : resources_by_bibids(bib_ids: bib_ids)
    coin_resources + bib_resources
  end

  private

    def ability
      context[:ability]
    end

    def change_set_persister
      context[:change_set_persister]
    end

    def coin_id?(id)
      id.start_with?("coin-")
    end

    def type_defined?(resource)
      "Types::#{resource.class}Type".constantize
    end

    delegate :metadata_adapter, to: :change_set_persister
    delegate :query_service, to: :metadata_adapter
end
