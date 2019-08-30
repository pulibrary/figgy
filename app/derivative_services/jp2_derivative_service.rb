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
    @change_set ||= ChangeSet.for(resource)
  end

  def parent
    decorator = FileSetDecorator.new(change_set)
    decorator.parent
  end

  def recipe
    return :default unless parent.is_a?(ScannedMap)
    :geo
  end

  def run_derivatives
    case mime_type
    when ["image/tiff"]
      run_tiff_derivatives
    when ["image/jpeg"]
      run_jpg_derivatives
    end
  end

  def run_tiff_derivatives
    create_tiff_derivative(filename)
  rescue RuntimeError # Rescue if there's a compression error.
    create_tiff_derivative(clean_filename)
  end

  def create_tiff_derivative(filename)
    Hydra::Derivatives::Jpeg2kImageDerivatives.create(
      filename,
      outputs: [
        label: "intermediate_file",
        recipe: recipe,
        service: {
          datastream: "intermediate_file"
        },
        url: URI("file://#{temporary_output.path}")
      ]
    )
  end

  def run_jpg_derivatives
    create_tiff_derivative(jpg_tiff_filename)
  end

  def jpg_tiff_filename
    @jpg_tiff_filename ||=
      begin
        Hydra::Derivatives::ImageDerivatives.create(
          filename,
          outputs: [
            label: "intermediate_file",
            url: URI("file://#{temporary_jpg_tiff.path}"),
            format: "tiff"
          ]
        )
        temporary_jpg_tiff
      end
  end

  def temporary_jpg_tiff
    @temporary_jpg_tiff ||= Tempfile.new(["temporary_jpg", ".tiff"])
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

  def build_file
    IoDecorator.new(temporary_output, "intermediate_file.jp2", "image/jp2", use)
  end

  def use
    [Valkyrie::Vocab::PCDMUse.ServiceFile]
  end

  def filename
    Pathname.new(file_object.disk_path)
  end

  def clean_filename
    @filename ||=
      begin
        Pathname.new(cleaned_file.path)
      end
  end

  # Remove compression from given TIFF file, just in case.
  def cleaned_file
    @cleaned_file ||=
      begin
        t = Tempfile.new
        MiniMagick::Tool::Convert.new do |convert|
          convert << file_object.disk_path.to_s
          convert.compress.+
          convert << t.path.to_s
        end
        t
      end
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
