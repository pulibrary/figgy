# frozen_string_literal: true
class EphemeraProject < Valhalla::Resource
  include Valkyrie::Resource::AccessControls
  attribute :id, Valkyrie::Types::ID.optional
  attribute :member_ids, Valkyrie::Types::Array
  attribute :title, Valkyrie::Types::Set
  attribute :slug, Valkyrie::Types::Set

  def logical_structure
    []
  end
end
