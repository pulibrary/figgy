# frozen_string_literal: true
class ExternalMetadataDerivativeService
  class Factory
    attr_reader :change_set_persister
    def initialize(change_set_persister:)
      @change_set_persister = change_set_persister
    end

    def new(id:)
      ExternalMetadataDerivativeService.new(id: id, change_set_persister: change_set_persister)
    end
  end

  attr_reader :id, :change_set_persister
  delegate :mime_type, to: :original_file
  delegate :original_file, to: :resource
  delegate :query_service, to: :change_set_persister
  def initialize(id:, change_set_persister:)
    @id = id
    @change_set_persister = change_set_persister
  end

  def resource
    @resource ||= query_service.find_by(id: id)
  end

  def cleanup_derivatives; end

  # Extract external geo metadata into parent vector or raster resource.
  def create_derivatives
    GeoMetadataExtractor.new(change_set: parent_change_set, file_node: resource, persister: change_set_persister).extract
  end

  def parent
    decorator = FileSetDecorator.new(resource)
    decorator.parent.model
  end

  def parent_change_set
    ChangeSet.for(parent)
  end

  def valid?
    valid_mime_type? && valid_parent?
  end

  def valid_mime_type?
    return false unless original_file
    ["application/xml; schema=fgdc", "application/xml; schema=iso19139"].include? mime_type.first
  end

  def valid_parent?
    parent.is_a?(VectorResource) || parent.is_a?(RasterResource)
  end
end
