# frozen_string_literal: true
class DefaultDerivativeService
  class Factory
    attr_reader :change_set_persister
    delegate :metadata_adapter, to: :change_set_persister
    delegate :query_service, to: :metadata_adapter
    def initialize(change_set_persister:)
      @change_set_persister = change_set_persister
    end

    def new(id:)
      DefaultDerivativeService.new(id: id, change_set_persister: change_set_persister)
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

  def change_set
    @change_set ||= ChangeSet.for(resource)
  end

  def valid?
    return false unless target_file
    valid_mime_types.include?(mime_type.first) && !parent.is_a?(ScannedMap)
  end

  def valid_mime_types
    ["image/tiff", "image/jpeg", "image/png"]
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

  def parent
    decorator = FileSetDecorator.new(change_set)
    decorator.parent
  end

  def create_derivatives
    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      hocr_derivative_service(buffered_changeset_persister).create_derivatives if parent.try(:ocr_language).present? && hocr_derivative_service(buffered_changeset_persister).valid?
      vips_derivative_service(buffered_changeset_persister).create_derivatives if vips_derivative_service(buffered_changeset_persister).valid?
    end
  end

  # Removes Valkyrie::StorageAdapter::File member Objects for any given Resource (usually a FileSet)
  # (see Jp2DerivativeService#cleanup_derivatives)
  def cleanup_derivatives
    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      hocr_derivative_service(buffered_changeset_persister).cleanup_derivatives if parent.try(:ocr_language).present? && hocr_derivative_service(buffered_changeset_persister).valid?
      vips_derivative_service(buffered_changeset_persister).cleanup_derivatives if vips_derivative_service(buffered_changeset_persister).valid?
    end
  end

  def hocr_derivative_service(change_set_persister = self.change_set_persister)
    HocrDerivativeService::Factory.new(change_set_persister: change_set_persister).new(id: id)
  end

  def vips_derivative_service(change_set_persister = self.change_set_persister)
    VIPSDerivativeService::Factory.new(change_set_persister: pyramidal_change_set_persister(change_set_persister)).new(id: id)
  end

  def pyramidal_change_set_persister(change_set_persister)
    change_set_persister.with(storage_adapter: Valkyrie::StorageAdapter.find(:pyramidal_derivatives))
  end
end
