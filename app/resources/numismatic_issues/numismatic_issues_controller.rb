# frozen_string_literal: true
class NumismaticIssuesController < BaseResourceController
  self.change_set_class = DynamicChangeSet
  self.resource_class = NumismaticIssue
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )

  before_action :load_numismatic_references, only: [:new, :edit]
  before_action :load_monograms, only: [:new, :edit]
  before_action :load_numismatic_places, only: [:new, :edit]

  def load_numismatic_places
    @numismatic_places = query_service.find_all_of_model(model: NumismaticPlace).map(&:decorate)
  end

  def load_numismatic_references
    @numismatic_references = query_service.find_all_of_model(model: NumismaticReference).map(&:decorate).sort_by(&:short_title)
  end

  def load_monograms
    @numismatic_monograms = query_service.find_all_of_model(model: NumismaticMonogram).map(&:decorate)
    return [] if @numismatic_monograms.to_a.blank?
  end

  def manifest
    authorize! :manifest, resource
    respond_to do |f|
      f.json do
        render json: ManifestBuilder.new(resource).build
      end
    end
  end
end
