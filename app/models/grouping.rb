# frozen_string_literal: true

class Grouping < Valkyrie::Resource
  attribute :elements, Valkyrie::Types::Array.of(Valkyrie::Types::Anything)
end
