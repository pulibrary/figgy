# frozen_string_literal: true
class EphemeraField < Valhalla::Resource
  include Valkyrie::Resource::AccessControls
  attribute :id, Valkyrie::Types::ID.optional
  attribute :name, Valkyrie::Types::Set
end
