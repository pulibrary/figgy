# frozen_string_literal: true
class VIPSDerivativeService
  class Factory
    attr_reader :change_set_persister
    delegate :metadata_adapter, to: :change_set_persister
    delegate :query_service, to: :metadata_adapter
    def initialize(change_set_persister:)
      @change_set_persister = change_set_persister
    end

    def new(id:)
      VIPSDerivativeService.new(id: id, change_set_persister: change_set_persister)
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

  attr_reader :change_set_persister, :id
  delegate :mime_type, to: :target_file
  delegate :query_service, to: :change_set_persister
  def initialize(id:, change_set_persister:)
    @id = id
    @change_set_persister = change_set_persister
  end

  def resource
    @resource ||= query_service.find_by(id: id)
  end

  def target_file
    @target_file ||= intermediate_target_files(resource) || resource.original_file
  end

  # If there are intermediate files with the supported format attached to the
  #   resource, select the first of these
  # @param [Valkyrie::Resource] resource
  # @return [FileMetadata]
  def intermediate_target_files(resource)
    supported = resource.intermediate_files.select do |intermed|
      ["image/tiff", "image/jpeg"].include?(intermed.mime_type.first)
    end
    supported.empty? ? nil : supported.first
  end

  def valid?
    ["image/tiff", "image/jpeg"].include?(mime_type.first)
  end

  def create_derivatives
    run_derivatives
    change_set.files = [build_file]
    change_set_persister.buffer_into_index do |buffered_persister|
      @resource = buffered_persister.save(change_set: change_set)
    end
    update_error_message(message: nil) if target_file.error_message.present?
  rescue StandardError => error
    update_error_message(message: error.message)
    raise error
  end

  def change_set
    @change_set ||= DynamicChangeSet.new(resource)
  end

  def run_derivatives
    vips_image.tiffsave(
      temporary_output.path.to_s,
      compression: :jpeg,
      tile: true,
      pyramid: true,
      Q: 50,
      tile_width: 1024,
      tile_height: 1024,
      strip: true
    )
    raise "Unable to store pyramidal TIFF for #{filename}!" unless File.exist?(temporary_output.path)
  end

  def vips_image
    @vips_image ||=
      begin
        if grayscale?
          Vips::Image.thumbnail(filename.to_s, 30_000, size: :down, height: 30_000, auto_rotate: true)
        else
          Vips::Image.thumbnail(filename.to_s, 30_000, size: :down, height: 30_000, auto_rotate: true, import_profile: color_profile, export_profile: color_profile)
        end
      end
  end

  def color_profile
    Hydra::Derivatives::Processors::Jpeg2kImage.srgb_profile_path
  end

  def grayscale?
    @grayscale ||= MiniMagick::Image.open(filename)["%[channels]"] == "gray"
  end

  # Removes Valkyrie::StorageAdapter::File member Objects for any given Resource (usually a FileSet)
  # Please note that this simply deletes the files themselves from storage
  # File membership for the parent of the Valkyrie::StorageAdapter::File is removed using #cleanup_derivative_metadata
  def cleanup_derivatives
    deleted_files = []
    pyramidal_derivatives = resource.file_metadata.select { |file| file.derivative? && file.mime_type.include?("image/tiff") }
    pyramidal_derivatives.each do |file|
      storage_adapter.delete(id: file.file_identifiers.first)
      deleted_files << file.id
    end
    cleanup_derivative_metadata(derivatives: deleted_files)
  end

  def build_file
    IoDecorator.new(temporary_output, "intermediate_file.tif", "image/tiff", use)
  end

  def use
    [Valkyrie::Vocab::PCDMUse.ServiceFile]
  end

  def filename
    Pathname.new(file_object.disk_path)
  end

  def file_object
    @file_object ||= Valkyrie::StorageAdapter.find_by(id: target_file.file_identifiers[0])
  end

  def temporary_output
    @temporary_file ||= Tempfile.new(["intermediate_file", ".tif"])
  end

  private

    # This removes all Valkyrie::StorageAdapter::File member Objects from a given Resource (usually a FileSet)
    # and clears error messages from remaining files
    # Resources consistently store the membership using #file_metadata
    # A ChangeSet for the purged members is created and persisted
    def cleanup_derivative_metadata(derivatives:)
      resource.file_metadata = resource.file_metadata.reject { |file| derivatives.include?(file.id) }
      resource.file_metadata.map { |fm| fm.error_message = [] }
      updated_change_set = DynamicChangeSet.new(resource)
      change_set_persister.buffer_into_index do |buffered_persister|
        buffered_persister.save(change_set: updated_change_set)
      end
    end

    def storage_adapter
      @storage_adapter ||= Valkyrie::StorageAdapter.find(:pyramidal_derivatives)
    end

    # Updates error message property on the original file.
    def update_error_message(message:)
      target_file.error_message = [message]
      updated_change_set = DynamicChangeSet.new(resource)
      change_set_persister.buffer_into_index do |buffered_persister|
        buffered_persister.save(change_set: updated_change_set)
      end
    end
end
