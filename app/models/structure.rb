# frozen_string_literal: true
class Structure < Valkyrie::Resource
  attribute :label, Valkyrie::Types::Set
<<<<<<< HEAD
  attribute :nodes, Valkyrie::Types::Array.of(StructureNode)
=======
  attribute :nodes, Valkyrie::Types::Array.member(StructureNode)
>>>>>>> d8616123... adds lux order manager to figgy
end
