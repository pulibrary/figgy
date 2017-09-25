# frozen_string_literal: true
class EphemeraField < Valhalla::Resource
  include Valkyrie::Resource::AccessControls
  attribute :id, Valkyrie::Types::ID.optional
  attribute :field_name
  attribute :member_of_vocabulary_id
end
