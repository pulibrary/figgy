# frozen_string_literal: true
module Numismatics
  class Place < Resource
    include Valkyrie::Resource::AccessControls

    attribute :city, Valkyrie::Types::String
    attribute :geo_state, Valkyrie::Types::String
    attribute :region, Valkyrie::Types::String
    attribute :replaces
    attribute :depositor
  end
end
