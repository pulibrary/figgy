# frozen_string_literal: true
class EphemeraTermsController < ApplicationController
  include Valhalla::ResourceController
  include TokenAuth
  self.change_set_class = DynamicChangeSet
  self.resource_class = EphemeraTerm
  self.change_set_persister = ::PlumChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
  before_action :load_vocabularies, only: [:new, :edit]
  before_action :load_terms, only: [:index]
  rescue_from CanCan::AccessDenied, with: :deny_resource_access

  def index
    render 'index'
  end

  def load_vocabularies
    @vocabularies = query_service.find_all_of_model(model: EphemeraVocabulary).map(&:decorate)
  end

  def load_terms
    @terms = query_service.find_all_of_model(model: EphemeraTerm).map(&:decorate)
  end
end
