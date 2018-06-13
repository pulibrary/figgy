# frozen_string_literal: true
module Types::Resource
  include Types::BaseInterface
  description "A resource in the system."
  orphan_types Types::ScannedResourceType, Types::FileSetType

  field :label, String, null: true
  field :viewing_hint, String, null: true
  field :members, [Types::Resource], null: true

  definition_methods do
    def resolve_type(object, _context)
      "Types::#{object.class}Type".constantize
    end
  end

  def members
    @members ||= Wayfinder.for(object).members
  end
end
