# frozen_string_literal: true

class CoveragePoint < Valkyrie::Resource
  attribute :lat, Valkyrie::Types::Float
  attribute :lon, Valkyrie::Types::Float
end
