# frozen_string_literal: true

module Numismatics
  class PlaceDecorator < Valkyrie::ResourceDecorator
    display :city,
      :geo_state,
      :region

    def manageable_files?
      false
    end

    def manageable_order?
      false
    end

    def manageable_structure?
      false
    end

    def title
      [city, geo_state, region].compact.join(", ")
    end
  end
end
