# Builds a reduced-resolution pyramidal TIFF
class PyramidalThumbnailDerivativeService < VipsDerivativeService
  def use
    [::PcdmUse::ThumbnailServiceFile]
  end

  def derivative_filename
    "thumbnail.tif"
  end

  # Scales the image relative to the shortest edge of the image
  def resize(image)
    shortest_edge = [image.get("width"), image.get("height")].min
    image.resize(TILE_SIZE.to_f / shortest_edge)
  end

  def cleanup_derivatives
    deleted_files = []
    resource.file_metadata.select(&:thumbnail_derivative?).each do |file|
      storage_adapter.delete(id: file.file_identifiers.first)
      deleted_files << file.id
    end
    cleanup_derivative_metadata(derivatives: deleted_files)
  end
end
