# frozen_string_literal: true

class StructureNode < Valkyrie::Resource
  attribute :label, Valkyrie::Types::Set
  attribute :proxy, Valkyrie::Types::Set.of(Valkyrie::Types::ID.optional)
  attribute :nodes, Valkyrie::Types::Array.of(StructureNode)
end
