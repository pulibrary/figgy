# frozen_string_literal: true

class EphemeraVocabulary < Resource
  include Valkyrie::Resource::AccessControls
  attribute :label
  attribute :uri
  attribute :definition
  attribute :member_of_vocabulary_id, Valkyrie::Types::Set

  def linked_resource
    LinkedData::LinkedEphemeraVocabulary.new(resource: self)
  end
end
