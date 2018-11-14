# frozen_string_literal: true
class ScannedMapsController < ScannedResourcesController
  include GeoResourceController
  include GeoblacklightDocumentController
  self.resource_class = ScannedMap
end
