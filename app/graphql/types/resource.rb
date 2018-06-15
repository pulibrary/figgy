# frozen_string_literal: true
module Types::Resource
  include Types::BaseInterface
  description "A resource in the system."
  orphan_types Types::ScannedResourceType, Types::FileSetType

  field :id, String, null: true
  field :label, String, null: true
  field :viewing_hint, String, null: true
  field :url, String, null: true
  field :members, [Types::Resource], null: true

  definition_methods do
    def resolve_type(object, _context)
      "Types::#{object.class}Type".constantize
    end
  end

  def members
    @members ||= Wayfinder.for(object).members
  end

  def url
    @url ||= helper.show_url(object)
  end

  def helper
    @helper ||= ManifestBuilder::ManifestHelper.new
  end
end
