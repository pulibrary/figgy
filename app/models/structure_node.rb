# frozen_string_literal: true
class StructureNode < Valkyrie::Resource
  attribute :label, Valkyrie::Types::Set
  attribute :proxy, Valkyrie::Types::Set.member(Valkyrie::Types::ID.optional)
  attribute :nodes, Valkyrie::Types::Array.member(StructureNode)

  def to_hash
    super.compact
  end
end
