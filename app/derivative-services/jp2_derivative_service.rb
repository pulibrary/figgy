# frozen_string_literal: true
class Jp2DerivativeService
  class Factory
    attr_reader :change_set_persister
    delegate :metadata_adapter, :storage_adapter, to: :change_set_persister
    delegate :query_service, to: :metadata_adapter
    def initialize(change_set_persister:)
      @change_set_persister = change_set_persister
    end

    def new(change_set)
      Jp2DerivativeService.new(change_set: change_set, change_set_persister: change_set_persister, original_file: original_file(change_set.resource))
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

  def valid?
    mime_type == ['image/tiff']
  end

  def create_derivatives
    run_derivatives
    change_set.files = [build_file]
    change_set_persister.buffer_into_index do |buffered_persister|
      buffered_persister.save(change_set: change_set)
    end
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
    Hydra::Derivatives::Jpeg2kImageDerivatives.create(
      filename,
      outputs: [
        label: 'intermediate_file',
        recipe: recipe,
        service: {
          datastream: 'intermediate_file'
        },
        url: URI("file://#{temporary_output.path}")
      ]
    )
  end

  def cleanup_derivatives
    deleted_files = []
    jp2_derivatives = resource.file_metadata.select { |file| file.derivative? && file.mime_type.include?('image/jp2') }
    jp2_derivatives.each do |file|
      storage_adapter.delete(id: file.id)
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
    return Pathname.new(file_object.io.path) if file_object.io.respond_to?(:path) && File.exist?(file_object.io.path)
  end

  def file_object
    @file_object ||= Valkyrie::StorageAdapter.find_by(id: original_file.file_identifiers[0])
  end

  def temporary_output
    @temporary_file ||= Tempfile.new
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
