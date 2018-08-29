# frozen_string_literal: true
# Templates are used to apply default metadata to multiple ephemera objects
class Template < Resource
  include Valkyrie::Resource::AccessControls
<<<<<<< HEAD
  attribute :title
  attribute :parent_id
  attribute :nested_properties, Valkyrie::Types::Array.of(Valkyrie::Types::Anything.optional).optional
=======
  attribute :id, Valkyrie::Types::ID.optional
  attribute :title
  attribute :parent_id
  attribute :nested_properties, Valkyrie::Types::Array.member(Valkyrie::Types::Anything.optional).optional
>>>>>>> d8616123... adds lux order manager to figgy
  attribute :model_class
end
