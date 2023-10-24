# frozen_string_literal: true
class ThumbnailDerivativeService
  class Factory
    attr_reader :change_set_persister, :image_config
    delegate :metadata_adapter, to: :change_set_persister
    delegate :query_service, to: :metadata_adapter
    def initialize(change_set_persister:, image_config: ImageConfig.new(width: 200, height: 150))
      @change_set_persister = change_set_persister
      @image_config = image_config
    end

    def new(id:)
      ThumbnailDerivativeService.new(id: id, change_set_persister: change_set_persister, image_config: image_config)
    end

    class ImageConfig < Dry::Struct
      attribute :width, Valkyrie::Types::Integer
      attribute :height, Valkyrie::Types::Integer
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

  attr_reader :image_config, :change_set_persister, :id
  delegate :width, :height, to: :image_config
  delegate :mime_type, to: :target_file
  delegate :query_service, :storage_adapter, to: :change_set_persister
  def initialize(id:, change_set_persister:, image_config:)
    @id = id
    @change_set_persister = change_set_persister
    @image_config = image_config
  end

  def format
    "png"
  end

  def thumbnail_mime_type
    "image/png"
  end

  def resource
    @resource ||= query_service.find_by(id: id)
  end

  def target_file
    @target_file ||= intermediate_target_files(resource) || resource.primary_file
  end

  # If there are intermediate files with the supported format attached to the
  #   resource, select the first of these
  # @param [Valkyrie::Resource] resource
  # @return [FileMetadata]
  def intermediate_target_files(resource)
    supported = resource.intermediate_files.select do |intermed|
      valid_mime_types.include?(intermed.mime_type.first)
    end
    supported.empty? ? nil : supported.first
  end

  def valid?
    valid_mime_types.include?(mime_type.first)
  end

  def valid_mime_types
    ["image/tiff", "image/jpeg", "image/png"]
  end

  def create_derivatives
    run_derivatives
    change_set.files = [build_file]
    change_set_persister.buffer_into_index do |buffered_persister|
      @resource = buffered_persister.save(change_set: change_set)
    end
    update_error_message(message: nil) if target_file.error_message.present?
  rescue StandardError => error
    change_set_persister.after_rollback.add do
      update_error_message(message: error.message)
    end
    raise error
  end

  def change_set
    @change_set ||= ChangeSet.for(resource)
  end

  def run_derivatives
    vips_image.pngsave(
      temporary_output.path.to_s,
      strip: true
    )
    raise "Unable to store thunbnail for #{filename}!" unless File.exist?(temporary_output.path)
  end

  def vips_image
    @vips_image ||=
      Vips::Image.thumbnail(
          filename.to_s,
          width,
          height: height
        )
  end

  # Removes Valkyrie::StorageAdapter::File member Objects for any given Resource (usually a FileSet)
  # Please note that this simply deletes the files themselves from storage
  # File membership for the parent of the Valkyrie::StorageAdapter::File is removed using #cleanup_derivative_metadata
  def cleanup_derivatives
    deleted_files = []
    image_derivatives = resource.file_metadata.select { |file| (file.derivative? || file.thumbnail_file?) && file.mime_type.include?(thumbnail_mime_type) }
    image_derivatives.each do |file|
      storage_adapter.delete(id: file.file_identifiers.first)
      deleted_files << file.id
    end
    cleanup_derivative_metadata(derivatives: deleted_files)
  end

  def build_file
    IoDecorator.new(temporary_output, "thumbnail.#{format}", thumbnail_mime_type, use)
  end

  def use
    [Valkyrie::Vocab::PCDMUse.ThumbnailImage]
  end

  def filename
    Pathname.new(file_object.disk_path)
  end

  def file_object
    @file_object ||= Valkyrie::StorageAdapter.find_by(id: target_file.file_identifiers[0])
  end

  def temporary_output
    @temporary_file ||= Tempfile.new
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

    # Updates error message property on the original file.
    def update_error_message(message:)
      resource = change_set_persister.query_service.find_by(id: self.resource.id)
      target = resource.file_metadata.find { |x| x.id == target_file.id }
      target.error_message = [message]
      updated_change_set = ChangeSet.for(resource)
      change_set_persister.buffer_into_index do |buffered_persister|
        buffered_persister.save(change_set: updated_change_set)
      end
    end
end
