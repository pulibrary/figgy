# frozen_string_literal: true
class Jp2DerivativeService
  class Factory
    attr_reader :change_set_persister
    delegate :metadata_adapter, to: :change_set_persister
    delegate :query_service, to: :metadata_adapter
    def initialize(change_set_persister:)
      @change_set_persister = change_set_persister
    end

    def new(change_set)
      Jp2DerivativeService.new(change_set: change_set, change_set_persister: change_set_persister, original_file: original_file(change_set.resource))
    end

    def original_file(resource)
      members(resource).find { |x| x.use.include?(Valkyrie::Vocab::PCDMUse.OriginalFile) }
    end

    def members(resource)
      metadata_adapter.query_service.find_members(resource: resource)
    end
  end

  attr_reader :change_set, :change_set_persister, :original_file
  delegate :mime_type, to: :original_file
  def initialize(change_set:, change_set_persister:, original_file:)
    @change_set = change_set
    @change_set_persister = change_set_persister
    @original_file = original_file
  end

  def valid?
    mime_type == ['image/tiff']
  end

  def create_derivatives
    Hydra::Derivatives::Jpeg2kImageDerivatives.create(
      filename,
      outputs: [
        label: 'intermediate_file',
        recipe: :default,
        service: {
          datastream: 'intermediate_file'
        },
        url: URI("file://#{temporary_output.path}")
      ]
    )
    change_set.files = [build_file]
    change_set_persister.save(change_set: change_set)
  end

  def cleanup_derivatives; end

  class IoDecorator < SimpleDelegator
    attr_reader :original_filename, :content_type, :use
    def initialize(io, original_filename, content_type, use)
      @original_filename = original_filename
      @content_type = content_type
      @use = use
      super(io)
    end
  end

  def build_file
    IoDecorator.new(temporary_output, "intermediate_file.jp2", mime_type, use)
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
end
