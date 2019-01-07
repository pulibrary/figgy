# frozen_string_literal: true
class ScannedMapsController < ScannedResourcesController
  include GeoResourceController
  include GeoblacklightDocumentController
  self.resource_class = ScannedMap

  # View the structural metadata for a given repository resource
  def structure
    @change_set = change_set_class.new(find_resource(params[:id])).prepopulate!
    authorize! :structure, @change_set.resource
    @logical_order = (Array(@change_set.logical_structure).first || Structure.new).decorate
    members = Wayfinder.for(@change_set.resource).logical_structure_members
    @logical_order = WithProxyForObject.new(@logical_order, members)
  end
end
