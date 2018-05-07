# frozen_string_literal: true
class VectorResourceDerivativeService
  class Factory
    attr_reader :change_set_persister
    delegate :metadata_adapter, :storage_adapter, to: :change_set_persister
    delegate :query_service, to: :metadata_adapter
    def initialize(change_set_persister:)
      @change_set_persister = change_set_persister
    end

    def new(change_set)
      VectorResourceDerivativeService.new(change_set: change_set, change_set_persister: change_set_persister, original_file: original_file(change_set.resource))
    end

    def original_file(resource)
      resource.original_file
    end
  end

  class IoDecorator < SimpleDelegator
    attr_reader :original_filename, :content_type, :use
    def initialize(io, original_filename, content_type, use)
      @original_filename = original_filename
      @content_type = content_type
      @use = use
      super(io)
    end
  end

  attr_reader :change_set, :change_set_persister, :original_file
  delegate :mime_type, to: :original_file
  delegate :resource, to: :change_set
  def initialize(change_set:, change_set_persister:, original_file:)
    @change_set = change_set
    @change_set_persister = change_set_persister
    @original_file = original_file
  end

  def build_display_file
    IoDecorator.new(temporary_display_output, "display_vector.zip", 'application/zip; ogr-format="ESRI Shapefile"', use_display)
  end

  def build_thumbnail_file
    IoDecorator.new(temporary_thumbnail_output, "thumbnail.png", 'image/png', use_thumbnail)
  end

  # Removes Valkyrie::StorageAdapter::File member Objects for any given Resource (usually a FileSet)
  # Please note that this simply deletes the files themselves from storage
  # File membership for the parent of the Valkyrie::StorageAdapter::File is removed using #cleanup_derivative_metadata
  def cleanup_derivatives
    deleted_files = []
    vector_derivatives = resource.file_metadata.select { |file| file.derivative? || file.thumbnail_file? }
    vector_derivatives.each do |file|
      storage_adapter.delete(id: file.id)
      deleted_files << file.id
    end
    cleanup_derivative_metadata(derivatives: deleted_files)
  end

  def create_derivatives
    run_derivatives
    change_set.files = [build_display_file, build_thumbnail_file]
    change_set_persister.buffer_into_index do |buffered_persister|
      buffered_persister.save(change_set: change_set)
    end
    unzip_display
  end

  def file_object
    @file_object ||= Valkyrie::StorageAdapter.find_by(id: original_file.file_identifiers[0])
  end

  def filename
    return Pathname.new(file_object.io.path) if file_object.io.respond_to?(:path) && File.exist?(file_object.io.path)
  end

  def instructions_for_display
    {
      input_format: original_file.mime_type.first,
      label: :display_vector,
      id: resource.id,
      format: "zip",
      srid: "EPSG:3857",
      url: URI("file://#{temporary_display_output.path}")
    }
  end

  def instructions_for_thumbnail
    {
      input_format: original_file.mime_type.first,
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

  def run_derivatives
    GeoWorks::Derivatives::Runners::VectorDerivatives.create(
      filename, outputs: [instructions_for_display, instructions_for_thumbnail]
    )
  end

  def temporary_display_output
    @temporary_display_output ||= Tempfile.new
  end

  def temporary_thumbnail_output
    @temporary_thumbnail_output ||= Tempfile.new
  end

  # Unzip display raster so it can be read by GeoServer
  def unzip_display
    derivative_file = change_set.model.derivative_file
    derivative_path = Valkyrie::StorageAdapter.find_by(id: derivative_file.file_identifiers.first).io.path
    shapefile_dir = "#{File.dirname(derivative_path)}/#{File.basename(derivative_path, '.zip')}"
    system "unzip -qq -o #{derivative_path} -d #{shapefile_dir}"
  end

  def use_display
    [Valkyrie::Vocab::PCDMUse.ServiceFile]
  end

  def use_thumbnail
    [Valkyrie::Vocab::PCDMUse.ThumbnailImage]
  end

  def valid?
    parent.is_a?(VectorResource) && ControlledVocabulary::GeoVectorFormat.new.include?(mime_type.first)
  end

  private

    def storage_adapter
      @storage_adapter ||= Valkyrie::StorageAdapter.find(:geo_derivatives)
    end

    # This removes all Valkyrie::StorageAdapter::File member Objects from a given Resource (usually a FileSet)
    # Resources consistently store the membership using #file_metadata
    # A ChangeSet for the purged members is created and persisted
    def cleanup_derivative_metadata(derivatives:)
      resource.file_metadata = resource.file_metadata.reject { |file| derivatives.include?(file.id) }
      updated_change_set = DynamicChangeSet.new(resource)
      change_set_persister.buffer_into_index do |buffered_persister|
        buffered_persister.save(change_set: updated_change_set)
      end
    end
end
