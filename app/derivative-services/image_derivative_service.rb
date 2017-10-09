# frozen_string_literal: true
class ImageDerivativeService
  class Factory
    attr_reader :change_set_persister, :image_config
    delegate :metadata_adapter, to: :change_set_persister
    delegate :query_service, to: :metadata_adapter
    def initialize(change_set_persister:, image_config: ImageConfig.new(width: 200, height: 150, format: 'jpg', mime_type: 'image/jpeg', output_name: 'thumbnail'))
      @change_set_persister = change_set_persister
      @image_config = image_config
    end

    def new(change_set)
      ImageDerivativeService.new(change_set: change_set, original_file: original_file(change_set.resource), change_set_persister: change_set_persister, image_config: image_config)
    end

    def original_file(resource)
      resource.original_file
    end

    class ImageConfig < Dry::Struct
      attribute :width, Valkyrie::Types::Int
      attribute :height, Valkyrie::Types::Int
      attribute :format, Valkyrie::Types::String
      attribute :mime_type, Valkyrie::Types::String
      attribute :output_name, Valkyrie::Types::String
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
  attr_reader :change_set, :original_file, :image_config, :use, :change_set_persister
  delegate :width, :height, :format, :output_name, to: :image_config
  delegate :mime_type, to: :original_file
  delegate :resource, to: :change_set
  def initialize(change_set:, original_file:, change_set_persister:, image_config:)
    @change_set = change_set
    @original_file = original_file
    @change_set_persister = change_set_persister
    @image_config = image_config
  end

  def image_mime_type
    image_config.mime_type
  end

  def create_derivatives
    run_derivatives
    change_set.files = [build_file]
    change_set_persister.save(change_set: change_set)
  end

  def run_derivatives
    Hydra::Derivatives::ImageDerivatives.create(
      filename,
      outputs: [
        {
          label: :thumbnail,
          format: format,
          size: "#{width}x#{height}>",
          url: URI("file://#{temporary_output.path}")
        }
      ]
    )
  end

  def build_file
    IoDecorator.new(temporary_output, "#{output_name}.#{format}", image_mime_type, use)
  end

  def use
    [Valkyrie::Vocab::PCDMUse.ServiceFile]
  end

  def cleanup_derivatives
    deleted_files = []
    image_derivatives = resource.file_metadata.select { |file| file.derivative? && file.mime_type.include?(image_mime_type) }
    image_derivatives.each do |file|
      storage_adapter.delete(id: file.id)
      deleted_files << file.id
      cleanup_derivative_metadata(derivatives: deleted_files)
    end
  end

  def filename
    return Pathname.new(file_object.io.path) if file_object.io.respond_to?(:path) && File.exist?(file_object.io.path)
  end

  def file_object
    @file_object ||= Valkyrie::StorageAdapter.find_by(id: original_file.file_identifiers[0])
  end

  def temporary_output
    @temporary_file ||= Tempfile.new
  end

  ALLOWABLE_FORMATS = [
    'image/bmp',
    'image/gif',
    'image/jpeg',
    'image/png',
    'image/tiff'
  ].freeze

  def valid?
    ALLOWABLE_FORMATS.include?(mime_type.first)
  end

  private

    def storage_adapter
      @storage_adapter ||= Valkyrie::StorageAdapter.find(:derivatives)
    end

    def cleanup_derivative_metadata(derivatives:)
      resource.file_metadata = resource.file_metadata.reject { |file| derivatives.include?(file.id) }
      updated_change_set = FileSetChangeSet.new(resource)
      change_set_persister.buffer_into_index do |buffered_persister|
        buffered_persister.save(change_set: updated_change_set)
      end
    end
end
