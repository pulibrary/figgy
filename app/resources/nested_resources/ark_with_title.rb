# frozen_string_literal: true

class ArkWithTitle < Valkyrie::Resource
  attribute :title, Valkyrie::Types::String
  attribute :identifier, Valkyrie::Types::String
end
