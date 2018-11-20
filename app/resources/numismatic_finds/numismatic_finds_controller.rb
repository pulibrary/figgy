# frozen_string_literal: true
class NumismaticFindsController < BaseResourceController
  self.change_set_class = DynamicChangeSet
  self.resource_class = NumismaticFind
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
  before_action :load_numismatic_finds, only: :index

  def index
    render "index"
  end

  private

    def load_numismatic_finds
      @numismatic_finds = query_service.find_all_of_model(model: NumismaticFind).map(&:decorate)
    end
end
