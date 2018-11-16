# frozen_string_literal: true
class NumismaticAccessionsController < BaseResourceController
  self.change_set_class = DynamicChangeSet
  self.resource_class = NumismaticAccession
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
  before_action :load_numismatic_accessions, only: :index

  def index
    render "index"
  end

  private

    def load_numismatic_accessions
      @numismatic_accessions = query_service.find_all_of_model(model: NumismaticAccession).map(&:decorate)
    end
end
