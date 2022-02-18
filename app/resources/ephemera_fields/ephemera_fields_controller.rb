# frozen_string_literal: true

class EphemeraFieldsController < ResourceController
  self.resource_class = EphemeraField
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
  before_action :load_vocabularies, only: [:new, :edit]

  def load_vocabularies
    @vocabularies = query_service.find_all_of_model(model: EphemeraVocabulary).map(&:decorate).sort_by(&:label)
  end
end
