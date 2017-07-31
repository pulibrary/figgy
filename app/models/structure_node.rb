# frozen_string_literal: true
class StructureNode < Valkyrie::Resource
  attribute :label, Valkyrie::Types::Set
  attribute :proxy, Valkyrie::Types::Set
  attribute :nodes, Valkyrie::Types::Array.member(StructureNode)
end
