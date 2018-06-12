# frozen_string_literal: true
module Types::Resource
  include Types::BaseInterface
  description "A resource in the system."
  orphan_types Types::ScannedResourceType, Types::FileSetType

  field :label, String, null: true
  field :viewing_hint, String, null: true
  field :orderable_members, [Types::Resource], null: true

  definition_methods do
    def resolve_type(object, _context)
      "Types::#{object.class}Type".constantize
    end
  end

  def orderable_members
    @orderable_members ||= OrderableMembersFilter.new(resource: object).to_a
  end

  class OrderableMembersFilter
    delegate :query_service, to: :metadata_adapter

    attr_reader :resource
    def initialize(resource:)
      @resource = resource
    end

    def to_a
      query_service.find_members(resource: resource).select do |obj|
        obj.is_a?(ScannedResource) ||
          obj.is_a?(FileSet) && obj.mime_type.first.to_s.include?("image/")
      end.to_a
    end

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end
  end
end
