# frozen_string_literal: true
class NumismaticPlaceDecorator < Valkyrie::ResourceDecorator
  def rendered_place
    [city, state, region].join(", ")
  end
end
