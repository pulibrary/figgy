# frozen_string_literal: true
class Structure < Valkyrie::Resource
  attribute :label, Valkyrie::Types::Set
  attribute :nodes, Valkyrie::Types::Array.member(StructureNode)
end
