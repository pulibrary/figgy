# frozen_string_literal: true
class EphemeraTermsController < ResourcesController
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

  def destroy
    folders = query_service.custom_queries.find_id_usage_by_model(model: EphemeraFolder, id: resource.id)
    if folders.empty?
      super
    else
      flash[:alert] = "This is term is currently in use. To delete, please remove from related folders."
      redirect_back(fallback_location: root_path)
    end
  end

  def load_vocabularies
    @vocabularies = query_service.find_all_of_model(model: EphemeraVocabulary).map(&:decorate)
  end

  def load_terms
    @terms = query_service.find_all_of_model(model: EphemeraTerm).map(&:decorate)
  end
end
