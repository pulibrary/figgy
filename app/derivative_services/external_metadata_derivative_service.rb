# frozen_string_literal: true
class ExternalMetadataDerivativeService
  class Factory
    attr_reader :change_set_persister
    def initialize(change_set_persister:)
      @change_set_persister = change_set_persister
    end

    def new(change_set)
      ExternalMetadataDerivativeService.new(change_set: change_set, change_set_persister: change_set_persister, original_file: original_file(change_set.resource))
    end

    def original_file(resource)
      resource.original_file
    end
  end

  attr_reader :change_set, :change_set_persister, :original_file
  delegate :mime_type, to: :original_file
  def initialize(change_set:, change_set_persister:, original_file:)
    @change_set = change_set
    @change_set_persister = change_set_persister
    @original_file = original_file
  end

  def cleanup_derivatives; end

  # Extract external geo metadata into parent vector or raster resource.
  def create_derivatives
    GeoMetadataExtractor.new(change_set: parent_change_set, file_node: change_set.resource, persister: change_set_persister).extract
  end

  def parent
    decorator = FileSetDecorator.new(change_set)
    decorator.parent.model
  end

  def parent_change_set
    DynamicChangeSet.new(parent)
  end

  def valid?
    valid_mime_type? && valid_parent?
  end

  def valid_mime_type?
    ["application/xml; schema=fgdc", "application/xml; schema=iso19139"].include? mime_type.first
  end

  def valid_parent?
    parent.is_a?(VectorResource) || parent.is_a?(RasterResource)
  end
end
