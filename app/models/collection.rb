# frozen_string_literal: true
class Collection < Resource
  include Valkyrie::Resource::AccessControls
<<<<<<< HEAD
=======
  attribute :id, Valkyrie::Types::ID.optional
>>>>>>> d8616123... adds lux order manager to figgy
  attribute :title, Valkyrie::Types::Set
  attribute :slug, Valkyrie::Types::Set
  attribute :description, Valkyrie::Types::Set
  attribute :visibility, Valkyrie::Types::Set
  attribute :local_identifier, Valkyrie::Types::Set
  attribute :owners, Valkyrie::Types::Set # values should be User.uid

  def thumbnail_id; end
end
