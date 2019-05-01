# frozen_string_literal: true
class NumismaticAccessionsController < BaseResourceController
  self.change_set_class = DynamicChangeSet
  self.resource_class = NumismaticAccession
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
  before_action :load_numismatic_accessions, only: :index
  before_action :load_numismatic_people, only: [:new, :edit]
  before_action :load_numismatic_references, only: [:new, :edit]

  def index
    render "index"
  end

  def after_create_success(_obj, _change_set)
    redirect_to numismatic_accessions_path
  end

  def after_update_success(_obj, _change_set)
    redirect_to numismatic_accessions_path
  end

  private

    def load_numismatic_accessions
      @numismatic_accessions = query_service.find_all_of_model(model: NumismaticAccession).map(&:decorate)
    end

    def load_numismatic_people
      @numismatic_people = query_service.find_all_of_model(model: NumismaticPerson).map(&:decorate)
    end

    def load_numismatic_references
      @numismatic_references = query_service.find_all_of_model(model: NumismaticReference).map(&:decorate).sort_by(&:short_title)
    end
end
