# frozen_string_literal: true
class NumismaticFirmsController < BaseResourceController
  self.change_set_class = DynamicChangeSet
  self.resource_class = NumismaticFirm
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
  before_action :load_numismatic_firms, only: :index

  def index
    render "index"
  end

  private

    def load_numismatic_firms
      @numismatic_firms = query_service.find_all_of_model(model: NumismaticFirm).map(&:decorate)
      return [] if @numismatic_firms.to_a.blank?
    end
end
