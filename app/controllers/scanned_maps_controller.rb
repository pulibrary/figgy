# frozen_string_literal: true
class ScannedMapsController < ScannedResourcesController
  include GeoResourceController
  self.resource_class = ScannedMap
end
