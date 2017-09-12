# frozen_string_literal: true
class EphemeraProject < Valhalla::Resource
  include Valkyrie::Resource::AccessControls
  attribute :id, Valkyrie::Types::ID.optional
  attribute :member_ids, Valkyrie::Types::Array
  attribute :member_of_collection_ids, Valkyrie::Types::Array
  attribute :name, Valkyrie::Types::Set
  alias title name
end
