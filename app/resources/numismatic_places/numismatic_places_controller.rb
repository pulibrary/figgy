# frozen_string_literal: true
class NumismaticPlacesController < BaseResourceController
  self.change_set_class = DynamicChangeSet
  self.resource_class = NumismaticPlace
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
  before_action :load_numismatic_places, only: :index

  def index
    render "index"
  end

  def after_create_success(_obj, _change_set)
    redirect_to numismatic_places_path
  end

  def after_update_success(_obj, _change_set)
    redirect_to numismatic_places_path
  end

  private

    def load_numismatic_places
      @numismatic_places = query_service.find_all_of_model(model: NumismaticPlace).map(&:decorate)
      return [] if @numismatic_places.to_a.blank?
    end
end
