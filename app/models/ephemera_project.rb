# frozen_string_literal: true
class EphemeraProject < Resource
  include Valkyrie::Resource::AccessControls
<<<<<<< HEAD
=======
  attribute :id, Valkyrie::Types::ID.optional
>>>>>>> d8616123... adds lux order manager to figgy
  attribute :member_ids, Valkyrie::Types::Array
  attribute :title, Valkyrie::Types::Set
  attribute :slug, Valkyrie::Types::Set
  attribute :top_language, Valkyrie::Types::Set

  def logical_structure
    []
  end
end
