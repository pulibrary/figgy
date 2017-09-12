# frozen_string_literal: true
class EphemeraField < Valhalla::Resource
  include Valkyrie::Resource::AccessControls
  attribute :id, Valkyrie::Types::ID.optional
  attribute :member_ids, Valkyrie::Types::Array
  attribute :name, Valkyrie::Types::Set
end
