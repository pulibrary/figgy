# frozen_string_literal: true
class EphemeraTermsController < BaseResourceController
  self.resource_class = EphemeraTerm
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
  before_action :load_vocabularies, only: [:new, :edit]
  before_action :load_terms, only: [:index]

  def index
    render "index"
  end

  def load_vocabularies
    @vocabularies = query_service.find_all_of_model(model: EphemeraVocabulary).map(&:decorate)
  end

  def load_terms
    @terms = query_service.find_all_of_model(model: EphemeraTerm).map(&:decorate)
  end
end
