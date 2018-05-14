# frozen_string_literal: true
class EphemeraVocabulariesController < ApplicationController
  include Valhalla::ResourceController
  include TokenAuth
  self.change_set_class = DynamicChangeSet
  self.resource_class = EphemeraVocabulary
  self.change_set_persister = ::PlumChangeSetPersister.new(
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
end
