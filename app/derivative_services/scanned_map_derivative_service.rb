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
  delegate :primary_file, to: :resource
  delegate :mime_type, to: :primary_file
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
    return false unless primary_file
    valid_mime_types.include?(mime_type.first) && parent.is_a?(ScannedMap)
  end

  def valid_mime_types
    ["image/tiff", "image/jpeg", "image/png"]
  end

  def parent
    decorator = FileSetDecorator.new(change_set)
    decorator.parent
  end

  def create_derivatives
    vips_derivative_service.create_derivatives if vips_derivative_service.valid?
    thumbnail_derivative_service.create_derivatives if thumbnail_derivative_service.valid?
  end

  # Removes Valkyrie::StorageAdapter::File member Objects for any given Resource (usually a FileSet)
  # (see ImageDerivativeService#cleanup_derivatives)
  def cleanup_derivatives
    vips_derivative_service.cleanup_derivatives if vips_derivative_service.valid?
    thumbnail_derivative_service.cleanup_derivatives if thumbnail_derivative_service.valid?
  end

  def thumbnail_derivative_service
    ThumbnailDerivativeService::Factory.new(change_set_persister: change_set_persister).new(id: id)
  end

  def vips_derivative_service
    VIPSDerivativeService::Factory.new(change_set_persister: pyramidal_change_set_persister(change_set_persister)).new(id: id)
  end

  def pyramidal_change_set_persister(change_set_persister)
    change_set_persister.with(storage_adapter: Valkyrie::StorageAdapter.find(:pyramidal_derivatives))
  end
end
