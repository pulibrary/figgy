# frozen_string_literal: true
class EphemeraTemplate < Valhalla::Resource
  include Valkyrie::Resource::AccessControls
  attribute :id, Valkyrie::Types::ID.optional
end
