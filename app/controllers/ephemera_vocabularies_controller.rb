# frozen_string_literal: true
class EphemeraVocabulariesController < ResourcesController
  self.resource_class = EphemeraVocabulary
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
  before_action :load_vocabularies, only: [:index, :new, :edit]

  def index
    render "index"
  end

  def load_vocabularies
    @vocabularies = query_service.find_all_of_model(model: EphemeraVocabulary).map(&:decorate).sort_by(&:label)
  end

  def around_delete_action
    # Only allow deleting empty vocabularies. Avoids difficulty of restoring a
    # full vocabulary from preservation and supporting restoring accidentally
    # deleted vocabularies.
    if Wayfinder.for(@change_set.resource).members_count.positive?
      flash[:alert] = "Unable to delete a vocabulary with members."
      redirect_to solr_document_path(@change_set.resource.id.to_s)
    else
      yield
    end
  end
end
