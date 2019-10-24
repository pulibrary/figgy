# frozen_string_literal: true
class RestrictedRasterResourceDerivativeService < RasterResourceDerivativeService
  class Factory
    attr_reader :change_set_persister
    delegate :metadata_adapter, :storage_adapter, to: :change_set_persister
    delegate :query_service, to: :metadata_adapter
    def initialize(change_set_persister:)
      @change_set_persister = change_set_persister
    end

    def new(id:)
      RestrictedRasterResourceDerivativeService.new(id: id, change_set_persister: change_set_persister)
    end
  end

  def valid?
    return false if parent.model.visibility == [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC]
    parent.is_a?(RasterResource) && ControlledVocabulary::GeoRasterFormat.new.include?(mime_type.first)
  end
end
