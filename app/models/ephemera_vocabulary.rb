# frozen_string_literal: true
class EphemeraVocabulary < Valhalla::Resource
  include Valkyrie::Resource::AccessControls
  attribute :id, Valkyrie::Types::ID.optional
  attribute :label, Valkyrie::Types::String
  attribute :value, Valkyrie::Types::Any
  attribute :definition, Valkyrie::Types::String
  attribute :member_of_vocabulary_id
end
