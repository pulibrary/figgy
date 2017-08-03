# frozen_string_literal: true
class Collection < Valhalla::Resource
  include Valkyrie::Resource::AccessControls
  attribute :id, Valkyrie::Types::ID.optional
  attribute :title, Valkyrie::Types::Set
  attribute :slug, Valkyrie::Types::Set
  attribute :description, Valkyrie::Types::Set
  attribute :visibility, Valkyrie::Types::Set

  def thumbnail_id; end
end
