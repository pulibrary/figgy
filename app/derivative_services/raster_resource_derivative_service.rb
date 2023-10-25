# frozen_string_literal: true
class RasterResourceDerivativeService
  class Factory
    attr_reader :change_set_persister
    delegate :metadata_adapter, :storage_adapter, to: :change_set_persister
    delegate :query_service, to: :metadata_adapter
    def initialize(change_set_persister:)
      @change_set_persister = change_set_persister
    end

    def new(id:)
      RasterResourceDerivativeService.new(id: id, change_set_persister: change_set_persister)
    end
  end

  attr_reader :id, :change_set_persister
  delegate :mime_type, to: :primary_file
  delegate :query_service, to: :change_set_persister
  delegate :primary_file, to: :resource
  def initialize(id:, change_set_persister:)
    @id = id
    @change_set_persister = change_set_persister
  end

  def resource
    @resource ||= query_service.find_by(id: id)
  end

  def change_set
    @change_set ||= ChangeSet.for(resource)
  end

  def build_display_file
    IngestableFile.new(file_path: temporary_display_output.path, mime_type: "image/tiff; gdal-format=GTiff", original_filename: "display_raster.tif", use: use_display, copy_before_ingest: false)
  end

  def build_cloud_file
    IngestableFile.new(file_path: temporary_display_output.path, mime_type: "image/tiff; gdal-format=GTiff", original_filename: "display_raster.tif", use: use_cloud_derivative,
                       copy_before_ingest: false)
  end

  def build_thumbnail_file
    IngestableFile.new(file_path: temporary_thumbnail_output.path, mime_type: "image/png", use: use_thumbnail, original_filename: "thumbnail.png", copy_before_ingest: true)
  end

  # Removes Valkyrie::StorageAdapter::File member Objects for any given Resource (usually a FileSet)
  # Please note that this simply deletes the files themselves from storage
  # File membership for the parent of the Valkyrie::StorageAdapter::File is removed using #cleanup_derivative_metadata
  def cleanup_derivatives
    deleted_files = []
    raster_derivatives = resource.file_metadata.select { |file| file.derivative? || file.thumbnail_file? || file.cloud_derivative? }
    raster_derivatives.each do |file|
      storage_adapter.delete(id: file.file_identifiers.first)
      deleted_files << file.id
    end
    cleanup_derivative_metadata(derivatives: deleted_files)
    generate_mosaic unless deleted_files.empty?
  end

  def create_derivatives
    run_derivatives
    create_local_derivatives
    # Persist a second copy of the display file to the cloud.
    create_cloud_derivatives
    update_cloud_acl
    generate_mosaic
    update_error_message(message: nil) if primary_file.error_message.present?
  rescue StandardError => error
    change_set_persister.after_rollback.add do
      update_error_message(message: error.message)
    end
    raise error
  end

  def cloud_storage_adapter
    Valkyrie::StorageAdapter.find(:cloud_geo_derivatives)
  end

  def file_object
    @file_object ||= Valkyrie::StorageAdapter.find_by(id: primary_file.file_identifiers[0])
  end

  def filename
    return Pathname.new(file_object.disk_path) if file_object.respond_to?(:disk_path) && File.exist?(file_object.disk_path)
  end

  def instructions_for_display
    {
      input_format: primary_file.mime_type.first,
      label: :display_raster,
      id: prefixed_id,
      format: "tif",
      srid: "EPSG:3857",
      url: URI("file://#{temporary_display_output.path}")
    }
  end

  def instructions_for_thumbnail
    {
      input_format: primary_file.mime_type.first,
      label: :thumbnail,
      id: resource.id,
      format: "png",
      size: "200x150",
      url: URI("file://#{temporary_thumbnail_output.path}")
    }
  end

  def parent
    decorator = FileSetDecorator.new(change_set)
    decorator.parent
  end

  # Resource id prefixed with letter to avoid restrictions on
  # numbers in QNames from GeoServer generated WFS GML.
  def prefixed_id
    "p-#{resource.id}"
  end

  # generates the derivatives used for local/cloud display and thumbnail files
  def run_derivatives
    GeoDerivatives::Runners::RasterDerivatives.create(
      filename, outputs: [instructions_for_display, instructions_for_thumbnail]
    )
  end

  def temporary_display_output
    @temporary_display_output ||= Tempfile.new
  end

  def temporary_thumbnail_output
    @temporary_thumbnail_output ||= Tempfile.new
  end

  def update_cloud_acl
    parent = Wayfinder.for(change_set.model).parent
    cloud_file = change_set.model.cloud_derivative_files.first
    key = cloud_file.file_identifiers.first.to_s.gsub("cloud-geo-derivatives-shrine://", "")
    CloudFilePermissionsService.new(resource: parent, key: key).run
  end

  def use_display
    [Valkyrie::Vocab::PCDMUse.ServiceFile]
  end

  def use_thumbnail
    [Valkyrie::Vocab::PCDMUse.ThumbnailImage]
  end

  def use_cloud_derivative
    [Valkyrie::Vocab::PCDMUse.CloudDerivative]
  end

  def valid?
    parent.is_a?(RasterResource) && ControlledVocabulary::GeoRasterFormat.new.include?(mime_type.first)
  end

  private

    # This removes all Valkyrie::StorageAdapter::File member Objects from a given Resource (usually a FileSet)
    # and clears error messages from remaining files
    # Resources consistently store the membership using #file_metadata
    # A ChangeSet for the purged members is created and persisted
    def cleanup_derivative_metadata(derivatives:)
      resource.file_metadata = resource.file_metadata.reject { |file| derivatives.include?(file.id) }
      resource.file_metadata.map { |fm| fm.error_message = [] }
      updated_change_set = ChangeSet.for(resource)
      change_set_persister.buffer_into_index do |buffered_persister|
        buffered_persister.save(change_set: updated_change_set)
      end
    end

    def storage_adapter
      @storage_adapter ||= Valkyrie::StorageAdapter.find(:geo_derivatives)
    end

    # Updates error message property on the original file.
    def update_error_message(message:)
      # refresh the resource to avoid stale object error
      @resource = query_service.find_by(id: id)
      primary_file.error_message = [message]
      updated_change_set = ChangeSet.for(resource)
      change_set_persister.buffer_into_index do |buffered_persister|
        buffered_persister.save(change_set: updated_change_set)
      end
    end

    def generate_mosaic
      parent = resource.decorate.parent
      grandparent = parent.parents.first
      return unless grandparent.is_a? RasterResource
      return unless grandparent.decorate.public_readable_state?
      MosaicJob.perform_later(grandparent.id.to_s)
    end

    def create_local_derivatives
      return unless missing_local_display? && missing_thumbnail?
      @resource = query_service.find_by(id: id)
      @change_set = ChangeSet.for(resource)
      change_set.files = [build_display_file, build_thumbnail_file]
      change_set_persister.buffer_into_index do |buffered_persister|
        @resource = buffered_persister.save(change_set: change_set)
      end
    end

    def create_cloud_derivatives
      @change_set = ChangeSet.for(resource)
      change_set.files = [build_cloud_file]
      change_set_persister.with(storage_adapter: cloud_storage_adapter) do |cloud_persister|
        cloud_persister.buffer_into_index do |buffered_persister|
          @resource = buffered_persister.save(change_set: change_set)
        end
      end
    end

    def missing_local_display?
      resource.file_metadata.find_all { |fm| fm.use == use_display }.empty?
    end

    def missing_thumbnail?
      resource.file_metadata.find_all { |fm| fm.use == use_thumbnail }.empty?
    end
end
