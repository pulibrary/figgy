# frozen_string_literal: true
class DefaultDerivativeService
  class Factory
    attr_reader :change_set_persister
    delegate :metadata_adapter, to: :change_set_persister
    delegate :query_service, to: :metadata_adapter
    def initialize(change_set_persister:)
      @change_set_persister = change_set_persister
    end

    def new(change_set)
      DefaultDerivativeService.new(change_set: change_set, change_set_persister: change_set_persister, original_file: original_file(change_set.resource))
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

  def valid?
    ["image/tiff", "image/jpeg"].include?(mime_type.first) && !parent.is_a?(ScannedMap)
  end

  def parent
    decorator = FileSetDecorator.new(change_set)
    decorator.parent
  end

  def create_derivatives
    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      hocr_derivative_service(buffered_changeset_persister).create_derivatives if parent.try(:ocr_language).present? && hocr_derivative_service(buffered_changeset_persister).valid?
      jp2_derivative_service(buffered_changeset_persister).create_derivatives if jp2_derivative_service(buffered_changeset_persister).valid?
    end
  end

  # Removes Valkyrie::StorageAdapter::File member Objects for any given Resource (usually a FileSet)
  # (see Jp2DerivativeService#cleanup_derivatives)
  def cleanup_derivatives
    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      hocr_derivative_service(buffered_changeset_persister).cleanup_derivatives if parent.try(:ocr_language).present? && hocr_derivative_service(buffered_changeset_persister).valid?
      jp2_derivative_service(buffered_changeset_persister).cleanup_derivatives if jp2_derivative_service(buffered_changeset_persister).valid?
    end
  end

  def jp2_derivative_service(change_set_persister = self.change_set_persister)
    Jp2DerivativeService::Factory.new(change_set_persister: change_set_persister).new(change_set)
  end

  def hocr_derivative_service(change_set_persister = self.change_set_persister)
    HocrDerivativeService::Factory.new(change_set_persister: change_set_persister).new(change_set)
  end
end
