# frozen_string_literal: true
class PlumDerivativeService
  class Factory
    attr_reader :change_set_persister
    delegate :metadata_adapter, to: :change_set_persister
    delegate :query_service, to: :metadata_adapter
    def initialize(change_set_persister:)
      @change_set_persister = change_set_persister
    end

    def new(change_set)
      PlumDerivativeService.new(change_set: change_set, change_set_persister: change_set_persister, original_file: original_file(change_set.resource))
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
    mime_type == ['image/tiff'] && !parent.is_a?(ScannedMap)
  end

  def parent
    decorator = FileSetDecorator.new(change_set)
    decorator.parent
  end

  def create_derivatives
    jp2_derivative_service.create_derivatives if jp2_derivative_service.valid?
  end

  def cleanup_derivatives
    jp2_derivative_service.cleanup_derivatives if jp2_derivative_service.valid?
  end

  def jp2_derivative_service
    Jp2DerivativeService::Factory.new(change_set_persister: change_set_persister).new(change_set)
  end
end
