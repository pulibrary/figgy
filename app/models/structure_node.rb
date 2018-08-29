# frozen_string_literal: true
class StructureNode < Valkyrie::Resource
  attribute :label, Valkyrie::Types::Set
<<<<<<< HEAD
  attribute :proxy, Valkyrie::Types::Set.of(Valkyrie::Types::ID.optional)
  attribute :nodes, Valkyrie::Types::Array.of(StructureNode)
=======
  attribute :proxy, Valkyrie::Types::Set.member(Valkyrie::Types::ID.optional)
  attribute :nodes, Valkyrie::Types::Array.member(StructureNode)
>>>>>>> d8616123... adds lux order manager to figgy
end
