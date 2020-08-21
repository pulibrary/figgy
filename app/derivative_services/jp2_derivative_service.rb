# frozen_string_literal: true
class Jp2DerivativeService
  class Factory
    attr_reader :change_set_persister
    delegate :metadata_adapter, :storage_adapter, to: :change_set_persister
    delegate :query_service, to: :metadata_adapter
    def initialize(change_set_persister:)
      @change_set_persister = change_set_persister
    end

    def new(id:)
      Jp2DerivativeService.new(id: id, change_set_persister: change_set_persister)
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
    output = create_tiff_derivative(filename)
    change_set.files = [build_file(output)]
    change_set_persister.buffer_into_index do |buffered_persister|
      @resource = buffered_persister.save(change_set: change_set)
    end
    update_error_message(message: nil) if target_file.error_message.present?
  rescue StandardError => error
    update_error_message(message: error.message)
    raise error
  end

  def change_set
    @change_set ||= ChangeSet.for(resource)
  end

  def create_tiff_derivative(filename)
    JP2Creator.new(filename: filename).generate
  end

  def correct_color(filename)
    temp_file = Tempfile.new(["tempfile", ".tif"])
    file = MiniMagick::Image.open(filename)
    return File.open(filename) unless file["%[channels]"] != "gray"
    file.format "tiff"
    file.combine_options do |c|
      c.profile Hydra::Derivatives::Processors::Jpeg2kImage.srgb_profile_path
      c.type "truecolor"
    end
    file.write temp_file.path
    temp_file
  end

  # Removes Valkyrie::StorageAdapter::File member Objects for any given Resource (usually a FileSet)
  # Please note that this simply deletes the files themselves from storage
  # File membership for the parent of the Valkyrie::StorageAdapter::File is removed using #cleanup_derivative_metadata
  def cleanup_derivatives
    deleted_files = []
    jp2_derivatives = resource.file_metadata.select { |file| file.derivative? && file.mime_type.include?("image/jp2") }
    jp2_derivatives.each do |file|
      storage_adapter.delete(id: file.file_identifiers.first)
      deleted_files << file.id
    end
    cleanup_derivative_metadata(derivatives: deleted_files)
  end

  def build_file(output)
    IoDecorator.new(output, "intermediate_file.jp2", "image/jp2", use)
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
      @storage_adapter ||= Valkyrie::StorageAdapter.find(:derivatives)
    end

    # Updates error message property on the original file.
    def update_error_message(message:)
      target_file.error_message = [message]
      updated_change_set = ChangeSet.for(resource)
      change_set_persister.buffer_into_index do |buffered_persister|
        buffered_persister.save(change_set: updated_change_set)
      end
    end
end
