# frozen_string_literal: true
class NumismaticReferencesController < BaseResourceController
  self.change_set_class = DynamicChangeSet
  self.resource_class = NumismaticReference
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
  before_action :load_numismatic_references, only: :index

  def index
    render "index"
  end

  private

    def load_numismatic_references
      @numismatic_references = query_service.find_all_of_model(model: NumismaticReference).map(&:decorate)
    end
end
