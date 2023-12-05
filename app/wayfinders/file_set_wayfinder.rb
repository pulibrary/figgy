# frozen_string_literal: true
class FileSetWayfinder < BaseWayfinder
  inverse_relationship_by_property :parents, property: :member_ids, singular: true
  inverse_relationship_by_property :preservation_objects, property: :preserved_object_id, singular: true, model: PreservationObject

  def collections
    []
  end

  def members
    []
  end

  alias decorated_members members
  alias members_with_parents members

  # Returns a geotiff FileSet for ScannedMaps and MapSets which have attached Raster resources.
  # Use Case 1:
  # ScannedMap (MapSet) ->  ScannedMap -> RasterResource -> FileSet (target set to tiles)  + FileSet (no target - uncropped)
  #
  # Use Case 2:
  # ScannedMap -> RasterResource -> FileSet (target set to tiles - uncropped)
  def companion_geotiff(cropped: false)
    return unless parent&.is_a?(ScannedMap)
    parent_wayfinder = Wayfinder.for(parent)
    raster_resource = parent_wayfinder.raster_resources&.first
    return unless raster_resource
    raster_wayfinder = Wayfinder.for(raster_resource)
    geo_members = raster_wayfinder.geo_members
    return unless geo_members.count.positive?
    # Return the single geotiff FileSet if it's the only FileSet
    # attached to the raster. This occurs when a single (not part of a
    # set) ScannedMap has child Raster Resource. This will usually be an
    # uncropped geotiff.
    return geo_members.first if geo_members.count == 1
    if cropped
      # Return the geotiff FileSet where the service target is 'tiles'. These are cropped geotiffs.
      geo_members.find { |x| x.service_targets.present? && x.service_targets.include?("tiles") }
    else
      #  Return the geotiff FileSet where the service target is NOT 'tiled'.
      #  These are uncropped geotiffs.
      geo_members.find { |x| x.service_targets.blank? }
    end
  end
end
