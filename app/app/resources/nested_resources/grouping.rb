# frozen_string_literal: true

class Grouping < Valkyrie::Resource
  attribute :elements, Valkyrie::Types::Array.of(Valkyrie::Types::Anything)

  def to_s
    elements.map(&:to_s).join("; ")
  end
end
