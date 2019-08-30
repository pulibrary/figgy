# frozen_string_literal: true
class ScannedMapDerivativeService
  class Factory
    attr_reader :change_set_persister
    delegate :metadata_adapter, to: :change_set_persister
    delegate :query_service, to: :metadata_adapter
    def initialize(change_set_persister:)
      @change_set_persister = change_set_persister
    end

    def new(id:)
      ScannedMapDerivativeService.new(id: id, change_set_persister: change_set_persister)
    end
  end

  attr_reader :id, :change_set_persister
  delegate :original_file, to: :resource
  delegate :mime_type, to: :original_file
  delegate :query_service, to: :change_set_persister
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

  def valid?
    return false unless original_file
    mime_type == ["image/tiff"] && parent.is_a?(ScannedMap)
  end

  def parent
    decorator = FileSetDecorator.new(change_set)
    decorator.parent
  end

  def create_derivatives
    jp2_derivative_service.create_derivatives if jp2_derivative_service.valid?
    thumbnail_derivative_service.create_derivatives if thumbnail_derivative_service.valid?
  end

  # Removes Valkyrie::StorageAdapter::File member Objects for any given Resource (usually a FileSet)
  # (see Jp2DerivativeService#cleanup_derivatives)
  # (see ImageDerivativeService#cleanup_derivatives)
  def cleanup_derivatives
    jp2_derivative_service.cleanup_derivatives if jp2_derivative_service.valid?
    thumbnail_derivative_service.cleanup_derivatives if thumbnail_derivative_service.valid?
  end

  def jp2_derivative_service
    Jp2DerivativeService::Factory.new(change_set_persister: change_set_persister).new(id: id)
  end

  def thumbnail_derivative_service
    ImageDerivativeService::Factory.new(change_set_persister: change_set_persister, image_config: image_config).new(id: id)
  end

  def image_config
    ImageDerivativeService::Factory::ImageConfig.new(width: 200,
                                                     height: 150,
                                                     format: "png",
                                                     mime_type: "image/png",
                                                     output_name: "thumbnail")
  end
end
