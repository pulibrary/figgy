# frozen_string_literal: true
class EphemeraVocabulary < Resource
  include Valkyrie::Resource::AccessControls
  attribute :id, Valkyrie::Types::ID.optional
  attribute :label
  attribute :uri
  attribute :definition
  attribute :member_of_vocabulary_id, Valkyrie::Types::Set
end
